// Simplified AES implementation for HarmonyOS
// Based on libaes, adapted for cross-platform compatibility

#ifndef AES_H
#define AES_H

#include <stdint.h>
#include <stddef.h>
#include <string.h>

// AES constants
#define AES_BLOCK_SIZE 16
#define AES_128_KEY_SIZE 16
#define AES_128_ROUNDS 10

// Status codes
enum AesStatus {
    AES_OK = 0,
    AES_ERROR = -1,
    AES_ERR_INVALID_KEY_SIZE = -2,
    AES_ERR_INVALID_INPUT_SIZE = -3,
    AES_ERR_INVALID_PADDING = -4
};

// AES context
typedef struct {
    uint8_t roundKeys[AES_128_ROUNDS + 1][AES_BLOCK_SIZE];
    uint8_t key[AES_128_KEY_SIZE];
    uint8_t keySize;
} AesContext;

// Core AES functions
int aes_init(AesContext* ctx, const uint8_t* key, size_t keySize);
int aes_cbc_encrypt(const AesContext* ctx, const uint8_t* iv, 
                    const uint8_t* input, size_t inputLen,
                    uint8_t* output, size_t* outputLen);
int aes_cbc_decrypt(const AesContext* ctx, const uint8_t* iv,
                    const uint8_t* input, size_t inputLen,
                    uint8_t* output, size_t* outputLen);

// Utility functions
void aes_pkcs7_pad(uint8_t* data, size_t dataLen, size_t blockSize);
int aes_pkcs7_unpad(const uint8_t* data, size_t dataLen, size_t* unpaddedLen);

#endif // AES_H
