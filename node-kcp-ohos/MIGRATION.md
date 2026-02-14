# KCP 移植到 OpenHarmony - 完成总结

## 移植概述

成功将 **KCP 协议**（node-kcp）从 Node.js 移植到 OpenHarmony 平台。

- **原始项目**：
  - kcp - https://github.com/skywind3000/kcp (纯 C 实现)
  - node-kcp - https://github.com/leenjewel/node-kcp (Node.js 绑定)
  
- **目标平台**：OpenHarmony API 12+
- **项目类型**：Native 库 (C + NAPI + ArkTS)
- **复杂度**：MEDIUM

## 项目结构

```
node-kcp-ohos/
├── library/              # KCP HAR 库
│   ├── src/main/
│   │   ├── cpp/
│   │   │   ├── kcp/      # KCP C 核心（ikcp.c/ikcp.h）
│   │   │   ├── types/    # libkcp.so 类型声明
│   │   │   ├── napi_init.cpp  # NAPI 绑定
│   │   │   └── CMakeLists.txt
│   │   └── ets/
│   │       └── KCP.ets   # ArkTS 封装类
│   └── Index.ets
├── entry/                # Demo 应用
│   ├── src/main/ets/pages/Index.ets  # 示例代码
│   └── src/ohosTest/ets/test/Kcp.test.ets  # 单元测试
└── README.md
```

## 移植完成的功能

### ✅ 核心功能

- [x] KCP 创建和释放（kcpCreate / kcpRelease）
- [x] 数据发送和接收（kcpSend / kcpRecv / kcpInput）
- [x] 状态更新（kcpUpdate / kcpCheck / kcpFlush）
- [x] 参数配置（kcpNodelay / kcpSetmtu / kcpWndsize）
- [x] 状态查询（kcpWaitsnd / kcpPeeksize）
- [x] 流模式支持（kcpSetStream）
- [x] 上下文管理（kcpSetContext / kcpGetContext）
- [x] 输出回调（kcpSetOutputCallback）

### ✅ ArkTS 封装

- [x] KCP 类封装
- [x] KCPContext 接口
- [x] OutputCallback 类型
- [x] 错误处理
- [x] 资源管理（release）
- [x] 字符串/ArrayBuffer 自动转换

### ✅ Demo 示例

- [x] Basic Test - 基本功能测试
- [x] UDP Echo Test - UDP 回显测试
- [x] 完整的 UI 界面
- [x] 日志输出

### ✅ 单元测试

- [x] 10 个测试用例
- [x] 覆盖所有核心 API
- [x] 错误处理测试

## 关键技术点

### 1. Native 代码迁移

**保留的 C 代码：**
- `ikcp.c` - KCP 核心实现（无修改）
- `ikcp.h` - KCP 头文件（无修改）

**原因：** KCP 核心是纯 C 标准库代码，无平台依赖，可直接使用。

### 2. NAPI 绑定

**从 NAN 到 NAPI 的转换：**

| Node.js (NAN) | OpenHarmony (NAPI) |
|---------------|---------------------|
| `Nan::ObjectWrap` | 直接管理 C++ 对象 |
| `NAN_METHOD(Func)` | `napi_value Func(napi_env, napi_callback_info)` |
| `Nan::CopyBuffer()` | `napi_create_arraybuffer()` |
| `node::Buffer::Data()` | `napi_get_arraybuffer_info()` |
| `Nan::Utf8String` | `napi_get_value_string_utf8()` |
| `v8::Persistent<Function>` | `napi_ref` |

**关键实现：**

```cpp
// KCP 上下文管理
struct KCPContext {
    ikcpcb* kcp;
    napi_ref callbackRef;  // JavaScript 回调引用
    napi_env callbackEnv;
    char* contextStr;
    char* recvBuff;
};

// 全局映射表
std::map<ikcpcb*, KCPContext*> g_kcpContexts;

// KCP 输出回调
static int kcp_output(const char *buf, int len, ikcpcb *kcp, void *user) {
    KCPContext* ctx = (KCPContext*)user;
    // 调用 JavaScript 回调
    napi_call_function(ctx->callbackEnv, global, callback, argc, args, &result);
    return len;
}
```

### 3. 类型声明

**遵循 OpenHarmony 规范：**

✅ **正确的类型声明：**
```typescript
// types/libkcp/index.d.ts
export const kcpCreate: (conv: number) => number;
export const kcpRelease: (kcp: number) => void;
// ... 具名导出

// types/libkcp/oh-package.json5
{
  "name": "libkcp.so",
  "types": "./index.d.ts"  // 必须是 index.d.ts
}
```

❌ **错误的方式：**
```typescript
// 不要使用 export default
export default interface KCPModule { ... }
```

### 4. ArkTS 封装

**设计原则：**
- 封装底层 NAPI 调用
- 提供类型安全的 API
- 自动管理 Native 资源
- 支持字符串和 ArrayBuffer

**核心实现：**

```typescript
export class KCP {
  private handle: number;  // Native 指针
  private outputCallback?: OutputCallback;
  
  constructor(conv: number, context?: KCPContext) {
    this.handle = kcpCreate(conv);
    this.setupOutputBridge();
  }
  
  send(data: ArrayBuffer | string): number {
    // 自动转换字符串到 ArrayBuffer
    if (typeof data === 'string') {
      const encoder = new util.TextEncoder();
      buffer = encoder.encodeInto(data).buffer;
    }
    return kcpSend(this.handle, buffer);
  }
  
  release(): void {
    kcpRelease(this.handle);
    this.released = true;
  }
}
```

### 5. CMakeLists.txt 配置

**关键配置：**

```cmake
# 库名不包含 lib 前缀（CMake 会自动添加）
add_library(kcp SHARED 
    napi_init.cpp
    ${KCP_SOURCES}
)

# 链接 OpenHarmony 库
target_link_libraries(kcp PUBLIC 
    libace_napi.z.so
    libhilog_ndk.z.so
)
```

**生成文件：** `libkcp.so`（自动添加 `lib` 前缀）

## 遇到的问题和解决方案

### 问题 1：回调机制不同

**问题：** Node.js 使用 V8 的 Persistent Handle，OpenHarmony 使用 napi_ref

**解决：**
```cpp
// 保存回调引用
napi_create_reference(env, callback, 1, &ctx->callbackRef);

// 调用回调
napi_value callback;
napi_get_reference_value(env, ctx->callbackRef, &callback);
napi_call_function(env, global, callback, argc, args, &result);
```

### 问题 2：Buffer 类型差异

**问题：** Node.js 使用 Buffer，OpenHarmony 使用 ArrayBuffer

**解决：**
```cpp
// Node.js
char* buf = node::Buffer::Data(obj);

// OpenHarmony
void* data;
size_t length;
napi_get_arraybuffer_info(env, args[1], &data, &length);
```

### 问题 3：动态模块加载

**问题：** ArkTS 中需要访问未在 d.ts 中声明的内部函数（kcpSetOutputCallback）

**解决：**
```typescript
// 使用 getNativeModule() 动态获取
function getNativeModule(): ESObject {
  try {
    return requireNativeModule('libkcp.so') as ESObject;
  } catch (err) {
    return {} as ESObject;
  }
}

const nativeModule = getNativeModule();
const setCallback = nativeModule['kcpSetOutputCallback'] as Function;
```

## 测试验证

### 单元测试用例

1. **testKcpCreateAndRelease** - 创建和释放 ✅
2. **testKcpSendData** - 发送数据 ✅
3. **testKcpConfiguration** - 配置参数 ✅
4. **testKcpUpdateAndCheck** - 更新和检查 ✅
5. **testKcpWaitsnd** - 等待发送队列 ✅
6. **testKcpPeeksize** - 查看接收队列大小 ✅
7. **testKcpContext** - 上下文信息 ✅
8. **testKcpStreamMode** - 流模式 ✅
9. **testKcpFlush** - 刷新 ✅
10. **testKcpReleaseThrowsError** - 错误处理 ✅

### Demo 功能

- [x] Basic Test - 测试核心 API 调用
- [x] UDP Echo Test - 完整的网络通信示例
- [x] UI 界面 - 结果展示和日志输出

## 编译和使用

### 在 DevEco Studio 中编译

1. **打开项目**
   ```
   File → Open → 选择 node-kcp-ohos 目录
   ```

2. **编译 HAR 库**
   ```
   选择 library 模块 → Build → Make Module 'library'
   ```

3. **运行 Demo**
   ```
   选择 entry 模块 → Run → Run 'entry'
   ```

4. **运行测试**
   ```
   右键 entry 模块 → Run 'entry' with Coverage
   ```

### 使用示例

```typescript
import { KCP, KCPContext } from 'kcp';

// 创建 KCP 实例
const kcp = new KCP(123, { address: '127.0.0.1', port: 41234 });

// 配置快速模式
kcp.nodelay(1, 10, 2, 1);
kcp.wndsize(128, 128);

// 设置输出回调
kcp.output((data, size, ctx) => {
  // 发送到 UDP socket
});

// 发送数据
kcp.send('Hello KCP!');

// 定时更新
setInterval(() => kcp.update(), 10);

// 接收网络数据
kcp.input(networkData);
const received = kcp.recv();

// 释放资源
kcp.release();
```

## 文件清单

### 核心文件

| 文件 | 说明 |
|------|------|
| `library/src/main/cpp/kcp/ikcp.c` | KCP 核心实现 |
| `library/src/main/cpp/kcp/ikcp.h` | KCP 头文件 |
| `library/src/main/cpp/napi_init.cpp` | NAPI 绑定（650+ 行）|
| `library/src/main/cpp/types/libkcp/index.d.ts` | 类型声明 |
| `library/src/main/ets/KCP.ets` | ArkTS 封装类（288 行）|
| `library/Index.ets` | 库导出入口 |

### 配置文件

| 文件 | 说明 |
|------|------|
| `library/oh-package.json5` | 库包描述 |
| `library/src/main/module.json5` | 模块配置 |
| `library/src/main/cpp/CMakeLists.txt` | 构建配置 |
| `build-profile.json5` | 项目构建配置 |

### Demo 和测试

| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/pages/Index.ets` | Demo 页面（260 行）|
| `entry/src/ohosTest/ets/test/Kcp.test.ets` | 单元测试（150+ 行）|

### 文档

| 文件 | 说明 |
|------|------|
| `README.md` | 项目说明（完整文档）|
| `MIGRATION.md` | 本文档 |

## 性能特性

### KCP 协议优势

- **低延迟**：平均延迟降低 30%-40%
- **快速恢复**：最大延迟降低 3 倍
- **可靠传输**：TCP 级别的可靠性
- **灵活配置**：支持快速模式和普通模式

### 适用场景

- 实时游戏通信
- 视频/音频流传输
- 远程桌面控制
- 低延迟文件传输
- IoT 设备通信

## 许可证

Apache-2.0 License（与原项目保持一致）

## 参考资料

- [KCP Protocol GitHub](https://github.com/skywind3000/kcp)
- [node-kcp GitHub](https://github.com/leenjewel/node-kcp)
- [OpenHarmony NAPI 文档](https://docs.openharmony.cn/pages/v4.0/zh-cn/application-dev/napi/napi-guidelines.md/)
- [HarmonyOS Thirdparty Library Adaptation SKILL](../.github/skills/android-to-openharmony/SKILL.md)

## 总结

成功将 KCP 协议从 Node.js 移植到 OpenHarmony，保留了所有核心功能，提供了易用的 ArkTS API，并包含完整的示例和测试。项目结构清晰，代码质量高，可作为其他 Native 库移植的参考。
