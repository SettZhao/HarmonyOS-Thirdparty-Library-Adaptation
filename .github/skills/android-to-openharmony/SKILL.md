---
name: android-to-openharmony
description:
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

## 📚 Skill 自进化机制

本 skill 是一个**持续学习和改进的知识库**，在每次实际移植过程中不断积累经验：

### 何时更新 Skill

**1. 遇到需要注意的重点问题**
- 移植过程中遇到的阻塞性问题（编译错误、运行时错误）
- 现有文档未覆盖或覆盖不足的问题
- 具有通用性，可能在其他移植项目中再次出现的问题

**2. 发现新的 API 映射关系**
- 使用了现有文档未记录的 OpenHarmony API
- 发现 Android API 的新映射关系

**3. 归纳可复用的操作流程**
- 需要重复执行的操作序列
- 可以自动化的处理步骤

### 如何更新

详细的自进化指南参见：[references/EVOLUTION.md](references/EVOLUTION.md)

**快速更新清单：**
- 重点问题 → 更新 `SKILL.md` 的"关键注意事项"部分
- API 映射 → 更新 `references/api-mapping.md` 和 `references/refs/*.md`
- 可复用流程 → 创建 `scripts/` 下的辅助脚本

在移植过程中，AI 助手会主动识别需要更新的内容并自动完善 skill 文档。

---

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
- `entry/` — **示例应用和测试代码**（对应 Android 的 app module）
  - **必须包含 demo 示例：** 如果原 Android 库有 example/sample 目录，需迁移对应功能；如果没有，需创建基本的 demo 用于演示核心 API 和简单测试
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
4. **编写 `.d.ts` 类型声明文件供 ArkTS 调用（关键）**
5. 修改 CMakeLists.txt 链接 OH 系统库

**⚠️ Native 模块类型声明的正确写法（必须遵守）**

**问题案例：** 使用 `export default` 导致 ArkTS 找不到函数实现。

**错误写法❌：**
```typescript
// libmodule.d.ts - 错误：使用 default 导出和 interface
export interface ModuleNative {
  funcA: (arg: string) => number;
  funcB: (arg: number) => void;
}
declare const module: ModuleNative;
export default module;

// 使用时 - 错误：default 导入
import module from 'libmodule.so';
module.funcA('test');  // 运行时错误：找不到 funcA
```

**正确写法✅：**
```typescript
// index.d.ts - 正确：使用具名导出
/**
 * Function A description
 */
export const funcA: (arg: string) => number;

/**
 * Function B description
 */
export const funcB: (arg: number) => void;

// 使用时 - 正确：具名导入
import { funcA, funcB } from 'libmodule.so';
funcA('test');  // ✅ 正常工作
```

**类型声明文件规范：**

1. **文件位置和命名**
   ```
   library/src/main/cpp/types/libmodule/
   ├── oh-package.json5     # 配置 types 路径
   └── index.d.ts           # ⚠️ 必须命名为 index.d.ts
   ```

2. **oh-package.json5 配置**
   ```json5
   {
     "name": "libmodule.so",
     "types": "./index.d.ts",  // ⚠️ 指向 index.d.ts
     "version": "1.0.0",
     "description": "Native module type definitions"
   }
   ```

3. **index.d.ts 内容规范**
   ```typescript
   // ✅ 使用 export const 具名导出每个函数
   export const funcName: (param1: type1, param2: type2) => returnType;
   
   // ❌ 不要使用 export default
   // ❌ 不要使用 export interface 定义整个模块
   // ❌ 不要使用 declare namespace
   ```

4. **NAPI 注册代码（必须匹配）**
   ```cpp
   // napi_init.cpp
   EXTERN_C_START
   static napi_value Init(napi_env env, napi_value exports) {
       napi_property_descriptor desc[] = {
           // ⚠️ 属性名必须与 .d.ts 中的导出名一致
           { "funcName", nullptr, FuncName, nullptr, nullptr, nullptr, napi_default, nullptr },
           { "otherFunc", nullptr, OtherFunc, nullptr, nullptr, nullptr, napi_default, nullptr }
       };
       
       // ⚠️ 使用 napi_define_properties 注册到 exports 对象
       napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
       return exports;
   }
   EXTERN_C_END
   
   static napi_module demoModule = {
       .nm_version = 1,
       .nm_flags = 0,
       .nm_filename = nullptr,
       .nm_register_func = Init,
       .nm_modname = "modulename",  // ⚠️ 模块名
       .nm_priv = ((void*)0),
       .reserved = { 0 },
   };
   
   extern "C" __attribute__((constructor)) void RegisterModule(void) {
       napi_module_register(&demoModule);
   }
   ```

5. **ArkTS 使用方式（必须匹配）**
   ```typescript
   // ✅ 正确：使用具名导入
   import { funcName, otherFunc } from 'libmodule.so';
   
   const result = funcName(param1, param2);
   otherFunc(param);
   
   // ❌ 错误：不要使用 default 导入
   // import module from 'libmodule.so';  // 找不到模块
   ```

**验证清单：**
- [ ] 类型文件命名为 `index.d.ts`（不是 libXXX.d.ts）
- [ ] oh-package.json5 的 types 指向 `"./index.d.ts"`
- [ ] 所有函数使用 `export const funcName: ...` 声明
- [ ] 没有使用 `export default` 或 `export interface`
- [ ] NAPI 函数注册使用 `napi_define_properties`
- [ ] NAPI 注册的属性名与 .d.ts 导出名完全一致
- [ ] ArkTS 代码使用具名导入 `import { func } from 'lib.so'`
- [ ] 编译无警告："Declared function has no native implementation"
- [ ] 运行时无错误："Cannot find function"

### Demo 示例迁移

**必须在 `entry/src/main/ets/pages/` 中创建 demo 示例代码：**

**情况 A：原 Android 库有 example/sample 目录**
- 找到 Android 项目中的 `app/`, `example/`, `sample/` 等示例代码
- 将示例中的核心功能迁移到 `entry/src/main/ets/pages/Index.ets` 或单独的示例页面
- 保持原示例的功能演示逻辑，替换 Android API 为 ArkUI 组件

**情况 B：原 Android 库无 example**
- 创建基本的 demo 演示核心 API 使用方法
- Demo 必须包含：
  1. 导入并实例化库的主要类
  2. 调用核心 API 方法
  3. 显示返回结果或状态
  4. 错误处理示例

**示例代码模板：**
```typescript
// entry/src/main/ets/pages/Index.ets
import { LibraryClass } from 'library';  // 导入库
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  @State message: string = '';
  @State result: string = '';

  aboutToAppear() {
    this.runDemo();
  }

  async runDemo() {
    try {
      // 演示核心 API 使用
      let instance = new LibraryClass();
      let output = await instance.mainMethod('test input');
      this.result = `Success: ${output}`;
      hilog.info(0x0000, 'Demo', this.result);
    } catch (err) {
      this.result = `Error: ${err.message}`;
      hilog.error(0x0000, 'Demo', this.result);
    }
  }

  build() {
    Column() {
      Text('Library Demo')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 });
      
      Text(this.result)
        .fontSize(16)
        .margin({ top: 10 });
      
      Button('Run Test')
        .onClick(() => this.runDemo())
        .margin({ top: 20 });
    }
    .width('100%')
    .height('100%')
    .padding(20)
  }
}
```

**Demo 验证要点：**
- Demo 必须能够在 entry 模块中成功导入 library
- Demo 运行时不应产生 crash 或未捕获的异常
- Demo 应清晰展示库的主要功能和使用方法

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

## ⚠️ 关键注意事项（必须遵守）

### 1. **必须进行编译验证（Library + Demo）**

**问题：** 代码迁移完成后未进行编译验证，导致 HAR 无法正常编译或 Demo 应用无法运行。

**解决方案：** 在完成代码迁移后，**立即**运行编译命令验证：

**A. 验证 Library HAR 编译**

```bash
cd <project-directory>
hvigorw clean
hvigorw assembleHar
```

**验证成功标准：**
- 编译输出 `BUILD SUCCESSFUL`
- HAR 文件生成在 `library/build/default/outputs/default/<module-name>.har`
- 文件大小合理（通常 > 100KB）

**B. 验证 Demo 应用编译（必须）**

在完成 Demo 代码后，**必须**运行完整应用编译：

```bash
cd <project-directory>
hvigorw clean
hvigorw assembleApp
```

**验证成功标准：**
- 编译输出 `BUILD SUCCESSFUL`
- Library 模块编译成功
- Entry 模块编译成功
- HAP 文件生成在 `entry/build/default/outputs/default/entry-default-signed.hap`
- 文件大小合理（通常 > 1MB，包含 library 和 demo 代码）

**C. Demo 依赖配置检查（常见错误）**

如果 Demo 编译失败，检查以下配置：

1. **entry/oh-package.json5** 必须包含 library 依赖：
   ```json5
   {
     "dependencies": {
       "library": "file:../library"  // ⚠️ 依赖名称必须与模块名一致
     }
   }
   ```

2. **build-profile.json5** 中 library 必须在 entry 之前：
   ```json5
   {
     "modules": [
       { "name": "library", "srcPath": "./library" },  // ⚠️ 必须在前
       { "name": "entry", "srcPath": "./entry" }
     ]
   }
   ```

3. **entry/src/main/ets** 中的导入语句：
   ```typescript
   import { KCP } from 'library';  // ⚠️ 依赖名称必须与 oh-package.json5 一致
   ```

### 2. **清理 Template 模板文件**

**问题：** 从 Template 复制后，遗留了不需要的模板文件（如 `types/liblibrary/`）。

**解决方案：** 创建项目结构后，**必须**删除以下模板文件：

```bash
# 删除模板的 native module 类型声明
Remove-Item -Recurse library/src/main/cpp/types/liblibrary

# 删除模板的示例组件（如果不需要）
Remove-Item -Recurse library/src/main/ets/components
```

**检查清单：**
- [ ] `library/src/main/cpp/types/` 下只有当前库的类型声明目录
- [ ] `library/src/main/ets/` 下只有当前库的源代码
- [ ] 删除所有包含 "library" 或 "template" 字样的模板文件

### 3. **配置 Native Module 类型声明（关键）**

**问题：** 
1. 类型文件名错误（应该是 `index.d.ts` 而不是 `libXXX.d.ts`）
2. 使用错误的导出方式（`export default` 而不是 `export const`）
3. ArkTS 使用错误的导入方式（default import 而不是 named import）
4. 导致编译警告 "Declared function has no native implementation" 和运行时错误 "Cannot find function"

**解决方案：** 严格按照以下规范配置 Native 模块类型声明。

**A. 文件结构和命名**

```
library/src/main/cpp/types/libmodule/
├── oh-package.json5
└── index.d.ts          ⚠️ 必须命名为 index.d.ts（不是 libmodule.d.ts）
```

**B. oh-package.json5 配置**

```json5
{
  "name": "libmodule.so",
  "types": "./index.d.ts",  // ⚠️ 必须指向 index.d.ts
  "version": "1.0.0",
  "description": "Native module type definitions"
}
```

**常见错误：**
- ❌ `"types": "./libmodule.d.ts"` —— 错误：文件名不对
- ❌ `"types": "./types.d.ts"` —— 错误：应该是 index.d.ts
- ✅ `"types": "./index.d.ts"` —— 正确

**C. index.d.ts 内容（使用具名导出）**

**❌ 错误写法（export default）：**
```typescript
// 错误：使用 interface 和 default 导出
export interface ModuleNative {
  mp4DemuxOpen: (fileName: string) => number;
  mp4DemuxClose: (demux: number) => number;
}
declare const module: ModuleNative;
export default module;
```

**✅ 正确写法（export const）：**
```typescript
/**
 * Opens an MP4 file
 * @param fileName - File path
 * @returns Handle number
 */
export const mp4DemuxOpen: (fileName: string) => number;

/**
 * Closes the demuxer
 * @param demux - Handle
 * @returns Status code
 */
export const mp4DemuxClose: (demux: number) => number;

/**
 * Gets metadata
 * @param demux - Handle
 * @returns Metadata object
 */
export const mp4DemuxGetMetadata: (demux: number) => Record<string, string>;
```

**D. NAPI 注册代码（必须匹配 index.d.ts）**

```cpp
// napi_init.cpp
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        // ⚠️ 第一个字符串必须与 index.d.ts 中的导出名完全一致
        { "mp4DemuxOpen", nullptr, Mp4DemuxOpen, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "mp4DemuxClose", nullptr, Mp4DemuxClose, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "mp4DemuxGetMetadata", nullptr, Mp4DemuxGetMetadata, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    
    // ⚠️ 必须使用 napi_define_properties（不是 napi_set_named_property）
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "modulename",  // 模块名
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterModule(void) {
    napi_module_register(&demoModule);
}
```

**E. ArkTS 使用方式（使用具名导入）**

**❌ 错误写法（default import）：**
```typescript
// 错误：使用 default 导入
import libmodule from 'libmodule.so';
libmodule.mp4DemuxOpen('/path');  // 运行时错误：找不到函数
```

**✅ 正确写法（named import）：**
```typescript
// 正确：使用具名导入
import { mp4DemuxOpen, mp4DemuxClose, mp4DemuxGetMetadata } from 'libmodule.so';

// 直接调用函数
const demux = mp4DemuxOpen('/path/to/file.mp4');
const metadata = mp4DemuxGetMetadata(demux);
mp4DemuxClose(demux);
```

**F. 在封装类中使用**

```typescript
// Libmp4.ets
import { mp4DemuxOpen, mp4DemuxClose, mp4DemuxGetMetadata } from 'libmp4.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

export class Libmp4 {
  private demuxHandle: number = 0;
  
  constructor(fileName: string) {
    // ✅ 直接调用具名导入的函数
    this.demuxHandle = mp4DemuxOpen(fileName);
  }
  
  getMetadata(): Record<string, string> {
    return mp4DemuxGetMetadata(this.demuxHandle);
  }
  
  close(): void {
    mp4DemuxClose(this.demuxHandle);
  }
}
```

**检查清单：**
- [ ] 类型文件必须命名为 `index.d.ts`（不是 libXXX.d.ts）
- [ ] oh-package.json5 的 `types` 指向 `"./index.d.ts"`
- [ ] 所有函数使用 `export const functionName: (params) => returnType` 声明
- [ ] 没有使用 `export default` 或 `export interface ModuleNative`
- [ ] NAPI 使用 `napi_define_properties` 注册函数到 exports
- [ ] NAPI 注册的属性名与 index.d.ts 导出名完全一致
- [ ] ArkTS 使用 `import { func1, func2 } from 'lib.so'` 具名导入
- [ ] 编译无警告："Declared function 'xxx' has no native implementation"
- [ ] 运行时无错误："Cannot find function"

### 4. **确保模块名一致**

**问题：** `build-profile.json5` 和 `module.json5` 中的模块名不一致，导致编译错误。

**错误示例：**
```
Error: The module name library in build-profile.json5 must be same as moduleName in module.json5
```

**解决方案：** 确保以下文件中的模块名**完全一致**：

**`library/src/main/module.json5`:**
```json5
{
  "module": {
    "name": "libmp4",  // ← 模块名
    "type": "har",
    ...
  }
}
```

**`build-profile.json5` (根目录):**
```json5
{
  "modules": [
    {
      "name": "libmp4",  // ← 必须与 module.json5 一致
      "srcPath": "./library"
    }
  ]
}
```

**检查清单：**
- [ ] `module.json5` 的 `module.name` 
- [ ] `build-profile.json5` 的 `modules[].name`
- [ ] `oh-package.json5` 的 `name`（可以不同，但建议一致）

### 5. **处理 Native 库的外部依赖**

**问题：** Native C 代码依赖外部库（如 `futils`），直接注释 `#include` 会导致编译失败。

**典型错误：**
```
error: field has incomplete type 'struct list_node'
error: use of undeclared identifier 'list_init'
```

**解决方案：**

**A. 检测依赖（在 Step 1）**
```bash
# 搜索所有 #include 语句
grep -r "#include <" <android-library>/src/ | grep -v "std\|stdio\|stdlib\|string"

# 搜索外部头文件引用
grep -r "^#include.*/" <android-library>/src/
```

**B. 处理策略**

1. **如果依赖是简单的工具函数/数据结构：** 实现一个简化版本

   示例：实现简化的链表库（见 `list.h`）
   ```c
   // library/src/main/cpp/<module>/list.h
   struct list_node {
       struct list_node *prev;
       struct list_node *next;
   };
   
   static inline void list_init(struct list_node *head) { ... }
   static inline void list_add(struct list_node *node) { ... }
   ```

2. **如果依赖是复杂的三方库：** 一并迁移该库，或寻找 OpenHarmony 替代

3. **如果依赖未使用：** 用 `#if 0 ... #endif` 注释相关代码

**C. 更新头文件引用**
```c
// 替换：
// #include <futils/futils.h>

// 为：
#include "list.h"  // 自实现的简化版本
```

### 6. **CMakeLists.txt 库名配置（不要加 lib 前缀）**

**问题：** CMakeLists.txt 中使用 `add_library(libmodule ...)` 导致生成 `liblibmodule.so`，与 ArkTS 导入语句 `import from 'libmodule.so'` 不匹配。

**典型错误：**
```
SyntaxError: the requested module 'modulename' does not provide an export name 'functionName'
Error: Cannot find function
```

**原因：** CMake 会自动为库名添加 `lib` 前缀和 `.so` 后缀。

**解决方案：**

**❌ 错误写法：**
```cmake
# CMakeLists.txt
add_library(libmp4 SHARED       # ← 错误：库名包含 lib
    napi_init.cpp
    ${SOURCES}
)

target_link_libraries(libmp4 PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

# 生成文件：liblibmp4.so  ← 错误：重复的 lib 前缀
```

**✅ 正确写法：**
```cmake
# CMakeLists.txt
add_library(mp4 SHARED          # ← 正确：库名不包含 lib
    napi_init.cpp
    ${SOURCES}
)

# Note: CMake will automatically add 'lib' prefix to generate 'libmp4.so'
target_link_libraries(mp4 PUBLIC
    libace_napi.z.so
    libhilog_ndk.z.so
)

# 生成文件：libmp4.so  ← 正确
```

**类型声明和导入（必须匹配）：**
```typescript
// types/libmp4/oh-package.json5
{
  "name": "libmp4.so"  // ← 与生成的 .so 文件名一致
}

// Libmp4.ets
import { mp4DemuxOpen, ... } from 'libmp4.so';  // ← 导入库名匹配
```

**规则总结：**
- **CMakeLists.txt**: `add_library(modulename SHARED ...)` —— 库名不含 `lib`
- **生成文件**: `libmodulename.so` —— CMake 自动添加 `lib` 前缀
- **oh-package.json5**: `"name": "libmodulename.so"` —— 完整 .so 文件名
- **ArkTS 导入**: `import ... from 'libmodulename.so'` —— 完整 .so 文件名

**对比参考（使用 mqtt 库的正确模式）：**
```cmake
# mqtt/src/main/cpp/CMakeLists.txt
add_library(mqtt SHARED ...)     # ← 库名: mqtt
# → 生成: libmqtt.so

# types/libmqtt/oh-package.json5
{ "name": "libmqtt.so" }

# MqttClient.ets
import { createClient, ... } from 'libmqtt.so';  # ← 匹配
```

**检查清单：**
- [ ] CMakeLists.txt 的 `add_library()` 第一个参数不含 `lib` 前缀
- [ ] 编译后在 `build/.../libs/.../` 中生成的 .so 文件名正确（只有一个 `lib` 前缀）
- [ ] `oh-package.json5` 的 name 与生成的 .so 文件名完全一致
- [ ] ArkTS 导入语句使用完整的 .so 文件名（包含 `lib` 前缀）

### 7. **hilog 日志格式化符（Debug 可见性）**

**问题：** 使用普通格式化符（如 `%d`, `%s`, `%u`）输出的日志参数值在 debug 时不可见，显示为 `<private>`。

**典型错误输出：**
```
OH_LOG_INFO: Found <private> metadata entries
OH_LOG_INFO: Closed MP4 demuxer, ret=<private>
OH_LOG_DEBUG: Metadata: <private>: <private>
```

**原因：** OpenHarmony hilog 默认将所有日志参数视为敏感信息，需要显式标记为 `public` 才能在 debug 日志中显示。

**解决方案：** 在所有格式化符前添加 `{public}` 修饰符。

**❌ 错误写法：**
```c
// 参数值不可见
OH_LOG_INFO(LOG_APP, "Found %u metadata entries", count);
OH_LOG_INFO(LOG_APP, "Closed demuxer, ret=%d", ret);
OH_LOG_DEBUG(LOG_APP, "Metadata: %s: %s", key, value);
OH_LOG_INFO(LOG_APP, "Opened file, demux=%p", demux);

// 输出：
// Found <private> metadata entries
// Closed demuxer, ret=<private>
// Metadata: <private>: <private>
// Opened file, demux=<private>
```

**✅ 正确写法：**
```c
// 参数值可见
OH_LOG_INFO(LOG_APP, "Found %{public}u metadata entries", count);
OH_LOG_INFO(LOG_APP, "Closed demuxer, ret=%{public}d", ret);
OH_LOG_DEBUG(LOG_APP, "Metadata: %{public}s: %{public}s", key, value);
OH_LOG_INFO(LOG_APP, "Opened file, demux=%{public}p", demux);

// 输出：
// Found 5 metadata entries
// Closed demuxer, ret=0
// Metadata: title: My Video
// Opened file, demux=0x7ff8a1234560
```

**常用格式化符对照表：**
| 数据类型 | 错误写法 | 正确写法 | 说明 |
|---------|---------|---------|------|
| `int`, `long` | `%d`, `%ld` | `%{public}d`, `%{public}ld` | 整数 |
| `unsigned int` | `%u` | `%{public}u` | 无符号整数 |
| `size_t` | `%zu` | `%{public}zu` | 大小类型 |
| `float`, `double` | `%f`, `%lf` | `%{public}f`, `%{public}lf` | 浮点数 |
| `char*`, `string` | `%s` | `%{public}s` | 字符串 |
| `void*` | `%p` | `%{public}p` | 指针地址 |
| `bool` | `%d` | `%{public}d` | 布尔值（转为 int） |
| 十六进制 | `%x`, `%X` | `%{public}x`, `%{public}X` | 十六进制 |

**修改示例：**
```c
// napi_init.cpp 修改前后对比
// 修改前❌
OH_LOG_INFO(LOG_APP, "Found %u metadata entries", count);
OH_LOG_WARN(LOG_APP, "Failed to set property %s", keys[i]);
OH_LOG_DEBUG(LOG_APP, "Metadata: %s: %s", keys[i], values[i]);

// 修改后✅
OH_LOG_INFO(LOG_APP, "Found %{public}u metadata entries", count);
OH_LOG_WARN(LOG_APP, "Failed to set property %{public}s", keys[i]);
OH_LOG_DEBUG(LOG_APP, "Metadata: %{public}s: %{public}s", keys[i], values[i]);
```

**规则总结：**
- **所有 hilog 日志** 的格式化符都应使用 `%{public}...` 形式
- **开发阶段** 必须加 `{public}`，否则无法 debug
- **发布阶段** 敏感信息可移除 `{public}` 以保护隐私
- **编译器不报错** —— 即使忘记加 `{public}` 也能编译，但运行时参数不可见

**检查清单：**
- [ ] 所有 `OH_LOG_INFO/DEBUG/WARN/ERROR` 中的格式化符都包含 `{public}`
- [ ] 运行 app 后在 hilog 中能看到完整的参数值（不是 `<private>`）
- [ ] 指针地址、数字、字符串都正确显示

**库内部 C 代码日志（Native 库特有）：**

如果移植的库包含大量 C/C++ 源码（如 libmp4），这些源码中的调试日志可能显示为 `<private>`：

```
offset 0x<private> box '<private><private><private><private>' size <private>
# ftyp: major_brand=<private><private><private><private>
# mvhd: timescale=<private>
```

**原因：**
- 库内部的 C 代码使用 `MP4_LOGD()` 等宏，这些宏内部调用 `OH_LOG_*`
- 但格式化字符串是从调用方传入的字面量（如 `"offset 0x%llx box '%c%c%c%c' size %llu"`）
- C 预处理器无法在宏内修改传入的字符串字面量

**判断是否需要修复：**

1. **检查 NAPI 层日志是否可见：**
   ```
   Successfully opened MP4 file, demux=0x5b20ac2800  ← ✅ 应该可见
   Found 1 metadata entries                          ← ✅ 应该可见
   Metadata: title: My Video                         ← ✅ 应该可见
   ```
   
   如果 NAPI 层（napi_init.cpp）的日志都可见，说明**修复已完成**。

2. **库内部调试日志显示 private 是正常的：**
   - 这些是库的实现细节（Box 解析、内部状态），不影响应用功能
   - 应用层关心的关键信息（打开成功、元数据内容）已通过 NAPI 层暴露
   - 发布版本中，内部日志显示为 private 反而更安全

3. **如果必须调试库内部：**
   
   可以选择性地修改特定文件的日志（但通常不推荐）：
   
   ```c
   // 修改 libmp4/mp4_box.c 中的某个日志
   // 修改前：
   MP4_LOGD("# ftyp: major_brand=%c%c%c%c", ...);
   
   // 修改后：
   MP4_LOGD("# ftyp: major_brand=%{public}c%{public}c%{public}c%{public}c", ...);
   ```
   
   或者创建一个包装函数（性能开销较大）：
   
   ```c
   // mp4_log.c
   void mp4_log_public(int level, const char *fmt, ...) {
       // 运行时字符串替换（复杂且性能开销大，不推荐）
   }
   ```

**推荐做法：**
- ✅ **NAPI 层日志（必须）**：所有 napi_init.cpp 中的 OH_LOG_* 都使用 `%{public}`
- ✅ **库内部日志（可选）**：保持原样，显示为 private 是可接受的
- ⚠️ **有选择地修改**：仅在需要调试特定模块时修改对应文件的日志

### 8. **处理日志宏冲突**

**问题：** OpenHarmony 的 `hilog/log.h` 已定义 `LOG_DOMAIN` 和 `LOG_TAG`，重复定义会导致警告或错误。

**解决方案：** 在定义前先 `#undef`：

```c
// mp4_log.h
#ifdef BUILD_OPENHARMONY
#include <hilog/log.h>

// 取消 hilog 的默认定义
#undef LOG_DOMAIN
#undef LOG_TAG

// 重新定义为库专用值
#define LOG_DOMAIN 0x0001
#define LOG_TAG "libmp4"

#define MP4_LOGD(...) OH_LOG_DEBUG(LOG_APP, __VA_ARGS__)
#define MP4_LOGI(...) OH_LOG_INFO(LOG_APP, __VA_ARGS__)
#define MP4_LOGE(...) OH_LOG_ERROR(LOG_APP, __VA_ARGS__)
#endif
```

**兼容旧日志宏：**

如果原代码使用 `ULOG_*` 宏，添加兼容宏：
```c
#define ULOG_DEBUG LOG_DEBUG
#define ULOG_PRI(level, fmt, ...) \
    do { \
        if (level == LOG_DEBUG) OH_LOG_DEBUG(LOG_APP, fmt, ##__VA_ARGS__); \
        else if (level == LOG_INFO) OH_LOG_INFO(LOG_APP, fmt, ##__VA_ARGS__); \
        else OH_LOG_ERROR(LOG_APP, fmt, ##__VA_ARGS__); \
    } while(0)
```

### 9. **必须提供 entry 模块的 Demo 示例**

**问题：** 移植后的库缺少使用示例，无法快速验证功能和为用户提供参考。

**解决方案：** 在 `entry/src/main/ets/pages/` 中**必须**创建 demo 示例代码。

**A. 有 example 的情况**

如果原 Android 库包含 `example/`, `sample/`, `app/` 等示例模块：

1. **定位示例代码：**
   ```bash
   # Android 项目中常见的示例位置
   <android-library>/app/src/main/java/
   <android-library>/example/src/main/java/
   <android-library>/sample/src/main/java/
   ```

2. **迁移示例功能：**
   - 识别示例中的核心演示功能（通常在 MainActivity 或示例 Activity 中）
   - 将功能逻辑迁移到 `entry/src/main/ets/pages/Index.ets` 或创建独立示例页面
   - 替换 Android UI (Activity/Fragment/View) 为 ArkUI (@Component struct)

**B. 无 example 的情况**

如果原 Android 库没有示例代码，**必须**创建基本 demo：

**Demo 最低要求：**
```typescript
// entry/src/main/ets/pages/Index.ets
import { YourLibraryClass } from 'library';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  @State result: string = 'Ready';

  runBasicDemo() {
    try {
      // 1. 实例化库的主要类
      let lib = new YourLibraryClass();
      
      // 2. 调用核心 API
      let output = lib.mainMethod('test');
      
      // 3. 显示结果
      this.result = `Output: ${output}`;
      hilog.info(0x0000, 'Demo', this.result);
    } catch (err) {
      this.result = `Error: ${err.message}`;
      hilog.error(0x0000, 'Demo', this.result);
    }
  }

  build() {
    Column() {
      Text('Library Demo')
        .fontSize(24)
        .margin({ bottom: 20 });
      
      Button('Run Test')
        .onClick(() => this.runBasicDemo());
      
      Text(this.result)
        .margin({ top: 20 });
    }
    .width('100%')
    .padding(20)
  }
}
```

**Demo 必须包含：**
- [ ] 导入库的主要类/函数
- [ ] 实例化对象或调用方法的示例
- [ ] 至少一个核心 API 的演示
- [ ] 结果展示（Text 组件或 hilog 输出）
- [ ] 错误处理（try-catch）

**C. 验证 Demo 可用性**

```bash
# 1. 编译整个项目（包括 entry）
hvigorw assembleApp

# 2. 运行 entry 模块
# 在 DevEco Studio 中点击 Run 按钮，或通过 hdc 安装 HAP

# 3. 检查 Demo 运行
# ✅ 应看到：Demo 页面正常显示
# ✅ 点击按钮后功能正常执行
# ❌ 不应出现：crash、未捕获异常、import 失败
```

**检查清单：**
- [ ] `entry/src/main/ets/pages/Index.ets` 存在且包含 demo 代码
- [ ] Demo 成功导入 library 模块（`import ... from 'library'`）
- [ ] Demo 能够实例化库的类或调用函数
- [ ] Demo 运行时无 crash（使用 try-catch 包裹）
- [ ] Demo 输出可观察（Text 组件或 hilog）

**D. Demo 模块依赖配置（关键）**

创建 demo 后，必须正确配置 entry 模块对 library 模块的依赖：

**1. 配置 entry/oh-package.json5：**
```json5
{
  "name": "entry",
  "version": "1.0.0",
  "description": "Demo application",
  "dependencies": {
    "library": "file:../library"  // ⚠️ 依赖名必须是 "library"（模块名）
  }
}
```

**常见错误：**
- ❌ `"libmp4": "file:../library"` —— 错误：import 时找不到模块
- ❌ `"library": "file:../library/build/default/outputs/default/library.har"` —— 错误：指向 HAR 文件会导致编译失败
- ✅ `"library": "file:../library"` —— 正确：指向 library 模块源码目录

**2. 调整模块编译顺序：**

在根目录的 `build-profile.json5` 中，确保 library 模块在 entry 之前：

```json5
{
  "modules": [
    {
      "name": "library",  // ← library 必须在前
      "srcPath": "./library",
      "targets": [
        {
          "name": "default",
          "applyToProducts": ["default"]
        }
      ]
    },
    {
      "name": "entry",    // ← entry 在后
      "srcPath": "./entry",
      "targets": [
        {
          "name": "default",
          "applyToProducts": ["default"]
        }
      ]
    }
  ]
}
```

**原因：** hvigor 按照 modules 数组顺序编译，entry 依赖 library，必须先编译 library。

**4. 验证依赖配置：**

```bash
# 清理并重新编译
hvigorw clean
hvigorw assembleApp

# ✅ 应看到：
# - library 模块先编译
# - entry 模块编译时成功导入 library
# - 最终生成 entry-default-signed.hap

# ❌ 如果看到错误：
# "Cannot find module 'library'" → 检查 oh-package.json5 依赖名
# "Dependency library not found" → 检查 oh_modules/library 链接
# "module name mismatch" → 检查 build-profile.json5 顺序
```

**完整配置检查清单：**
- [ ] `entry/oh-package.json5` 中 dependencies 包含 `"library": "file:../library"`
- [ ] `build-profile.json5` 中 library 模块在 entry 之前
- [ ] library 模块的 `module.json5` 中 `module.name` 是 "library"（或其他名称但保持一致）
- [ ] entry 模块能成功编译且无 "Cannot find module" 错误

---

### 10. **网络 API 类型使用（UDP/TCP Socket）**

**问题：** 使用 `@kit.NetworkKit` 的 `socket.UDPSocket` 或 `socket.TCPSocket` 时，事件回调的参数类型使用错误，导致运行时类型不匹配。

**常见错误：** 在使用 UDP socket 的 `on('message')` 事件时，错误地将回调参数类型声明为 `socket.UDPMessageInfo`。

**❌ 错误示例：**
```typescript
import socket from '@kit.NetworkKit';

let udpSocket = socket.constructUDPSocketInstance();

// 错误：回调参数类型应该是 socket.SocketMessageInfo，而不是 socket.UDPMessageInfo
udpSocket.on('message', (data: socket.UDPMessageInfo) => {
  // 运行时会收到 socket.SocketMessageInfo 类型的对象，导致类型不匹配
  console.log(data.remoteInfo.address);  // 可能导致运行时错误
});
```

**✅ 正确示例：**
```typescript
import socket from '@kit.NetworkKit';

let udpSocket = socket.constructUDPSocketInstance();

// 正确：使用 socket.SocketMessageInfo 类型
udpSocket.on('message', (data: socket.SocketMessageInfo) => {
  let view = new Uint8Array(data.message);
  let address = data.remoteInfo.address;  // 正确访问属性
  let port = data.remoteInfo.port;
  console.log(`Received from ${address}:${port}`);
});
```

**解决方案和类型映射：**

| Socket 类型 | 事件名 | 回调参数类型 | 说明 |
|------------|--------|-------------|------|
| `UDPSocket` | `'message'` | `socket.SocketMessageInfo` | ⚠️ 不是 `UDPMessageInfo` |
| `UDPSocket` | `'error'` | `{ errno: number }` | 错误事件 |
| `TCPSocket` | `'message'` | `socket.SocketMessageInfo` | 与 UDP 相同 |
| `TCPSocket` | `'connect'` | `void` | 连接成功事件 |
| `TCPSocketServer` | `'connect'` | `socket.TCPSocketConnection` | 新连接事件 |

**SocketMessageInfo 结构：**
```typescript
interface SocketMessageInfo {
  message: ArrayBuffer;        // 接收到的数据
  remoteInfo: {                // 远程地址信息
    address: string;           // IP 地址
    port: number;              // 端口号
    family: string;            // 'IPv4' 或 'IPv6'
    size: number;              // 数据大小
  };
}
```

**检查清单：**
- [ ] 所有 `socket.on('message', ...)` 回调使用 `socket.SocketMessageInfo` 类型
- [ ] 不使用 `socket.UDPMessageInfo` 或 `socket.TCPMessageInfo`（这些类型可能不存在或不适用）
- [ ] 访问 `data.message` 时使用 `ArrayBuffer` 处理（如 `new Uint8Array(data.message)`）
- [ ] 访问远程地址信息使用 `data.remoteInfo.address` 和 `data.remoteInfo.port`

**参考文档：**
- [@kit.NetworkKit (网络管理)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-socket-V5)
- [socket.UDPSocket](https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/js-apis-socket-V5#udpsocket)

---

### 11. **编译验证清单**

完成代码迁移后，按以下清单逐项检查和验证：

#### 项目结构检查
- [ ] 删除了所有 Template 模板文件（`liblibrary`, `MainPage` 等）
- [ ] `types/<module-name>/oh-package.json5` 存在且 types 路径正确
- [ ] `types/<module-name>/<module-name>.d.ts` 存在

#### 配置文件检查
- [ ] `module.json5` 的 `module.name` 已更新
- [ ] `build-profile.json5` 的 `modules[].name` 与 `module.json5` 一致
- [ ] `oh-package.json5` 的依赖指向正确（native module）
- [ ] `CMakeLists.txt` 包含所有 C 源文件
- [ ] **Demo 依赖配置检查（必须）：**
  - [ ] `entry/oh-package.json5` 中 dependencies 包含 `"library": "file:../library"`
  - [ ] `build-profile.json5` 中 library 模块在 entry 模块之前
  - [ ] 依赖名称与模块名称保持一致

#### Native 代码检查（如适用）
- [ ] 所有 `#include` 引用的头文件存在或已实现
- [ ] 无 `JNIEnv*`, `jstring`, `JNIEXPORT` 等 JNI 残留
- [ ] 日志宏已替换为 OpenHarmony hilog
- [ ] 无 `__android_log_print` 调用

#### 编译验证

**A. HAR 库编译验证（必须）**

```bash
# 1. 清理
hvigorw clean

# 2. 编译 HAR
hvigorw assembleHar

# 3. 检查输出
# ✅ 应看到：BUILD SUCCESSFUL
# ❌ 任何 ERROR 都必须解决

# 4. 验证 HAR 文件
ls library/build/default/outputs/default/*.har
# ✅ 文件存在且大小 > 100KB
```

**检查清单：**
- [ ] `hvigorw assembleHar` 编译成功
- [ ] HAR 文件生成在 `library/build/default/outputs/default/`
- [ ] HAR 文件大小合理（通常 > 100KB）
- [ ] 无编译错误或警告

**B. Demo 应用编译验证（必须）**

在完成 Demo 代码后，必须验证整个应用能够成功编译和运行：

```bash
# 1. 清理所有模块
hvigorw clean

# 2. 编译整个应用（包括 library + entry）
hvigorw assembleApp

# 3. 检查编译输出
# ✅ 应看到：
# - "BUILD SUCCESSFUL" 
# - library 模块编译成功
# - entry 模块编译成功

# 4. 验证 HAP 文件
ls entry/build/default/outputs/default/entry-default-signed.hap

# ✅ 应看到：
# - 文件存在
# - 文件大小合理（通常 > 1MB，包含 library 和 demo 代码）
```

**检查清单：**
- [ ] `hvigorw clean` 成功清理所有构建输出
- [ ] `hvigorw assembleApp` 编译成功
- [ ] library 模块先于 entry 模块编译
- [ ] entry 模块能成功导入 library 模块（无 "Cannot find module" 错误）
- [ ] HAP 文件生成在 `entry/build/default/outputs/default/`
- [ ] HAP 文件大小 > 1MB（包含 library HAR 和 demo 代码）
- [ ] 无编译错误或警告

**C. 设备运行验证（可选但推荐）**

```bash
# 1. 安装到设备（需要连接设备或模拟器）
hdc install entry/build/default/outputs/default/entry-default-signed.hap

# 2. 启动应用
hdc shell aa start -a EntryAbility -b <bundle-name>

# 3. 查看日志
hdc hilog | grep -i "demo"

# ✅ 应看到：
# - 应用成功安装
# - 应用成功启动
# - Demo 页面正常显示
# - 点击按钮后功能正常执行
# - hilog 输出正确的日志信息
```

**检查清单：**
- [ ] HAP 成功安装到设备
- [ ] 应用启动无 crash
- [ ] Demo 页面正常显示
- [ ] Demo 功能正常执行
- [ ] hilog 输出符合预期（无错误日志）

#### 功能验证
- [ ] **创建单元测试用例（必须）**
  - [ ] 在 `entry/src/ohosTest/ets/test/` 目录创建测试文件（如 `Libmp4.test.ets`）
  - [ ] **测试用例必须添加到 `List.test.ets` 中**：
    ```typescript
    // List.test.ets
    import abilityTest from './Ability.test';
    import yourLibraryTest from './YourLibrary.test'; // ← 必须导入
    
    export default function testsuite() {
      abilityTest();
      yourLibraryTest(); // ← 必须调用
    }
    ```
  - [ ] **使用正确的断言方法**（hypium 1.0.4+）：
    - ✅ 支持：`assertNull()`, `assertUndefined()`, `assertEqual()`, `assertTrue()`, `assertFalse()`
    - ✅ 取反：`expect(obj).not().assertNull()` —— 实现 assertNotNull
    - ❌ 不支持：`assertNotNull()`, `assertNotUndefined()`, `assertNotEqual()`
    - 详见 [references/testing.md](references/testing.md)
  - [ ] **测试命名规范（严格要求）**：
    - **`describe()` 测试套件名称**：
      - ✅ 只能包含：字母、数字、下划线 `_`、点 `.`
      - ✅ 必须以字母开头
      - ❌ 不能包含空格或其他特殊字符
      - 推荐：驼峰命名（CamelCase）
      - 示例：`describe('Libmp4Tests', ...)` ✅ | `describe('Libmp4 Tests', ...)` ❌
    - **`it()` 测试用例写法（必须遵守）**：
      - **⚠️ 必须提供 3 个参数**：`it(testName, filterParam, testFunction)`
      - **参数 1 - 测试名称**：不能包含空格，推荐驼峰命名（camelCase）
      - **参数 2 - 过滤参数**：通常使用 `0`（必需，不能省略）
      - **参数 3 - 测试函数**：包含实际测试逻辑的箭头函数
      - **❌ 错误示例**（缺少 filter 参数）：
        ```typescript
        it('testCreateInstance', () => {  // ❌ 编译错误：Expected 3 arguments, but got 2
          // ...
        });
        ```
      - **✅ 正确示例**（3 个参数）：
        ```typescript
        it('testCreateInstance', 0, () => {  // ✅ 正确
          const instance = new MyClass();
          expect(instance).not().assertNull();
        });
        ```
      - **完整测试用例示例**：
        ```typescript
        import { describe, it, expect } from '@ohos/hypium';
        import { MyClass } from 'library';
        
        export default function myLibraryTests() {
          describe('MyLibraryTests', () => {
            
            it('testBasicFunction', 0, () => {
              const result = MyClass.doSomething();
              expect(result).assertEqual(42);
            });
            
            it('testErrorHandling', 0, () => {
              try {
                MyClass.throwError();
                expect(false).assertTrue(); // 不应该执行到这里
              } catch (err) {
                expect((err as Error).message).assertEqual('Expected error');
              }
            });
            
          });
        }
        ```
  - [ ] 测试覆盖核心 API 的基本功能和异常情况
- [ ] **在 entry 模块中创建 demo 示例（必须）**
  - [ ] 如果原库有 example，迁移对应功能
  - [ ] 如果原库无 example，创建基本 demo 演示核心 API
  - [ ] Demo 能成功导入 library 模块（`import { ... } from 'library'`）
  - [ ] Demo 能正常运行，无 crash
  - [ ] Demo 包含错误处理（try-catch）
  - [ ] Demo 有清晰的 UI 反馈（Text 组件或 hilog）
- [ ] **运行单元测试验证**：
  ```bash
  # 运行所有测试
  hvigorw --mode module test
  
  # ✅ 应看到：
  # - 测试套件执行
  # - 测试用例通过
  # - 无断言失败
  ```
- [ ] **编译并运行 entry 应用验证 demo：**
  ```bash
  # 编译整个应用（包括 library 和 entry）
  hvigorw assembleApp
  
  # ✅ 应看到：
  # - library 模块编译成功
  # - entry 模块编译成功
  # - 生成 entry-default-signed.hap
  # - 文件大小 > 1MB（包含 library 和 demo）
  
  # 在设备上运行（可选）
  hdc install entry/build/default/outputs/default/entry-default-signed.hap
  hdc shell aa start -a EntryAbility -b <bundle-name>
  ```

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
| [refs/udp-socket.md](references/refs/udp-socket.md) | UDP Socket 完整 API (UDPSocket) | 替代 DatagramSocket |
| [refs/error-codes.md](references/refs/error-codes.md) | 语言基础库错误码 | 调试错误时 |
