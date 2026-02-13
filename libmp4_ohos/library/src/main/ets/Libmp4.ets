/**
 * @file Libmp4.ets
 * @brief ArkTS wrapper for libmp4 native module
 * Provides high-level API for MP4 demuxing, replacing Android's Libmp4.java
 */

import { mp4DemuxOpen, mp4DemuxClose, mp4DemuxGetMetadata } from 'libmp4.so';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'Libmp4';
const LOG_DOMAIN = 0x0001;

/**
 * MP4 Demuxer class
 * Usage:
 *   let mp4 = new Libmp4('/path/to/file.mp4');
 *   let metadata = mp4.getMetadata();
 *   mp4.close();
 */
export class Libmp4 {
  private demuxHandle: number = 0;
  private filePath: string = '';

  /**
   * Opens an MP4 file for demuxing
   * @param fileName - Path to MP4 file
   * @throws Error if file cannot be opened
   */
  constructor(fileName: string) {
    if (!fileName || fileName.length === 0) {
      throw new Error('fileName cannot be empty');
    }

    this.filePath = fileName;
    
    try {
      this.demuxHandle = mp4DemuxOpen(fileName);
      
      if (this.demuxHandle === 0) {
        throw new Error(`Cannot open file: ${fileName}`);
      }
      
      hilog.info(LOG_DOMAIN, LOG_TAG, `Opened MP4 file: ${fileName}`);
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to open MP4 file: ${error}`);
      throw new Error(`Cannot open file ${fileName}: ${error}`);
    }
  }

  /**
   * Gets metadata from the MP4 file
   * @returns Object with metadata key-value pairs
   */
  getMetadata(): Record<string, string> {
    if (this.demuxHandle === 0) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'Demux handle is null, returning empty metadata');
      return {};
    }

    try {
      const metadata = mp4DemuxGetMetadata(this.demuxHandle);
      
      if (metadata) {
        hilog.info(LOG_DOMAIN, LOG_TAG, `Retrieved ${Object.keys(metadata).length} metadata entries`);
        return metadata;
      } else {
        hilog.warn(LOG_DOMAIN, LOG_TAG, 'No metadata found');
        return {};
      }
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to get metadata: ${error}`);
      return {};
    }
  }

  /**
   * Closes the MP4 demuxer and releases resources
   * @throws Error if close operation fails
   */
  close(): void {
    if (this.demuxHandle === 0) {
      return;
    }

    try {
      const ret = mp4DemuxClose(this.demuxHandle);
      
      if (ret !== 0) {
        hilog.warn(LOG_DOMAIN, LOG_TAG, `Close returned non-zero: ${ret}`);
      }
      
      hilog.info(LOG_DOMAIN, LOG_TAG, `Closed MP4 file: ${this.filePath}`);
      this.demuxHandle = 0;
    } catch (error) {
      hilog.error(LOG_DOMAIN, LOG_TAG, `Failed to close demuxer: ${error}`);
      this.demuxHandle = 0;
      throw new Error(`Failed to close demuxer: ${error}`);
    }
  }

  /**
   * Returns whether the demuxer is currently open
   */
  isOpen(): boolean {
    return this.demuxHandle !== 0;
  }

  /**
   * Gets the file path of the opened MP4 file
   */
  getFilePath(): string {
    return this.filePath;
  }
}
