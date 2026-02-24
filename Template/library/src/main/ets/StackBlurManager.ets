/**
 * StackBlurManager.ets
 *
 * HarmonyOS port of android-stackblur (Apache License 2.0)
 * Original algorithm by Mario Klingemann <mario@quasimondo.com>
 * Original Android library by Enrique López Mañas <eenriquelopez@gmail.com>
 *
 * Provides two blur paths:
 *   - process()         : pure ArkTS implementation (CPU, single-threaded)
 *   - processNatively() : NAPI → C implementation (libblur.so, faster for large images)
 */

import { image } from '@kit.ImageKit';
import { nativeBlur } from 'libblur.so';

// ---------------------------------------------------------------------------
// Lookup tables — identical to Android JavaBlurProcess and blur_core.c
// ---------------------------------------------------------------------------
const STACKBLUR_MUL: number[] = [
  512, 512, 456, 512, 328, 456, 335, 512, 405, 328, 271, 456, 388, 335, 292, 512,
  454, 405, 364, 328, 298, 271, 496, 456, 420, 388, 360, 335, 312, 292, 273, 512,
  482, 454, 428, 405, 383, 364, 345, 328, 312, 298, 284, 271, 259, 496, 475, 456,
  437, 420, 404, 388, 374, 360, 347, 335, 323, 312, 302, 292, 282, 273, 265, 512,
  497, 482, 468, 454, 441, 428, 417, 405, 394, 383, 373, 364, 354, 345, 337, 328,
  320, 312, 305, 298, 291, 284, 278, 271, 265, 259, 507, 496, 485, 475, 465, 456,
  446, 437, 428, 420, 412, 404, 396, 388, 381, 374, 367, 360, 354, 347, 341, 335,
  329, 323, 318, 312, 307, 302, 297, 292, 287, 282, 278, 273, 269, 265, 261, 512,
  505, 497, 489, 482, 475, 468, 461, 454, 447, 441, 435, 428, 422, 417, 411, 405,
  399, 394, 389, 383, 378, 373, 368, 364, 359, 354, 350, 345, 341, 337, 332, 328,
  324, 320, 316, 312, 309, 305, 301, 298, 294, 291, 287, 284, 281, 278, 274, 271,
  268, 265, 262, 259, 257, 507, 501, 496, 491, 485, 480, 475, 470, 465, 460, 456,
  451, 446, 442, 437, 433, 428, 424, 420, 416, 412, 408, 404, 400, 396, 392, 388,
  385, 381, 377, 374, 370, 367, 363, 360, 357, 354, 350, 347, 344, 341, 338, 335,
  332, 329, 326, 323, 320, 318, 315, 312, 310, 307, 304, 302, 299, 297, 294, 292,
  289, 287, 285, 282, 280, 278, 275, 273, 271, 269, 267, 265, 263, 261, 259
];

const STACKBLUR_SHR: number[] = [
  9, 11, 12, 13, 13, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 17,
  17, 17, 17, 17, 17, 17, 18, 18, 18, 18, 18, 18, 18, 18, 18, 19,
  19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 19, 20, 20, 20,
  20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 20, 21,
  21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 21,
  21, 21, 21, 21, 21, 21, 21, 21, 21, 21, 22, 22, 22, 22, 22, 22,
  22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22,
  22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 22, 23,
  23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
  23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
  23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23, 23,
  23, 23, 23, 23, 23, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24,
  24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24, 24
];

// ---------------------------------------------------------------------------
// Internal ArkTS Stack Blur algorithm
// Translates JavaBlurProcess.blurIteration() to ArkTS using RGBA Uint8Array
// ---------------------------------------------------------------------------

/**
 * One pass of the stack blur algorithm over src (in-place, RGBA_8888 format).
 * step=1 → horizontal pass, step=2 → vertical pass.
 */
function stackBlurJobArkTS(
  src: Uint8Array,
  w: number,
  h: number,
  radius: number,
  cores: number,
  core: number,
  step: number
): void {
  const wm = w - 1;
  const hm = h - 1;
  const w4 = w * 4; // bytes per row
  const div = (radius * 2) + 1;
  const mulSum = STACKBLUR_MUL[radius];
  const shrSum = STACKBLUR_SHR[radius];

  // stack stores R,G,B for each of the div window positions
  const stack = new Uint8Array(div * 3);

  if (step === 1) {
    const minY = Math.floor(core * h / cores);
    const maxY = Math.floor((core + 1) * h / cores);

    for (let y = minY; y < maxY; y++) {
      let sumR = 0, sumG = 0, sumB = 0;
      let sumInR = 0, sumInG = 0, sumInB = 0;
      let sumOutR = 0, sumOutG = 0, sumOutB = 0;

      let srcIdx = w4 * y; // start of row (0, y) in bytes

      for (let i = 0; i <= radius; i++) {
        const si = i * 3;
        stack[si]     = src[srcIdx];
        stack[si + 1] = src[srcIdx + 1];
        stack[si + 2] = src[srcIdx + 2];
        sumR += src[srcIdx]     * (i + 1);
        sumG += src[srcIdx + 1] * (i + 1);
        sumB += src[srcIdx + 2] * (i + 1);
        sumOutR += src[srcIdx];
        sumOutG += src[srcIdx + 1];
        sumOutB += src[srcIdx + 2];
      }

      for (let i = 1; i <= radius; i++) {
        if (i <= wm) srcIdx += 4;
        const si = (i + radius) * 3;
        stack[si]     = src[srcIdx];
        stack[si + 1] = src[srcIdx + 1];
        stack[si + 2] = src[srcIdx + 2];
        sumR += src[srcIdx]     * (radius + 1 - i);
        sumG += src[srcIdx + 1] * (radius + 1 - i);
        sumB += src[srcIdx + 2] * (radius + 1 - i);
        sumInR += src[srcIdx];
        sumInG += src[srcIdx + 1];
        sumInB += src[srcIdx + 2];
      }

      let sp = radius;
      let xp = radius;
      if (xp > wm) xp = wm;
      srcIdx = 4 * (xp + y * w);
      let dstIdx = y * w4;

      for (let x = 0; x < w; x++) {
        const alpha = src[dstIdx + 3];
        src[dstIdx]     = Math.min((sumR * mulSum) >>> shrSum, alpha);
        src[dstIdx + 1] = Math.min((sumG * mulSum) >>> shrSum, alpha);
        src[dstIdx + 2] = Math.min((sumB * mulSum) >>> shrSum, alpha);
        dstIdx += 4;

        sumR -= sumOutR;
        sumG -= sumOutG;
        sumB -= sumOutB;

        let stackStart = sp + div - radius;
        if (stackStart >= div) stackStart -= div;
        const ssi = stackStart * 3;

        sumOutR -= stack[ssi];
        sumOutG -= stack[ssi + 1];
        sumOutB -= stack[ssi + 2];

        if (xp < wm) {
          srcIdx += 4;
          xp++;
        }

        stack[ssi]     = src[srcIdx];
        stack[ssi + 1] = src[srcIdx + 1];
        stack[ssi + 2] = src[srcIdx + 2];

        sumInR += src[srcIdx];
        sumInG += src[srcIdx + 1];
        sumInB += src[srcIdx + 2];
        sumR   += sumInR;
        sumG   += sumInG;
        sumB   += sumInB;

        sp++;
        if (sp >= div) sp = 0;
        const spsi = sp * 3;

        sumOutR += stack[spsi];
        sumOutG += stack[spsi + 1];
        sumOutB += stack[spsi + 2];
        sumInR  -= stack[spsi];
        sumInG  -= stack[spsi + 1];
        sumInB  -= stack[spsi + 2];
      }
    }
  } else if (step === 2) {
    const minX = Math.floor(core * w / cores);
    const maxX = Math.floor((core + 1) * w / cores);

    for (let x = minX; x < maxX; x++) {
      let sumR = 0, sumG = 0, sumB = 0;
      let sumInR = 0, sumInG = 0, sumInB = 0;
      let sumOutR = 0, sumOutG = 0, sumOutB = 0;

      let srcIdx = 4 * x; // (x, 0)

      for (let i = 0; i <= radius; i++) {
        const si = i * 3;
        stack[si]     = src[srcIdx];
        stack[si + 1] = src[srcIdx + 1];
        stack[si + 2] = src[srcIdx + 2];
        sumR     += src[srcIdx]     * (i + 1);
        sumG     += src[srcIdx + 1] * (i + 1);
        sumB     += src[srcIdx + 2] * (i + 1);
        sumOutR  += src[srcIdx];
        sumOutG  += src[srcIdx + 1];
        sumOutB  += src[srcIdx + 2];
      }

      for (let i = 1; i <= radius; i++) {
        if (i <= hm) srcIdx += w4;
        const si = (i + radius) * 3;
        stack[si]     = src[srcIdx];
        stack[si + 1] = src[srcIdx + 1];
        stack[si + 2] = src[srcIdx + 2];
        sumR   += src[srcIdx]     * (radius + 1 - i);
        sumG   += src[srcIdx + 1] * (radius + 1 - i);
        sumB   += src[srcIdx + 2] * (radius + 1 - i);
        sumInR += src[srcIdx];
        sumInG += src[srcIdx + 1];
        sumInB += src[srcIdx + 2];
      }

      let sp = radius;
      let yp = radius;
      if (yp > hm) yp = hm;
      srcIdx = 4 * (x + yp * w);
      let dstIdx = 4 * x;

      for (let y = 0; y < h; y++) {
        const alpha = src[dstIdx + 3];
        src[dstIdx]     = Math.min((sumR * mulSum) >>> shrSum, alpha);
        src[dstIdx + 1] = Math.min((sumG * mulSum) >>> shrSum, alpha);
        src[dstIdx + 2] = Math.min((sumB * mulSum) >>> shrSum, alpha);
        dstIdx += w4;

        sumR -= sumOutR;
        sumG -= sumOutG;
        sumB -= sumOutB;

        let stackStart = sp + div - radius;
        if (stackStart >= div) stackStart -= div;
        const ssi = stackStart * 3;

        sumOutR -= stack[ssi];
        sumOutG -= stack[ssi + 1];
        sumOutB -= stack[ssi + 2];

        if (yp < hm) {
          srcIdx += w4;
          yp++;
        }

        stack[ssi]     = src[srcIdx];
        stack[ssi + 1] = src[srcIdx + 1];
        stack[ssi + 2] = src[srcIdx + 2];

        sumInR += src[srcIdx];
        sumInG += src[srcIdx + 1];
        sumInB += src[srcIdx + 2];
        sumR   += sumInR;
        sumG   += sumInG;
        sumB   += sumInB;

        sp++;
        if (sp >= div) sp = 0;
        const spsi = sp * 3;

        sumOutR += stack[spsi];
        sumOutG += stack[spsi + 1];
        sumOutB += stack[spsi + 2];
        sumInR  -= stack[spsi];
        sumInG  -= stack[spsi + 1];
        sumInB  -= stack[spsi + 2];
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Public class
// ---------------------------------------------------------------------------

/**
 * StackBlurManager
 *
 * HarmonyOS port of android-stackblur's StackBlurManager.
 *
 * Usage:
 *   const manager = new StackBlurManager(pixelMap);
 *   const blurred = await manager.process(15);
 *   // or
 *   const blurredNative = await manager.processNatively(15);
 */
export class StackBlurManager {
  private readonly _pixelMap: image.PixelMap;
  private _result: image.PixelMap | null = null;

  /**
   * @param pixelMap Original image to be blurred. The original is never modified.
   */
  constructor(pixelMap: image.PixelMap) {
    this._pixelMap = pixelMap;
  }

  /**
   * Blur using pure ArkTS Stack Blur implementation (CPU, single-threaded).
   * @param radius  Blur radius in pixels. Must be in [1, 254].
   * @returns Promise that resolves to a new blurred PixelMap of the same dimensions.
   */
  async process(radius: number): Promise<image.PixelMap> {
    if (radius < 1 || radius > 254) {
      return Promise.reject(new Error(`INVALID_RADIUS: ${radius} must be in [1, 254]`));
    }

    const info = this._pixelMap.getImageInfoSync();
    const w = info.size.width;
    const h = info.size.height;

    const buf = new ArrayBuffer(w * h * 4);
    await this._pixelMap.readPixelsToBuffer(buf);

    // readPixelsToBuffer gives correct RGBA bytes.
    // Blur operates on them correctly.
    const src = new Uint8Array(buf);
    stackBlurJobArkTS(src, w, h, radius, 1, 0, 1); // horizontal pass
    stackBlurJobArkTS(src, w, h, radius, 1, 0, 2); // vertical pass

    const blurred = await image.createPixelMap(buf, {
      size: { width: w, height: h },
      pixelFormat: image.PixelMapFormat.RGBA_8888
    });

    this._result = blurred;
    return blurred;
  }

  /**
   * Blur using NAPI/C Stack Blur implementation (Native, faster for large images).
   * @param radius  Blur radius in pixels. Must be in [1, 254].
   * @returns Promise that resolves to a new blurred PixelMap of the same dimensions.
   */
  async processNatively(radius: number): Promise<image.PixelMap> {
    if (radius < 1 || radius > 254) {
      return Promise.reject(new Error(`INVALID_RADIUS: ${radius} must be in [1, 254]`));
    }

    const info = this._pixelMap.getImageInfoSync();
    const w = info.size.width;
    const h = info.size.height;

    const buf = new ArrayBuffer(w * h * 4);
    await this._pixelMap.readPixelsToBuffer(buf);

    // In-place modification by the native C layer
    nativeBlur(buf, w, h, radius);
    const blurred = await image.createPixelMap(buf, {
      size: { width: w, height: h },
      pixelFormat: image.PixelMapFormat.RGBA_8888
    });

    this._result = blurred;
    return blurred;
  }

  /**
   * Returns the most recent blur result, or null if no process() call has been made yet.
   */
  returnBlurredImage(): image.PixelMap | null {
    return this._result;
  }

  /**
   * Returns the original PixelMap passed to the constructor.
   */
  getImage(): image.PixelMap {
    return this._pixelMap;
  }
}
