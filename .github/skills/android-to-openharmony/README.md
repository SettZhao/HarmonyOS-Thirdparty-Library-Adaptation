# Android to OpenHarmony Skill

Android 三方库移植到 OpenHarmony 的知识库和工作流指南。

## 📁 文件结构

```
android-to-openharmony/
├── SKILL.md                    # 主文档：完整的移植工作流和注意事项
├── README.md                   # 本文件：skill 使用说明
│
├── references/                 # 详细参考文档
│   ├── EVOLUTION.md            # 自进化指南：如何更新和完善 skill
│   ├── QUICKSTART.md           # 快速入门：自进化机制使用指南
│   ├── API_MAPPING_TEMPLATE.md # 模板：记录新发现的 API 映射
│   ├── ISSUES_TEMPLATE.md      # 模板：收集移植过程中的问题
│   ├── IMPLEMENTATION_SUMMARY.md # 实施总结：自进化系统说明
│   ├── api-mapping.md          # Android → OpenHarmony API 映射表
│   ├── native-migration.md     # JNI/NDK → NAPI 迁移指南
│   ├── ui-migration.md         # Android UI → ArkUI 迁移指南
│   ├── project-structure.md    # OpenHarmony 项目结构说明
│   ├── template-structure.md   # Template 标准结构说明
│   ├── testing.md              # 测试指南
│   └── refs/                   # 详细 API 参考
│       ├── buffer.md           # buffer.Buffer API
│       ├── collections.md      # collections API
│       ├── containers.md       # containers API
│       ├── taskpool.md         # 异步任务
│       ├── worker.md           # 多线程
│       ├── xml.md              # XML 解析
│       ├── utils.md            # 工具类
│       └── error-codes.md      # 错误码
│
└── scripts/                    # 辅助脚本
    └── analyze_library.py      # 库可移植性分析脚本
```

## 🚀 快速开始

### 使用 Skill 进行移植

1. **阅读主文档**
   ```bash
   打开 SKILL.md，按照"移植工作流"执行
   ```

2. **分析可移植性**
   ```bash
   python scripts/analyze_library.py <android-library-path>
   ```

3. **查阅参考文档**
   - API 映射：`references/api-mapping.md`
   - Native 迁移：`references/native-migration.md`
   - UI 迁移：`references/ui-migration.md`

4. **遇到问题时**
   - 先查看 SKILL.md 的"关键注意事项"部分
   - 搜索错误信息关键词
   - 查阅 references/ 中的相关文档

### AI 助手使用 Skill

当用户提出移植需求时，AI 助手会：

1. **读取 SKILL.md** 获取完整工作流
2. **执行移植步骤** 按照文档指导进行
3. **自动更新 skill** 遇到新问题时完善文档

AI 助手会在以下情况下自动更新 skill：
- 遇到阻塞性问题且现有文档未覆盖
- 使用了新的 OpenHarmony API
- 发现可以自动化的操作流程

## 📖 Skill 自进化机制

本 skill 会在使用过程中不断完善和更新。

### 为什么需要自进化？

- **技术迁移** — OpenHarmony API 持续更新
- **经验积累** — 每次移植都会遇到新问题
- **知识沉淀** — 避免重复踩坑

### 自进化工作流

```
移植过程 → 发现问题/新 API → 评估是否通用 → 更新文档 → 归档经验
```

### 自进化三原则

1. **通用性优先** — 只记录可能再次出现的问题
2. **实用性优先** — 确保更新能节省未来的时间
3. **准确性优先** — 所有代码示例必须验证

### 更新内容分类

| 类型 | 更新位置 | 触发条件 |
|-----|---------|---------|
| 重点问题 | SKILL.md 关键注意事项 | 阻塞性 + 未覆盖 + 通用 |
| API 映射 | api-mapping.md, refs/*.md | 使用新的 OH API |
| 工作流优化 | SKILL.md 工作流部分 | 发现可改进的步骤 |
| 辅助脚本 | scripts/*.py | 需要自动化的操作 |

### 如何贡献更新

**人工更新：**

1. **记录问题**
   ```bash
   编辑 references/ISSUES_TEMPLATE.md，填写问题详情
   ```

2. **记录 API 映射**
   ```bash
   编辑 references/API_MAPPING_TEMPLATE.md，添加新的映射
   ```

3. **批量更新到正式文档**
   ```bash
   # 评估后，将模板中的内容合并到对应的正式文档
   ```

**AI 助手自动更新：**

AI 助手会在移植过程中自动识别需要更新的内容，并直接更新到正式文档。更新后会通知用户：

```
✅ 已更新 skill 文档，防止此问题在未来的移植中再次出现。
更新内容：[简要说明]
```

## 📋 更新清单

完成移植项目后，建议 review 以下内容：

### 必须检查
- [ ] 遇到了新的编译/运行时错误 → 检查是否需要添加到 SKILL.md
- [ ] 使用了新的 OpenHarmony API → 更新 api-mapping.md

### 可选检查
- [ ] 某个 API 使用频繁且复杂 → 创建 refs/*.md
- [ ] 需要重复执行复杂操作 → 创建辅助脚本

### 质量检查
- [ ] 新增代码示例都经过验证
- [ ] 错误写法和正确写法成对出现
- [ ] Markdown 格式正确

## 🔧 辅助工具

### 可移植性分析脚本

```bash
python scripts/analyze_library.py <android-library-path>

# 保存报告
python scripts/analyze_library.py <path> --output report.json

# 详细输出
python scripts/analyze_library.py <path> --verbose
```

**输出内容：**
- 复杂度评分（LOW/MEDIUM/HIGH/VERY_HIGH）
- 检测到的 Android API 及 OH 替代方案
- 三方依赖列表
- JNI/NDK 使用情况
- 迁移建议

### 未来计划的工具

- [ ] `clean_template.py` — 清理 Template 模板文件
- [ ] `validate_config.py` — 验证配置文件一致性
- [ ] `generate_demo.py` — 生成 demo 示例代码模板

## 📚 相关资源

### OpenHarmony 官方文档
- [API 参考](https://docs.openharmony.cn/pages/v5.0/)
- [开发指南](https://docs.openharmony.cn/)
- [DevEco Studio](https://developer.huawei.com/consumer/cn/deveco-studio/)

### 社区资源
- [OpenHarmony 三方库中心](https://ohpm.openharmony.cn/)
- [鸿蒙开发者论坛](https://developer.huawei.com/consumer/cn/forum/)

## 📝 版本历史

### 2026-02-15
- ✨ 添加自进化机制
- ✨ 创建 EVOLUTION.md 指导文档
- ✨ 创建 API_MAPPING_TEMPLATE.md
- ✨ 创建 ISSUES_TEMPLATE.md

### 2026-02-14
- ✨ 初始版本
- 📄 完整的移植工作流
- 📄 关键注意事项汇总
- 📄 API 映射表

## 🤝 贡献指南

欢迎贡献新的问题解决方案、API 映射和工作流改进。

### 贡献方式

1. **提交 Issue**
   - 使用 ISSUES_TEMPLATE.md 格式
   - 描述清晰、附带代码示例

2. **提交 Pull Request**
   - 遵循现有文档格式
   - 代码示例必须验证
   - 更新相关索引

### Commit 规范

```bash
# 格式：[Skill] <type>: <description>

[Skill] feat: add CMakeLists library naming issue
[Skill] fix: correct hilog format specifier syntax
[Skill] docs: improve Native migration examples
[Skill] refactor: reorganize API mapping structure
```

## 📄 License

本 skill 遵循与主项目相同的 License。

## 💬 联系方式

如有问题或建议，请通过以下方式联系：
- GitHub Issues
- 鸿蒙开发者论坛

---

**持续更新中 | Continuously Evolving**
