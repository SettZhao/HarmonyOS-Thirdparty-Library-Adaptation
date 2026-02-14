# 分析库的可移植性与确定迁移策略

本 skill 覆盖移植工作流的 Step 1 和 Step 2：分析 Android 三方库的可移植性，并根据分析结果确定迁移策略。

---

## Step 1: 分析库的可移植性

运行分析脚本扫描 Android 库源码，生成可移植性报告：

```bash
python scripts/analyze_library.py <android-library-source-path>
python scripts/analyze_library.py <path> --output report.json  # 保存报告
```

报告输出：
- **complexity score** — 迁移复杂度评分 (0-100)，LOW/MEDIUM/HIGH/VERY_HIGH
- **android_apis** — 检测到的 Android API 按类别分组，含 OH 替代方案
- **dependencies** — 从 build.gradle 提取的三方依赖
- **native_code** — JNI/NDK 使用情况
- **recommendations** — 按难度排序的迁移建议

### 分析脚本检测的 API 类别

| 类别 | 难度 | 检测模式 | OH 替代方案 |
|------|------|----------|------------|
| `ui_view` | HIGH | `android.widget.*`, `android.view.*`, `androidx.*` | ArkUI 声明式组件 |
| `ui_compose` | HIGH | `androidx.compose.*`, `@Composable` | ArkUI (@Component + build()) |
| `network` | MEDIUM | `java.net.*`, `okhttp3.*`, `retrofit2.*` | @ohos.net.http / @ohos.net.socket |
| `storage` | MEDIUM | `SharedPreferences`, `SQLite`, `Room` | @ohos.data.preferences / relationalStore |
| `multimedia` | MEDIUM | `android.media.*`, `android.graphics.*` | @ohos.multimedia.* |
| `lifecycle` | HIGH | `Activity`, `Fragment`, `Service` | UIAbility / ExtensionAbility |
| `threading` | MEDIUM | `Handler`, `Coroutines`, `RxJava` | TaskPool / Worker |
| `ipc_intent` | HIGH | `Intent`, `Context`, `Bundle` | Want 机制 |
| `jni_ndk` | HIGH | `System.loadLibrary`, `JNIEnv*` | NAPI |
| `pure_java` | LOW | `java.util.*`, `java.io.*` | 直接复用或 ArkTS 等价物 |
| `json_serialization` | LOW | `Gson`, `Jackson`, `Moshi` | JSON.parse/stringify |
| `logging` | LOW | `android.util.Log` | @ohos.hilog |

### 手动检测补充

除脚本自动检测外，还需手动检查：

```bash
# 检查外部头文件依赖（Native 库）
grep -r "#include <" <library>/src/ | grep -v "std\|stdio\|stdlib\|string"

# 检查 Android 特有注解
grep -r "@RequiresApi\|@TargetApi" <library>/src/

# 检查 Proguard 规则
cat <library>/proguard-rules.pro
```

---

## Step 2: 确定库类型和移植策略

根据分析结果确定移植路径：

### 纯逻辑库 (complexity LOW)

- **典型库**：Gson、Apache Commons、算法库
- **特征**：不依赖 Android API，主要使用 `java.util.*` / `java.io.*`
- **策略**：将 Java/Kotlin 代码翻译为 ArkTS，保持相同的接口设计
- **参考**：[code-migration](../code-migration/README.md)

### 网络/存储库 (complexity MEDIUM)

- **典型库**：OkHttp、Retrofit、Room
- **特征**：使用 Android 平台 API（网络、存储、权限等）
- **策略**：核心接口保持不变，将 Android 平台 API 调用替换为 OH API
- **参考**：[code-migration](../code-migration/README.md) + [references/api-mapping.md](../../references/api-mapping.md)

### UI 组件库 (complexity HIGH)

- **典型库**：RecyclerView adapter 库、Material 组件
- **特征**：大量使用 Android View 系统或 Jetpack Compose
- **策略**：使用 ArkUI 声明式 UI 完全重写 UI 层，保留业务逻辑
- **参考**：[ui-migration](../ui-migration/README.md)

### Native 库 (complexity HIGH)

- **典型库**：包含 JNI/NDK 代码的库
- **特征**：C/C++ 源码 + JNI 绑定层
- **策略**：C/C++ 业务逻辑代码直接复用，将 JNI 绑定层替换为 NAPI
- **参考**：[native-migration](../native-migration/README.md)

### 选择包格式

根据库类型选择 HAR 或 HSP：

| 场景 | 推荐格式 | 说明 |
|------|---------|------|
| 纯逻辑工具库 | HAR | 如 Gson、算法库 |
| 网络请求封装 | HAR | 如 OkHttp、Retrofit |
| UI 组件库 | HSP | 大量资源的组件库 |
| 含大量资源/图片 | HSP | 减小应用总包体积 |
| 发布到 ohpm | HAR | 推荐默认选择 |
