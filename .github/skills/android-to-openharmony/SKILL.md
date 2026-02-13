---
name: android-to-openharmony
description: |
  Android 三方库移植到 OpenHarmony (API 12+) 的完整工作流，涵盖可移植性分析、API 映射、代码迁移和项目构建。
  支持所有类型的 Android 库移植：Java/Kotlin 纯逻辑库、Android UI 组件库、包含 JNI/NDK Native 代码的库。
  Use when:
  (1) 将 Android 三方库（如 OkHttp、Gson、Glide 等）移植/迁移到 OpenHarmony 或 HarmonyOS NEXT
  (2) 分析 Android 库的 OpenHarmony 可移植性
  (3) 将 Android API 调用替换为 OpenHarmony API
  (4) 将 JNI/NDK 代码迁移到 NAPI
  (5) 将 Android View/Compose UI 代码迁移到 ArkUI
  (6) 创建 HAR/HSP 格式的 OpenHarmony 三方库包
  触发关键词：移植、迁移、porting、migration、Android to OpenHarmony、鸿蒙适配、三方库适配
---

# Android 三方库移植 OpenHarmony

## 移植工作流

将 Android 三方库移植到 OpenHarmony 遵循以下步骤：

1. **分析库的可移植性** — 运行 `scripts/analyze_library.py` 扫描源码
2. **确定库类型和移植策略** — 根据分析结果选择迁移路径
3. **创建 OpenHarmony 项目结构** — HAR 或 HSP 格式
4. **迁移核心代码** — 按类型替换 API
5. **构建、测试与发布**

## Step 1: 分析库的可移植性

运行分析脚本扫描 Android 库源码，生成可移植性报告：

```bash
python scripts/analyze_library.py <android-library-source-path>
python scripts/analyze_library.py <path> --output report.json  # 保存报告
```

报告输出：
- **complexity score** — 迁移复杂度评分 (0-100)，LOW/MEDIUM/HIGH/VERY_HIGH
- **android_apis** — 检测到的 Android API 按类别分组，含 OH 替代方案
- **dependencies** — 从 build.gradle 提取的三方依赖
- **native_code** — JNI/NDK 使用情况
- **recommendations** — 按难度排序的迁移建议

## Step 2: 确定库类型和移植策略

根据分析结果确定移植路径：

**纯逻辑库 (complexity LOW)**
- 如 Gson、Apache Commons 等不依赖 Android API 的库
- 策略：将 Java/Kotlin 代码翻译为 ArkTS，保持相同的接口设计
- 大部分 `java.util.*` / `java.io.*` 需替换为 ArkTS 等价物

**网络/存储库 (complexity MEDIUM)**
- 如 OkHttp、Retrofit、Room 等使用 Android 平台 API 的库
- 策略：核心接口保持不变，将 Android 平台 API 调用替换为 OH API
- 参考 [references/api-mapping.md](references/api-mapping.md) 的 Network / Storage 部分

**UI 组件库 (complexity HIGH)**
- 如 RecyclerView adapter 库、Material 组件等
- 策略：使用 ArkUI 声明式 UI 完全重写 UI 层，保留业务逻辑
- 参考 [references/ui-migration.md](references/ui-migration.md)

**Native 库 (complexity HIGH)**
- 包含 JNI/NDK 代码的库
- 策略：C/C++ 业务逻辑代码直接复用，将 JNI 绑定层替换为 NAPI
- 参考 [references/native-migration.md](references/native-migration.md)

## Step 3: 创建 OpenHarmony 项目结构

### 使用 Template 标准结构

推荐使用 OpenHarmony 标准项目模板（Template）组织移植代码，参考 [references/template-structure.md](references/template-structure.md)。

**Template 标准目录映射：**
- `library/` — 移植后的 HAR 库模块（对应 Android 的 library module）
- `entry/` — 示例应用和测试代码（对应 Android 的 app module）
- `cpp/` — Native C++ 代码和 NAPI 绑定（对应 Android 的 jni/cpp）

### 选择包格式

根据库类型选择 HAR (静态共享包) 或 HSP (动态共享包)：
- **HAR** — 适合纯逻辑库、工具库、网络库（推荐默认选择）
- **HSP** — 适合包含大量 UI 资源的组件库

项目结构和配置文件详见 [references/project-structure.md](references/project-structure.md)。

关键文件：
- `oh-package.json5` — 包描述（类似 package.json）
- `module.json5` — 模块配置（替代 AndroidManifest.xml）
- `build-profile.json5` — 构建配置（替代 build.gradle）
- `library/Index.ets` — 库的公共 API 导出入口

## Step 4: 迁移核心代码

### 通用迁移规则

1. Java/Kotlin class → ArkTS class 或 struct (UI 组件用 `@Component` struct)
2. Android import → OpenHarmony import（查 [references/api-mapping.md](references/api-mapping.md)）
3. `Log.d()` → `hilog.debug()`
4. `SharedPreferences` → `@ohos.data.preferences`
5. `Intent` → `Want`
6. `Activity/Fragment` lifecycle → `UIAbility` lifecycle

### 代码翻译要点

- **类型系统**：Java 类型 → ArkTS 类型（`int` → `number`, `String` → `string`, `List<T>` → `Array<T>`）
- **空安全**：Java `@Nullable` → ArkTS `T | null`，Kotlin `?` → ArkTS `?`
- **泛型**：基本保持一致，ArkTS 支持泛型
- **接口**：Java `interface` → ArkTS `interface`（无 default method，需改用抽象类或工具函数）
- **异常**：`try/catch` 模式保持一致
- **异步**：Java Thread/Coroutine → ArkTS `async/await` + `TaskPool`（详见 [refs/taskpool.md](references/refs/taskpool.md)）
- **容器**：Java Collections → ArkTS containers/collections（详见 [refs/containers.md](references/refs/containers.md) 和 [refs/collections.md](references/refs/collections.md)）
- **Buffer**：Java ByteBuffer → buffer.Buffer（详见 [refs/buffer.md](references/refs/buffer.md)）

### UI 代码迁移

Android View/Compose → ArkUI 详细映射表和迁移范例见 [references/ui-migration.md](references/ui-migration.md)。

### Native 代码迁移

JNI/NDK → NAPI 的详细类型映射、注册方式和代码示例见 [references/native-migration.md](references/native-migration.md)。

核心步骤：
1. 保留 C/C++ 业务逻辑代码不变
2. 删除所有 JNI 绑定代码 (`JNIEnv*`, `JNIEXPORT` 等)
3. 编写 NAPI 入口 (`napi_init.cpp`)，将函数注册到 NAPI
4. 编写 `.d.ts` 类型声明文件供 ArkTS 调用
5. 修改 CMakeLists.txt 链接 OH 系统库

## Step 5: 构建、测试与发布

### 使用 hvigorw 构建库

hvigor 是 OpenHarmony 的构建工具链（对应 Gradle），使用命令行编译项目：

```bash
# 清理旧的构建产物
hvigorw clean

# 构建 HAR 库（对应 ./gradlew assembleRelease）
hvigorw assembleHar

# 构建完整应用（对应 ./gradlew build）
hvigorw assembleApp
```

构建成功后，产物位于 `library/build/default/outputs/default/library.har`。

详细的 hvigorw 命令和编译错误排查参见 [references/project-structure.md](references/project-structure.md#hvigorw-构建工具)。

### 编写测试

使用 @ohos/hypium 测试框架（对应 JUnit），测试代码放在 `entry/src/ohosTest/ets/test/`：

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { MyClass } from 'library';

export default function abilityTest() {
  describe('MyClass Tests', () => {
    it('shouldWorkCorrectly', () => {
      let result = new MyClass().process();
      expect(result).assertEqual(expected);
    });
  });
}
```

**运行测试：**

```bash
# 运行所有测试（对应 ./gradlew test）
hvigorw --mode module test

# 生成覆盖率报告
hvigorw collectCoverage
```

完整的断言方法和测试最佳实践参见 [references/testing.md](references/testing.md)。

### 发布库

1. 在 DevEco Studio 中导入项目，确认编译通过
2. 验证单元测试通过，核心功能与原 Android 版本行为一致
3. 配置 `library/oh-package.json5` 的 name, version, description
4. 通过 `ohpm publish` 发布到 ohpm 仓库（可选）

## References

### 核心迁移指南

| 文档 | 内容 | 何时查阅 |
|------|------|----------|
| [references/template-structure.md](references/template-structure.md) | Template 标准项目结构、模块映射 | 创建项目结构时 |
| [references/api-mapping.md](references/api-mapping.md) | Android API → OH API 完整映射表 | 替换 API 调用时 |
| [references/project-structure.md](references/project-structure.md) | OH 项目结构、构建系统、hvigorw | 配置构建文件时 |
| [references/ui-migration.md](references/ui-migration.md) | View/Compose → ArkUI 迁移 | 迁移 UI 代码时 |
| [references/native-migration.md](references/native-migration.md) | JNI/NDK → NAPI 迁移 | 迁移 Native 代码时 |
| [references/testing.md](references/testing.md) | hypium 测试框架、断言方法 | 编写测试用例时 |

### 详细 API 参考 (refs/)

| 文档 | 内容 | 适用场景 |
|------|------|----------|
| [refs/taskpool.md](references/refs/taskpool.md) | TaskPool 完整 API (任务池、并发) | 替代 Executor/Coroutines |
| [refs/worker.md](references/refs/worker.md) | Worker 完整 API (后台线程) | 替代 Thread/HandlerThread |
| [refs/collections.md](references/refs/collections.md) | 共享容器完整 API | 跨线程数据传递 |
| [refs/utils.md](references/refs/utils.md) | ArkTSUtils (AsyncLock、LruCache) | 线程同步、工具类 |
| [refs/containers.md](references/refs/containers.md) | 线性/非线性容器完整 API | 替代 Java Collections |
| [refs/buffer.md](references/refs/buffer.md) | Buffer 完整 API | 替代 ByteBuffer |
| [refs/xml.md](references/refs/xml.md) | XML 解析生成完整 API | 替代 XmlPullParser |
| [refs/error-codes.md](references/refs/error-codes.md) | 语言基础库错误码 | 调试错误时 |
