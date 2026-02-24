/**
 * nativeBlur - Apply Stack Blur algorithm in-place to RGBA_8888 pixel data.
 * @param buffer  ArrayBuffer containing raw RGBA_8888 pixel data (width * height * 4 bytes)
 * @param width   Image width in pixels
 * @param height  Image height in pixels
 * @param radius  Blur radius, must be in [1, 254]
 */
export const nativeBlur: (buffer: ArrayBuffer, width: number, height: number, radius: number) => void;
