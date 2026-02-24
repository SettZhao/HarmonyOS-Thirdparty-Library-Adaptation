# UDP Socket API 参考

## 概述

OpenHarmony 提供的 UDP Socket API，用于 UDP 网络通信。

**包路径：** `@kit.NetworkKit`

**权限要求：** `ohos.permission.INTERNET`

---

## 核心 API

### 创建 UDP Socket

```typescript
import { socket } from '@kit.NetworkKit';

let udpSocket: socket.UDPSocket = socket.constructUDPSocketInstance();
```

---

## UDPSocket 类方法

### bind() - 绑定地址和端口

**功能：** 绑定 IP 地址和端口（可由系统随机分配）

**权限：** `ohos.permission.INTERNET`

#### Promise 方式

```typescript
bind(address: NetAddress): Promise<void>
```

**示例：**

```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

let udp: socket.UDPSocket = socket.constructUDPSocketInstance();

let bindAddr: socket.NetAddress = {
  address: '0.0.0.0',  // 绑定所有接口
  port: 0              // 0 表示系统随机分配端口
};

udp.bind(bindAddr).then(() => {
  console.info('bind success');
}).catch((err: BusinessError) => {
  console.error('bind fail: ' + err.message);
});
```

#### Callback 方式

```typescript
bind(address: NetAddress, callback: AsyncCallback<void>): void
```

---

### send() - 发送数据

**功能：** 通过 UDP Socket 发送数据

**权限：** `ohos.permission.INTERNET`

**前提条件：** 必须先调用 `bind()` 绑定地址

**注意：** 该接口为耗时操作，建议在 Worker 线程或 taskpool 线程调用

#### Promise 方式

```typescript
send(options: UDPSendOptions): Promise<void>
```

**示例：**

```typescript
import { socket } from '@kit.NetworkKit';

let udp: socket.UDPSocket = socket.constructUDPSocketInstance();

// 先绑定
await udp.bind({ address: '0.0.0.0', port: 0 });

// 发送数据
let sendOptions: socket.UDPSendOptions = {
  data: 'Hello, server!',  // 可以是 string 或 ArrayBuffer
  address: {
    address: '192.168.1.100',
    port: 8080
  }
};

await udp.send(sendOptions);
```

**使用代理发送：**

```typescript
let socks5Server: socket.NetAddress = {
  address: '192.168.1.1',
  port: 1080
};

let proxyOptions: socket.ProxyOptions = {
  type: 1,  // SOCKS5
  address: socks5Server,
  username: "user",
  password: "pass"
};

let sendOptions: socket.UDPSendOptions = {
  data: 'Hello via proxy!',
  address: { address: '192.168.1.100', port: 8080 },
  proxy: proxyOptions
};

await udp.send(sendOptions);
```

---

### on('message') - 订阅接收消息事件

**功能：** 订阅 UDP 接收消息事件

**⚠️ 重要：** 回调参数类型必须是 `socket.SocketMessageInfo`，不是 `socket.UDPMessageInfo`！

```typescript
on(type: 'message', callback: Callback<SocketMessageInfo>): void
```

**示例：**

```typescript
import { socket } from '@kit.NetworkKit';

let udp: socket.UDPSocket = socket.constructUDPSocketInstance();

// ✅ 正确：使用 socket.SocketMessageInfo
udp.on('message', (data: socket.SocketMessageInfo) => {
  // 解析接收到的数据
  let uint8Array = new Uint8Array(data.message);
  let messageView = '';
  for (let i = 0; i < data.message.byteLength; i++) {
    messageView += String.fromCharCode(uint8Array[i]);
  }
  
  console.info('Received: ' + messageView);
  console.info('From: ' + data.remoteInfo.address + ':' + data.remoteInfo.port);
});
```

**使用 TextDecoder 解析文本：**

```typescript
import { util } from '@kit.ArkTS';

udp.on('message', (data: socket.SocketMessageInfo) => {
  const decoder = new util.TextDecoder('utf-8');
  const text = decoder.decodeToString(new Uint8Array(data.message));
  console.info('Received text: ' + text);
});
```

---

### off('message') - 取消订阅接收消息事件

```typescript
off(type: 'message', callback?: Callback<SocketMessageInfo>): void
```

**示例：**

```typescript
// 取消特定回调
let callback = (data: socket.SocketMessageInfo) => { ... };
udp.on('message', callback);
udp.off('message', callback);

// 清空所有订阅
udp.off('message');
```

---

### getState() - 获取 Socket 状态

**功能：** 获取 UDP Socket 状态信息

**权限：** `ohos.permission.INTERNET`

**前提条件：** 必须先调用 `bind()` 成功

```typescript
getState(): Promise<SocketStateBase>
```

**示例：**

```typescript
let state: socket.SocketStateBase = await udp.getState();

console.info('isBound: ' + state.isBound);      // 是否已绑定
console.info('isClose: ' + state.isClose);      // 是否已关闭
console.info('isConnected: ' + state.isConnected); // 是否已连接（UDP 通常为 false）
```

**⚠️ 注意：** `SocketStateBase` 只包含以下属性：
- `isBound: boolean` - 是否绑定
- `isClose: boolean` - 是否关闭
- `isConnected: boolean` - 是否连接

**不包含** `localAddress` 和 `localPort` 属性！如需获取本地地址，请使用 `getLocalAddress()` 方法。

---

### getLocalAddress() - 获取本地 Socket 地址

**功能：** 获取 UDP 连接的本地 Socket 地址

**前提条件：** 必须先调用 `bind()` 成功

```typescript
getLocalAddress(): Promise<NetAddress>
```

**示例：**

```typescript
let udp: socket.UDPSocket = socket.constructUDPSocketInstance();

await udp.bind({ address: '0.0.0.0', port: 0 });

let localAddr: socket.NetAddress = await udp.getLocalAddress();
console.info('Local address: ' + localAddr.address);
console.info('Local port: ' + localAddr.port);
```

---

### setExtraOptions() - 设置额外属性

**功能：** 设置 UDP Socket 的额外属性（缓冲区、超时、广播等）

**权限：** `ohos.permission.INTERNET`

**前提条件：** 必须先调用 `bind()` 成功

```typescript
setExtraOptions(options: UDPExtraOptions): Promise<void>
```

**示例：**

```typescript
let udpExtraOptions: socket.UDPExtraOptions = {
  receiveBufferSize: 8192,   // 接收缓冲区大小
  sendBufferSize: 8192,      // 发送缓冲区大小
  reuseAddress: false,       // 是否重用地址
  socketTimeout: 6000,       // 超时时间（毫秒）
  broadcast: true            // 是否允许广播
};

await udp.setExtraOptions(udpExtraOptions);
```

---

### close() - 关闭连接

**功能：** 关闭 UDP Socket 连接

**权限：** `ohos.permission.INTERNET`

```typescript
close(): Promise<void>
```

**示例：**

```typescript
await udp.close();
console.info('UDP socket closed');
```

---

### on('listening' | 'close') - 订阅事件

```typescript
on(type: 'listening' | 'close', callback: Callback<void>): void
```

**示例：**

```typescript
udp.on('listening', () => {
  console.info('UDP socket is listening');
});

udp.on('close', () => {
  console.info('UDP socket closed');
});
```

---

### on('error') - 订阅错误事件

```typescript
on(type: 'error', callback: ErrorCallback): void
```

**示例：**

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

udp.on('error', (err: BusinessError) => {
  console.error('UDP error: ' + err.code + ', ' + err.message);
});
```

---

## 数据类型

### NetAddress - 网络地址信息

```typescript
interface NetAddress {
  address: string;   // IP 地址或域名
  port: number;      // 端口号 (0-65535)，0 表示系统随机分配
  family?: number;   // 1: IPv4 (默认), 2: IPv6, 3: Domain
}
```

---

### UDPSendOptions - 发送选项

```typescript
interface UDPSendOptions {
  data: string | ArrayBuffer;  // 发送的数据
  address: NetAddress;         // 目标地址
  proxy?: ProxyOptions;        // 可选：代理配置
}
```

---

### UDPExtraOptions - 额外配置

```typescript
interface UDPExtraOptions extends ExtraOptionsBase {
  broadcast?: boolean;  // 是否允许发送广播，默认 false
}

interface ExtraOptionsBase {
  receiveBufferSize?: number;  // 接收缓冲区大小
  sendBufferSize?: number;     // 发送缓冲区大小
  reuseAddress?: boolean;      // 是否重用地址
  socketTimeout?: number;      // 超时时间（毫秒）
}
```

---

### SocketMessageInfo - 接收消息信息

**⚠️ 这是 UDP on('message') 回调的参数类型！**

```typescript
interface SocketMessageInfo {
  message: ArrayBuffer;          // 接收到的消息数据
  remoteInfo: SocketRemoteInfo;  // 远程连接信息
}
```

---

### SocketRemoteInfo - 远程连接信息

```typescript
interface SocketRemoteInfo {
  address: string;           // 远程 IP 地址
  family: 'IPv4' | 'IPv6';  // 网络协议类型
  port: number;              // 远程端口号
  size: number;              // 消息字节长度
}
```

---

### SocketStateBase - Socket 状态

```typescript
interface SocketStateBase {
  isBound: boolean;      // 是否已绑定
  isClose: boolean;      // 是否已关闭
  isConnected: boolean;  // 是否已连接
}
```

**⚠️ 注意：** `SocketStateBase` **不包含** `localAddress` 和 `localPort` 属性！

---

### ProxyOptions - 代理配置

```typescript
interface ProxyOptions {
  type: ProxyTypes;       // 代理类型
  address: NetAddress;    // 代理服务器地址
  username?: string;      // 用户名（如需验证）
  password?: string;      // 密码（如需验证）
}

enum ProxyTypes {
  NONE = 0,    // 不使用代理
  SOCKS5 = 1   // 使用 SOCKS5 代理
}
```

---

## 完整示例

### UDP Echo Client

```typescript
import { socket } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';

async function udpEchoClient() {
  // 1. 创建 UDP Socket
  let udp: socket.UDPSocket = socket.constructUDPSocketInstance();
  
  try {
    // 2. 绑定本地地址（系统随机分配端口）
    await udp.bind({ address: '0.0.0.0', port: 0 });
    console.info('UDP socket bound');
    
    // 3. 获取本地地址
    let localAddr = await udp.getLocalAddress();
    console.info(`Local: ${localAddr.address}:${localAddr.port}`);
    
    // 4. 设置接收消息回调
    udp.on('message', (data: socket.SocketMessageInfo) => {
      const decoder = new util.TextDecoder('utf-8');
      const text = decoder.decodeToString(new Uint8Array(data.message));
      console.info(`Received: ${text} from ${data.remoteInfo.address}:${data.remoteInfo.port}`);
    });
    
    // 5. 设置错误回调
    udp.on('error', (err: BusinessError) => {
      console.error(`UDP error: ${err.message}`);
    });
    
    // 6. 发送数据到服务器
    let sendOptions: socket.UDPSendOptions = {
      data: 'Hello, UDP Server!',
      address: {
        address: '192.168.1.100',
        port: 8080
      }
    };
    await udp.send(sendOptions);
    console.info('Message sent');
    
    // 7. 等待一段时间后关闭
    setTimeout(async () => {
      await udp.close();
      console.info('UDP socket closed');
    }, 5000);
    
  } catch (err) {
    let error = err as BusinessError;
    console.error(`Error: ${error.message}`);
    await udp.close();
  }
}
```

---

## 常见错误码

| 错误码 | 说明 |
|--------|------|
| 401 | 参数错误 |
| 201 | 权限被拒绝（缺少 INTERNET 权限）|
| 2300002 | 系统内部错误 |
| 2301009 | 错误的文件描述符 |
| 2303188 | 在非 socket 上执行 socket 操作 |
| 2301206 | SOCKS5 连接代理服务器失败 |
| 2301207 | SOCKS5 用户名或密码无效 |
| 2301208 | SOCKS5 连接远程服务器失败 |

---

## 最佳实践

### 1. 权限配置

在 `module.json5` 中添加 INTERNET 权限：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

在 `string.json` 中添加权限说明：

```json
{
  "string": [
    {
      "name": "internet_permission_reason",
      "value": "Application requires network access for UDP communication"
    }
  ]
}
```

---

### 2. 错误处理

始终使用 try-catch 包裹异步操作：

```typescript
try {
  await udp.bind({ address: '0.0.0.0', port: 0 });
  await udp.send(sendOptions);
} catch (err) {
  let error = err as BusinessError;
  console.error(`Error ${error.code}: ${error.message}`);
}
```

---

### 3. 资源释放

使用完毕后务必关闭 socket：

```typescript
// 在组件销毁或页面离开时
async cleanup() {
  if (this.udpSocket) {
    try {
      await this.udpSocket.close();
    } catch (err) {
      console.error('Close error: ' + (err as Error).message);
    }
  }
}
```

---

### 4. 使用正确的类型

**⚠️ 关键：** UDP on('message') 回调必须使用 `socket.SocketMessageInfo`：

```typescript
// ❌ 错误
udp.on('message', (data: socket.UDPMessageInfo) => { ... });

// ✅ 正确
udp.on('message', (data: socket.SocketMessageInfo) => { ... });
```

---

### 5. 获取本地地址的正确方式

**❌ 错误：** 从 `getState()` 获取本地地址

```typescript
let state = await udp.getState();
// ❌ SocketStateBase 没有 localAddress/localPort 属性
console.info(state.localAddress);  // 编译错误！
```

**✅ 正确：** 使用 `getLocalAddress()` 方法

```typescript
let localAddr = await udp.getLocalAddress();
console.info(`${localAddr.address}:${localAddr.port}`);
```

---

### 6. 数据编码转换

**发送文本数据：**

```typescript
import { util } from '@kit.ArkTS';

// 方式1：直接使用 string（由系统自动转换）
await udp.send({
  data: 'Hello',
  address: targetAddr
});

// 方式2：手动转换为 ArrayBuffer
const encoder = new util.TextEncoder();
const buffer = encoder.encode('Hello');
await udp.send({
  data: buffer,
  address: targetAddr
});
```

**接收文本数据：**

```typescript
import { util } from '@kit.ArkTS';

udp.on('message', (data: socket.SocketMessageInfo) => {
  const decoder = new util.TextDecoder('utf-8');
  const text = decoder.decodeToString(new Uint8Array(data.message));
  console.info('Received: ' + text);
});
```

---

## 与 Android 的主要差异

| Android UDP (DatagramSocket) | OpenHarmony UDP Socket |
|------------------------------|------------------------|
| `new DatagramSocket(port)` | `constructUDPSocketInstance()` + `bind()` |
| `socket.send(packet)` | `udp.send(options)` (Promise) |
| `socket.receive(packet)` | `udp.on('message', callback)` (事件监听) |
| `socket.getLocalAddress()` | `udp.getLocalAddress()` |
| `socket.getLocalPort()` | `localAddr.port` (从 getLocalAddress 返回) |
| `socket.close()` | `udp.close()` (Promise) |
| 阻塞式接收 | 异步事件回调 |

---

## 参考文档

- [OpenHarmony Socket API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-socket-V5)
- [网络管理 (NetworkKit)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-socket-V5#udpsocket)
