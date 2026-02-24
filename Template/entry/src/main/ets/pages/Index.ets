/**
 * Index.ets — StackBlur Demo Page
 *
 * Demonstrates:
 *   1. Creating a PixelMap from an in-memory 200x200 RGBA gradient
 *   2. Blurring it with the ArkTS path (process)
 *   3. Blurring it with the Native/NAPI path (processNatively)
 *   4. Displaying original, ArkTS blurred, and Native blurred side-by-side
 */

import { StackBlurManager } from 'library';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';


/**
 * Create a 200×200 RGBA_8888 PixelMap with a simple colour gradient for testing.
 * Top-left is red, top-right is green, bottom is blue.
 */
async function createTestPixelMap(): Promise<image.PixelMap> {
  const w = 200;
  const h = 200;
  const buf = new ArrayBuffer(w * h * 4);
  const data = new Uint8Array(buf);
  for (let y = 0; y < h; y++) {
    for (let x = 0; x < w; x++) {
      const idx = (y * w + x) * 4;
      data[idx]     = Math.floor(255 * x / w);          // R
      data[idx + 1] = Math.floor(255 * y / h);          // G
      data[idx + 2] = Math.floor(255 * (1 - x / w));    // B
      data[idx + 3] = 255;                               // A
    }
  }
  return image.createPixelMap(buf, {
    size: { width: w, height: h },
    pixelFormat: image.PixelMapFormat.RGBA_8888
  });
}

@Entry
@Component
struct Index {
  @State originalPixelMap: image.PixelMap | null = null;
  @State arktsBlurredPixelMap: image.PixelMap | null = null;
  @State nativeBlurredPixelMap: image.PixelMap | null = null;
  @State radius: number = 15;
  @State statusMsg: string = 'Tap "Create & Blur" to start';
  @State isProcessing: boolean = false;

  private manager: StackBlurManager | null = null;

  async onCreateAndBlur(): Promise<void> {
    if (this.isProcessing) return;
    this.isProcessing = true;
    this.statusMsg = 'Creating test PixelMap...';

    try {
      // -----------------------------------------------------------------------
      // Diagnostic: verify whether createPixelMap(RGBA_8888) swaps R↔B channels.
      // We write a single pixel with known RGBA = [255, 0, 0, 255] (pure red).
      // If readback gives [0, 0, 255, 255] then createPixelMap swapped R↔B.
      // If readback gives [255, 0, 0, 255] then no swap happened.
      const diagBuf = new ArrayBuffer(4);
      new Uint8Array(diagBuf).set([255, 0, 0, 255]); // pure red RGBA
      const diagPm = await image.createPixelMap(diagBuf, {
        size: { width: 1, height: 1 },
        pixelFormat: image.PixelMapFormat.BGRA_8888
      });
      const diagOut = new ArrayBuffer(4);
      await diagPm.readPixelsToBuffer(diagOut);
      const diagBytes = new Uint8Array(diagOut);
      console.log(`[DiagSwap] input [255,0,0,255] → readback [${diagBytes[0]},${diagBytes[1]},${diagBytes[2]},${diagBytes[3]}]`);
      // -----------------------------------------------------------------------

      // const pm = await createTestPixelMap();
      const resourceMgr: resourceManager.ResourceManager | undefined = this.getUIContext().getHostContext()?.resourceManager;
      let rawFileDescriptor = await resourceMgr?.getRawFd('startIcon.png');
      const imageSourceObj: image.ImageSource = image.createImageSource(rawFileDescriptor);

      const pm = await imageSourceObj.createPixelMap({
        desiredPixelFormat: image.PixelMapFormat.BGRA_8888
      })
      this.originalPixelMap = pm;
      this.manager = new StackBlurManager(pm);

      this.statusMsg = `Blurring with ArkTS path (radius=${this.radius})...`;
      const arktsResult = await this.manager.process(this.radius);
      this.arktsBlurredPixelMap = arktsResult;

      this.statusMsg = `Blurring with Native path (radius=${this.radius})...`;
      // Create a fresh manager (same original) for native path
      const manager2 = new StackBlurManager(pm);
      const nativeResult = await manager2.processNatively(this.radius);
      this.nativeBlurredPixelMap = nativeResult;

      this.statusMsg = `Done! radius=${this.radius}`;
    } catch (err) {
      const errMsg: string = err instanceof Error ? err.message : String(err);
      this.statusMsg = `Error: ${errMsg}`;
      console.log("test error: ", err.message, JSON.stringify(err))
    } finally {
      this.isProcessing = false;
    }
  }

  build() {
    Scroll() {
      Column({ space: 16 }) {
        Text('StackBlur Demo')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 24 })

        // Radius slider
        Row({ space: 12 }) {
          Text('Radius:').fontSize(16).width(60)
          Slider({
            value: this.radius,
            min: 1,
            max: 50,
            step: 1,
            style: SliderStyle.OutSet
          })
            .width('65%')
            .onChange((value: number) => {
              this.radius = Math.round(value);
            })
          Text(`${this.radius}`)
            .fontSize(16)
            .width(30)
        }
        .width('90%')

        // Create & Blur button
        Button(this.isProcessing ? 'Processing...' : 'Create & Blur')
          .width('70%')
          .onClick(() => {
            this.onCreateAndBlur();
          })
          .enabled(!this.isProcessing)

        // Status message
        Text(this.statusMsg)
          .fontSize(13)
          .fontColor(Color.Gray)
          .textAlign(TextAlign.Center)
          .width('90%')

        Divider()

        // Images row
        Row({ space: 12 }) {
          Column({ space: 6 }) {
            Text('Original').fontSize(12).fontColor(Color.Gray)
            if (this.originalPixelMap !== null) {
              Image(this.originalPixelMap)
                .width(100)
                .height(100)
                .objectFit(ImageFit.Fill)
                .border({ width: 1, color: '#CCCCCC' })
            } else {
              Column()
                .width(100)
                .height(100)
                .backgroundColor('#F0F0F0')
                .border({ width: 1, color: '#CCCCCC' })
            }
          }

          Column({ space: 6 }) {
            Text('ArkTS Blur').fontSize(12).fontColor(Color.Gray)
            if (this.arktsBlurredPixelMap !== null) {
              Image(this.arktsBlurredPixelMap)
                .width(100)
                .height(100)
                .objectFit(ImageFit.Fill)
                .border({ width: 1, color: '#CCCCCC' })
            } else {
              Column()
                .width(100)
                .height(100)
                .backgroundColor('#F0F0F0')
                .border({ width: 1, color: '#CCCCCC' })
            }
          }

          Column({ space: 6 }) {
            Text('Native Blur').fontSize(12).fontColor(Color.Gray)
            if (this.nativeBlurredPixelMap !== null) {
              Image(this.nativeBlurredPixelMap)
                .width(100)
                .height(100)
                .objectFit(ImageFit.Fill)
                .border({ width: 1, color: '#CCCCCC' })
            } else {
              Column()
                .width(100)
                .height(100)
                .backgroundColor('#F0F0F0')
                .border({ width: 1, color: '#CCCCCC' })
            }
          }
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ bottom: 32 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .height('100%')
    .width('100%')
  }
}
