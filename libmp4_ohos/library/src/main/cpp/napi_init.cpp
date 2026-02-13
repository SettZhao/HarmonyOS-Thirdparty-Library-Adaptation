/**
 * @file napi_init.cpp
 * @brief NAPI wrapper for libmp4 - OpenHarmony Native API bindings
 * Replaces JNI layer from Android version
 */

#include "napi/native_api.h"
#include "hilog/log.h"
#include <string>
#include <map>

extern "C" {
#include "libmp4/libmp4.h"
}

#define LOG_DOMAIN 0x0001
#define LOG_TAG "libmp4_napi"

/**
 * NAPI function: mp4DemuxOpen
 * Opens an MP4 file for demuxing
 * JS signature: mp4DemuxOpen(fileName: string): number
 */
static napi_value Mp4DemuxOpen(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // Get string argument
    size_t str_size = 0;
    status = napi_get_value_string_utf8(env, args[0], nullptr, 0, &str_size);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to get string size");
        return nullptr;
    }
    
    char* filename = new char[str_size + 1];
    status = napi_get_value_string_utf8(env, args[0], filename, str_size + 1, &str_size);
    if (status != napi_ok) {
        delete[] filename;
        napi_throw_error(env, nullptr, "Failed to get string value");
        return nullptr;
    }
    
    // Call native libmp4 function
    struct mp4_demux* demux = mp4_demux_open(filename);
    delete[] filename;
    
    if (demux == nullptr) {
        OH_LOG_ERROR(LOG_APP, "Failed to open MP4 file");
        napi_throw_error(env, nullptr, "Cannot open MP4 file");
        return nullptr;
    }
    
    // Return demux pointer as number (int64)
    napi_value result;
    status = napi_create_int64(env, reinterpret_cast<int64_t>(demux), &result);
    if (status != napi_ok) {
        mp4_demux_close(demux);
        napi_throw_error(env, nullptr, "Failed to create return value");
        return nullptr;
    }
    
    OH_LOG_INFO(LOG_APP, "Successfully opened MP4 file, demux=%{public}p", demux);
    return result;
}

/**
 * NAPI function: mp4DemuxClose
 * Closes an MP4 demuxer
 * JS signature: mp4DemuxClose(demux: number): number
 */
static napi_value Mp4DemuxClose(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // Get demux pointer
    int64_t demux_ptr;
    status = napi_get_value_int64(env, args[0], &demux_ptr);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to get demux pointer");
        return nullptr;
    }
    
    struct mp4_demux* demux = reinterpret_cast<struct mp4_demux*>(demux_ptr);
    int ret = mp4_demux_close(demux);
    
    // Return result code
    napi_value result;
    status = napi_create_int32(env, ret, &result);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to create return value");
        return nullptr;
    }
    
    OH_LOG_INFO(LOG_APP, "Closed MP4 demuxer, ret=%{public}d", ret);
    return result;
}

/**
 * NAPI function: mp4DemuxGetMetadata
 * Gets metadata from MP4 file as key-value map
 * JS signature: mp4DemuxGetMetadata(demux: number): Object
 */
static napi_value Mp4DemuxGetMetadata(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    
    napi_status status = napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // Get demux pointer
    int64_t demux_ptr;
    status = napi_get_value_int64(env, args[0], &demux_ptr);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to get demux pointer");
        return nullptr;
    }
    
    struct mp4_demux* demux = reinterpret_cast<struct mp4_demux*>(demux_ptr);
    
    // Get metadata from libmp4
    unsigned int count = 0;
    char** keys = nullptr;
    char** values = nullptr;
    
    int ret = mp4_demux_get_metadata_strings(demux, &count, &keys, &values);
    
    // Create JavaScript object
    napi_value result;
    status = napi_create_object(env, &result);
    if (status != napi_ok) {
        napi_throw_error(env, nullptr, "Failed to create object");
        return nullptr;
    }
    
    if (ret == 0 && count > 0) {
        OH_LOG_INFO(LOG_APP, "Found %{public}u metadata entries", count);
        
        for (unsigned int i = 0; i < count; i++) {
            if (keys[i] != nullptr && values[i] != nullptr) {
                napi_value key_value;
                napi_value val_value;
                
                // Create string values for key and value
                status = napi_create_string_utf8(env, keys[i], NAPI_AUTO_LENGTH, &key_value);
                if (status != napi_ok) continue;
                
                status = napi_create_string_utf8(env, values[i], NAPI_AUTO_LENGTH, &val_value);
                if (status != napi_ok) continue;
                
                // Set property on result object
                status = napi_set_property(env, result, key_value, val_value);
                if (status != napi_ok) {
                    OH_LOG_WARN(LOG_APP, "Failed to set property %{public}s", keys[i]);
                }
                
                OH_LOG_DEBUG(LOG_APP, "Metadata: %{public}s: %{public}s", keys[i], values[i]);
            }
        }
    } else {
        OH_LOG_WARN(LOG_APP, "No metadata found or error, ret=%{public}d count=%{public}u", ret, count);
    }
    
    return result;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"mp4DemuxOpen", nullptr, Mp4DemuxOpen, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"mp4DemuxClose", nullptr, Mp4DemuxClose, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"mp4DemuxGetMetadata", nullptr, Mp4DemuxGetMetadata, nullptr, nullptr, nullptr, napi_default, nullptr}};

    napi_status status = napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    if (status != napi_ok) {
        OH_LOG_ERROR(LOG_APP, "Failed to define properties");
        return nullptr;
    }
    
    OH_LOG_INFO(LOG_APP, "libmp4 NAPI module initialized");
    return exports;
}
EXTERN_C_END

/**
 * Module definition
 */
static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "mp4",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

/**
 * Module registration
 */
extern "C" __attribute__((constructor)) void RegisterLibmp4Module(void) {
    napi_module_register(&demoModule);
}

