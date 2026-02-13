# libmp4 Demo 应用使用说明

## 概述

这是 libmp4 OpenHarmony 库的演示应用，展示了如何使用 libmp4 库来：
- 打开 MP4 文件
- 提取元数据信息
- 正确处理错误
- 释放资源

## Demo 功能

### 主要功能

1. **文件路径输入**：输入或选择要解析的 MP4 文件路径
2. **打开并提取**：打开 MP4 文件并提取所有元数据
3. **元数据显示**：以键值对形式展示提取到的元数据（如标题、艺术家、时长等）
4. **关闭文件**：正确关闭文件并释放资源
5. **错误处理**：展示如何捕获和处理各种错误情况

### UI 组成

- **状态指示器**：显示当前操作状态（Ready/Opening/Success/Failed）
- **错误信息**：显示详细的错误消息（如果有）
- **文件路径输入框**：输入 MP4 文件的完整路径
- **示例路径按钮**：快速填充常用路径示例
- **操作按钮**：
  - "Open & Extract"：打开文件并提取元数据
  - "Close"：关闭文件
- **元数据列表**：显示提取到的所有元数据
- **使用说明**：指导用户如何使用 demo
- **代码示例**：展示 API 的基本用法

## 如何使用

### 准备测试文件

由于 OpenHarmony 应用的文件访问权限限制，您需要将测试 MP4 文件放在应用可访问的目录中：

#### 方法 1：使用 hdc 推送文件

```bash
# 将 MP4 文件推送到应用的 files 目录
hdc file send test.mp4 /data/app/el2/100/base/com.example.libmp4demo/haps/entry/files/test.mp4

# 或推送到公共目录（需要相应权限）
hdc file send test.mp4 /data/storage/el2/base/haps/entry/files/test.mp4
```

#### 方法 2：从公共存储目录读取

如果有 SDCard 权限，可以从以下位置读取：
```
/sdcard/Movies/test.mp4
/sdcard/Download/test.mp4
```

### 运行 Demo

1. **启动应用**
   ```bash
   # 编译并安装应用
   cd libmp4_ohos
   hvigorw assembleApp
   
   # 在 DevEco Studio 中点击 Run 按钮
   ```

2. **输入文件路径**
   - 在文件路径输入框中输入 MP4 文件的完整路径
   - 或点击示例路径按钮快速填充

3. **打开文件**
   - 点击 "Open & Extract" 按钮
   - 等待状态变为 "Success!"
   - 查看下方显示的元数据

4. **查看结果**
   - 元数据会以列表形式展示
   - 每个条目包含键和值
   - 常见的元数据包括：title, artist, album, genre, duration 等

5. **关闭文件**
   - 使用完毕后，点击 "Close" 按钮释放资源
   - 状态变为 "File closed successfully"

### 错误处理示例

Demo 展示了以下错误处理场景：

1. **文件不存在**
   ```
   Error: Cannot open file: /invalid/path.mp4
   ```

2. **空文件路径**
   ```
   Error: Please enter a file path
   ```

3. **文件格式错误**
   ```
   Error: Invalid MP4 file format
   ```

## API 使用示例

Demo 中演示的核心代码逻辑：

```typescript
import { Libmp4 } from 'library';
import { hilog } from '@kit.PerformanceAnalysisKit';

try {
  // 1. 创建 Libmp4 实例并打开文件
  const mp4 = new Libmp4('/data/storage/el2/base/haps/entry/files/test.mp4');
  
  // 2. 检查是否成功打开
  if (mp4.isOpen()) {
    console.log('File opened:', mp4.getFilePath());
    
    // 3. 提取元数据
    const metadata = mp4.getMetadata();
    
    // 4. 遍历元数据
    Object.keys(metadata).forEach(key => {
      console.log(`${key}: ${metadata[key]}`);
    });
    
    // 5. 关闭文件
    mp4.close();
  }
} catch (err) {
  console.error('Error:', err.message);
}
```

## 代码结构

```
entry/src/main/ets/pages/Index.ets
├── openAndExtractMetadata()  // 打开文件并提取元数据
├── closeFile()               // 关闭文件
├── loadSamplePath()          // 加载示例路径
└── build()                   // UI 构建
```

## 状态管理

Demo 使用以下状态变量：

| 状态变量 | 类型 | 说明 |
|---------|------|------|
| `status` | string | 当前操作状态 |
| `filePath` | string | MP4 文件路径 |
| `metadata` | Record<string, string> | 提取的元数据 |
| `isOpen` | boolean | 文件是否打开 |
| `errorMessage` | string | 错误消息 |
| `mp4Instance` | Libmp4 \| null | libmp4 实例 |

## 日志输出

Demo 会输出详细的日志信息，可通过 hilog 查看：

```bash
# 查看 demo 的运行日志
hdc shell hilog | grep Libmp4Demo

# 示例输出：
# Libmp4Demo: Attempting to open: /data/storage/el2/base/haps/entry/files/test.mp4
# Libmp4Demo: MP4 file opened successfully
# Libmp4Demo: Extracted 8 metadata entries
# Libmp4Demo: MP4 file closed successfully
```

## 测试场景

建议测试以下场景：

- [x] 打开有效的 MP4 文件
- [x] 提取元数据并显示
- [x] 关闭文件
- [x] 尝试打开不存在的文件（错误处理）
- [x] 空文件路径输入（输入验证）
- [x] 重复打开文件（状态管理）
- [x] 在已打开状态下尝试再次打开（按钮禁用）

## 性能说明

- 打开小文件（< 10MB）通常在 100ms 内完成
- 元数据提取通常在 50ms 内完成
- 不会加载整个文件到内存，仅读取文件头部的元数据

## 故障排查

### 问题：点击 "Open & Extract" 后显示 "Cannot open file"

**解决方案：**
1. 检查文件路径是否正确
2. 确认文件确实存在：`hdc shell ls -l <file-path>`
3. 检查应用是否有文件访问权限
4. 确认文件是有效的 MP4 格式

### 问题：元数据为空

**可能原因：**
- MP4 文件不包含元数据
- 文件损坏或格式不标准

**解决方案：**
- 使用包含元数据的 MP4 文件测试
- 检查原始文件是否能被其他播放器正常播放

### 问题：应用崩溃

**解决方案：**
1. 查看崩溃日志：`hdc shell hilog`
2. 确认 libmp4.so 已正确加载
3. 检查文件路径格式是否正确

## 扩展建议

可以基于此 demo 扩展的功能：

1. **文件选择器**：集成文件选择组件，让用户从图形界面选择文件
2. **批量处理**：支持选择多个 MP4 文件批量提取元数据
3. **元数据编辑**：添加修改元数据的功能
4. **缩略图提取**：提取视频的缩略图并显示
5. **轨道信息**：显示视频和音频轨道的详细信息

## 相关文档

- [libmp4 API 文档](../README.md)
- [迁移总结](../MIGRATION_SUMMARY.md)
- [快速开始](../QUICKSTART.md)

## 许可证

本 demo 遵循 BSD-3-Clause 许可证，与 libmp4 库相同。
