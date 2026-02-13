/**
 * @file index.d.ts
 * @brief TypeScript declarations for libmp4 native module
 * Native functions exported by libmp4.so
 */

/**
 * Opens an MP4 file for demuxing
 * @param fileName - Path to the MP4 file
 * @returns Demux handle (pointer as number), throws on error
 * @example
 * ```ts
 * import { mp4DemuxOpen } from 'libmp4.so';
 * const demux = mp4DemuxOpen('/path/to/file.mp4');
 * ```
 */
export const mp4DemuxOpen: (fileName: string) => number;

/**
 * Closes an MP4 demuxer and releases resources
 * @param demux - Demux handle returned by mp4DemuxOpen
 * @returns 0 on success, non-zero on error
 * @example
 * ```ts
 * import { mp4DemuxClose } from 'libmp4.so';
 * mp4DemuxClose(demux);
 * ```
 */
export const mp4DemuxClose: (demux: number) => number;

/**
 * Gets metadata from an opened MP4 file
 * @param demux - Demux handle returned by mp4DemuxOpen
 * @returns Object containing metadata key-value pairs (e.g., title, artist, album)
 * @example
 * ```ts
 * import { mp4DemuxGetMetadata } from 'libmp4.so';
 * const metadata = mp4DemuxGetMetadata(demux);
 * console.log(metadata['title']);
 * ```
 */
export const mp4DemuxGetMetadata: (demux: number) => Record<string, string>;
