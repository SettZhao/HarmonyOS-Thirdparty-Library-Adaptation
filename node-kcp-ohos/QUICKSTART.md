# KCP for OpenHarmony - 快速开始

## 安装和导入

### 在 DevEco Studio 中添加依赖

1. 将 `kcp.har` 文件放入项目的 `libs` 目录
2. 在 `oh-package.json5` 中添加依赖：

```json5
{
  "dependencies": {
    "kcp": "file:../library"  // 或 "file:libs/kcp.har"
  }
}
```

### 导入 KCP

```typescript
import { KCP, KCPContext } from 'kcp';
```

## 基本使用

### 1. 创建 KCP 实例

```typescript
// 创建 KCP 实例（conv 是会话 ID，两端必须一致）
const conv = 123;
const kcp = new KCP(conv);

// 或者带上下文信息
const context: KCPContext = {
  address: '192.168.1.100',
  port: 41234
};
const kcp = new KCP(conv, context);
```

### 2. 配置 KCP 参数

```typescript
// 快速模式（低延迟）
kcp.nodelay(
  1,    // nodelay: 1=启用快速模式, 0=禁用
  10,   // interval: 内部更新间隔(ms)
  2,    // resend: 快速重传倍数
  1     // nc: 1=关闭拥塞控制
);

// 设置窗口大小
kcp.wndsize(128, 128);  // 发送窗口, 接收窗口

// 设置 MTU
kcp.setmtu(1400);

// 设置流模式（可选）
kcp.stream(1);  // 1=流模式, 0=消息模式
```

### 3. 设置输出回调

```typescript
// 当 KCP 需要发送数据时会调用此回调
kcp.output((data: ArrayBuffer, size: number, ctx?: KCPContext) => {
  // 通过 UDP socket 发送数据
  if (ctx) {
    udpSocket.send({
      data: data,
      address: {
        address: ctx.address!,
        port: ctx.port!
      }
    });
  }
});
```

### 4. 发送数据

```typescript
// 发送字符串
kcp.send('Hello KCP!');

// 发送 ArrayBuffer
const buffer = new ArrayBuffer(1024);
kcp.send(buffer);
```

### 5. 接收网络数据

```typescript
// 当从网络接收到数据时
udpSocket.on('message', (msg) => {
  // 输入数据到 KCP
  kcp.input(msg.message);
  
  // 尝试接收
  const recvData = kcp.recv();
  if (recvData) {
    // 处理接收到的数据
    const decoder = new util.TextDecoder('utf-8');
    const text = decoder.decodeToString(new Uint8Array(recvData));
    console.log('Received:', text);
  }
});
```

### 6. 定时更新

```typescript
// 启动更新定时器（每 10ms）
const updateTimer = setInterval(() => {
  kcp.update();  // 使用当前时间
  // 或
  // kcp.update(Date.now());  // 手动传入时间戳
}, 10);
```

### 7. 释放资源

```typescript
// 使用完毕后必须释放
clearInterval(updateTimer);
kcp.release();
```

## 完整示例

### UDP Echo 客户端

```typescript
import { KCP, KCPContext } from 'kcp';
import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';

class KCPClient {
  private kcp: KCP;
  private udpSocket: socket.UDPSocket;
  private updateTimer?: number;

  async start() {
    // 1. 创建 UDP socket
    this.udpSocket = socket.constructUDPSocketInstance();
    await this.udpSocket.bind({ address: '0.0.0.0' });

    // 2. 创建 KCP 实例
    const context: KCPContext = {
      address: '127.0.0.1',
      port: 41234
    };
    this.kcp = new KCP(123, context);

    // 3. 配置 KCP
    this.kcp.nodelay(1, 10, 2, 1);
    this.kcp.wndsize(128, 128);

    // 4. 设置输出回调
    this.kcp.output((data, size, ctx) => {
      if (this.udpSocket && ctx) {
        this.udpSocket.send({
          data: data,
          address: {
            address: ctx.address!,
            port: ctx.port!
          }
        });
      }
    });

    // 5. 设置消息接收
    this.udpSocket.on('message', (msg) => {
      this.kcp.input(msg.message);
      
      const recvData = this.kcp.recv();
      if (recvData) {
        const decoder = new util.TextDecoder('utf-8');
        const text = decoder.decodeToString(new Uint8Array(recvData));
        console.log('Received:', text);
      }
    });

    // 6. 启动更新定时器
    this.updateTimer = setInterval(() => {
      this.kcp.update();
    }, 10);

    // 7. 发送测试消息
    this.kcp.send('Hello from OpenHarmony!');
  }

  stop() {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
    }
    this.kcp.release();
    this.udpSocket.close();
  }
}

// 使用
const client = new KCPClient();
client.start();
```

## 常见场景

### 场景 1：低延迟游戏通信

```typescript
// 配置极速模式
kcp.nodelay(1, 10, 2, 1);    // 最低延迟
kcp.wndsize(256, 256);       // 大窗口
kcp.setmtu(1400);            // 合适的 MTU

// 高频更新（5ms）
setInterval(() => kcp.update(), 5);
```

### 场景 2：文件传输

```typescript
// 配置普通模式（节省带宽）
kcp.nodelay(0, 40, 0, 0);    // 正常模式
kcp.wndsize(512, 512);       // 大窗口提高吞吐量
kcp.stream(1);               // 流模式

// 正常更新频率（20ms）
setInterval(() => kcp.update(), 20);
```

### 场景 3：实时语音/视频

```typescript
// 配置快速模式
kcp.nodelay(1, 20, 2, 1);    // 快速模式
kcp.wndsize(128, 128);       // 适中窗口
kcp.setmtu(1200);            // 较小 MTU（避免分片）

// 中等更新频率（10-20ms）
setInterval(() => kcp.update(), 15);
```

## 参数说明

### nodelay 参数

```typescript
kcp.nodelay(nodelay, interval, resend, nc)
```

- `nodelay`: 0=禁用快速模式, 1=启用快速模式
- `interval`: 内部更新间隔(ms)，越小延迟越低，但 CPU 占用越高
- `resend`: 快速重传倍数，0=禁用，1-N=启用
- `nc`: 0=启用拥塞控制, 1=禁用拥塞控制

**推荐配置：**
- 游戏：`nodelay(1, 10, 2, 1)` - 最低延迟
- 文件传输：`nodelay(0, 40, 0, 0)` - 节省带宽
- 实时音视频：`nodelay(1, 20, 2, 1)` - 平衡

### 窗口大小

```typescript
kcp.wndsize(sndwnd, rcvwnd)
```

- `sndwnd`: 发送窗口大小（默认 32）
- `rcvwnd`: 接收窗口大小（默认 32）

**建议：**
- 低延迟：32-128
- 高吞吐量：256-512

### MTU

```typescript
kcp.setmtu(mtu)
```

- `mtu`: 最大传输单元（默认 1400）

**建议：**
- 局域网：1400-1500
- 互联网：1200-1400（避免分片）

## 错误处理

```typescript
try {
  const kcp = new KCP(123);
  kcp.send('test');
  // ...
  kcp.release();
} catch (err) {
  console.error('KCP error:', err.message);
}
```

## 注意事项

1. **必须定时调用 update()**
   - KCP 需要定时更新内部状态
   - 更新频率影响延迟和 CPU 占用
   - 建议 10-20ms

2. **必须调用 release()**
   - 释放 Native 资源
   - 避免内存泄漏

3. **conv 必须匹配**
   - 客户端和服务端的 conv 必须一致
   - 否则无法通信

4. **output 回调必须设置**
   - KCP 通过 output 回调发送数据
   - 需要将数据发送到 UDP socket

5. **线程安全**
   - 不要在多个线程同时操作同一个 KCP 实例

## 性能优化

### 减少延迟

- 启用快速模式 `nodelay(1, ...)`
- 减小 interval（10ms 或更小）
- 增加 resend 参数
- 禁用拥塞控制 `nc=1`

### 提高吞吐量

- 增大窗口大小 `wndsize(512, 512)`
- 使用流模式 `stream(1)`
- 增大 MTU `setmtu(1400)`

### 降低 CPU 占用

- 增大 interval（20-40ms）
- 减小窗口大小
- 禁用快速重传

## 调试

### 检查 KCP 状态

```typescript
const waitsnd = kcp.waitsnd();  // 等待发送的包数量
const peeksize = kcp.peeksize(); // 下一个消息大小
console.log(`waitsnd=${waitsnd}, peeksize=${peeksize}`);
```

### 日志输出

```typescript
import { hilog } from '@kit.PerformanceAnalysisKit';

kcp.output((data, size, ctx) => {
  hilog.info(0x0000, 'KCP', `Send ${size} bytes to ${ctx?.address}:${ctx?.port}`);
  // ...
});
```

## 常见问题

### Q: 为什么没有收到数据？

A: 检查：
1. conv 是否匹配
2. output 回调是否设置
3. 是否定时调用 update()
4. 网络是否连通

### Q: 延迟太高怎么办？

A: 
1. 启用快速模式 `nodelay(1, 10, 2, 1)`
2. 增加更新频率（减小 interval）
3. 禁用拥塞控制 `nc=1`

### Q: CPU 占用太高怎么办？

A:
1. 增大更新间隔（增加 interval 到 20-40ms）
2. 禁用快速重传 `resend=0`
3. 启用拥塞控制 `nc=0`

## 更多示例

参见项目中的完整示例：
- `entry/src/main/ets/pages/Index.ets` - Demo 应用
- `entry/src/ohosTest/ets/test/Kcp.test.ets` - 单元测试

## 相关文档

- [README.md](README.md) - 项目说明
- [MIGRATION.md](MIGRATION.md) - 移植文档
