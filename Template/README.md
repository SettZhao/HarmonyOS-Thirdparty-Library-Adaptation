# LibAES for HarmonyOS

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![HarmonyOS](https://img.shields.io/badge/HarmonyOS-API%2012%2B-blue)](https://developer.huawei.com/consumer/cn/harmonyos/)

AES-128-CBC encryption library for HarmonyOS, ported from the libaes C library.

## Features

- ✅ **AES-128-CBC Encryption/Decryption**
- ✅ **Native C++ Implementation** (high performance)
- ✅ **Simple ArkTS API** (text and binary data support)
- ✅ **PKCS#7 Padding**
- ✅ **Random Key/IV Generation**
- ✅ **Base64 Encoding** (for text encryption)
- ✅ **Pure Software** (no hardware dependencies, works on all HarmonyOS devices)

## Installation

### Option 1: Import HAR File
1. Build the library:
   ```bash
   cd Template
   hvigorw assembleHar
   ```
2. Find the HAR file at:
   ```
   library/build/default/outputs/default/library-default-signed.har
   ```
3. Import into your HarmonyOS project

### Option 2: Copy Source Files
Copy the `library/` folder into your project and add it as a module dependency.

## Quick Start

### Text Encryption

```typescript
import { AES } from 'library';

// Encrypt text
const plaintext = "Hello, HarmonyOS!";
const key = "my-secret-key-16"; // Must be 16 bytes (padded/truncated automatically)

const encrypted = AES.encryptText(plaintext, key);
console.log("Encrypted (Base64):", encrypted);

// Decrypt text
const decrypted = AES.decryptText(encrypted, key);
console.log("Decrypted:", decrypted); // "Hello, HarmonyOS!"
```

### Binary Data Encryption

```typescript
import { AES } from 'library';

// Generate secure key and IV
const key = AES.generateKey();     // 16 random bytes
const iv = AES.generateIV();       // 16 random bytes

// Encrypt binary data
const data = new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8]);
const encrypted = AES.encryptData(data.buffer, key, iv);

// Decrypt binary data
const decrypted = AES.decryptData(encrypted, key, iv);
const result = new Uint8Array(decrypted);
```

### Key Management

```typescript
import { AES } from 'library';

// Automatic key conversion (pads or truncates to 16 bytes)
const shortKey = "abc";           // Padded to 16 bytes
const longKey = "very-long-key";  // Truncated to 16 bytes

// Or use stringToKey explicitly
const key = AES.stringToKey("my-password");

// Generate cryptographically secure random keys
const randomKey = AES.generateKey();
const hexKey = AES.toHex(randomKey);
console.log("Random Key (hex):", hexKey);
```

## API Reference

### AES Class

#### Static Methods

| Method | Parameters | Returns | Description |
|--------|------------|---------|-------------|
| `encryptText()` | `plaintext: string, key: string` | `string` | Encrypts text, returns Base64 |
| `decryptText()` | `ciphertext: string, key: string` | `string` | Decrypts Base64 to text |
| `encryptData()` | `data: ArrayBuffer, key: ArrayBuffer, iv: ArrayBuffer` | `ArrayBuffer` | Encrypts binary data |
| `decryptData()` | `data: ArrayBuffer, key: ArrayBuffer, iv: ArrayBuffer` | `ArrayBuffer` | Decrypts binary data |
| `generateKey()` | - | `ArrayBuffer` | Generates 16 random bytes |
| `generateIV()` | - | `ArrayBuffer` | Generates 16 random bytes |
| `stringToKey()` | `key: string` | `ArrayBuffer` | Converts string to 16-byte key |
| `toHex()` | `buffer: ArrayBuffer` | `string` | Converts buffer to hex string |

### Helper Classes

#### Base64
- `encode(data: ArrayBuffer): string` - Encode to Base64
- `decode(str: string): ArrayBuffer` - Decode from Base64

#### TextEncoder
- `encode(text: string): ArrayBuffer` - UTF-8 encode
- `decode(buffer: ArrayBuffer): string` - UTF-8 decode

## Demo Application

Run the demo app to see the library in action:

```powershell
cd Template

# Build and install
hvigorw assembleHap
hdc install -r entry\build\default\outputs\default\entry-default-signed.hap

# Launch on device
hdc shell "aa start -a EntryAbility -b com.example.template"
```

The demo provides an interactive UI for:
- Text encryption/decryption
- Key input
- Real-time result verification
- Performance timing

## Technical Details

- **Algorithm**: AES-128 (128-bit key)
- **Mode**: CBC (Cipher Block Chaining)
- **Padding**: PKCS#7
- **Block Size**: 16 bytes (128 bits)
- **IV Size**: 16 bytes (128 bits)
- **Implementation**: Pure C++ (no hardware acceleration)

## Security Notes

⚠️ **Important Security Considerations**:

1. **Never reuse IV with the same key** - Always generate random IV for each encryption
2. **Use strong keys** - Prefer `generateKey()` over user-provided passwords
3. **Secure key storage** - Store keys in HarmonyOS secure storage (not in plain text)
4. **This is CBC mode** - For authenticated encryption, consider adding HMAC or use GCM mode (future version)
5. **Demo app is for testing only** - Not production-ready (no secure key storage)

## Performance

Software implementation benchmarks (ARM64):
- Encryption: ~5-10 MB/s
- Decryption: ~5-10 MB/s

✅ **Suitable for**: Text messages, small files, settings encryption  
⚠️ **Not optimal for**: Large file encryption (>10MB), real-time video

## Limitations

- AES-128 only (no AES-192/256 support)
- CBC mode only (no ECB, CTR, GCM)
- Software-based (no ARM Crypto Extensions acceleration)
- Text encryption uses UTF-8 encoding only

## Troubleshooting

### Build Errors

**Error**: `Cannot find module 'library'`
```powershell
# Solution: Install dependencies first
ohpm install
hvigorw clean
hvigorw assembleHap
```

**Error**: `ArkTS Compiler Error`
```powershell
# Solution: Check ArkTS version compatibility
# Ensure you're using DevEco Studio 5.0 or later
```

### Runtime Errors

**Error**: Decryption returns garbled text
- ✅ Check: Are you using the same key for encryption and decryption?
- ✅ Check: Is the encrypted string properly preserved (no corruption)?

**Error**: `ArrayBuffer` size mismatch
- ✅ Check: Are you using correct IV size (16 bytes)?
- ✅ Check: Is the input data properly formed?

## License

MIT License - See [LICENSE](../libaes/LICENSE) file for details

Original libaes library: https://github.com/webs3c/libaes

## Credits

- **Original Library**: libaes by webs3c
- **HarmonyOS Port**: Migrated for OpenHarmony API 12+
- **AES Algorithm**: Based on FIPS 197 standard

## Contributing

Contributions are welcome! Areas for improvement:
- Add AES-192 and AES-256 support
- Implement GCM mode for authenticated encryption
- Add ARM Crypto Extensions acceleration
- Improve error handling
- Add more test cases

## Changelog

### v1.0.0 (2025)
- ✅ Initial release
- ✅ AES-128-CBC encryption/decryption
- ✅ ArkTS API wrapper
- ✅ Demo application
- ✅ Base64 helpers
- ✅ Random key/IV generation

---

**Status**: Production-ready for AES-128-CBC encryption on HarmonyOS

For detailed migration documentation, see [MIGRATION_REPORT.md](./MIGRATION_REPORT.md)
