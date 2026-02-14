/**
 * LibAES Demo - AES Encryption Demo Application
 * 
 * Demonstrates AES-128-CBC encryption and decryption
 */

import { AES } from 'library';
import hilog from '@ohos.hilog';

const TAG = 'AESDemo';

@Entry
@Component
struct Index {
  @State plaintext: string = 'Hello, HarmonyOS!';
  @State encryptionKey: string = 'my-secret-key-16';
  @State encryptedText: string = '';
  @State decryptedText: string = '';
  @State statusMessage: string = 'Ready';
  @State isEncrypted: boolean = false;

  aboutToAppear() {
    hilog.info(0x0000, TAG, 'LibAES Demo started');
  }

  performEncryption() {
    try {
      hilog.info(0x0000, TAG, `Encrypting: ${this.plaintext}`);
      
      const startTime = Date.now();
      this.encryptedText = AES.encryptText(this.plaintext, this.encryptionKey);
      const endTime = Date.now();
      
      this.isEncrypted = true;
      this.decryptedText = '';
      this.statusMessage = `Encrypted in ${endTime - startTime}ms`;
      
      hilog.info(0x0000, TAG, `Encrypted (${this.encryptedText.length} bytes): ${this.encryptedText.substring(0, 32)}...`);
    } catch (error) {
      this.statusMessage = `Error: ${error.message}`;
      hilog.error(0x0000, TAG, `Encryption failed: ${error.message}`);
    }
  }

  performDecryption() {
    try {
      if (!this.encryptedText) {
        this.statusMessage = 'Please encrypt first';
        return;
      }
      
      hilog.info(0x0000, TAG, 'Decrypting...');
      
      const startTime = Date.now();
      this.decryptedText = AES.decryptText(this.encryptedText, this.encryptionKey);
      const endTime = Date.now();
      
      const isMatch = this.decryptedText === this.plaintext;
      this.statusMessage = `Decrypted in ${endTime - startTime}ms - ${isMatch ? '✓ Match' : '✗ Mismatch'}`;
      
      hilog.info(0x0000, TAG, `Decrypted: ${this.decryptedText}`);
    } catch (error) {
      this.statusMessage = `Error: ${error.message}`;
      hilog.error(0x0000, TAG, `Decryption failed: ${error.message}`);
    }
  }

  resetDemo() {
    this.encryptedText = '';
    this.decryptedText = '';
    this.isEncrypted = false;
    this.statusMessage = 'Ready';
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        // Header
        Text('LibAES Demo')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('AES-128-CBC Encryption')
          .fontSize(16)
          .fontColor(Color.Gray)
          .margin({ bottom: 20 })

        // Input Section
        Column({ space: 12 }) {
          Text('Plaintext')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: 'Enter text to encrypt', text: this.plaintext })
            .onChange((value: string) => {
              this.plaintext = value;
              this.resetDemo();
            })
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // Key Section
        Column({ space: 12 }) {
          Text('Encryption Key (16 chars)')
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)

          TextInput({ placeholder: 'Enter 16-character key', text: this.encryptionKey })
            .type(InputType.Password)
            .onChange((value: string) => {
              this.encryptionKey = value;
              this.resetDemo();
            })
            .width('100%')
            .padding(12)
        }
        .width('90%')
        .padding(16)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // Action Buttons
        Row({ space: 12 }) {
          Button('Encrypt')
            .onClick(() => this.performEncryption())
            .width('45%')
            .backgroundColor('#007DFF')
            .enabled(!this.isEncrypted)

          Button('Decrypt')
            .onClick(() => this.performDecryption())
            .width('45%')
            .backgroundColor('#00C853')
            .enabled(this.isEncrypted)
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)

        // Status
        Text(this.statusMessage)
          .fontSize(14)
          .fontColor(this.statusMessage.includes('Error') ? Color.Red : Color.Blue)
          .margin({ top: 8 })

        // Encrypted Output
        if (this.encryptedText) {
          Column({ space: 12 }) {
            Text('Encrypted (Base64)')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)

            Text(this.encryptedText)
              .fontSize(12)
              .fontColor(Color.Gray)
              .wordBreak(WordBreak.BREAK_ALL)
              .maxLines(4)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .width('100%')
              .padding(12)
              .backgroundColor('#E8F5E9')
              .borderRadius(4)
          }
          .width('90%')
          .padding(16)
          .backgroundColor('#F1F8E9')
          .borderRadius(8)
        }

        // Decrypted Output
        if (this.decryptedText) {
          Column({ space: 12 }) {
            Text('Decrypted')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .alignSelf(ItemAlign.Start)

            Text(this.decryptedText)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.decryptedText === this.plaintext ? Color.Green : Color.Red)
              .width('100%')
              .padding(12)
              .backgroundColor('#FFF9C4')
              .borderRadius(4)
          }
          .width('90%')
          .padding(16)
          .backgroundColor('#FFFDE7')
          .borderRadius(8)
        }

        // Reset Button
        Button('Reset')
          .onClick(() => this.resetDemo())
          .width('90%')
          .backgroundColor('#FF5252')
          .margin({ top: 12, bottom: 20 })
          .enabled(this.isEncrypted)
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}