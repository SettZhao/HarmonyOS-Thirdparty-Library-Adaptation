# Android API → OpenHarmony API Mapping Reference

本文档提供 Android 常用 API 到 OpenHarmony (API 12+) 的映射关系。按功能领域组织，便于快速查找替代方案。

**详细 API 参考文档**: 对于特定领域的完整 API 说明，参见 [refs/](refs/) 目录下的详细文档。

## Table of Contents

- [UI Framework](#ui-framework)
- [Lifecycle & Components](#lifecycle--components)
- [Network](#network)
- [Storage & Database](#storage--database)
- [Multimedia](#multimedia)
- [Threading & Concurrency](#threading--concurrency)
- [Permission](#permission)
- [Notification](#notification)
- [IPC & Intent](#ipc--intent)
- [Logging](#logging)
- [JSON & Serialization](#json--serialization)
- [Common Third-Party Libraries](#common-third-party-libraries)

---

## UI Framework

| Android | OpenHarmony (ArkUI) | Notes |
|---------|-------------------|-------|
| `View` / `ViewGroup` | `@Component` struct + `build()` | 声明式 UI，无继承 |
| `TextView` | `Text()` | `Text('hello').fontSize(16)` |
| `Button` | `Button()` | `Button('Click').onClick(()=>{})` |
| `ImageView` | `Image()` | `Image($r('app.media.icon'))` |
| `EditText` | `TextInput()` / `TextArea()` | 双向绑定用 `$$` |
| `RecyclerView` | `List` + `ForEach` | `List() { ForEach(data, item => { ListItem() {...} }) }` |
| `ScrollView` | `Scroll` | `Scroll() { Column() {...} }` |
| `LinearLayout` | `Column` / `Row` | 垂直=Column, 水平=Row |
| `RelativeLayout` | `RelativeContainer` | 使用 alignRules |
| `FrameLayout` | `Stack` | 层叠布局 |
| `ConstraintLayout` | `RelativeContainer` | 通过 id 和 alignRules 约束 |
| `ViewPager` | `Swiper` | `Swiper() { ForEach(...) }` |
| `TabLayout` | `Tabs` + `TabContent` | |
| `Toast` | `promptAction.showToast()` | `import promptAction from '@ohos.promptAction'` |
| `AlertDialog` | `AlertDialog.show()` | 使用 CustomDialogController 自定义 |
| `Fragment` | NavDestination / 自定义组件 | OH 无 Fragment 概念 |
| `RecyclerView.Adapter` | `@Builder` + `ForEach` | LazyForEach 用于大数据量 |
| `ProgressBar` | `Progress` | `Progress({ value: 50, type: ProgressType.Linear })` |
| `Switch` | `Toggle` | `Toggle({ type: ToggleType.Switch })` |
| `CheckBox` | `Checkbox` | `Checkbox({ name: 'check' })` |
| `WebView` | `Web` | `Web({ src: url, controller })` |

### Jetpack Compose → ArkUI

| Compose | ArkUI | Notes |
|---------|-------|-------|
| `@Composable` | `@Component` + `build()` | |
| `remember { mutableStateOf() }` | `@State` decorator | |
| `LazyColumn` | `List` + `LazyForEach` | |
| `Modifier` | 链式属性调用 | `.width().height().margin()` |
| `Column` | `Column` | |
| `Row` | `Row` | |
| `Box` | `Stack` | |
| `NavHost` | `Navigation` | |
| `ViewModel` | 无直接对应，用 `@State`/`@Prop`/`@Link`/AppStorage | |

---

## Lifecycle & Components

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `Activity` | `UIAbility` | 使用 WindowStage 管理窗口 |
| `Service` | `ServiceExtensionAbility` | 系统应用专用；三方应用用后台任务 |
| `BroadcastReceiver` | `commonEventManager` | `import commonEventManager from '@ohos.commonEventManager'` |
| `ContentProvider` | `DataShareExtensionAbility` | 跨应用数据共享 |
| `Application` | `AbilityStage` | 应用级生命周期 |
| `onCreate()` | `onCreate()` / `onWindowStageCreate()` | UIAbility 生命周期 |
| `onResume()` | `onForeground()` | |
| `onPause()` | `onBackground()` | |
| `onDestroy()` | `onDestroy()` | |
| `startActivity(intent)` | `context.startAbility(want)` | 使用 Want 替代 Intent |

### Lifecycle 对比

```
Android Activity:       onCreate → onStart → onResume → onPause → onStop → onDestroy
OpenHarmony UIAbility:  onCreate → onWindowStageCreate → onForeground → onBackground → onWindowStageDestroy → onDestroy
```

---

## Network

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `HttpURLConnection` | `http.createHttp()` | `import http from '@ohos.net.http'` |
| `OkHttp` | `http.createHttp()` 或 `@ohos/axios` | ohpm 上有 axios 包 |
| `Retrofit` | 手动封装 或 `@ohos/axios` | 需重写接口层 |
| `Volley` | `http.createHttp()` | |
| `WebSocket` | `webSocket.createWebSocket()` | `import webSocket from '@ohos.net.webSocket'` |
| `Socket` | `socket.constructTCPSocketInstance()` | `import socket from '@ohos.net.socket'` |
| `ConnectivityManager` | `connection` | `import connection from '@ohos.net.connection'` |

### HTTP Request Example

```typescript
// Android (OkHttp)
val client = OkHttpClient()
val request = Request.Builder().url("https://api.example.com/data").build()
val response = client.newCall(request).execute()

// OpenHarmony
import http from '@ohos.net.http'
let httpRequest = http.createHttp()
let response = await httpRequest.request("https://api.example.com/data", {
  method: http.RequestMethod.GET,
  header: { 'Content-Type': 'application/json' }
})
```

---

## Storage & Database

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `SharedPreferences` | `preferences` | `import dataPreferences from '@ohos.data.preferences'` |
| `SQLiteDatabase` | `relationalStore` | `import relationalStore from '@ohos.data.relationalStore'` |
| `Room` | `relationalStore` | 需手动写 SQL，无 ORM |
| `DataStore` | `preferences` | |
| `File I/O` | `fileIo` | `import fs from '@ohos.file.fs'` |
| `Environment.getExternalStorageDirectory()` | `context.filesDir` / `context.cacheDir` | 沙箱路径 |
| `ContentResolver` | `dataSharePredicates` + `fileAccess` | |

### SharedPreferences → Preferences Example

```typescript
// Android
val prefs = getSharedPreferences("config", MODE_PRIVATE)
prefs.edit().putString("key", "value").apply()
val value = prefs.getString("key", "")

// OpenHarmony
import dataPreferences from '@ohos.data.preferences'
let pref = await dataPreferences.getPreferences(context, 'config')
await pref.put('key', 'value')
await pref.flush()
let value = await pref.get('key', '')
```

---

## Multimedia

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `MediaPlayer` | `media.createAVPlayer()` | `import media from '@ohos.multimedia.media'` |
| `MediaRecorder` | `media.createAVRecorder()` | |
| `Bitmap` | `image.createPixelMap()` | `import image from '@ohos.multimedia.image'` |
| `Canvas` / `Paint` | `Canvas` + `CanvasRenderingContext2D` | ArkUI Canvas 组件 |
| `Camera2` | `camera` | `import camera from '@ohos.multimedia.camera'` |
| `ExoPlayer` | `media.createAVPlayer()` | |
| `Glide` / `Picasso` | `Image($rawfile())` 或 `@ohos/imageknife` | 内置图片加载 |
| `AudioManager` | `audio` | `import audio from '@ohos.multimedia.audio'` |

---

## Threading & Concurrency

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `Thread` | `Worker` / `TaskPool` | |
| `Handler` / `Looper` | `emitter` | `import emitter from '@ohos.events.emitter'` |
| `AsyncTask` | `taskpool.execute()` | `import taskpool from '@ohos.taskpool'` |
| `Executor` | `TaskPool` | |
| `Coroutines` | `async/await` + `TaskPool` | ArkTS 原生支持 async/await |
| `RxJava` | `async/await` + `emitter` | 需要重写响应式链 |
| `LiveData` | `@Watch` + `AppStorage` | 响应式数据绑定 |

### Coroutines → TaskPool Example

```typescript
// Android (Coroutines)
lifecycleScope.launch {
    val result = withContext(Dispatchers.IO) { heavyWork() }
    updateUI(result)
}

// OpenHarmony (TaskPool)
import taskpool from '@ohos.taskpool'

@Concurrent
function heavyWork(): string { /* ... */ return 'result' }

let task = new taskpool.Task(heavyWork)
let result = await taskpool.execute(task) as string
// UI update happens on main thread after await
```

**详细文档**: 
- **TaskPool 完整 API**: [refs/taskpool.md](refs/taskpool.md) - Task/TaskGroup/SequenceRunner/AsyncRunner/LongTask
- **Worker 完整 API**: [refs/worker.md](refs/worker.md) - ThreadWorker
- **共享容器 API**: [refs/collections.md](refs/collections.md) - collections.Array/Map/Set，跨线程数据传递
- **工具类 API**: [refs/utils.md](refs/utils.md) - AsyncLock/ConditionVariable/SendableLruCache
- **线性/非线性容器**: [refs/containers.md](refs/containers.md) - ArrayList/HashMap/Queue/Stack 等

---

## Permission

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `Manifest.permission.*` | `ohos.permission.*` | |
| `requestPermissions()` | `abilityAccessCtrl.requestPermissionsFromUser()` | |
| `checkSelfPermission()` | `abilityAccessCtrl.checkAccessToken()` | |
| `INTERNET` | 免申请 | OH 中网络权限在 module.json5 声明即可 |
| `CAMERA` | `ohos.permission.CAMERA` | |
| `READ_EXTERNAL_STORAGE` | `ohos.permission.READ_MEDIA` | |
| `RECORD_AUDIO` | `ohos.permission.MICROPHONE` | |
| `ACCESS_FINE_LOCATION` | `ohos.permission.APPROXIMATELY_LOCATION` | |

---

## Notification

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `NotificationManager` | `notificationManager` | `import notificationManager from '@ohos.notificationManager'` |
| `NotificationCompat.Builder` | `notificationManager.publish()` | 构造 NotificationRequest 对象 |
| `NotificationChannel` | `notificationManager.addSlot()` | 使用 SlotType |

---

## IPC & Intent

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `Intent` | `Want` | `import Want from '@ohos.app.ability.Want'` |
| `startActivity(intent)` | `context.startAbility(want)` | |
| `startService(intent)` | `context.startServiceExtensionAbility(want)` | 仅系统应用 |
| `sendBroadcast(intent)` | `commonEventManager.publish()` | |
| `Bundle` | Want 的 parameters 字段 | `want.parameters = { key: value }` |
| `AIDL` | `IPC` + `RPC` | `import rpc from '@ohos.rpc'` |

---

## Logging

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `Log.d(TAG, msg)` | `hilog.debug(domain, tag, msg)` | `import hilog from '@ohos.hilog'` |
| `Log.i()` | `hilog.info()` | |
| `Log.w()` | `hilog.warn()` | |
| `Log.e()` | `hilog.error()` | |

```typescript
// Android
Log.d("MyTag", "debug message: %s", value)

// OpenHarmony
import hilog from '@ohos.hilog'
hilog.debug(0x0000, 'MyTag', 'debug message: %{public}s', value)
```

---

## JSON & Serialization

| Android | OpenHarmony | Notes |
|---------|-------------|-------|
| `Gson` | `JSON.parse()` / `JSON.stringify()` | ArkTS 内置 |
| `Jackson` | `JSON.parse()` / `JSON.stringify()` | |
| `Moshi` | `JSON.parse()` / `JSON.stringify()` | |
| `org.json.JSONObject` | `JSON.parse()` | 返回 object |
| `Kotlinx.serialization` | 手动映射 或 class + JSON | |
| `Protobuf` | 需引入 protobuf JS 库 | ohpm 可能有可用包 |

**详细文档**:
- **Buffer API**: [refs/buffer.md](refs/buffer.md) - 二进制数据处理，替代 ByteBuffer
- **XML API**: [refs/xml.md](refs/xml.md) - XML 解析生成，替代 XmlPullParser

---

## Common Third-Party Libraries

| Android Library | OpenHarmony Alternative | ohpm Package |
|----------------|------------------------|-------------|
| OkHttp | `@ohos.net.http` / `@ohos/axios` | `@ohos/axios` |
| Retrofit | 手动封装 HTTP 接口 | - |
| Gson | 内置 `JSON` | - |
| Glide / Picasso | `Image` 组件 / `@ohos/imageknife` | `@ohos/imageknife` |
| Room | `@ohos.data.relationalStore` | - |
| EventBus | `@ohos.events.emitter` | - |
| RxJava | `async/await` + `TaskPool` | - |
| Dagger/Hilt | 手动依赖注入 | - |
| ButterKnife | ArkUI 不需要 | - |
| LeakCanary | `hidebug` / DevEco Profiler | - |
| Timber | `@ohos.hilog` | - |
| Lottie | `@ohos/lottie` | `@ohos/lottie` |
| ZXing | `@ohos.multimedia.scan` (API 12+) | - |
| MPAndroidChart | `@ohos/mpchart` | `@ohos/mpchart` |
