# Skill 自进化快速入门

## 🎯 核心理念

**Skill 会在使用过程中自己学习和成长**

每次移植 Android 库到 OpenHarmony 时，如果遇到新问题或发现新知识，skill 会自动更新，下次就不会再遇到同样的问题。

## 📖 三类可以自进化的内容

### 1️⃣ 重点问题与解决方案

**什么时候记录？**
- ✅ 编译错误或运行时错误让你卡住了
- ✅ 错误信息不能直接指向问题
- ✅ 其他人可能也会遇到这个问题

**记录在哪里？**
- 临时记录：`ISSUES_TEMPLATE.md`
- 正式文档：`SKILL.md` 的"⚠️ 关键注意事项"部分

**示例：**
```markdown
### 3. **配置 Native Module 类型声明（关键）**

**问题：** 使用 `export default` 导致 ArkTS 找不到函数

**解决方案：** 使用 `export const funcName: ...` 具名导出
```

### 2️⃣ API 映射关系

**什么时候记录？**
- ✅ 使用了新的 OpenHarmony API
- ✅ 发现 Android API 的新映射方式

**记录在哪里？**
- 临时记录：`API_MAPPING_TEMPLATE.md`
- 正式文档：`references/api-mapping.md`

**示例：**
```markdown
| java.net.HttpURLConnection | @kit.NetworkKit (http) | HTTP 请求 |
| java.util.concurrent.ExecutorService | @kit.ArkTS.taskpool | 线程池 |
```

### 3️⃣ 可复用的操作流程

**什么时候创建？**
- ✅ 某个操作需要重复执行多次
- ✅ 可以通过脚本自动化

**创建在哪里？**
- `scripts/*.py` — Python 脚本
- `SKILL.md` — 操作步骤说明

**示例：**
```python
# scripts/clean_template.py
# 自动清理 Template 模板文件
```

## 🚀 快速开始

### 方式一：AI 助手自动更新（推荐）

使用 AI 助手进行移植时，它会自动识别需要更新的内容并完善文档。

```
你：帮我移植这个 Android 库到 OpenHarmony
AI：[执行移植]
AI：✅ 遇到了一个新问题，已更新 skill 文档防止未来再次出现
```

### 方式二：手动记录和更新

**1. 移植过程中记录问题**

遇到问题时，快速记录：
```markdown
问题：CMakeLists.txt 库名配置错误导致生成 liblibmodule.so
原因：库名不应包含 lib 前缀
解决：使用 add_library(module SHARED ...) 而不是 add_library(libmodule ...)
验证：✅
需要更新 SKILL：是
```

**2. 移植完成后批量更新**

运行辅助工具检查待处理内容：
```bash
python scripts/skill_evolution_helper.py --skill-dir . --check
```

**3. 合并到正式文档**

```bash
# 查看详细报告
python scripts/skill_evolution_helper.py --skill-dir . --report

# 交互式合并
python scripts/skill_evolution_helper.py --skill-dir . --merge
```

## 📋 更新决策树

```
遇到问题
    │
    ├─ 是否阻塞？（编译失败/运行失败）
    │    NO → 不记录，继续
    │    YES ↓
    │
    ├─ 现有文档有说明吗？
    │    YES → 不记录，继续
    │    NO ↓
    │
    ├─ 其他项目会遇到吗？
    │    NO → 不记录（特定项目问题）
    │    YES ↓
    │
    └─ ✅ 更新 SKILL！
```

## 📝 更新格式速查

### 问题记录格式

```markdown
### N. **问题标题（分类）**

**问题：** 现象描述

**典型错误：**
\```
错误信息
\```

**原因：** 深层分析

**解决方案：** 步骤说明

**❌ 错误写法：**
\```code
错误代码
\```

**✅ 正确写法：**
\```code
正确代码
\```

**检查清单：**
- [ ] 验证点
```

### API 映射格式

```markdown
| Android API | OpenHarmony API | 说明 |
|------------|----------------|------|
| android.xxx | @kit.XXXKit | 说明 |
```

## 🔧 辅助工具命令

```bash
# 检查待处理内容
python scripts/skill_evolution_helper.py --skill-dir . --check

# 验证 SKILL.md 格式
python scripts/skill_evolution_helper.py --skill-dir . --validate

# 生成详细报告
python scripts/skill_evolution_helper.py --skill-dir . --report

# 交互式合并模板
python scripts/skill_evolution_helper.py --skill-dir . --merge
```

## ✅ 更新后的验证清单

完成 skill 更新后，确认：

- [ ] 代码示例都经过验证
- [ ] 错误/正确写法成对出现
- [ ] 检查清单完整可操作
- [ ] Markdown 格式正确
- [ ] 运行 `--validate` 无错误

## 💡 最佳实践

### ✅ 推荐做法

1. **及时记录** — 遇到问题时立即记录，不要事后回忆
2. **详细说明** — 包含错误信息、原因分析、完整代码
3. **配对示例** — 错误写法和正确写法都提供
4. **验证测试** — 所有代码示例必须验证
5. **分类整理** — 按照现有分类组织内容

### ❌ 避免做法

1. **记录简单错误** — 语法错误、拼写错误不需要记录
2. **缺少上下文** — 只有代码片段，没有说明
3. **未验证代码** — 未经测试的解决方案
4. **格式混乱** — 不符合现有文档格式
5. **重复内容** — 与现有内容重复

## 📚 完整文档索引

- **SKILL.md** — 主文档，完整工作流
- **EVOLUTION.md** — 自进化详细指南
- **API_MAPPING_TEMPLATE.md** — API 映射暂存
- **ISSUES_TEMPLATE.md** — 问题暂存
- **README.md** — 总体说明
- **references/api-mapping.md** — API 映射正式文档
- **references/refs/*.md** — 详细 API 参考

## 🤝 AI 助手与人工协作

```
┌────────────────┐
│   AI 助手      │ ← 移植过程中自动识别并更新
├────────────────┤
│   自动更新     │
│   - 重点问题   │
│   - API 映射   │
│   - 工作流优化 │
└────────┬───────┘
         │
         ▼
┌────────────────┐
│   模板文件     │ ← 临时暂存
├────────────────┤
│   - ISSUES_... │
│   - API_MAP... │
└────────┬───────┘
         │
         ▼ (人工 review)
┌────────────────┐
│   正式文档     │ ← 经过验证的知识
├────────────────┤
│   - SKILL.md   │
│   - api-map... │
│   - refs/*.md  │
└────────────────┘
```

## 🎓 示例场景

### 场景 1：遇到 Native 模块导出问题

**移植过程：**
1. 创建 Native 模块，使用 `export default`
2. 编译通过，但运行时错误："Cannot find function"
3. 调试发现应该使用 `export const` 具名导出

**自进化操作：**
```markdown
✅ AI 助手自动识别这是通用问题
✅ 在 SKILL.md 添加"Native 模块类型声明"章节
✅ 包含错误/正确写法对比
✅ 添加验证清单
```

### 场景 2：使用新的 OpenHarmony API

**移植过程：**
1. 需要文件操作，查找发现 `@kit.CoreFileKit`
2. 使用 `fileIo.openSync()` 替代 Java `FileInputStream`

**自进化操作：**
```markdown
✅ 在 API_MAPPING_TEMPLATE.md 记录映射
✅ 移植完成后合并到 api-mapping.md
✅ 如果使用频繁，创建 refs/filesystem.md
```

---

**记住：Skill 越用越强！**

每次移植都是 skill 成长的机会 🌱 → 🌳
