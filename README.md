# HarmonyOS-Thirdparty-Library-Adaptation

HarmonyOS Thirdparty Library Adaptation by Agent - 自动化 Android 三方库移植到 OpenHarmony 的完整工作流。

## 项目说明

本项目提供了一套标准化的 Android 三方库移植到 OpenHarmony 的方法和工具，包括：

- 📊 **可移植性分析工具** - 自动扫描 Android 库源码，评估迁移难度
- 📚 **完整迁移指南** - 涵盖纯逻辑库、UI 库、Native 库的迁移策略
- 🔧 **标准项目模板** - OpenHarmony HAR 库开发模板
- ✅ **最佳实践规范** - 经过验证的关键注意事项和问题解决方案

## 项目结构

```
.
├── .github/skills/android-to-openharmony/  # 核心 Skill 定义和文档
│   ├── SKILL.md                            # 完整移植工作流（⭐ 主文档）
│   ├── scripts/
│   │   └── analyze_library.py              # 可移植性分析工具
│   └── references/                         # 详细参考文档
│       ├── api-mapping.md                  # Android API → OH API 映射表
│       ├── native-migration.md             # JNI/NDK → NAPI 迁移指南
│       ├── project-structure.md            # OH 项目结构和构建系统
│       ├── ui-migration.md                 # View/Compose → ArkUI 迁移
│       ├── testing.md                      # 测试框架使用指南
│       └── refs/                           # 详细 API 参考
│
├── Template/                               # OpenHarmony 标准项目模板
│   ├── library/                            # HAR 库模块示例
│   └── entry/                              # 示例应用模块
│
└── libmp4_ohos/                           # 示例：libmp4 移植项目
    ├── README.md                           # 用户文档
    ├── MIGRATION_SUMMARY.md                # 技术迁移报告
    ├── FIXES_SUMMARY.md                    # 修复问题汇总 ⭐
    └── library/                            # 移植后的 HAR 库
```

## 快速开始

### 1. 分析 Android 库的可移植性

```bash
# 扫描 Android 库源码
python .github/skills/android-to-openharmony/scripts/analyze_library.py <android-library-path>

# 生成 JSON 报告
python .github/skills/android-to-openharmony/scripts/analyze_library.py <path> --output report.json
```

报告包含：
- 迁移复杂度评分（0-100）
- 检测到的 Android API 及 OH 替代方案
- 依赖分析
- Native 代码检测
- 迁移建议

### 2. 阅读完整移植指南

查看 [SKILL.md](.github/skills/android-to-openharmony/SKILL.md) 了解完整的移植工作流，包括：

1. **分析库的可移植性** - 运行分析脚本
2. **确定库类型和移植策略** - 纯逻辑/网络/UI/Native
3. **创建 OpenHarmony 项目结构** - 使用 Template
4. **迁移核心代码** - API 替换和代码翻译
5. **构建、测试与发布** - hvigor 编译和测试

### 3. 使用 Template 创建项目

将 `Template/` 目录复制为新项目的基础：

```bash
# 创建新项目
cp -r Template my-library-ohos

# 重命名和配置（见 SKILL.md Step 3）
```

## ⚠️ 重要：移植注意事项

在进行库移植时，**必须遵守**以下关键规则（详见 [SKILL.md 关键注意事项](.github/skills/android-to-openharmony/SKILL.md#关键注意事项必须遵守)）：

1. ✅ **必须进行编译验证** - 代码迁移完成后立即运行 `hvigorw assembleHar`
2. ✅ **清理 Template 模板文件** - 删除 `types/liblibrary` 等模板目录
3. ✅ **配置 Native Module 类型声明** - 正确设置 `oh-package.json5` 的 types 路径
4. ✅ **确保模块名一致** - `module.json5` 和 `build-profile.json5` 中的名称必须匹配
5. ✅ **处理 Native 库的外部依赖** - 检测并实现缺失的依赖（如链表库）
6. ✅ **处理日志宏冲突** - 使用 `#undef` 避免与 hilog 冲突
7. ✅ **完整的编译验证清单** - 按清单逐项检查

> 💡 这些规则是从实际移植过程中总结出来的，忽略任何一项都可能导致编译失败。

## 示例项目：libmp4

`libmp4_ohos/` 目录包含一个完整的移植示例：

- **原库**：Android MP4 文件库（Native C + JNI）
- **复杂度**：VERY_HIGH (93/100)
- **迁移内容**：
  - ✅ 2500+ 行 C 代码直接复用
  - ✅ JNI → NAPI 完全重写
  - ✅ Java → ArkTS API 包装
  - ✅ 实现简化链表库替代 futils 依赖
  - ✅ 完整的编译验证和问题修复

**查看详细文档：**
- [README.md](libmp4_ohos/README.md) - API 使用指南
- [MIGRATION_SUMMARY.md](libmp4_ohos/MIGRATION_SUMMARY.md) - 技术迁移报告
- [FIXES_SUMMARY.md](libmp4_ohos/FIXES_SUMMARY.md) - 问题修复汇总 ⭐

**编译验证：**
```bash
cd libmp4_ohos
hvigorw clean
hvigorw assembleHar
# ✅ BUILD SUCCESSFUL
# 输出：library/build/default/outputs/default/libmp4.har (453KB)
```

## 参考文档

### 核心指南
| 文档 | 内容 | 何时查阅 |
|------|------|----------|
| [SKILL.md](.github/skills/android-to-openharmony/SKILL.md) | ⭐ 完整移植工作流 | **必读** |
| [api-mapping.md](.github/skills/android-to-openharmony/references/api-mapping.md) | Android API → OH API 映射 | 替换 API 时 |
| [native-migration.md](.github/skills/android-to-openharmony/references/native-migration.md) | JNI/NDK → NAPI 指南 | 迁移 Native 代码 |
| [ui-migration.md](.github/skills/android-to-openharmony/references/ui-migration.md) | View/Compose → ArkUI | 迁移 UI 组件 |
| [testing.md](.github/skills/android-to-openharmony/references/testing.md) | hypium 测试框架 | 编写测试 |

### 详细 API 参考
- [taskpool.md](.github/skills/android-to-openharmony/references/refs/taskpool.md) - 任务池 API
- [worker.md](.github/skills/android-to-openharmony/references/refs/worker.md) - Worker API
- [containers.md](.github/skills/android-to-openharmony/references/refs/containers.md) - 容器 API
- [buffer.md](.github/skills/android-to-openharmony/references/refs/buffer.md) - Buffer API

## Template

`./Template` 是一个 OpenHarmony 三方库适配的标准项目模板，包含：

- **library/** - HAR 库模块（对应 Android 的 library module）
- **entry/** - 示例应用和测试（对应 Android 的 app module）
- **完整的配置文件** - build-profile.json5, oh-package.json5, module.json5
- **Native 代码支持** - CMakeLists.txt, NAPI 示例
- **测试框架集成** - @ohos/hypium 单元测试

## 工具和脚本

### 可移植性分析工具

```bash
python .github/skills/android-to-openharmony/scripts/analyze_library.py <path>
```

**功能：**
- 扫描 Java/Kotlin/C++ 源码
- 检测 Android API 使用情况
- 分析依赖和 Native 代码
- 评估迁移复杂度（LOW/MEDIUM/HIGH/VERY_HIGH）
- 生成迁移建议

## 支持的库类型

| 类型 | 复杂度 | 迁移策略 | 示例 |
|------|-------|---------|------|
| **纯逻辑库** | LOW | Java/Kotlin → ArkTS | Gson, Apache Commons |
| **网络/存储库** | MEDIUM | 核心逻辑保留，API 替换 | OkHttp, Retrofit, Room |
| **UI 组件库** | HIGH | ArkUI 完全重写 | RecyclerView 库, Material 组件 |
| **Native 库** | HIGH | C/C++ 复用，JNI → NAPI | libmp4, FFmpeg 绑定 |

## 贡献和反馈

如果您在使用过程中发现问题或有改进建议，欢迎：

1. 提交 Issue 描述问题
2. 提交 Pull Request 改进文档或工具
3. 分享您的移植经验和最佳实践

## 许可证

本项目遵循 Apache 2.0 许可证。

示例项目（libmp4）保持其原始许可证（BSD-3-Clause）。

---

**最后更新：** 2026-02-13  
**维护者：** HarmonyOS Agent Team

