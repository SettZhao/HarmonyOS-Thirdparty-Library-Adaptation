# 创建 OpenHarmony 项目结构

本 skill 覆盖移植工作流的 Step 3：使用 Template 标准模板创建 OpenHarmony 项目结构。

---

## 使用 Template 标准结构

推荐使用 OpenHarmony 标准项目模板（Template）组织移植代码。

### Template 标准目录映射

| Android 模块 | Template 模块 | 说明 |
|-------------|--------------|------|
| `mylibrary/` (Library Module) | `library/` | 库代码主目录 |
| `app/` (Sample App) | `entry/` | 示例应用/入口（**必须包含 demo**） |
| `mylibrary/src/main/cpp/` | `library/src/main/cpp/` | Native C++ 代码 |
| `mylibrary/src/androidTest/` | `entry/src/ohosTest/` | 测试代码 |

### 文件映射示例

```
Android 库结构                      → Template 结构
─────────────────────────────────────────────────────────
mylibrary/
├── src/main/java/
│   └── com/example/mylib/
│       ├── MyClass.java           → library/src/main/ets/MyClass.ets
│       └── utils/Helper.java      → library/src/main/ets/utils/Helper.ets
├── src/main/cpp/
│   ├── CMakeLists.txt             → library/src/main/cpp/CMakeLists.txt
│   └── native-lib.cpp             → library/src/main/cpp/napi_init.cpp
├── src/androidTest/
│   └── MyClassTest.java           → entry/src/ohosTest/ets/test/MyClass.test.ets
└── build.gradle                   → library/build-profile.json5

app/
└── src/main/java/
    └── MainActivity.java         → entry/src/main/ets/pages/Index.ets
```

---

## ⚠️ 项目名保持不变（必须遵守）

**规则：** 从 Template 复制项目后，**不要修改**以下标识：

1. **`AppScope/app.json5`** 的 `bundleName` 保持为 `"com.example.template"`
2. **`build-profile.json5`** 的签名配置保持不变

**原因：** 保持 bundleName 不变可以避免每次都需要重新生成签名证书，方便在手机上安装和测试。

```json5
// AppScope/app.json5 - 不要修改 bundleName
{
  "app": {
    "bundleName": "com.example.template",  // ⚠️ 保持不变！
    "vendor": "example",
    "versionCode": 1000000,
    "versionName": "1.0.0",
    "icon": "$media:layered_image",
    "label": "$string:app_name"
  }
}
```

---

## 关键配置文件

### oh-package.json5（包描述，类似 package.json）

```json5
// library/oh-package.json5
{
  "name": "library",
  "version": "1.0.0",
  "description": "移植自 Android 的 XXX 库",
  "main": "Index.ets",
  "author": "",
  "license": "Apache-2.0",
  "dependencies": {},
  "devDependencies": {}
}
```

### module.json5（模块配置，替代 AndroidManifest.xml）

```json5
// library/src/main/module.json5
{
  "module": {
    "name": "library",
    "type": "har",
    "deviceTypes": ["default", "tablet", "2in1"],
    "deliveryWithInstall": true
  }
}
```

### build-profile.json5（构建配置，替代 build.gradle）

```json5
// library/build-profile.json5
{
  "apiType": "stageMode",
  "buildOption": {},
  "targets": [
    {
      "name": "default"
    }
  ]
}
```

### library/Index.ets（库的公共 API 导出入口）

```typescript
// library/Index.ets - 对外导出的公共 API
export { MyClass } from './src/main/ets/MyClass';
export { Helper } from './src/main/ets/utils/Helper';
export type { Config } from './src/main/ets/models/Config';
```

---

## 清理 Template 模板文件（必须）

从 Template 复制后，**必须**删除以下模板文件：

```powershell
# 删除模板的 native module 类型声明
Remove-Item -Recurse -Force library/src/main/cpp/types/liblibrary

# 删除模板的示例组件（如果不需要）
Remove-Item -Recurse -Force library/src/main/ets/components
```

**检查清单：**
- [ ] `library/src/main/cpp/types/` 下只有当前库的类型声明目录
- [ ] `library/src/main/ets/` 下只有当前库的源代码
- [ ] 删除所有包含 "library" 或 "template" 字样的模板文件
- [ ] `AppScope/app.json5` 的 `bundleName` 为 `"com.example.template"`（保持不变）

---

## 确保模块名一致

**问题：** `build-profile.json5` 和 `module.json5` 中的模块名不一致，导致编译错误。

**解决方案：** 确保以下文件中的模块名**完全一致**：

| 文件 | 字段 | 示例值 |
|------|------|--------|
| `library/src/main/module.json5` | `module.name` | `"library"` |
| 根目录 `build-profile.json5` | `modules[].name` | `"library"` |
| `library/oh-package.json5` | `name` | `"library"`（建议一致） |

---

## Demo 依赖配置

### entry/oh-package.json5

```json5
{
  "name": "entry",
  "version": "1.0.0",
  "dependencies": {
    "library": "file:../library"  // ⚠️ 依赖名必须与模块名一致
  },
  "devDependencies": {
    "@ohos/hypium": "^1.0.4"
  }
}
```

### build-profile.json5 模块顺序

```json5
{
  "modules": [
    {
      "name": "library",   // ⚠️ library 必须在 entry 之前
      "srcPath": "./library"
    },
    {
      "name": "entry",
      "srcPath": "./entry"
    }
  ]
}
```

**原因：** hvigor 按照 modules 数组顺序编译，entry 依赖 library，必须先编译 library。

---

## 详细参考

- [references/template-structure.md](../../references/template-structure.md) — Template 完整结构详解
- [references/project-structure.md](../../references/project-structure.md) — OH 项目结构与构建系统
