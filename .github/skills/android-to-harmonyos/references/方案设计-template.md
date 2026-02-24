# 方案设计文档

> **使用说明**：  
> 本文档在 Step 1-2（可移植性分析完成后）开始撰写，在 Step 3-4（代码迁移过程中）持续完善。  
> 移植完成后作为技术归档文档留存，供后续维护、版本升级和其他开发者参考。  
> 方案设计文档应引用《三方库规格.md》中的接口定义，不重复描述已在规格文档中记录的内容。

---

## 一、背景与目标

### 1.1 背景

<!-- 说明为何需要将此 Android 库移植到 HarmonyOS。
     例：StackBlur 是广泛使用的图像模糊处理库，原生支持 Android 平台。
     为支持鸿蒙应用开发者使用同等能力，需将其适配到 HarmonyOS API 12+ 。 -->

### 1.2 移植目标

- **功能目标**：<!-- 例：实现与 Android 侧 API 语义等价的模糊处理能力，保留 Java 和 Native 两种实现路径 -->
- **兼容目标**：<!-- 例：接口尽量与 Android 侧保持一致，降低开发者迁移成本 -->
- **质量目标**：<!-- 例：核心算法测试用例 100% pass，性能不低于 Android 侧的 90% -->
- **交付物**：<!-- 例：HAR 包 + Demo Entry + 完整测试用例 -->

### 1.3 范围

| 纳入范围 | 排除范围 |
|----------|----------|
| <!-- Java 层栈式模糊算法 --> | <!-- RenderScript 实现（HarmonyOS 不支持）--> |
| <!-- Native C 层模糊算法（NAPI 封装）--> | <!-- GPU 加速路径 --> |
| <!-- Demo 示例页面 --> | <!-- --> |

---

## 二、Android 库分析总结

### 2.1 库整体架构

<!-- 描述 Android 源库的模块划分、核心类关系、执行流程。
     建议附简单的架构图或类关系描述。

     例：StackBlur 分为三层：
     - API 层：StackBlur.java — 对外接口，根据 BlurMode 选择实现
     - 算法层：JavaStackBlur.java / NativeStackBlur.java / RSBlur.java
     - Native 层：blur.c — 纯 C 实现的 Stack Blur 算法（通过 JNI 调用）
-->

```
┌──────────────────────────────────────────────┐
│               Android 架构示意                │
│                                              │
│  caller ──► StackBlur.blur(bmp, radius)      │
│                    │                         │
│         ┌──────────┼──────────┐              │
│      JAVA 层    RS 层(废弃) NATIVE 层         │
│    JavaBlur.java            JNI              │
│                             └─ blur.c        │
└──────────────────────────────────────────────┘
```

### 2.2 可移植性分析结论

| 分析维度 | 结论 | 说明 |
|----------|------|------|
| **复杂度评级** | <!-- LOW / MEDIUM / HIGH / VERY_HIGH --> | <!-- 综合评分和主要依据 --> |
| **Android 专有 API 依赖** | <!-- 有 / 无 --> | <!-- 列出主要依赖项 --> |
| **JNI/NDK 依赖** | <!-- 有 / 无 --> | <!-- 说明 C/C++ 模块情况 --> |
| **UI 组件依赖** | <!-- 有 / 无 --> | <!-- 是否依赖 View/Compose --> |
| **外部三方库依赖** | <!-- 有 / 无 --> | <!-- 依赖的其他 Android 库 --> |
| **移植可行性** | <!-- 完全可移植 / 部分可移植 / 不可移植 --> | <!-- 并说明原因 --> |

### 2.3 关键迁移挑战

<!-- 列出移植过程中预期的主要技术难点，每条说明挑战来源和预期解决思路 -->

| # | 挑战描述 | 复杂度 | 预期解决方向 |
|---|----------|--------|-------------|
| 1 | <!-- Bitmap → PixelMap 数据模型差异 --> | <!-- MEDIUM --> | <!-- 使用 @ohos.multimedia.image PixelMap API，封装转换辅助方法 --> |
| 2 | <!-- JNI 层绑定迁移到 NAPI --> | <!-- HIGH --> | <!-- 使用 NAPI 重新编写绑定层，C 层核心算法直接复用 --> |
| 3 | <!-- 同步 API → 异步 API 设计 --> | <!-- MEDIUM --> | <!-- 使用 Promise/async-await 封装异步接口 --> |

---

## 三、整体移植方案

### 3.1 移植路径选择

> 根据 Step 2 分析结果，选择以下移植路径（可多选）：

- [ ] **路径 A：纯逻辑翻译** — Java/Kotlin 逻辑直接翻译为 ArkTS
- [ ] **路径 B：平台 API 替换** — 核心逻辑复用，替换平台相关 API
- [ ] **路径 C：Native 代码复用 + NAPI 封装** — C/C++ 算法代码复用，JNI 层替换为 NAPI
- [ ] **路径 D：UI 重写** — 使用 ArkUI 完全重写 UI 层

**选择理由**：<!-- 说明为何选择上述路径，以及放弃其他路径的原因 -->

### 3.2 整体架构设计

<!-- 描述移植后的 HarmonyOS 库架构，与 Android 架构的对比。
     建议提供架构图。 -->

```
┌──────────────────────────────────────────────────┐
│              HarmonyOS 架构设计                   │
│                                                  │
│  caller ──► StackBlur.blur(pixelMap, radius)     │
│                    │                             │
│         ┌──────────┴──────────┐                  │
│       CPU 实现           NATIVE 实现              │
│   ArkTS 纯算法         NAPI ──► blur.c           │
│                                (直接复用)         │
└──────────────────────────────────────────────────┘
```

### 3.3 项目结构设计

```
Template/
├── library/                        # HAR 库模块
│   ├── Index.ets                   # 对外导出入口
│   └── src/main/
│       ├── ets/
│       │   ├── <CoreClass>.ets     # 核心逻辑类 (对应 Android 主类)
│       │   ├── impl/               # 内部实现
│       │   │   ├── <ImplA>.ets     # 实现 A（例：CPU 路径）
│       │   │   └── <ImplB>.ets     # 实现 B（例：Native 路径）
│       │   └── types/              # 类型定义
│       │       └── <Types>.ets
│       ├── cpp/                    # (如有 Native) C/C++ 源码
│       │   ├── CMakeLists.txt
│       │   ├── napi_entry.cpp      # NAPI 绑定层（新增）
│       │   └── <algo>.c            # 算法代码（直接复用）
│       └── resources/
├── entry/                          # Demo 应用模块
│   └── src/main/ets/pages/
│       └── Index.ets               # Demo 示例页面
└── entry/src/ohosTest/             # 测试代码
    └── ets/test/
        └── <LibName>.test.ets
```

---

## 四、核心模块移植方案

> 对每个需要移植的核心模块给出详细的迁移设计。

### 4.1 模块：`<模块名>`

**Android 实现**：<!-- 简述 Android 侧的实现原理 -->

**HarmonyOS 方案**：<!-- 详述移植后的实现原理，说明 API 替换关系和新增处理 -->

**关键 API 替换**：

| Android API | HarmonyOS API | 说明 |
|-------------|---------------|------|
| <!-- `Bitmap.createBitmap(w, h, Config.ARGB_8888)` --> | <!-- `image.createPixelMap(...)` --> | <!-- 位图创建 --> |
| <!-- `Canvas(bitmap)` --> | <!-- `drawing.Canvas` --> | <!-- 画布操作 --> |
| <!-- `Paint.setColor(int)` --> | <!-- `drawing.Pen.setColor(Color)` --> | <!-- 颜色设置 --> |

**伪代码设计**：

```typescript
// HarmonyOS 侧核心方法伪代码
export class <ClassName> {
  // 方法说明
  async methodName(param: Type): Promise<ReturnType> {
    // 1. 参数校验
    // 2. 核心逻辑
    // 3. 返回结果
  }
}
```

---

### 4.2 模块：Native 层（如有）

**迁移方式**：JNI → NAPI

**C/C++ 代码处理**：
- **直接复用**（不修改）：<!-- 列出文件，例：blur.c、blur_impl.cpp -->
- **适配修改**：<!-- 列出需要修改的文件及修改说明 -->
- **新增文件**：
  - `napi_entry.cpp` — NAPI 绑定层，替代原 JNI 绑定文件

**NAPI 绑定层设计**：

```cpp
// napi_entry.cpp 核心结构
static napi_value FunctionName(napi_env env, napi_callback_info info) {
    // 1. 解析 JS 参数
    // 2. 调用 C 层函数
    // 3. 将结果转换为 JS 值并返回
}

static napi_value Init(napi_env env, napi_value exports) {
    // 注册导出函数
    napi_property_descriptor props[] = {
        { "functionName", nullptr, FunctionName, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, 1, props);
    return exports;
}
EXTERN_C_START
static napi_module module = { .nm_version = 1, .nm_register_func = Init, .nm_modname = "libname" };
EXTERN_C_END
```

**CMakeLists.txt 关键配置**：

```cmake
cmake_minimum_required(VERSION 3.5.0)
project(<ProjectName>)

add_library(<libname> SHARED
    napi_entry.cpp
    # 复用的 C/C++ 源文件
    <algo>.c
)

target_link_libraries(<libname> PUBLIC libace_napi.z.so libhilog_ndk.z.so)
```

**TypeScript 类型声明（index.d.ts）**：

```typescript
// library/src/main/cpp/types/<libname>/index.d.ts
export const functionName: (param: ParamType) => ReturnType;
```

---

### 4.3 模块：UI 层（如有）

**Android 原实现**：<!-- 描述 Android View/Compose 实现 -->

**ArkUI 重写方案**：<!-- 描述 ArkUI 重写思路 -->

**关键组件映射**：

| Android 组件 | ArkUI 组件 | 说明 |
|-------------|-----------|------|
| <!-- `ImageView` --> | <!-- `Image` --> | <!-- 图片展示 --> |
| <!-- `Button` --> | <!-- `Button` --> | <!-- 按钮 --> |
| <!-- `RecyclerView` --> | <!-- `List` + `LazyForEach` --> | <!-- 列表 --> |

---

## 五、关键技术决策

> 记录移植过程中的重要技术选择，说明选择原因和放弃的备选方案。

### 决策 1：<决策标题>

**背景**：<!-- 描述要解决的问题 -->

**方案对比**：

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 方案 A：<!-- --> | <!-- --> | <!-- --> | <!-- 采用 / 放弃 --> |
| 方案 B：<!-- --> | <!-- --> | <!-- --> | <!-- 采用 / 放弃 --> |

**决策结论**：<!-- 采用方案 X，原因是…… -->

---

### 决策 2：同步 vs 异步 API 设计

**背景**：Android 侧 StackBlur 采用同步 API，但 HarmonyOS 主线程不允许执行耗时操作。

**方案对比**：

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 保持同步（在调用方自行切换线程） | 接口最简单 | 调用方容易误用导致主线程卡顿 | 放弃 |
| 返回 Promise（库内使用 taskpool）| 安全，与 OH 异步生态一致 | 接口与 Android 侧差异较大 | 采用 |

**决策结论**：采用 Promise 异步接口，在库内部使用 `taskpool` 切换到后台线程执行模糊算法。

---

## 六、API 差异与兼容性说明

> 总结与 Android 侧的主要差异，供上层应用开发者迁移参考。

### 6.1 破坏性变更（Breaking Changes）

| # | 变更描述 | Android 侧 | HarmonyOS 侧 | 迁移方法 |
|---|----------|-----------|-------------|---------|
| 1 | <!-- 图像类型变更 --> | <!-- Bitmap --> | <!-- PixelMap --> | <!-- 使用 image.createPixelMap() 替代 BitmapFactory.decodeResource() --> |
| 2 | <!-- 异步模型变更 --> | <!-- 同步返回 Bitmap --> | <!-- Promise<PixelMap> --> | <!-- 调用处改为 await 或 .then() --> |

### 6.2 行为差异（非破坏性）

| # | 差异描述 | Android 侧行为 | HarmonyOS 侧行为 |
|---|----------|--------------|----------------|
| 1 | <!-- 错误抛出方式 --> | <!-- 抛出 IllegalArgumentException --> | <!-- reject Promise 或抛出 Error --> |

---

## 七、测试方案

### 7.1 测试用例设计原则

- 每个公开方法至少覆盖：正常路径、边界值、异常输入三类用例
- Native 功能和 ArkTS 功能分组测试
- 测试命名规范：`it('test<方法名><场景>', 0, () => {...})`

### 7.2 测试用例清单

| 测试用例 ID | 所测接口 | 测试场景 | 预期结果 | 优先级 |
|------------|---------|---------|---------|--------|
| TC-001 | <!-- `StackBlur.blur()` --> | <!-- 正常输入，radius=10 --> | <!-- 返回模糊后 PixelMap，宽高与输入相同 --> | <!-- P0 --> |
| TC-002 | <!-- `StackBlur.blur()` --> | <!-- radius=0 边界值 --> | <!-- Promise reject 并返回 INVALID_RADIUS 错误 --> | <!-- P0 --> |
| TC-003 | <!-- `StackBlur.blur()` --> | <!-- radius=25 最大值 --> | <!-- 正常执行，返回高度模糊图像 --> | <!-- P1 --> |
| TC-004 | <!-- Native 路径 --> | <!-- 使用 BlurMode.NATIVE --> | <!-- 与 CPU 路径结果一致（像素差异 <1%） --> | <!-- P1 --> |

### 7.3 测试框架

使用 hypium 框架，测试文件位于 `entry/src/ohosTest/ets/test/`。  
详细测试编写规范参见 [references/testing.md](testing.md)。

---

## 八、风险评估

| 风险 | 概率 | 影响 | 应对措施 |
|------|------|------|----------|
| <!-- NAPI 与 C 层内存管理出现泄漏 --> | <!-- 中 --> | <!-- 高 --> | <!-- 使用 napi_create_reference 正确管理引用计数，使用 Sanitizer 检测泄漏 --> |
| <!-- PixelMap 颜色空间与 Bitmap 不一致导致色差 --> | <!-- 低 --> | <!-- 中 --> | <!-- 在测试中加入像素差对比，超出阈值时打印差异信息 --> |
| <!-- HarmonyOS 版本升级 API 变动 --> | <!-- 低 --> | <!-- 中 --> | <!-- 固定目标 API 版本，升级时回归测试 --> |

---

## 九、移植进度跟踪

| 阶段 | 任务 | 状态 | 完成日期 | 备注 |
|------|------|------|----------|------|
| 分析 | 可移植性分析 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 分析 | 三方库规格文档 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 分析 | 方案设计文档 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 项目搭建 | 创建 OH 项目结构 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 代码迁移 | ArkTS 核心逻辑 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 代码迁移 | NAPI 绑定层（如有）| <!-- ✅ / 🚧 / ⬜ --> | | |
| 代码迁移 | UI 层（如有）| <!-- ✅ / 🚧 / ⬜ --> | | |
| 代码迁移 | Demo Entry 页面 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 代码迁移 | 测试用例 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 验证 | assembleHar 编译通过 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 验证 | assembleHap 编译通过 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 验证 | 安装到真机成功 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 验证 | 所有测试用例 PASS | <!-- ✅ / 🚧 / ⬜ --> | | |
| 归档 | 规格文档补全 OH 侧内容 | <!-- ✅ / 🚧 / ⬜ --> | | |
| 归档 | 方案设计文档最终版 | <!-- ✅ / 🚧 / ⬜ --> | | |

---

## 十、参考资料

- [三方库规格.md](./三方库规格.md) — 本项目接口规格文档
- [references/api-mapping.md](../../references/api-mapping.md) — Android → HarmonyOS API 完整映射表
- [references/native-migration.md](../../references/native-migration.md) — JNI → NAPI 迁移参考
- [references/ui-migration.md](../../references/ui-migration.md) — View → ArkUI 迁移参考
- [references/testing.md](../../references/testing.md) — hypium 测试框架文档
- <!-- Android 源库官方文档 URL -->
- <!-- HarmonyOS 官方 API 文档 URL -->
