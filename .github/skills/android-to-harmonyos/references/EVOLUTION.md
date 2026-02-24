# Skill 自进化指南

本文档指导 AI 助手在移植过程中如何更新和完善 android-to-openharmony skill。

## 自进化原则

skill 应该是一个**持续学习和改进的知识库**，在每次实际移植过程中积累经验：

1. **记录重点问题** — 遇到的新问题和解决方案
2. **更新 API 映射** — 发现的新的 Android → OpenHarmony API 对应关系
3. **优化工作流** — 改进移植步骤和最佳实践

## 何时触发自进化

### 1. 遇到需要注意的重点问题

**触发条件：**
- 移植过程中遇到阻塞性问题（编译错误、运行时错误）
- 问题的解决方案在现有 SKILL.md 中**未覆盖或覆盖不足**
- 问题具有通用性，可能在其他移植项目中再次出现

**判断标准：**
- ✅ **应该记录**：
  - 编译错误且错误信息难以直接定位原因
  - 配置问题（如模块名不一致、类型声明文件命名错误）
  - OpenHarmony 特有的限制或行为差异（如 hilog 格式化符）
  - 需要特定顺序或步骤才能解决的问题
  
- ❌ **不需要记录**：
  - 简单的语法错误（拼写错误、缺少分号等）
  - 一次性的特定项目问题（不具通用性）
  - 已在 SKILL.md 中详细说明的问题

**记录步骤：**

1. **在 SKILL.md 的"关键注意事项"部分添加新条目**
   - 位置：`## ⚠️ 关键注意事项（必须遵守）` 下新增一节
   - 格式：
     ```markdown
     ### N. **问题简要描述（分类标签）**
     
     **问题：** 具体描述问题现象和影响
     
     **典型错误：**（可选）
     ```
     错误信息示例
     ```
     
     **原因：** 深层次原因分析
     
     **解决方案：** 分步骤的详细解决方法
     
     **❌ 错误写法：**
     ```code
     错误示例代码
     ```
     
     **✅ 正确写法：**
     ```code
     正确示例代码
     ```
     
     **检查清单：**
     - [ ] 验证点1
     - [ ] 验证点2
     ```

2. **如果是配置相关问题，同步更新 references/project-structure.md**

3. **如果是 Native 相关，同步更新 references/native-migration.md**

**示例：记录 Native 模块导出方式问题**

遇到问题：使用 `export default` 导致 ArkTS 运行时找不到函数

更新位置：`SKILL.md` 中的 `### Native 代码迁移` 部分

添加内容：详细的"Native 模块类型声明的正确写法"章节（已存在的示例）

### 2. 更新 refs 中的接口列表

**触发条件：**
- 使用了现有文档未记录的 OpenHarmony API
- 发现 Android API 的新映射关系
- 需要使用 ArkTS 的新特性或模块

**更新文件：**

#### A. `references/api-mapping.md`

**何时更新：**
- 发现新的 Android → OpenHarmony API 映射
- 使用了文档中未列出的 `@kit.*` 或 `@ohos.*` 模块

**更新格式：**
```markdown
| Android API | OpenHarmony API | 说明 |
|------------|----------------|------|
| android.xxx.YYY | @kit.ModuleKit / @ohos.module.api | 简要说明 |
```

**分类标准：**
- **Core Language** — 基础类型、集合、工具类
- **UI Components** — UI 组件和布局
- **Network** — 网络请求
- **Storage** — 数据存储
- **Media** — 音视频处理
- **Sensors** — 传感器
- **System** — 系统服务

**示例：添加新的网络 API 映射**

发现 Android 的 `HttpURLConnection` 映射到 `@kit.NetworkKit.http`

更新 `api-mapping.md` 的 Network 部分：
```markdown
| java.net.HttpURLConnection | @kit.NetworkKit (http) | HTTP 请求 |
| java.net.URL | string (URL 字符串) | URL 处理 |
```

#### B. `references/refs/*.md` - 详细 API 参考

**何时更新：**
- 使用了某个 OpenHarmony 模块的多个 API
- 需要记录完整的使用模式和示例

**现有 refs 文件：**
- `buffer.md` — buffer.Buffer API
- `collections.md` — @kit.ArkTS.collections
- `containers.md` — @kit.ArkTS.containers
- `taskpool.md` — @kit.ArkTS.taskpool (异步)
- `worker.md` — @kit.ArkTS.worker (多线程)
- `xml.md` — XML 解析
- `utils.md` — 工具类
- `error-codes.md` — 错误码

**更新格式（以 taskpool.md 为例）：**
```markdown
# TaskPool API Reference

## 概述
用途描述

## 导入
\```typescript
import { taskpool } from '@kit.ArkTS';
\```

## 核心 API

### 函数名/类名

**签名：**
\```typescript
function apiName(param: Type): ReturnType
\```

**参数：**
- `param` — 参数说明

**返回值：**
- 返回值说明

**示例：**
\```typescript
// 示例代码
\```

## 常见用法

### 用例1
\```typescript
// 完整示例
\```
```

**新增 refs 文件的时机：**
- 某个 OpenHarmony 模块被频繁使用（3+ 次）
- 该模块的 API 复杂，需要详细说明
- 有多个典型使用模式需要记录

#### C. 创建新的 refs 文件

**步骤：**

1. **评估是否需要新文件**
   - 检查 API 是否已在现有 refs 文件中
   - 评估使用频率和复杂度

2. **创建文件**
   ```bash
   # 文件名：modulename.md
   # 位置：references/refs/modulename.md
   ```

3. **填写内容**（使用上述模板）

4. **在 api-mapping.md 中添加引用**
   ```markdown
   详见 [refs/modulename.md](references/refs/modulename.md)
   ```

**示例：创建 filesystem.md**

场景：移植文件操作相关库，频繁使用 `@kit.CoreFileKit`

创建 `references/refs/filesystem.md`：
```markdown
# Filesystem API Reference

## 概述
OpenHarmony 文件系统操作 API，替代 Android 的 java.io.File

## 导入
\```typescript
import { fileIo } from '@kit.CoreFileKit';
\```

## 核心 API

### fileIo.openSync()
...（详细内容）
```

### 3. 归纳整理可复用的 Function Call

**触发条件：**
- 移植过程中多次重复执行相同的操作序列
- 某些操作步骤具有固定模式

**记录位置：**

#### A. SKILL.md 中的"工作流"部分

**何时更新：**
- 发现新的标准化操作流程
- 优化现有步骤的执行顺序

**示例：添加"快速验证编译"步骤**

在 `## Step 5: 构建、测试与发布` 中添加：
```markdown
### 快速验证编译（推荐）

在完成每个主要步骤后，运行快速验证：

\```bash
# 1. 清理旧构建
hvigorw clean

# 2. 编译 HAR（验证语法和类型）
hvigorw assembleHar

# 3. 检查产物
ls -lh library/build/default/outputs/default/*.har
\```

**验证通过标准：**
- 无编译错误
- HAR 文件大小 > 100KB
\```
```

#### B. 创建辅助脚本

**何时创建：**
- 需要执行复杂的文本处理或文件操作
- 操作步骤需要参数化

**步骤：**

1. **规划脚本功能**
   - 定义输入输出
   - 确定脚本语言（Python/Shell/PowerShell）

2. **创建脚本文件**
   ```bash
   # 位置：scripts/script_name.py
   ```

3. **在 SKILL.md 中引用**
   ```markdown
   运行以下脚本自动处理：
   \```bash
   python scripts/script_name.py <args>
   \```
   ```

**示例：创建"清理模板文件"脚本**

```python
# scripts/clean_template.py
"""
清理 Template 模板文件
用法：python scripts/clean_template.py <project-path>
"""
import sys
import shutil
from pathlib import Path

def clean_template(project_path):
    project = Path(project_path)
    
    # 删除模板的 native 类型声明
    template_types = project / "library/src/main/cpp/types/liblibrary"
    if template_types.exists():
        shutil.rmtree(template_types)
        print(f"✓ Removed {template_types}")
    
    # 删除模板组件
    template_components = project / "library/src/main/ets/components"
    if template_components.exists():
        shutil.rmtree(template_components)
        print(f"✓ Removed {template_components}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python scripts/clean_template.py <project-path>")
        sys.exit(1)
    
    clean_template(sys.argv[1])
```

在 SKILL.md 中引用：
```markdown
### 清理 Template 模板文件

**自动清理（推荐）：**
\```bash
python scripts/clean_template.py <project-directory>
\```

**手动清理：**
\```bash
Remove-Item -Recurse library/src/main/cpp/types/liblibrary
Remove-Item -Recurse library/src/main/ets/components
\```
```

## 自进化工作流

### 完整流程

```
┌─────────────────┐
│ 移植过程中      │
│ 遇到问题/发现   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ 判断是否需要    │  ← 使用"触发条件"判断
│ 更新 skill      │
└────────┬────────┘
         │
         ├─ YES ─→ ┌──────────────┐
         │         │ 确定更新位置 │  ← SKILL.md / references / scripts
         │         └──────┬───────┘
         │                │
         │                ▼
         │         ┌──────────────┐
         │         │ 按照格式     │
         │         │ 更新文档     │
         │         └──────┬───────┘
         │                │
         │                ▼
         │         ┌──────────────┐
         │         │ 验证更新     │  ← 确保文档一致性
         │         └──────────────┘
         │
         └─ NO ──→ 继续移植

```

### 实际操作示例

**场景：移植过程中发现 CMakeLists.txt 库名配置问题**

1. **遇到问题**
   - 编译生成 `liblibmodule.so`，ArkTS 导入失败
   - 错误：`Cannot find function`

2. **判断是否需要更新**
   - ✅ 阻塞性问题
   - ✅ 未在现有文档中说明
   - ✅ 具有通用性

3. **确定更新位置**
   - 主文档：`SKILL.md` → `## ⚠️ 关键注意事项` → 新增一节
   - 可能涉及：`references/native-migration.md`

4. **更新文档**
   - 添加"CMakeLists.txt 库名配置"章节
   - 包含：问题描述、错误示例、正确写法、检查清单

5. **验证更新**
   - 检查 Markdown 格式正确
   - 确保代码示例可复制粘贴
   - 验证章节编号连续

## 更新检查清单

在完成每次移植项目后，review 以下内容：

### 必须更新
- [ ] 遇到了编译/运行时错误且现有文档未覆盖 → 更新 SKILL.md 关键注意事项
- [ ] 使用了新的 OpenHarmony API → 更新 api-mapping.md

### 可选更新
- [ ] 某个 API 使用频繁且复杂 → 创建/更新 refs/*.md
- [ ] 需要重复执行复杂操作 → 创建辅助脚本

### 质量检查
- [ ] 所有新增代码示例都经过验证
- [ ] 错误写法和正确写法成对出现
- [ ] 检查清单完整且可操作
- [ ] Markdown 格式正确（标题层级、代码块）

## AI 助手自进化提示词

在移植过程中，AI 助手应该主动识别需要更新 skill 的时机。以下是推荐的内部 prompt：

```
# Self-Evolution Check

After resolving any issue during migration:

1. **Is this issue blocking?** (compile error / runtime error)
   - If NO → continue
   - If YES → check below

2. **Is this issue covered in SKILL.md?**
   - If YES → continue
   - If NO → check below

3. **Is this issue generic?** (may happen in other projects)
   - If NO → continue (project-specific)
   - If YES → **UPDATE SKILL**

4. **Update actions:**
   - Add to SKILL.md "关键注意事项"
   - Update api-mapping.md if new API used
   - Create/update refs/*.md if API usage is complex
   - Create script if operation is repetitive

5. **After update:**
   - Inform user: "I've updated the skill documentation to prevent this issue in future migrations."
   - Show updated section briefly
```

## 版本控制

### 记录更新历史

在 SKILL.md 的开头添加更新日志（可选）：

```markdown
## 更新历史

### 2026-02-15
- 添加：CMakeLists.txt 库名配置注意事项
- 更新：hilog 日志格式化符说明
- 新增：refs/filesystem.md

### 2026-02-10
- 添加：Native 模块类型声明规范
- 更新：api-mapping.md 网络部分
```

### Git Commit 规范

```bash
# 格式：[Skill] <type>: <description>

# 类型：
# - fix: 修正现有文档错误
# - feat: 添加新的知识点
# - refactor: 重组文档结构
# - docs: 文档格式调整

# 示例：
git commit -m "[Skill] feat: add CMakeLists library naming issue"
git commit -m "[Skill] fix: correct hilog format specifier syntax"
git commit -m "[Skill] feat: create filesystem.md reference"
```

## 总结

自进化的核心是**从实践中学习**，将每次移植过程中的经验和教训积累到 skill 中，使其成为越来越完善的知识库。

**三个核心问题判断是否需要更新：**
1. 这个问题会再次出现吗？（通用性）
2. 现有文档能解决这个问题吗？（覆盖度）
3. 更新后能节省未来的时间吗？（实用性）

如果三个问题的答案都是 YES，那就应该更新 skill。
