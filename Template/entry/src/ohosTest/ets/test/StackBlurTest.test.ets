/**
 * StackBlurTest.test.ets
 *
 * Instrument test suite for StackBlurManager (TC-001 ~ TC-011).
 * Runs on a real device or emulator via `hvigorw test`.
 */

import { describe, it, expect, beforeAll } from '@ohos/hypium';
import { StackBlurManager } from 'library';
import { image } from '@kit.ImageKit';

/** Create a solid white 200×200 RGBA_8888 PixelMap for testing. */
async function createWhitePixelMap(): Promise<image.PixelMap> {
  const w = 200;
  const h = 200;
  const buf = new ArrayBuffer(w * h * 4);
  const data = new Uint8Array(buf);
  data.fill(255); // all white, full alpha
  return image.createPixelMap(buf, {
    size: { width: w, height: h },
    pixelFormat: image.PixelMapFormat.RGBA_8888
  });
}

export default function stackBlurTest() {
  describe('StackBlurTest', () => {
    let whitePm: image.PixelMap;

    beforeAll(async () => {
      whitePm = await createWhitePixelMap();
    });

    /**
     * TC-001: process() with normal radius returns a valid PixelMap of the same size.
     */
    it('TC-001_process_normalRadius', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      const result = await manager.process(10);
      expect(result).not().assertNull();
      const info = result.getImageInfoSync();
      expect(info.size.width).assertEqual(200);
      expect(info.size.height).assertEqual(200);
    });

    /**
     * TC-002: process() with minimum valid radius (1) succeeds.
     */
    it('TC-002_process_minRadius', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      const result = await manager.process(1);
      expect(result).not().assertNull();
    });

    /**
     * TC-003: process() with maximum valid radius (254) succeeds.
     */
    it('TC-003_process_maxValidRadius', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      const result = await manager.process(254);
      expect(result).not().assertNull();
    });

    /**
     * TC-004: process() with radius=0 rejects with INVALID_RADIUS.
     */
    it('TC-004_process_zeroRadius_reject', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      let caught: string = '';
      try {
        await manager.process(0);
      } catch (err) {
        caught = (err as Error).message;
      }
      expect(caught).assertEqual('INVALID_RADIUS');
    });

    /**
     * TC-005: process() with radius=255 rejects with INVALID_RADIUS.
     */
    it('TC-005_process_255Radius_reject', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      let caught: string = '';
      try {
        await manager.process(255);
      } catch (err) {
        caught = (err as Error).message;
      }
      expect(caught).assertEqual('INVALID_RADIUS');
    });

    /**
     * TC-006: processNatively() with normal radius returns a valid PixelMap of same size.
     */
    it('TC-006_processNatively_normalRadius', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      const result = await manager.processNatively(10);
      expect(result).not().assertNull();
      const info = result.getImageInfoSync();
      expect(info.size.width).assertEqual(200);
      expect(info.size.height).assertEqual(200);
    });

    /**
     * TC-007: processNatively() with radius=0 rejects with INVALID_RADIUS.
     */
    it('TC-007_processNatively_zeroRadius_reject', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      let caught: string = '';
      try {
        await manager.processNatively(0);
      } catch (err) {
        caught = (err as Error).message;
      }
      expect(caught).assertEqual('INVALID_RADIUS');
    });

    /**
     * TC-008: returnBlurredImage() returns non-null after process().
     */
    it('TC-008_returnBlurredImage_afterProcess', 0, async () => {
      const manager = new StackBlurManager(whitePm);
      await manager.process(10);
      const blurred = manager.returnBlurredImage();
      expect(blurred).not().assertNull();
    });

    /**
     * TC-009: returnBlurredImage() returns null before process().
     */
    it('TC-009_returnBlurredImage_beforeProcess', 0, () => {
      const manager = new StackBlurManager(whitePm);
      const blurred = manager.returnBlurredImage();
      expect(blurred).assertNull();
    });

    /**
     * TC-010: getImage() returns the same PixelMap passed to the constructor.
     */
    it('TC-010_getImage_returnsSameObject', 0, () => {
      const manager = new StackBlurManager(whitePm);
      const img = manager.getImage();
      expect(img).assertEqual(whitePm);
    });

    /**
     * TC-011: process() and processNatively() produce same-sized results.
     */
    it('TC-011_arktsAndNative_sameSizeResult', 0, async () => {
      const manager1 = new StackBlurManager(whitePm);
      const manager2 = new StackBlurManager(whitePm);
      const arktsResult = await manager1.process(15);
      const nativeResult = await manager2.processNatively(15);

      const info1 = arktsResult.getImageInfoSync();
      const info2 = nativeResult.getImageInfoSync();
      expect(info1.size.width).assertEqual(info2.size.width);
      expect(info1.size.height).assertEqual(info2.size.height);
    });
  });
}
