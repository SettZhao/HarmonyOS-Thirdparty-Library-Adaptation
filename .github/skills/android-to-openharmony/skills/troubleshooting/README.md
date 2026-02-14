# 常见问题与解决方案

本 skill 汇总移植过程中遇到的关键注意事项和常见错误解决方案。

---

## 1. Native 模块类型声明文件

**问题：** 使用 `export default` 或错误的文件名导致 ArkTS 找不到函数。

**错误现象：**
- 编译警告：`Declared function 'xxx' has no native implementation`
- 运行时错误：`Cannot find function`

**解决方案：**

| 项目 | 正确 ✅ | 错误 ❌ |
|------|---------|---------|
| 文件名 | `index.d.ts` | `libXXX.d.ts` |
| `oh-package.json5` types | `"./index.d.ts"` | `"./libXXX.d.ts"` |
| 导出方式 | `export const funcA: ...` | `export default module` |
| ArkTS 导入 | `import { funcA } from 'lib.so'` | `import module from 'lib.so'` |

---

## 2. CMakeLists.txt 库名双 lib 前缀

**问题：** `add_library(libmp4 ...)` 生成 `liblibmp4.so`，导致导入不匹配。

**解决方案：** CMakeLists.txt 中库名**不加** `lib` 前缀：

```cmake
add_library(mp4 SHARED ...)     # ✅ 生成 libmp4.so
add_library(libmp4 SHARED ...)  # ❌ 生成 liblibmp4.so
```

---

## 3. 模块名不一致

**错误信息：**
```
Error: The module name library in build-profile.json5 must be same as moduleName in module.json5
```

**解决方案：** 确保以下三处名称完全一致：
- `library/src/main/module.json5` → `module.name`
- 根目录 `build-profile.json5` → `modules[].name`
- `library/oh-package.json5` → `name`（建议一致）

---

## 4. hilog 日志参数显示 `<private>`

**问题：** 日志输出 `Found <private> metadata entries` 而非实际值。

**解决方案：** 格式化符前加 `{public}`：

| 类型 | 错误 ❌ | 正确 ✅ |
|------|---------|---------|
| 整数 | `%d` | `%{public}d` |
| 无符号整数 | `%u` | `%{public}u` |
| 字符串 | `%s` | `%{public}s` |
| 浮点数 | `%f` | `%{public}f` |
| 指针 | `%p` | `%{public}p` |
| 十六进制 | `%x` | `%{public}x` |

---

## 5. 日志宏冲突

**问题：** `hilog/log.h` 已定义 `LOG_DOMAIN` 和 `LOG_TAG`，重复定义导致警告。

**解决方案：** 先 `#undef` 再重新定义：

```c
#include <hilog/log.h>
#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x0001
#define LOG_TAG "mylib"
```

---

## 6. Template 模板文件未清理

**问题：** 遗留 `types/liblibrary/`、`components/` 等模板文件导致编译冲突。

**解决方案：** 创建项目后立即清理：

```powershell
Remove-Item -Recurse -Force library/src/main/cpp/types/liblibrary
Remove-Item -Recurse -Force library/src/main/ets/components
```

---

## 7. Demo 依赖配置错误

**问题：** entry 模块编译时找不到 library 模块。

**检查清单：**

1. `entry/oh-package.json5` 必须包含：
   ```json5
   "dependencies": { "library": "file:../library" }
   ```

2. `build-profile.json5` 中 library 必须在 entry 之前

3. 导入语句使用模块名：
   ```typescript
   import { MyClass } from 'library';
   ```

---

## 8. 网络 Socket 类型错误

**问题：** UDP/TCP 事件回调参数类型使用 `UDPMessageInfo` 导致运行时错误。

**解决方案：** 统一使用 `socket.SocketMessageInfo`：

```typescript
udpSocket.on('message', (data: socket.SocketMessageInfo) => {
  let view = new Uint8Array(data.message);
  let address = data.remoteInfo.address;
});
```

---

## 9. Native 外部依赖缺失

**错误信息：**
```
error: field has incomplete type 'struct list_node'
error: use of undeclared identifier 'list_init'
```

**解决方案：**
1. 简单数据结构 → 手动实现简化版
2. 复杂第三方库 → 一并迁移或替代
3. 未使用的代码 → `#if 0 ... #endif`

---

## 10. 测试用例命名规范

**问题：** 测试名称包含空格或特殊字符导致测试框架报错。

**规范：**
- `describe()` 名称：字母/数字/下划线/点，必须字母开头
- `it()` 名称：不能有空格，推荐驼峰命名
- `it()` 必须 3 个参数：`it('name', 0, () => { ... })`

```typescript
// ❌ 错误
describe('My Library Tests', () => { ... });
it('should work', () => { ... });

// ✅ 正确
describe('MyLibraryTests', () => { ... });
it('shouldWork', 0, () => { ... });
```

---

## 11. 安装签名验证失败

**问题：** `hdc install` 报 `signature verification failed`。

**解决方案：**
1. 确保 `AppScope/app.json5` 的 `bundleName` 为 `"com.example.template"`
2. 使用 Template 内置的签名配置
3. 如果旧版本已安装，先卸载：`hdc uninstall com.example.template`

---

## 编译验证完整清单

### 项目结构检查

- [ ] 删除了 Template 模板残留文件
- [ ] `types/` 目录下只有当前库的类型声明
- [ ] `AppScope/app.json5` bundleName 为 `"com.example.template"`

### 配置文件检查

- [ ] `module.json5` / `build-profile.json5` / `oh-package.json5` 模块名一致
- [ ] `entry/oh-package.json5` 依赖指向 `"library": "file:../library"`
- [ ] `build-profile.json5` 中 library 在 entry 之前
- [ ] `CMakeLists.txt` 包含所有源文件

### Native 代码检查（如适用）

- [ ] 无 JNI 残留（`JNIEnv*`, `JNIEXPORT` 等）
- [ ] 日志宏使用 `%{public}` 修饰符
- [ ] `add_library()` 名称不含 `lib` 前缀
- [ ] `index.d.ts` 使用 `export const` 具名导出

### 编译验证

- [ ] `hvigorw assembleHar` 成功
- [ ] `hvigorw assembleHap` 成功
- [ ] `hdc install` 成功
- [ ] 测试用例全部通过
