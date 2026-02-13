# libmp4 for OpenHarmony

MP4 file library for OpenHarmony - demux and metadata extraction. This is a port of the Android libmp4 library to OpenHarmony.

## Overview

**libmp4** is a native library that provides MP4 file demuxing and metadata extraction capabilities for OpenHarmony applications. It wraps a C-based MP4 parser with a convenient ArkTS API.

### Features

- Open and parse MP4 files
- Extract metadata (title, artist, album, etc.)
- Native C implementation for high performance
- Simple, easy-to-use ArkTS API

### Original Source

This library is ported from the Android version:
- Original author: Aurelien Barre <aurelien.barre@akaaba.net>
- License: BSD-3-Clause
- Source: [libmp4](../libmp4/)

## Architecture

The library consists of three layers:

1. **Native C Layer** (`library/src/main/cpp/libmp4/`)
   - Pure C implementation of MP4 parsing
   - Reused directly from Android version
   - `mp4_demux.c`, `mp4_box.c`, `mp4_track.c`, etc.

2. **NAPI Binding Layer** (`library/src/main/cpp/napi_init.cpp`)
   - Converts between C functions and JavaScript/ArkTS
   - Replaces JNI layer from Android version
   - Exports: `mp4DemuxOpen`, `mp4DemuxClose`, `mp4DemuxGetMetadata`

3. **ArkTS API Layer** (`library/src/main/ets/Libmp4.ets`)
   - High-level object-oriented API
   - Replaces `Libmp4.java` from Android version
   - Provides resource management and error handling

## Usage

### Installation

Add the library to your project's `oh-package.json5`:

```json
{
  "dependencies": {
    "libmp4": "file:../libmp4_ohos/library"
  }
}
```

### API Example

```typescript
import { Libmp4 } from 'libmp4';

// Open an MP4 file
let mp4 = new Libmp4('/path/to/video.mp4');

// Get metadata
let metadata = mp4.getMetadata();
console.log('Title:', metadata['title']);
console.log('Artist:', metadata['artist']);
console.log('Album:', metadata['album']);

// Close the file
mp4.close();
```

### API Reference

#### `Libmp4` Class

**Constructor**
```typescript
constructor(fileName: string)
```
Opens an MP4 file for demuxing. Throws an error if the file cannot be opened.

**Methods**

- `getMetadata(): Record<string, string>` - Returns metadata key-value pairs from the MP4 file
- `close(): void` - Closes the demuxer and releases resources
- `isOpen(): boolean` - Returns whether the demuxer is currently open
- `getFilePath(): string` - Returns the path of the opened file

## Building

### Prerequisites

- DevEco Studio 5.0 or later
- OpenHarmony SDK API 12 or later

### Build Commands

```bash
# Clean build artifacts
hvigorw clean

# Build the HAR library
hvigorw assembleHar

# Build with the entry app
hvigorw assembleApp

# Run tests
hvigorw --mode module test
```

Build output: `library/build/default/outputs/default/libmp4.har`

## Migration Notes

### Changes from Android Version

| Android | OpenHarmony | Notes |
|---------|------------|-------|
| JNI (`JNIEnv*`, `JNIEXPORT`) | NAPI (`napi_env`, `napi_value`) | Native binding layer |
| `System.loadLibrary()` | `import from 'libmp4.so'` | Module loading |
| `__android_log_print()` | `OH_LOG_*()` | Logging |
| `java.util.HashMap` | `Record<string, string>` | Data structures |
| `Closeable` interface | Manual `close()` method | Resource management |

### Complexity Analysis

**Portability Level:** VERY_HIGH (93/100)
- 14 JNI/NDK API calls → Replaced with NAPI
- 4 Pure Java APIs → Converted to ArkTS
- Native C code → Reused directly with minimal changes

### Key Migration Steps

1. ✅ Copied C source files from `libmp4/src/` to `library/src/main/cpp/libmp4/`
2. ✅ Updated logging macros to support OpenHarmony hilog
3. ✅ Replaced JNI bindings (`libmp4_jni.c`) with NAPI (`napi_init.cpp`)
4. ✅ Created TypeScript declarations (`libmp4.d.ts`)
5. ✅ Wrote ArkTS wrapper class (`Libmp4.ets`) to replace Java class
6. ✅ Configured CMake build system for native compilation
7. ✅ Updated module configuration files

## Testing

Run the test suite:

```bash
hvigorw --mode module test
```

For full integration testing, place a sample MP4 file in the app's sandbox and update the test paths in `entry/src/ohosTest/ets/test/Libmp4.test.ets`.

## Known Limitations

- Only basic metadata extraction is exposed in the ArkTS API
- Advanced demuxing features (track extraction, seeking) not yet wrapped
- Requires file system access permissions for the app

## Future Enhancements

- [ ] Expose full demuxing API (tracks, samples, seeking)
- [ ] Add support for `ResourceManager` to load MP4 from rawfile
- [ ] Add async/Promise-based API for large files
- [ ] Performance benchmarking vs. Android version

## License

BSD-3-Clause (inherited from original libmp4)

## Credits

- Original library: Aurelien Barre
- OpenHarmony port: Ported using Android-to-OpenHarmony migration workflow

## Support

For issues and questions, please refer to:
- OpenHarmony documentation: https://docs.openharmony.cn/
- NAPI guide: See `references/native-migration.md` in this repository
