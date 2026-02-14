# API 映射更新模板

本文件用于暂存待添加到 `references/api-mapping.md` 的 API 映射关系。

## 使用方法

1. 在移植过程中遇到新的 API 映射时，记录在下方对应分类
2. 移植完成后，批量更新到 `references/api-mapping.md`
3. 清空本文件内容，供下次使用

---

## 待添加映射

### Core Language（核心语言）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|
| <!-- 示例：java.util.concurrent.ExecutorService --> | <!-- @kit.ArkTS.taskpool --> | <!-- 线程池 --> | <!-- project-name --> |

### UI Components（UI 组件）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

### Network（网络）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

### Storage（存储）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

### Media（媒体）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

### System（系统）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

### Sensors（传感器）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

### Other（其他）

| Android API | OpenHarmony API | 说明 | 来源项目 |
|------------|----------------|------|---------|

---

## 待创建详细文档

记录需要创建 `references/refs/*.md` 详细文档的 OpenHarmony 模块：

### 模块名：`@kit.XXXKit` 或 `@ohos.xxx`

**原因：** （为什么需要详细文档，如：API 复杂、使用频繁等）

**包含内容：**
- API 列表
- 使用示例
- 常见问题

**优先级：** 高/中/低

---

## 更新说明

更新 `api-mapping.md` 时的注意事项：

1. **保持一致性**
   - 格式与现有条目一致
   - 分类准确

2. **验证准确性**
   - 确保 API 映射正确
   - 代码示例可运行

3. **添加说明**
   - 简要说明用途
   - 如有差异，注明

4. **引用详细文档**
   - 如果有对应的 refs/*.md，添加链接
   - 格式：`详见 [refs/modulename.md](references/refs/modulename.md)`
