# KCP for OpenHarmony

KCP 协议的 OpenHarmony 移植版本，提供快速可靠的 ARQ 传输协议。

## 项目介绍

KCP 是一个快速可靠协议，能以比 TCP 浪费 10%-20% 的带宽的代价，换取平均延迟降低 30%-40%，且最大延迟降低三倍的传输效果。

本项目将 KCP 核心 C 代码和 node-kcp 的功能移植到 OpenHarmony 平台，提供 ArkTS API 接口。

## 特性

- ✅ **纯 C 核心**：保留原始 KCP C 代码，性能优异
- ✅ **NAPI 绑定**：通过 NAPI 将 C 函数暴露给 ArkTS
- ✅ **易用封装**：提供 KCP 类封装，API 设计友好
- ✅ **完整功能**：支持所有 KCP 核心功能
  - 可靠传输
  - 快速模式（nodelay）
  - 流模式/消息模式
  - MTU 配置
  - 窗口大小控制

## 项目结构

```
node-kcp-ohos/
├── library/                    # KCP 库模块 (HAR)
│   ├── src/main/
│   │   ├── cpp/               # Native 代码
│   │   │   ├── kcp/          # KCP C 核心代码
│   │   │   │   ├── ikcp.c
│   │   │   │   └── ikcp.h
│   │   │   ├── types/        # TypeScript 类型声明
│   │   │   │   └── libkcp/
│   │   │   │       ├── index.d.ts
│   │   │   │       └── oh-package.json5
│   │   │   ├── napi_init.cpp # NAPI 绑定代码
│   │   │   └── CMakeLists.txt
│   │   └── ets/              # ArkTS 代码
│   │       └── KCP.ets       # KCP 类封装
│   ├── Index.ets             # 库导出入口
│   └── oh-package.json5
├── entry/                     # Demo 应用
│   └── src/main/ets/pages/
│       └── Index.ets         # Demo 示例
└── build-profile.json5

```

## 编译和使用

### 前提条件

- DevEco Studio 4.0+
- OpenHarmony SDK API 12+

### 在 DevEco Studio 中编译

1. **打开项目**
   - 启动 DevEco Studio
   - File → Open → 选择 `node-kcp-ohos` 目录
   - 等待项目索引完成

2. **编译 HAR 库**
   - 选择 `library` 模块
   - Build → Make Module 'library'
   - 等待编译完成

3. **运行 Demo**
   - 选择 `entry` 模块
   - 连接设备或启动模拟器
   - Run → Run 'entry'

4. **运行测试**
   - 在 `entry` 模块上右键
   - Run 'entry' with Coverage
   - 查看测试结果

### 验证编译成功

编译成功后，HAR 文件位于：
```
library/build/default/outputs/default/kcp.har
```

文件大小应 > 100KB。

## API 使用

### 基本示例

```typescript
import { KCP, KCPContext } from 'kcp';

// 创建 KCP 实例
const conv = 123;
const context: KCPContext = {
  address: '127.0.0.1',
  port: 41234
};
const kcp = new KCP(conv, context);

// 配置快速模式
kcp.nodelay(1, 10, 2, 1);
kcp.wndsize(128, 128);

// 设置输出回调（KCP 需要发送数据时调用）
kcp.output((data: ArrayBuffer, size: number, ctx?: KCPContext) => {
  // 通过 UDP socket 发送 data 到 ctx.address:ctx.port
  console.log(`Send ${size} bytes to ${ctx?.address}:${ctx?.port}`);
});

// 发送数据
kcp.send('Hello KCP!');

// 定时更新（每 10ms）
setInterval(() => {
  kcp.update();
}, 10);

// 接收网络数据时
// udpSocket.on('message', (msg) => {
//   kcp.input(msg);
//   const data = kcp.recv();
//   if (data) {
//     console.log('Received:', data);
//   }
// });

// 使用完毕后释放
kcp.release();
```

### UDP Echo 示例

完整的 UDP Echo 示例见 `entry/src/main/ets/pages/Index.ets`。

Demo 包含两个测试：
1. **Basic Test** - 测试 KCP 的基本功能
2. **UDP Echo** - 通过 UDP 发送消息并接收回显（需要服务器）

### 核心 API

#### 构造函数

```typescript
constructor(conv: number, context?: KCPContext)
```

- `conv` - 会话 ID（两端必须一致）
- `context` - 可选的上下文信息（如远程地址）

#### 数据传输

```typescript
send(data: ArrayBuffer | string): number
recv(): ArrayBuffer | null
input(data: ArrayBuffer | string): number
```

#### 配置方法

```typescript
nodelay(nodelay: number, interval: number, resend: number, nc: number): number
setmtu(mtu: number): number
wndsize(sndwnd: number, rcvwnd: number): number
stream(stream: number): void
```

#### 更新和状态

```typescript
update(current?: number): void
check(current?: number): number
flush(): void
peeksize(): number
waitsnd(): number
```

#### 回调

```typescript
output(callback: OutputCallback): void
```

- `callback` - 当 KCP 需要发送数据时调用

#### 资源管理

```typescript
release(): void
```

**必须调用** `release()` 释放 Native 资源。

## 测试

### 单元测试

测试文件：`entry/src/ohosTest/ets/test/Kcp.test.ets`

包含以下测试用例：
- `testKcpCreateAndRelease` - 创建和释放
- `testKcpSendData` - 发送数据
- `testKcpConfiguration` - 配置参数
- `testKcpUpdateAndCheck` - 更新和检查
- `testKcpWaitsnd` - 等待发送队列
- `testKcpPeeksize` - 查看接收队列大小
- `testKcpContext` - 上下文信息
- `testKcpStreamMode` - 流模式
- `testKcpFlush` - 刷新
- `testKcpReleaseThrowsError` - 错误处理

### 运行测试

在 DevEco Studio 中：
1. 右键 `entry` 模块
2. Run 'entry' with Coverage
3. 查看测试结果和覆盖率

## 迁移说明

本项目从以下源代码迁移：
- **kcp** - https://github.com/skywind3000/kcp
- **node-kcp** - https://github.com/leenjewel/node-kcp

主要变更：
- NAN (Node.js Addons) → NAPI (OpenHarmony)
- Node.js Buffers → ArrayBuffer
- V8 API → NAPI API
- JavaScript → ArkTS

## 性能特性

KCP 的性能优势：
- **低延迟**：平均延迟降低 30%-40%
- **可靠性**：TCP 级别的可靠性
- **快速恢复**：支持快速重传和选择性确认
- **灵活配置**：可根据场景调整参数

## 许可证

Apache-2.0 License

## 参考

- [KCP Protocol](https://github.com/skywind3000/kcp)
- [node-kcp](https://github.com/leenjewel/node-kcp)
- [OpenHarmony NAPI](https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/napi/napi-guidelines.md/)
