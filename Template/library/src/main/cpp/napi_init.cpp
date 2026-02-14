#include "napi/native_api.h"
#include "aes.h"
#include <hilog/log.h>
#include <vector>
#include <string>

#undef LOG_DOMAIN
#undef LOG_TAG
#define LOG_DOMAIN 0x3200
#define LOG_TAG "LibAES"

// Helper: Get ArrayBuffer data
static uint8_t* GetArrayBufferData(napi_env env, napi_value value, size_t* length) {
    void* data = nullptr;
    napi_get_arraybuffer_info(env, value, &data, length);
    return static_cast<uint8_t*>(data);
}

// Helper: Create ArrayBuffer from data
static napi_value CreateArrayBuffer(napi_env env, const uint8_t* data, size_t length) {
    void* bufferData = nullptr;
    napi_value result = nullptr;
    napi_create_arraybuffer(env, length, &bufferData, &result);
    if (bufferData && data) {
        memcpy(bufferData, data, length);
    }
    return result;
}

// NAPI: AES CBC Encrypt
// encrypt(key: ArrayBuffer, iv: ArrayBuffer, plaintext: ArrayBuffer): ArrayBuffer
static napi_value Encrypt(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // Get key
    size_t keyLen;
    uint8_t* key = GetArrayBufferData(env, args[0], &keyLen);
    if (keyLen != AES_128_KEY_SIZE) {
        napi_throw_error(env, nullptr, "Key must be 16 bytes (AES-128)");
        return nullptr;
    }
    
    // Get IV
    size_t ivLen;
    uint8_t* iv = GetArrayBufferData(env, args[1], &ivLen);
    if (ivLen != AES_BLOCK_SIZE) {
        napi_throw_error(env, nullptr, "IV must be 16 bytes");
        return nullptr;
    }
    
    // Get plaintext
    size_t plaintextLen;
    uint8_t* plaintext = GetArrayBufferData(env, args[2], &plaintextLen);
    
    // Initialize AES context
    AesContext ctx;
    int result = aes_init(&ctx, key, keyLen);
    if (result != AES_OK) {
        napi_throw_error(env, nullptr, "Failed to initialize AES context");
        return nullptr;
    }
    
    // Encrypt
    size_t ciphertextLen;
    std::vector<uint8_t> ciphertext(plaintextLen + AES_BLOCK_SIZE);
    result = aes_cbc_encrypt(&ctx, iv, plaintext, plaintextLen, 
                             ciphertext.data(), &ciphertextLen);
    
    if (result != AES_OK) {
        napi_throw_error(env, nullptr, "Encryption failed");
        return nullptr;
    }
    
    OH_LOG_INFO(LOG_APP, "AES Encrypt: plaintext=%{public}zu bytes, ciphertext=%{public}zu bytes", 
                plaintextLen, ciphertextLen);
    
    return CreateArrayBuffer(env, ciphertext.data(), ciphertextLen);
}

// NAPI: AES CBC Decrypt
// decrypt(key: ArrayBuffer, iv: ArrayBuffer, ciphertext: ArrayBuffer): ArrayBuffer
static napi_value Decrypt(napi_env env, napi_callback_info info) {
    size_t argc = 3;
    napi_value args[3] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 3) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    // Get key
    size_t keyLen;
    uint8_t* key = GetArrayBufferData(env, args[0], &keyLen);
    if (keyLen != AES_128_KEY_SIZE) {
        napi_throw_error(env, nullptr, "Key must be 16 bytes (AES-128)");
        return nullptr;
    }
    
    // Get IV
    size_t ivLen;
    uint8_t* iv = GetArrayBufferData(env, args[1], &ivLen);
    if (ivLen != AES_BLOCK_SIZE) {
        napi_throw_error(env, nullptr, "IV must be 16 bytes");
        return nullptr;
    }
    
    // Get ciphertext
    size_t ciphertextLen;
    uint8_t* ciphertext = GetArrayBufferData(env, args[2], &ciphertextLen);
    
    if (ciphertextLen == 0 || ciphertextLen % AES_BLOCK_SIZE != 0) {
        napi_throw_error(env, nullptr, "Ciphertext length must be multiple of 16");
        return nullptr;
    }
    
    // Initialize AES context
    AesContext ctx;
    int result = aes_init(&ctx, key, keyLen);
    if (result != AES_OK) {
        napi_throw_error(env, nullptr, "Failed to initialize AES context");
        return nullptr;
    }
    
    // Decrypt
    std::vector<uint8_t> plaintext(ciphertextLen);
    size_t plaintextLen;
    result = aes_cbc_decrypt(&ctx, iv, ciphertext, ciphertextLen,
                             plaintext.data(), &plaintextLen);
    
    if (result != AES_OK) {
        napi_throw_error(env, nullptr, "Decryption failed");
        return nullptr;
    }
    
    OH_LOG_INFO(LOG_APP, "AES Decrypt: ciphertext=%{public}zu bytes, plaintext=%{public}zu bytes",
                ciphertextLen, plaintextLen);
    
    return CreateArrayBuffer(env, plaintext.data(), plaintextLen);
}

// NAPI: Generate random bytes
// randomBytes(length: number): ArrayBuffer
static napi_value RandomBytes(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    if (argc < 1) {
        napi_throw_error(env, nullptr, "Wrong number of arguments");
        return nullptr;
    }
    
    int32_t length;
    napi_get_value_int32(env, args[0], &length);
    
    if (length <= 0 || length > 1024 * 1024) {
        napi_throw_error(env, nullptr, "Length must be between 1 and 1048576");
        return nullptr;
    }
    
    std::vector<uint8_t> randomData(length);
    // Simple random generation (for production, use cryptographic RNG)
    for (int32_t i = 0; i < length; i++) {
        randomData[i] = static_cast<uint8_t>(rand() % 256);
    }
    
    return CreateArrayBuffer(env, randomData.data(), length);
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "encrypt", nullptr, Encrypt, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "decrypt", nullptr, Decrypt, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "randomBytes", nullptr, RandomBytes, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    
    OH_LOG_INFO(LOG_APP, "LibAES Native module initialized");
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "library",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterLibraryModule(void) {
    napi_module_register(&demoModule);
}
