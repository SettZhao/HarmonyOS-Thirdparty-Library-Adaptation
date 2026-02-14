# 构建、安装与测试

本 skill 覆盖移植工作流的 Step 5：使用 hvigorw 构建、hdc 安装、运行测试的完整流程。

---

## SOP 标准流程（必须按顺序执行）

移植完成后，严格按以下顺序执行，**每一步都必须成功后才能进入下一步**：

```
Step A: assembleHar (编译 library)
  ↓ 成功
Step B: assembleHap (编译 entry + library)
  ↓ 成功
Step C: hdc install (安装到手机)
  ↓ 成功
Step D: 运行测试用例 (验证功能)
  ↓ 全部通过
✅ 完成
```

**⚠️ 错误反馈循环：** 在任何一步中遇到错误，**必须**分析错误日志，逆向定位到移植后的代码进行修复，然后**重新从当前步骤开始**，直到该步骤成功。

---

## Step A: 编译 Library HAR

```bash
cd <project-directory>
hvigorw clean
hvigorw assembleHar
```

**成功标准：**
- 编译输出 `BUILD SUCCESSFUL`
- HAR 文件生成在 `library/build/default/outputs/default/library.har`
- 文件大小合理（通常 > 100KB）

**常见错误与修复：**

| 错误 | 原因 | 修复 |
|------|------|------|
| ArkTS 语法错误 | Java/Kotlin 未完全转换 | 检查类型声明、泛型、可空类型 |
| 模块导入错误 | import 路径错误 | 检查 `@ohos.*` / `@kit.*` 模块路径 |
| Native 编译错误 | CMakeLists 配置错误 | 检查库链接、头文件路径 |
| `.d.ts` 声明错误 | 类型文件缺失或格式错误 | 确认使用 `export const` 具名导出 |
| 模块名不一致 | module.json5 与 build-profile.json5 不匹配 | 统一模块名 |

---

## Step B: 编译 Demo 应用 HAP

```bash
cd <project-directory>
hvigorw clean
hvigorw assembleHap
```

**成功标准：**
- 编译输出 `BUILD SUCCESSFUL`
- Library 模块和 Entry 模块都编译成功
- HAP 文件生成在 `entry/build/default/outputs/default/entry-default-signed.hap`
- 文件大小合理（通常 > 1MB）

**常见错误与修复：**

| 错误 | 原因 | 修复 |
|------|------|------|
| Cannot find module 'library' | entry 未正确依赖 library | 检查 `entry/oh-package.json5` 的 dependencies |
| 模块编译顺序错误 | library 未先于 entry 编译 | 检查 `build-profile.json5` 的 modules 顺序 |
| import 失败 | 导入名与 oh-package.json5 name 不匹配 | 统一名称 |

---

## Step C: 安装到手机

### 前置条件

确保 hdc 环境变量已配置（参见 [环境检查](#环境检查)）。

### 安装命令

```powershell
# HAP 文件路径
$hapPath = "entry\build\default\outputs\default\entry-default-signed.hap"

# 安装到手机
hdc install $hapPath
```

**成功标准：**
- 输出 `install bundle successfully`
- 手机上能看到应用图标

**常见错误与修复：**

| 错误 | 原因 | 修复 |
|------|------|------|
| `hdc: command not found` | 未配置环境变量 | 配置 hdc 到 PATH |
| `install failed: signature verification failed` | 签名配置问题 | 使用 Template 的默认签名（bundleName 保持 `com.example.template`） |
| `device not found` | 设备未连接 | 运行 `hdc list targets` 确认 |
| `install failed: already exists` | 旧版本未卸载 | 先运行 `hdc uninstall com.example.template` |

---

## Step D: 运行测试用例

### 使用 hdc 远程执行测试

```powershell
# 运行全部测试
hdc shell "aa test -b com.example.template -m entry_test -s unittest OpenHarmonyTestRunner"
```

**成功标准：**
- 所有测试用例 PASS
- 无断言失败
- 无 crash 或未捕获异常

**常见错误与修复：**

| 错误 | 原因 | 修复 |
|------|------|------|
| `ability not found` | entry_test 模块未安装 | 确认编译了 ohosTest target |
| 断言失败 | 库功能实现有误 | 根据失败信息修复库代码 |
| crash | 运行时错误 | 查看 `hdc hilog` 日志定位问题 |

### 查看测试日志

```powershell
# 实时查看日志
hdc hilog | Select-String -Pattern "test|Test|PASS|FAIL|Error"
```

---

## 环境检查

在执行 SOP 流程之前，先检查必要的环境变量：

```powershell
# 检查 hvigorw 是否可用
Get-Command hvigorw -ErrorAction SilentlyContinue
if (-not $?) { Write-Host "❌ hvigorw 未配置" -ForegroundColor Red }

# 检查 hdc 是否可用
Get-Command hdc -ErrorAction SilentlyContinue
if (-not $?) { Write-Host "❌ hdc 未配置" -ForegroundColor Red }

# 检查设备连接
hdc list targets
```

也可以使用脚本一键检查（从 workspace 根目录）：

```powershell
powershell -ExecutionPolicy Bypass -File .github\skills\android-to-openharmony\scripts\check_env.ps1
```

---

## 编写测试用例

使用 @ohos/hypium 测试框架（对应 JUnit）。

### 测试文件位置

```
entry/src/ohosTest/ets/test/
├── Ability.test.ets          # 默认测试
├── List.test.ets             # 测试列表（⚠️ 必须注册新测试）
└── MyLibrary.test.ets        # 你的库测试
```

### 测试代码模板

```typescript
import { describe, it, expect } from '@ohos/hypium';
import { MyClass } from 'library';

export default function myLibraryTests() {
  describe('MyLibraryTests', () => {  // ⚠️ 名称不能有空格

    it('testCreateInstance', 0, () => {  // ⚠️ 必须3个参数
      const instance = new MyClass();
      expect(instance).not().assertNull();
    });

    it('testCoreFunction', 0, () => {
      const result = MyClass.doSomething();
      expect(result).assertEqual(42);
    });

    it('testErrorHandling', 0, () => {
      try {
        MyClass.throwError();
        expect(false).assertTrue();
      } catch (err) {
        expect((err as Error).message).assertEqual('Expected error');
      }
    });
  });
}
```

### ⚠️ 测试必须注册到 List.test.ets

```typescript
// List.test.ets
import abilityTest from './Ability.test';
import myLibraryTests from './MyLibrary.test';  // ← 必须导入

export default function testsuite() {
  abilityTest();
  myLibraryTests();  // ← 必须调用
}
```

### 测试命名规范

- **`describe()` 名称**：只能包含字母、数字、下划线 `_`、点 `.`，以字母开头，不能有空格
- **`it()` 名称**：不能有空格，推荐驼峰命名
- **`it()` 必须3个参数**：`it(name, 0, () => { ... })`

### 常用断言

| 方法 | 说明 |
|------|------|
| `expect(x).assertEqual(y)` | 相等 |
| `expect(x).assertTrue()` | 为 true |
| `expect(x).assertFalse()` | 为 false |
| `expect(x).assertNull()` | 为 null |
| `expect(x).not().assertNull()` | 不为 null (assertNotNull) |
| `expect(x).not().assertEqual(y)` | 不相等 |
| `expect(x).assertLarger(y)` | 大于 |
| `expect(x).assertContain(y)` | 包含 |
| `expect(x).assertDeepEquals(y)` | 深度相等 |

---

## Demo 示例代码

**必须**在 `entry/src/main/ets/pages/Index.ets` 中创建 demo：

```typescript
import { MyClass } from 'library';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  @State result: string = 'Ready';

  runDemo() {
    try {
      let instance = new MyClass();
      let output = instance.mainMethod('test');
      this.result = `Success: ${output}`;
      hilog.info(0x0000, 'Demo', '%{public}s', this.result);
    } catch (err) {
      this.result = `Error: ${(err as Error).message}`;
      hilog.error(0x0000, 'Demo', '%{public}s', this.result);
    }
  }

  build() {
    Column() {
      Text('Library Demo').fontSize(24).margin({ bottom: 20 })
      Button('Run Test').onClick(() => this.runDemo())
      Text(this.result).margin({ top: 20 })
    }
    .width('100%').padding(20)
  }
}
```

---

## 详细参考

- [references/testing.md](../../references/testing.md) — hypium 测试框架完整文档
- [references/project-structure.md](../../references/project-structure.md) — hvigorw 构建工具详解
