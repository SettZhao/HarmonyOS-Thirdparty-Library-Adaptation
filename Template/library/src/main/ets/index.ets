/**
 * LibAES - AES Encryption Library for HarmonyOS
 * 
 * A simplified AES-128-CBC encryption library providing:
 * - Text encryption/decryption with Base64 encoding
 * - Binary data encryption/decryption
 * - Random key/IV generation
 * 
 * @example
 * ```typescript
 * import { AES } from 'library'
 * 
 * // Encrypt text
 * const encrypted = AES.encryptText("Hello, HarmonyOS!", "my-secret-key-16");
 * 
 * // Decrypt text
 * const decrypted = AES.decryptText(encrypted, "my-secret-key-16");
 * ```
 */

import libAES from 'liblibrary.so';
import util from '@ohos.util';

/**
 * Helper class for Base64 encoding/decoding
 */
class Base64 {
  static encode(data: ArrayBuffer): string {
    const encoder = new util.Base64Helper();
    const uint8Array = new Uint8Array(data);
    return encoder.encodeToStringSync(uint8Array);
  }

  static decode(str: string): ArrayBuffer {
    const encoder = new util.Base64Helper();
    const uint8Array = encoder.decodeSync(str);
    return uint8Array.buffer;
  }
}

/**
 * Helper class for text encoding/decoding
 */
class TextEncoder {
  static encode(text: string): ArrayBuffer {
    const encoder = new util.TextEncoder();
    return encoder.encodeInto(text);
  }

  static decode(data: ArrayBuffer): string {
    const decoder = new util.TextDecoder('utf-8');
    const uint8Array = new Uint8Array(data);
    return decoder.decodeToString(uint8Array);
  }
}

/**
 * Main AES encryption class
 */
export class AES {
  /**
   * Encrypt text string with AES-128-CBC
   * @param plaintext - Text to encrypt
   * @param keyStr - 16-character key string (padded/truncated automatically)
   * @returns Base64-encoded ciphertext
   */
  static encryptText(plaintext: string, keyStr: string): string {
    const key: ArrayBuffer = AES.stringToKey(keyStr);
    const iv: ArrayBuffer = AES.generateIV();
    const plaintextBuffer: ArrayBuffer = TextEncoder.encode(plaintext);
    
    const ciphertext: ArrayBuffer = libAES.encrypt(key, iv, plaintextBuffer);
    
    // Prepend IV to ciphertext
    const result: ArrayBuffer = AES.concatArrayBuffers(iv, ciphertext);
    return Base64.encode(result);
  }

  /**
   * Decrypt text string encrypted with AES-128-CBC
   * @param ciphertextB64 - Base64-encoded ciphertext (with prepended IV)
   * @param keyStr - 16-character key string
   * @returns Decrypted plaintext
   */
  static decryptText(ciphertextB64: string, keyStr: string): string {
    const key: ArrayBuffer = AES.stringToKey(keyStr);
    const data: ArrayBuffer = Base64.decode(ciphertextB64);
    
    // Extract IV and ciphertext
    const iv: ArrayBuffer = data.slice(0, 16);
    const ciphertext: ArrayBuffer = data.slice(16);
    
    const plaintext: ArrayBuffer = libAES.decrypt(key, iv, ciphertext);
    return TextEncoder.decode(plaintext);
  }

  /**
   * Encrypt binary data with AES-128-CBC
   * @param plaintext - Data to encrypt
   * @param key - 16-byte encryption key
   * @param iv - 16-byte initialization vector
   * @returns Encrypted ciphertext
   */
  static encryptData(plaintext: ArrayBuffer, key: ArrayBuffer, iv: ArrayBuffer): ArrayBuffer {
    return libAES.encrypt(key, iv, plaintext);
  }

  /**
   * Decrypt binary data with AES-128-CBC
   * @param ciphertext - Encrypted data
   * @param key - 16-byte encryption key
   * @param iv - 16-byte initialization vector
   * @returns Decrypted plaintext
   */
  static decryptData(ciphertext: ArrayBuffer, key: ArrayBuffer, iv: ArrayBuffer): ArrayBuffer {
    return libAES.decrypt(key, iv, ciphertext);
  }

  /**
   * Generate random 16-byte key
   * @returns Random key as ArrayBuffer
   */
  static generateKey(): ArrayBuffer {
    return libAES.randomBytes(16);
  }

  /**
   * Generate random 16-byte IV
   * @returns Random IV as ArrayBuffer
   */
  static generateIV(): ArrayBuffer {
    return libAES.randomBytes(16);
  }

  /**
   * Convert string to 16-byte key (pad or truncate)
   * @param str - Input string
   * @returns 16-byte ArrayBuffer
   */
  private static stringToKey(str: string): ArrayBuffer {
    const bytes = new Uint8Array(16);
    const encoder = new util.TextEncoder();
    const encoded = encoder.encodeInto(str);
    const view = new Uint8Array(encoded);
    
    // Copy up to 16 bytes
    for (let i = 0; i < Math.min(16, view.length); i++) {
      bytes[i] = view[i];
    }
    
    return bytes.buffer;
  }

  /**
   * Concatenate two ArrayBuffers
   * @param a - First buffer
   * @param b - Second buffer
   * @returns Concatenated buffer
   */
  private static concatArrayBuffers(a: ArrayBuffer, b: ArrayBuffer): ArrayBuffer {
    const result = new Uint8Array(a.byteLength + b.byteLength);
    result.set(new Uint8Array(a), 0);
    result.set(new Uint8Array(b), a.byteLength);
    return result.buffer;
  }

  /**
   * Convert ArrayBuffer to hex string (for debugging)
   * @param buffer - Input buffer
   * @returns Hex string
   */
  static toHex(buffer: ArrayBuffer): string {
    const bytes = new Uint8Array(buffer);
    let result = '';
    for (let i = 0; i < bytes.length; i++) {
      const hex = bytes[i].toString(16);
      result += (hex.length === 1 ? '0' + hex : hex);
    }
    return result;
  }
}

/**
 * Default export
 */
export default AES;
