/**
 * LibAES Test Suite
 * 
 * Comprehensive tests for AES encryption/decryption functionality
 */

import { describe, it, expect } from '@ohos/hypium';
import { AES } from 'library';
import hilog from '@ohos.hilog';
import { buffer } from '@kit.ArkTS';

const TAG = 'AESTest';

export default function aesTest() {
  describe('AESEncryptionTests', () => {
    // Test 1: Basic text encryption and decryption
    it('testBasicEncryptDecrypt', 0, () => {
      const plaintext = 'Hello, HarmonyOS!';
      const key = 'my-secret-key-16';
      
      hilog.info(0x0000, TAG, 'Testing basic encryption/decryption');
      
      const encrypted = AES.encryptText(plaintext, key);
      expect(encrypted).not().assertEqual('');
      expect(encrypted).not().assertEqual(plaintext);
      
      const decrypted = AES.decryptText(encrypted, key);
      expect(decrypted).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Basic encryption/decryption test PASSED');
    });

    // Test 2: Empty string encryption
    it('testEmptyStringEncryption', 0, () => {
      const plaintext = '';
      const key = 'test-key-1234567';
      
      hilog.info(0x0000, TAG, 'Testing empty string encryption');
      
      const encrypted = AES.encryptText(plaintext, key);
      expect(encrypted).not().assertEqual('');
      
      const decrypted = AES.decryptText(encrypted, key);
      expect(decrypted).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Empty string encryption test PASSED');
    });

    // Test 3: Long text encryption
    it('testLongTextEncryption', 0, () => {
      const plaintext = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '.repeat(10);
      const key = 'long-text-key-16';
      
      hilog.info(0x0000, TAG, `Testing long text encryption (${plaintext.length} chars)`);
      
      const encrypted = AES.encryptText(plaintext, key);
      expect(encrypted).not().assertEqual('');
      
      const decrypted = AES.decryptText(encrypted, key);
      expect(decrypted).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Long text encryption test PASSED');
    });

    // Test 4: Special characters and Unicode
    it('testSpecialCharactersEncryption', 0, () => {
      const plaintext = '!@#$%^&*()_+-=[]{}|;:,.<>?`~' + '中文测试' + '🔐😀';
      const key = 'special-chars-16';
      
      hilog.info(0x0000, TAG, 'Testing special characters encryption');
      
      const encrypted = AES.encryptText(plaintext, key);
      expect(encrypted).not().assertEqual('');
      
      const decrypted = AES.decryptText(encrypted, key);
      expect(decrypted).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Special characters encryption test PASSED');
    });

    // Test 5: Different keys produce different ciphertexts
    it('testDifferentKeys', 0, () => {
      const plaintext = 'Test message';
      const key1 = 'key1-0123456789';
      const key2 = 'key2-0123456789';
      
      hilog.info(0x0000, TAG, 'Testing different keys');
      
      const encrypted1 = AES.encryptText(plaintext, key1);
      const encrypted2 = AES.encryptText(plaintext, key2);
      
      // Different keys should produce different ciphertexts
      expect(encrypted1).not().assertEqual(encrypted2);
      
      // Each should decrypt correctly with its own key
      expect(AES.decryptText(encrypted1, key1)).assertEqual(plaintext);
      expect(AES.decryptText(encrypted2, key2)).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Different keys test PASSED');
    });

    // Test 6: Multiple block test (>16 bytes)
    it('testMultipleBlocks', 0, () => {
      // 48 bytes = 3 blocks
      const plaintext = 'This is a longer message that spans multiple AES blocks!';
      const key = 'multiblock-key16';
      
      hilog.info(0x0000, TAG, `Testing multiple blocks (${plaintext.length} bytes)`);
      
      const encrypted = AES.encryptText(plaintext, key);
      const decrypted = AES.decryptText(encrypted, key);
      
      expect(decrypted).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Multiple blocks test PASSED');
    });

    // Test 7: Key padding/truncation
    it('testKeyPaddingTruncation', 0, () => {
      const plaintext = 'Key length test';
      
      hilog.info(0x0000, TAG, 'Testing key padding/truncation');
      
      // Short key (will be padded)
      const shortKey = 'short';
      const encrypted1 = AES.encryptText(plaintext, shortKey);
      const decrypted1 = AES.decryptText(encrypted1, shortKey);
      expect(decrypted1).assertEqual(plaintext);
      
      // Long key (will be truncated)
      const longKey = 'this-is-a-very-long-key-that-exceeds-16-bytes';
      const encrypted2 = AES.encryptText(plaintext, longKey);
      const decrypted2 = AES.decryptText(encrypted2, longKey);
      expect(decrypted2).assertEqual(plaintext);
      
      hilog.info(0x0000, TAG, 'Key padding/truncation test PASSED');
    });

    // Test 8: Binary data encryption
    it('testBinaryDataEncryption', 0, () => {
      hilog.info(0x0000, TAG, 'Testing binary data encryption');
      
      // Create test data
      const plaintext = new Uint8Array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]);
      const key = AES.generateKey();
      const iv = AES.generateIV();
      
      const encrypted = AES.encryptData(buffer.from(plaintext).buffer, key, iv);
      expect(encrypted.byteLength).assertLarger(0);
      
      const decrypted = AES.decryptData(encrypted, key, iv);
      const decryptedArray = new Uint8Array(decrypted);
      
      expect(decryptedArray.length).assertEqual(plaintext.length);
      for (let i = 0; i < plaintext.length; i++) {
        expect(decryptedArray[i]).assertEqual(plaintext[i]);
      }
      
      hilog.info(0x0000, TAG, 'Binary data encryption test PASSED');
    });

    // Test 9: Random key/IV generation
    it('testRandomGeneration', 0, () => {
      hilog.info(0x0000, TAG, 'Testing random generation');
      
      const key1 = AES.generateKey();
      const key2 = AES.generateKey();
      const iv1 = AES.generateIV();
      const iv2 = AES.generateIV();
      
      expect(key1.byteLength).assertEqual(16);
      expect(key2.byteLength).assertEqual(16);
      expect(iv1.byteLength).assertEqual(16);
      expect(iv2.byteLength).assertEqual(16);
      
      // Keys and IVs should be different
      const key1Hex = AES.toHex(key1);
      const key2Hex = AES.toHex(key2);
      const iv1Hex = AES.toHex(iv1);
      const iv2Hex = AES.toHex(iv2);
      
      expect(key1Hex).not().assertEqual(key2Hex);
      expect(iv1Hex).not().assertEqual(iv2Hex);
      
      hilog.info(0x0000, TAG, 'Random generation test PASSED');
    });

    // Test 10: Hex conversion utility
    it('testHexConversion', 0, () => {
      hilog.info(0x0000, TAG, 'Testing hex conversion');
      
      const data = new Uint8Array([0x00, 0x11, 0x22, 0x33, 0xAA, 0xBB, 0xCC, 0xFF]);
      const hex = AES.toHex(buffer.from(data).buffer);
      
      expect(hex).assertEqual('00112233aabbccff');
      
      hilog.info(0x0000, TAG, 'Hex conversion test PASSED');
    });
  });
}
