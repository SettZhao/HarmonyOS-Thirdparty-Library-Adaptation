# node-kcp-ohos 文件清单

## 项目文件树

```
node-kcp-ohos/
├── README.md                          # 项目说明文档
├── MIGRATION.md                       # 移植详细文档
├── QUICKSTART.md                      # 快速开始指南
├── build-profile.json5                # 项目构建配置
├── oh-package.json5                   # 项目包描述
├── hvigorfile.ts                      # Hvigor 构建脚本
├── code-linter.json5                  # 代码检查配置
│
├── library/                           # KCP 库模块（HAR）
│   ├── Index.ets                      # 库导出入口
│   ├── oh-package.json5               # 库包描述
│   ├── build-profile.json5            # 库构建配置
│   ├── hvigorfile.ts                  # 库构建脚本
│   │
│   └── src/main/
│       ├── module.json5               # 模块配置
│       │
│       ├── cpp/                       # Native C/C++ 代码
│       │   ├── CMakeLists.txt         # CMake 构建配置
│       │   ├── napi_init.cpp          # NAPI 绑定实现（650+ 行）
│       │   │
│       │   ├── kcp/                   # KCP 核心 C 代码
│       │   │   ├── ikcp.c             # KCP 实现
│       │   │   └── ikcp.h             # KCP 头文件
│       │   │
│       │   └── types/                 # Native 模块类型声明
│       │       └── libkcp/
│       │           ├── oh-package.json5   # 类型包配置
│       │           └── index.d.ts         # TypeScript 类型声明
│       │
│       ├── ets/                       # ArkTS 代码
│       │   └── KCP.ets                # KCP 类封装（288 行）
│       │
│       └── resources/                 # 资源文件
│           └── base/
│               └── element/
│                   ├── float.json
│                   └── string.json
│
├── entry/                             # Demo 应用模块
│   ├── oh-package.json5               # 应用包描述
│   ├── build-profile.json5            # 应用构建配置
│   ├── hvigorfile.ts                  # 应用构建脚本
│   │
│   └── src/
│       ├── main/
│       │   ├── module.json5           # 应用模块配置
│       │   │
│       │   ├── ets/
│       │   │   ├── entryability/
│       │   │   │   └── EntryAbility.ets   # 应用入口
│       │   │   │
│       │   │   └── pages/
│       │   │       └── Index.ets          # Demo 页面（260+ 行）
│       │   │
│       │   └── resources/             # 应用资源
│       │       ├── base/
│       │       │   ├── element/
│       │       │   │   ├── color.json
│       │       │   │   ├── float.json
│       │       │   │   └── string.json
│       │       │   │
│       │       │   ├── media/
│       │       │   │   └── layered_image.json
│       │       │   │
│       │       │   └── profile/
│       │       │       ├── backup_config.json
│       │       │       └── main_pages.json
│       │       │
│       │       └── dark/
│       │           └── element/
│       │               └── color.json
│       │
│       └── ohosTest/                  # 测试代码
│           ├── module.json5
│           │
│           └── ets/
│               └── test/
│                   ├── Ability.test.ets    # 基础能力测试
│                   ├── Kcp.test.ets        # KCP 单元测试（150+ 行）
│                   └── List.test.ets       # 测试列表
│
├── AppScope/                          # 应用全局资源
│   ├── app.json5                      # 应用配置
│   │
│   └── resources/
│       └── base/
│           ├── element/
│           │   └── string.json
│           │
│           └── media/
│               └── layered_image.json
│
└── hvigor/                            # Hvigor 配置
    └── hvigor-config.json5
```

## 核心文件说明

### 1. Native 代码（C/C++）

#### kcp/ikcp.c / ikcp.h
- **来源：** https://github.com/skywind3000/kcp
- **说明：** KCP 协议核心实现（纯 C 代码）
- **修改：** 无修改，直接复用
- **行数：** ~1800 行

#### napi_init.cpp
- **说明：** NAPI 绑定层，将 KCP C 函数暴露给 ArkTS
- **功能：**
  - 17 个 NAPI 函数封装
  - KCP 上下文管理
  - 输出回调机制
  - 内存管理
- **行数：** 650+ 行
- **关键函数：**
  - `KcpCreate` / `KcpRelease`
  - `KcpSend` / `KcpRecv` / `KcpInput`
  - `KcpUpdate` / `KcpCheck` / `KcpFlush`
  - `KcpNodelay` / `KcpSetmtu` / `KcpWndsize`
  - `KcpSetOutputCallback`

#### CMakeLists.txt
- **说明：** CMake 构建配置
- **关键配置：**
  - 库名：`kcp`（生成 `libkcp.so`）
  - 源文件：`napi_init.cpp`, `ikcp.c`
  - 链接库：`libace_napi.z.so`, `libhilog_ndk.z.so`

#### types/libkcp/index.d.ts
- **说明：** TypeScript 类型声明
- **内容：** 17 个导出函数的类型定义
- **规范：** 使用 `export const` 具名导出（不使用 export default）

### 2. ArkTS 代码

#### library/src/main/ets/KCP.ets
- **说明：** KCP 类封装
- **行数：** 288 行
- **功能：**
  - 封装 Native 函数调用
  - 自动管理 Native 资源
  - 支持字符串/ArrayBuffer 转换
  - 输出回调桥接
  - 错误处理
- **导出：**
  - `KCP` 类
  - `KCPContext` 接口
  - `OutputCallback` 类型

#### library/Index.ets
- **说明：** 库导出入口
- **内容：** 导出 KCP 相关类型和函数

#### entry/src/main/ets/pages/Index.ets
- **说明：** Demo 应用页面
- **行数：** 260+ 行
- **功能：**
  - Basic Test - 基本功能测试
  - UDP Echo Test - UDP 回显测试
  - UI 界面展示
  - 日志输出

### 3. 测试代码

#### entry/src/ohosTest/ets/test/Kcp.test.ets
- **说明：** KCP 单元测试
- **行数：** 150+ 行
- **测试用例：** 10 个
  1. `testKcpCreateAndRelease` - 创建和释放
  2. `testKcpSendData` - 发送数据
  3. `testKcpConfiguration` - 配置参数
  4. `testKcpUpdateAndCheck` - 更新和检查
  5. `testKcpWaitsnd` - 等待发送队列
  6. `testKcpPeeksize` - 查看接收队列
  7. `testKcpContext` - 上下文信息
  8. `testKcpStreamMode` - 流模式
  9. `testKcpFlush` - 刷新
  10. `testKcpReleaseThrowsError` - 错误处理

### 4. 配置文件

#### build-profile.json5（根目录）
- **说明：** 项目构建配置
- **关键配置：**
  - SDK 版本：API 12
  - 模块顺序：kcp → entry（确保依赖正确）

#### library/oh-package.json5
- **说明：** 库包描述
- **关键配置：**
  - name: "kcp"
  - version: "1.0.0"
  - dependencies: `{ "libkcp.so": "file:./src/main/cpp/types/libkcp" }`

#### entry/oh-package.json5
- **说明：** 应用包描述
- **关键配置：**
  - dependencies: `{ "kcp": "file:../library" }`

#### library/src/main/module.json5
- **说明：** 库模块配置
- **关键配置：**
  - name: "kcp"
  - type: "har"

### 5. 文档

#### README.md
- **说明：** 项目说明文档
- **内容：**
  - 项目介绍
  - 特性列表
  - 编译和使用
  - API 使用示例
  - 性能特性
  - 许可证

#### MIGRATION.md
- **说明：** 移植详细文档
- **内容：**
  - 移植概述
  - 完成功能清单
  - 关键技术点
  - 遇到的问题和解决方案
  - 测试验证
  - 文件清单

#### QUICKSTART.md
- **说明：** 快速开始指南
- **内容：**
  - 安装和导入
  - 基本使用步骤
  - 完整示例
  - 常见场景配置
  - 参数说明
  - 错误处理
  - 性能优化
  - 常见问题

## 代码统计

### Native 代码
- `ikcp.c`: ~1500 行（KCP 核心）
- `ikcp.h`: ~400 行（KCP 头文件）
- `napi_init.cpp`: ~650 行（NAPI 绑定）
- **总计：** ~2550 行 C/C++

### ArkTS 代码
- `KCP.ets`: ~288 行（类封装）
- `Index.ets` (entry): ~260 行（Demo 页面）
- `Kcp.test.ets`: ~150 行（单元测试）
- **总计：** ~700 行 TypeScript

### 配置和文档
- 配置文件：~15 个
- 文档：3 个（README, MIGRATION, QUICKSTART）

## 构建产物

### HAR 库
- 位置：`library/build/default/outputs/default/kcp.har`
- 大小：~100KB+
- 包含：
  - ArkTS 代码（编译后）
  - Native 库（libkcp.so）
  - 类型声明
  - 资源文件

### HAP 应用
- 位置：`entry/build/default/outputs/default/entry-default-signed.hap`
- 大小：~1MB+
- 包含：
  - Demo 应用
  - KCP 库
  - UI 资源

## 依赖关系

```
entry (Demo 应用)
  └── depends on
      └── kcp (库模块)
          └── depends on
              └── libkcp.so (Native 模块)
                  └── depends on
                      ├── libace_napi.z.so (OpenHarmony NAPI)
                      ├── libhilog_ndk.z.so (OpenHarmony 日志)
                      └── kcp/ikcp.c (KCP 核心)
```

## 使用流程

1. **导入库**
   ```typescript
   import { KCP } from 'kcp';
   ```

2. **创建实例**
   ```typescript
   const kcp = new KCP(123);
   ```

3. **配置参数**
   ```typescript
   kcp.nodelay(1, 10, 2, 1);
   ```

4. **设置回调**
   ```typescript
   kcp.output((data, size, ctx) => { ... });
   ```

5. **使用 KCP**
   ```typescript
   kcp.send('data');
   kcp.input(networkData);
   const recv = kcp.recv();
   ```

6. **释放资源**
   ```typescript
   kcp.release();
   ```

## 编译指令

### 在 DevEco Studio 中
1. File → Open → 选择 `node-kcp-ohos`
2. Build → Make Module 'library'（编译库）
3. Run → Run 'entry'（运行 Demo）
4. Run 'entry' with Coverage（运行测试）

### 命令行（如果配置了 hvigorw）
```bash
# 清理
hvigorw clean

# 编译 HAR
hvigorw assembleHar

# 编译应用
hvigorw assembleApp

# 运行测试
hvigorw --mode module test
```

## 许可证

Apache-2.0 License

## 参考链接

- KCP GitHub: https://github.com/skywind3000/kcp
- node-kcp GitHub: https://github.com/leenjewel/node-kcp
- OpenHarmony NAPI: https://docs.openharmony.cn/
