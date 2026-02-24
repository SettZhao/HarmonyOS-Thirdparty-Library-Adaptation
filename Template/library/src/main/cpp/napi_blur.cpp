#include "napi/native_api.h"
#include <hilog/log.h>
#include <stdint.h>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x0001
#define LOG_TAG "libblur"

// Declaration of C algorithm from blur_core.c
#ifdef __cplusplus
extern "C" {
#endif
void stackblurJob(unsigned char* src, unsigned int w, unsigned int h,
                  unsigned int radius, int cores, int core, int step);
#ifdef __cplusplus
}
#endif

/**
 * nativeBlur(buffer: ArrayBuffer, width: number, height: number, radius: number): void
 *
 * Applies Stack Blur in-place to the RGBA_8888 pixel data in |buffer|.
 * buffer must have byte length == width * height * 4.
 */
static napi_value NativeBlur(napi_env env, napi_callback_info info)
{
    size_t argc = 4;
    napi_value args[4] = { nullptr };

    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);

    if (argc < 4) {
        OH_LOG_ERROR(LOG_APP, "nativeBlur: expected 4 arguments, got %{public}zu", argc);
        return nullptr;
    }

    // 1. Get ArrayBuffer data pointer
    void* data = nullptr;
    size_t byteLen = 0;
    napi_status status = napi_get_arraybuffer_info(env, args[0], &data, &byteLen);
    if (status != napi_ok || data == nullptr) {
        OH_LOG_ERROR(LOG_APP, "nativeBlur: failed to get ArrayBuffer info, status=%{public}d", status);
        return nullptr;
    }

    // 2. Get width, height, radius
    int32_t w = 0, h = 0, radius = 0;
    napi_get_value_int32(env, args[1], &w);
    napi_get_value_int32(env, args[2], &h);
    napi_get_value_int32(env, args[3], &radius);

    // 3. Basic validation
    if (w <= 0 || h <= 0 || radius < 1 || radius > 254) {
        OH_LOG_ERROR(LOG_APP,
            "nativeBlur: invalid args w=%{public}d h=%{public}d radius=%{public}d",
            w, h, radius);
        return nullptr;
    }
    if (byteLen < (size_t)(w * h * 4)) {
        OH_LOG_ERROR(LOG_APP,
            "nativeBlur: buffer too small, expected %{public}d bytes, got %{public}zu",
            w * h * 4, byteLen);
        return nullptr;
    }

    // 4. Execute Stack Blur: horizontal pass then vertical pass (single-threaded)
    stackblurJob((unsigned char*)data, (unsigned int)w, (unsigned int)h,
                 (unsigned int)radius, 1, 0, 1);
    stackblurJob((unsigned char*)data, (unsigned int)w, (unsigned int)h,
                 (unsigned int)radius, 1, 0, 2);

    OH_LOG_INFO(LOG_APP,
        "nativeBlur: done w=%{public}d h=%{public}d radius=%{public}d",
        w, h, radius);

    return nullptr;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "nativeBlur", nullptr, NativeBlur, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module blurModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "blur",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterBlurModule(void)
{
    napi_module_register(&blurModule);
}
