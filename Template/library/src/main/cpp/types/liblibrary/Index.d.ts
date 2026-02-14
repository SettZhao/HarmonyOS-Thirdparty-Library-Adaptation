/**
 * LibAES - AES Encryption Library for HarmonyOS
 * Simplified AES-128 CBC implementation
 */

/**
 * Encrypt data using AES-128-CBC
 * @param key - 16-byte encryption key (AES-128)
 * @param iv - 16-byte initialization vector
 * @param plaintext - Data to encrypt
 * @returns Encrypted ciphertext with PKCS#7 padding
 */
export const encrypt: (key: ArrayBuffer, iv: ArrayBuffer, plaintext: ArrayBuffer) => ArrayBuffer;

/**
 * Decrypt data using AES-128-CBC
 * @param key - 16-byte encryption key (AES-128)
 * @param iv - 16-byte initialization vector
 * @param ciphertext - Encrypted data
 * @returns Decrypted plaintext (padding removed)
 */
export const decrypt: (key: ArrayBuffer, iv: ArrayBuffer, ciphertext: ArrayBuffer) => ArrayBuffer;

/**
 * Generate cryptographically random bytes
 * @param length - Number of random bytes to generate (1-1048576)
 * @returns ArrayBuffer containing random bytes
 */
export const randomBytes: (length: number) => ArrayBuffer;