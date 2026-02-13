/**
 * @file Index.ets
 * @brief libmp4 Library Demo - MP4 Metadata Extractor
 * Demonstrates how to use the libmp4 library to:
 * - Open MP4 files
 * - Extract metadata
 * - Handle errors
 * - Close resources properly
 */

import { Libmp4 } from 'libmp4';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'Libmp4Demo';
const LOG_DOMAIN = 0x0001;

@Entry
@Component
struct Index {
  @State status: string = 'Ready';
  @State filePath: string = '/data/storage/el2/base/haps/entry/files/test.mp4';
  @State metadata: Record<string, string> = {};
  @State isOpen: boolean = false;
  @State errorMessage: string = '';
  
  private mp4Instance: Libmp4 | null = null;

  /**
   * Demo 1: Open MP4 file and extract metadata
   */
  openAndExtractMetadata() {
    this.errorMessage = '';
    this.metadata = {};
    
    if (this.filePath.trim() === '') {
      this.errorMessage = 'Please enter a file path';
      this.status = 'Error';
      return;
    }

    try {
      // Step 1: Open MP4 file
      this.status = `Opening ${this.filePath}...`;
      hilog.info(LOG_DOMAIN, LOG_TAG, `Attempting to open: ${this.filePath}`);
      
      this.mp4Instance = new Libmp4(this.filePath);
      this.isOpen = this.mp4Instance.isOpen();
      
      if (!this.isOpen) {
        throw new Error('Failed to open MP4 file');
      }
      
      this.status = 'File opened successfully';
      hilog.info(LOG_DOMAIN, LOG_TAG, 'MP4 file opened successfully');

      // Step 2: Extract metadata
      this.status = 'Extracting metadata...';
      this.metadata = this.mp4Instance.getMetadata();
      
      const metadataCount = Object.keys(this.metadata).length;
      this.status = `Success! Found ${metadataCount} metadata entries`;
      hilog.info(LOG_DOMAIN, LOG_TAG, `Extracted ${metadataCount} metadata entries`);
      
    } catch (err) {
      const error = err as Error;
      this.errorMessage = `Error: ${error.message}`;
      this.status = 'Failed';
      this.isOpen = false;
      hilog.error(LOG_DOMAIN, LOG_TAG, `Error: ${error.message}`);
      
      // Clean up on error
      if (this.mp4Instance) {
        try {
          this.mp4Instance.close();
        } catch (closeErr) {
          hilog.error(LOG_DOMAIN, LOG_TAG, `Error closing: ${closeErr}`);
        }
        this.mp4Instance = null;
      }
    }
  }

  /**
   * Demo 2: Close the MP4 file and release resources
   */
  closeFile() {
    if (!this.mp4Instance) {
      this.errorMessage = 'No file is currently open';
      return;
    }

    try {
      this.status = 'Closing file...';
      this.mp4Instance.close();
      this.mp4Instance = null;
      this.isOpen = false;
      this.metadata = {};
      this.status = 'File closed successfully';
      hilog.info(LOG_DOMAIN, LOG_TAG, 'MP4 file closed successfully');
    } catch (err) {
      const error = err as Error;
      this.errorMessage = `Close error: ${error.message}`;
      hilog.error(LOG_DOMAIN, LOG_TAG, `Close error: ${error.message}`);
    }
  }

  /**
   * Demo 3: Test with sample paths
   */
  loadSamplePath(path: string) {
    this.filePath = path;
    this.errorMessage = '';
    this.status = 'Sample path loaded';
  }

  build() {
    Scroll() {
      Column({ space: 15 }) {
        // Header
        Text('libmp4 Demo')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, bottom: 10 })

        Text('MP4 Metadata Extractor')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 20 })

        // Status indicator
        Row() {
          Text('Status: ')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
          
          Text(this.status)
            .fontSize(16)
            .fontColor(this.isOpen ? '#00AA00' : '#333333')
            .fontWeight(FontWeight.Bold)
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#F5F5F5')
        .borderRadius(8)

        // Error message
        if (this.errorMessage !== '') {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF3333')
            .width('90%')
            .padding(10)
            .backgroundColor('#FFEEEE')
            .borderRadius(5)
        }

        // File path input section
        Column({ space: 10 }) {
          Text('File Path')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .alignSelf(ItemAlign.Start)

          TextInput({ text: this.filePath })
            .onChange((value: string) => {
              this.filePath = value;
            })
            .width('100%')
            .fontSize(14)

          // Sample paths
          Text('Sample Paths:')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ top: 5 })

          Button('Use /data path')
            .onClick(() => this.loadSamplePath('/data/storage/el2/base/haps/entry/files/test.mp4'))
            .fontSize(12)
            .height(35)
            .backgroundColor('#E0E0E0')
            .fontColor('#333333')

          Button('Use /sdcard path')
            .onClick(() => this.loadSamplePath('/sdcard/Movies/test.mp4'))
            .fontSize(12)
            .height(35)
            .backgroundColor('#E0E0E0')
            .fontColor('#333333')
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)

        // Action buttons
        Row({ space: 10 }) {
          Button('Open & Extract')
            .onClick(() => this.openAndExtractMetadata())
            .fontSize(16)
            .height(45)
            .layoutWeight(1)
            .backgroundColor('#007AFF')
            .enabled(!this.isOpen)

          Button('Close')
            .onClick(() => this.closeFile())
            .fontSize(16)
            .height(45)
            .layoutWeight(1)
            .backgroundColor('#FF3B30')
            .enabled(this.isOpen)
        }
        .width('90%')

        // Metadata display
        if (Object.keys(this.metadata).length > 0) {
          Column({ space: 8 }) {
            Text(`Metadata (${Object.keys(this.metadata).length} entries)`)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 10 })

            ForEach(Object.keys(this.metadata), (key: string) => {
              Row() {
                Text(key + ':')
                  .fontSize(14)
                  .fontWeight(FontWeight.Medium)
                  .width('40%')
                  .fontColor('#333333')

                Text(this.metadata[key])
                  .fontSize(14)
                  .width('60%')
                  .fontColor('#666666')
              }
              .width('100%')
              .padding({ left: 10, right: 10, top: 8, bottom: 8 })
              .backgroundColor('#F9F9F9')
              .borderRadius(5)
            })
          }
          .width('90%')
          .padding(15)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .border({ width: 1, color: '#DDDDDD' })
        }

        // Instructions
        Column({ space: 8 }) {
          Text('Instructions:')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)

          Text('1. Enter the path to an MP4 file on your device')
            .fontSize(13)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('2. Click "Open & Extract" to load the file and get metadata')
            .fontSize(13)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('3. View the extracted metadata below')
            .fontSize(13)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('4. Click "Close" to release resources when done')
            .fontSize(13)
            .fontColor('#666666')
            .textAlign(TextAlign.Start)
            .width('100%')

          Text('Note: Make sure the MP4 file exists at the specified path')
            .fontSize(12)
            .fontColor('#FF9500')
            .margin({ top: 10 })
            .textAlign(TextAlign.Start)
            .width('100%')
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#F0F8FF')
        .borderRadius(8)
        .margin({ bottom: 30 })

        // API Usage Example
        Column({ space: 8 }) {
          Text('Code Example:')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .alignSelf(ItemAlign.Start)

          Text('import { Libmp4 } from \'library\';\n\n' +
               'try {\n' +
               '  let mp4 = new Libmp4(\'/path/to/file.mp4\');\n' +
               '  let metadata = mp4.getMetadata();\n' +
               '  console.log(metadata);\n' +
               '  mp4.close();\n' +
               '} catch (err) {\n' +
               '  console.error(err.message);\n' +
               '}')
            .fontSize(12)
            .fontColor('#333333')
            .fontFamily('monospace')
            .backgroundColor('#F5F5F5')
            .padding(10)
            .borderRadius(5)
            .width('100%')
        }
        .width('90%')
        .padding(15)
        .backgroundColor('#FAFAFA')
        .borderRadius(8)
        .margin({ bottom: 20 })
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}