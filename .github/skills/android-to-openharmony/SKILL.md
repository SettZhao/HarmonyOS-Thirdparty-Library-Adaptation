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

## Skill 结构

本 skill 按类别拆分为多个子模块，每个模块聚焦一个领域：

| 子模块 | 说明 | 何时查阅 |
|--------|------|----------|
| [skills/analysis](skills/analysis/README.md) | 分析库可移植性、确定迁移策略 | Step 1-2: 开始移植前 |
| [skills/project-setup](skills/project-setup/README.md) | 创建 OH 项目结构、Template 使用 | Step 3: 创建项目 |
| [skills/code-migration](skills/code-migration/README.md) | Java/Kotlin → ArkTS 代码翻译 | Step 4: 迁移代码 |
| [skills/native-migration](skills/native-migration/README.md) | JNI/NDK → NAPI 迁移 | Step 4: 迁移 Native 代码 |
| [skills/ui-migration](skills/ui-migration/README.md) | View/Compose → ArkUI 迁移 | Step 4: 迁移 UI 代码 |
| [skills/build-and-test](skills/build-and-test/README.md) | 构建、安装、测试 SOP 流程 | Step 5: 验证与发布 |
| [skills/troubleshooting](skills/troubleshooting/README.md) | 常见问题与解决方案 | 遇到问题时 |

### 详细 API 参考

| 文档 | 内容 |
|------|------|
| [references/api-mapping.md](references/api-mapping.md) | Android → OH 完整 API 映射表 |
| [references/native-migration.md](references/native-migration.md) | JNI → NAPI 完整迁移示例 |
| [references/ui-migration.md](references/ui-migration.md) | View/Compose → ArkUI 完整映射 |
| [references/project-structure.md](references/project-structure.md) | OH 项目结构与构建系统 |
| [references/template-structure.md](references/template-structure.md) | Template 项目结构详解 |
| [references/testing.md](references/testing.md) | hypium 测试框架完整文档 |
| [refs/taskpool.md](references/refs/taskpool.md) | TaskPool API |
| [refs/worker.md](references/refs/worker.md) | Worker API |
| [refs/collections.md](references/refs/collections.md) | 共享容器 API |
| [refs/containers.md](references/refs/containers.md) | 线性/非线性容器 API |
| [refs/buffer.md](references/refs/buffer.md) | Buffer API |
| [refs/xml.md](references/refs/xml.md) | XML API |
| [refs/udp-socket.md](references/refs/udp-socket.md) | UDP Socket API |
| [refs/utils.md](references/refs/utils.md) | 工具类 API |
| [refs/error-codes.md](references/refs/error-codes.md) | 错误码参考 |

---

## 📚 Skill 自进化机制

本 skill 在每次移植过程中持续积累经验。详见 [references/EVOLUTION.md](references/EVOLUTION.md)。

**快速更新清单：**
- 重点问题 → 更新 [skills/troubleshooting](skills/troubleshooting/README.md)
- API 映射 → 更新 [references/api-mapping.md](references/api-mapping.md) 和 `references/refs/*.md`
- 可复用流程 → 创建 `scripts/` 下的辅助脚本

---

## ⚠️ 前置条件：环境检查

**在开始移植工作之前，必须先检查开发环境：**

```powershell
# 运行环境检查脚本（在 workspace 根目录下执行）
powershell -ExecutionPolicy Bypass -File `
  .github\skills\android-to-openharmony\scripts\check_env.ps1
```

或手动检查：

```powershell
# 检查 hvigorw（构建工具）
Get-Command hvigorw

# 检查 hdc（设备连接工具）
Get-Command hdc

# 检查设备连接
hdc list targets
```

**必须确保 hvigorw 和 hdc 都可用后才能继续。**

---

## 移植工作流（SOP 标准流程）

### 概览

```
Step 1: 分析可移植性          → skills/analysis
Step 2: 确定迁移策略          → skills/analysis
Step 3: 创建项目结构          → skills/project-setup
Step 4: 迁移核心代码          → skills/code-migration + native-migration + ui-migration
Step 5: SOP 验证流程          → skills/build-and-test
         ├─ A. assembleHar    → 编译 library（重试直到成功）
         ├─ B. assembleHap    → 编译 entry + library（重试直到成功）
         ├─ C. hdc install    → 安装到手机（重试直到成功）
         └─ D. 运行测试       → 执行测试用例（重试直到全部通过）
```

### Step 1-2: 分析库的可移植性并确定策略

详见 [skills/analysis/README.md](skills/analysis/README.md)

```bash
python scripts/analyze_library.py <android-library-source-path>
```

### Step 3: 创建 OpenHarmony 项目结构

详见 [skills/project-setup/README.md](skills/project-setup/README.md)

**⚠️ 关键规则：**
1. 使用 Template 标准结构
2. **bundleName 保持为 `"com.example.template"`**（不要修改，避免重新生成证书）
3. 清理 Template 模板残留文件
4. 确保模块名一致

### Step 4: 迁移核心代码

根据库类型参考对应子模块：

- **纯逻辑库 / 网络库** → [skills/code-migration/README.md](skills/code-migration/README.md)
- **Native 库 (JNI/NDK)** → [skills/native-migration/README.md](skills/native-migration/README.md)
- **UI 组件库** → [skills/ui-migration/README.md](skills/ui-migration/README.md)

**必须同时完成：**
- 迁移库代码到 `library/src/main/ets/`
- 创建 Demo 示例到 `entry/src/main/ets/pages/Index.ets`
- 编写测试用例到 `entry/src/ohosTest/ets/test/`

### Step 5: SOP 验证流程（严格按顺序执行）

详见 [skills/build-and-test/README.md](skills/build-and-test/README.md)

**⚠️ 核心原则：每一步必须成功后才能进入下一步。遇到错误必须修复代码后重试。**

#### A. 编译 Library HAR（重试直到成功）

```bash
hvigorw clean
hvigorw assembleHar
```

✅ 成功标准：`BUILD SUCCESSFUL` + HAR 文件生成
❌ 失败处理：分析编译错误 → 修复代码 → 重新编译

#### B. 编译 Demo 应用 HAP（重试直到成功）

```bash
hvigorw clean
hvigorw assembleHap
```

✅ 成功标准：`BUILD SUCCESSFUL` + HAP 文件生成
❌ 失败处理：检查依赖配置、导入语句 → 修复 → 重新编译

#### C. 安装到手机（重试直到成功）

```powershell
# 方法 1：使用脚本安装（推荐，从 workspace 根目录执行）
powershell -ExecutionPolicy Bypass -File `
  .github\skills\android-to-openharmony\scripts\install_hap.ps1 `
  -ProjectPath Template -Uninstall

# 方法 2：在项目目录内手动安装
cd Template
hdc install entry\build\default\outputs\default\entry-default-signed.hap
```

**脚本参数说明**：`-ProjectPath Template` 指定项目路径，`-Uninstall` 先卸载旧版本

✅ 成功标准：`install bundle successfully`
❌ 失败处理：检查签名、bundleName、设备连接 → 修复 → 重新安装

#### D. 运行测试用例（重试直到全部通过）

```powershell
# 方法 1：使用脚本运行测试（推荐，从 workspace 根目录执行）
powershell -ExecutionPolicy Bypass -File `
  .github\skills\android-to-openharmony\scripts\run_tests.ps1 -ShowLog

# 方法 2：手动运行测试
hdc shell "aa test -b com.example.template -m entry_test -s unittest OpenHarmonyTestRunner"
```

**脚本参数说明**：`-ShowLog` 测试失败时显示详细的 hilog 日志

✅ 成功标准：所有测试用例 PASS
❌ 失败处理：分析测试日志 → 修复库代码或测试代码 → 重新测试

---

## ⚠️ 错误反馈循环（必须遵守）

在 SOP 流程的**任何阶段**出现错误时：

1. **分析错误日志** — 仔细阅读编译器/安装器/测试框架的错误输出
2. **逆向定位代码** — 根据错误信息找到移植后代码中的问题位置
3. **修复代码** — 修改移植后的 ArkTS/C++/配置文件
4. **重新执行当前步骤** — 从当前失败的步骤重新开始
5. **重复直到成功** — 确保当前步骤成功后才进入下一步

**常见错误速查：** 参见 [skills/troubleshooting/README.md](skills/troubleshooting/README.md)

**查看设备日志：**
```powershell
# 实时查看 hilog
hdc hilog

# 过滤特定标签
hdc hilog | Select-String -Pattern "Demo|Error|FAIL"
```

---

## ⚠️ 关键规则汇总

### 1. bundleName 保持不变

```json5
// AppScope/app.json5 — 不要修改！
{ "app": { "bundleName": "com.example.template" } }
```

### 2. 编译 SDK 使用 HarmonyOS

Template 已配置为 HarmonyOS SDK，方便在真机上安装测试：
```json5
// build-profile.json5
{ "runtimeOS": "HarmonyOS" }
```

### 3. Native 模块类型声明

- 文件名必须为 `index.d.ts`
- 使用 `export const` 具名导出（不要用 `export default`）
- ArkTS 使用具名导入 `import { func } from 'lib.so'`

### 4. CMake 库名不加 lib 前缀

```cmake
add_library(mp4 SHARED ...)     # ✅ 生成 libmp4.so
add_library(libmp4 SHARED ...)  # ❌ 生成 liblibmp4.so
```

### 5. hilog 日志使用 `%{public}` 修饰符

```c
OH_LOG_INFO(LOG_APP, "value=%{public}d", val);  // ✅ 可见
OH_LOG_INFO(LOG_APP, "value=%d", val);           // ❌ 显示 <private>
```

### 6. 测试命名规范

- `describe()` / `it()` 名称不能包含空格
- `it()` 必须 3 个参数：`it('testName', 0, () => { ... })`

---

## 辅助脚本

**注意：以下脚本需要在 workspace 根目录（包含 Template/ 和 .github/ 的目录）下执行**

| 脚本 | 说明 | 用法 |
|------|------|------|
| `check_env.ps1` | 检查开发环境 | `powershell -EP Bypass -File .github\skills\android-to-openharmony\scripts\check_env.ps1` |
| `analyze_library.py` | 分析 Android 库可移植性 | `python .github\skills\android-to-openharmony\scripts\analyze_library.py <path>` |
| `install_hap.ps1` | 编译并安装 HAP | `powershell -EP Bypass -File .github\skills\...\install_hap.ps1 -ProjectPath Template` |
| `run_tests.ps1` | 运行测试用例 | `powershell -EP Bypass -File .github\skills\...\run_tests.ps1` |
| `skill_evolution_helper.py` | Skill 自进化辅助工具 | `python .github\skills\android-to-openharmony\scripts\skill_evolution_helper.py --check` |

**详细用法参见**：[scripts/USAGE_GUIDE.md](.github/skills/android-to-openharmony/scripts/USAGE_GUIDE.md)
