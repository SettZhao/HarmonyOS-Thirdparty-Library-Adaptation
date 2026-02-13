/**
 * @file ExampleUsage.ets
 * @brief Example code demonstrating how to use the libmp4 library
 * 
 * This file shows various usage patterns for the Libmp4 class
 */

import { Libmp4 } from 'libmp4';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'Libmp4Example';

/**
 * Example 1: Basic usage with try-catch
 */
export function basicUsageExample(filePath: string) {
  try {
    // Open the MP4 file
    let mp4 = new Libmp4(filePath);
    
    // Get metadata
    let metadata = mp4.getMetadata();
    
    // Log all metadata keys
    hilog.info(0x0001, TAG, `Found ${Object.keys(metadata).length} metadata entries`);
    
    // Access specific metadata fields
    if (metadata['title']) {
      hilog.info(0x0001, TAG, `Title: ${metadata['title']}`);
    }
    if (metadata['artist']) {
      hilog.info(0x0001, TAG, `Artist: ${metadata['artist']}`);
    }
    if (metadata['album']) {
      hilog.info(0x0001, TAG, `Album: ${metadata['album']}`);
    }
    
    // Print all metadata
    for (let key in metadata) {
      hilog.info(0x0001, TAG, `  ${key}: ${metadata[key]}`);
    }
    
    // Always close when done
    mp4.close();
    
  } catch (error) {
    hilog.error(0x0001, TAG, `Error: ${error}`);
  }
}

/**
 * Example 2: Check if file is open before operations
 */
export function checkOpenExample(filePath: string) {
  let mp4: Libmp4 | null = null;
  
  try {
    mp4 = new Libmp4(filePath);
    
    if (mp4.isOpen()) {
      hilog.info(0x0001, TAG, `File is open: ${mp4.getFilePath()}`);
      
      let metadata = mp4.getMetadata();
      hilog.info(0x0001, TAG, `Metadata count: ${Object.keys(metadata).length}`);
    }
    
  } catch (error) {
    hilog.error(0x0001, TAG, `Failed to open file: ${error}`);
  } finally {
    // Clean up in finally block to ensure resources are released
    if (mp4 && mp4.isOpen()) {
      mp4.close();
      hilog.info(0x0001, TAG, 'File closed');
    }
  }
}

/**
 * Example 3: Process multiple files
 */
export function batchProcessExample(filePaths: string[]) {
  let results: Record<string, any> = {};
  
  for (let filePath of filePaths) {
    try {
      let mp4 = new Libmp4(filePath);
      let metadata = mp4.getMetadata();
      
      results[filePath] = {
        success: true,
        title: metadata['title'] || 'Unknown',
        artist: metadata['artist'] || 'Unknown',
        metadataCount: Object.keys(metadata).length
      };
      
      mp4.close();
      
    } catch (error) {
      results[filePath] = {
        success: false,
        error: error.toString()
      };
      hilog.error(0x0001, TAG, `Failed to process ${filePath}: ${error}`);
    }
  }
  
  return results;
}

/**
 * Example 4: Extract specific metadata fields with defaults
 */
export interface VideoMetadata {
  title: string;
  artist: string;
  album: string;
  year: string;
  genre: string;
  comment: string;
}

export function extractMetadata(filePath: string): VideoMetadata | null {
  try {
    let mp4 = new Libmp4(filePath);
    let metadata = mp4.getMetadata();
    
    // Extract common metadata fields with defaults
    let result: VideoMetadata = {
      title: metadata['title'] || metadata['©nam'] || 'Unknown Title',
      artist: metadata['artist'] || metadata['©ART'] || 'Unknown Artist',
      album: metadata['album'] || metadata['©alb'] || 'Unknown Album',
      year: metadata['year'] || metadata['©day'] || '',
      genre: metadata['genre'] || metadata['©gen'] || '',
      comment: metadata['comment'] || metadata['©cmt'] || ''
    };
    
    mp4.close();
    return result;
    
  } catch (error) {
    hilog.error(0x0001, TAG, `Metadata extraction failed: ${error}`);
    return null;
  }
}

/**
 * Example 5: Validate MP4 file
 */
export function validateMp4File(filePath: string): boolean {
  try {
    let mp4 = new Libmp4(filePath);
    let isValid = mp4.isOpen();
    mp4.close();
    return isValid;
  } catch (error) {
    return false;
  }
}

/**
 * Example 6: Get file info summary
 */
export interface Mp4FileInfo {
  filePath: string;
  isValid: boolean;
  hasMetadata: boolean;
  metadataCount: number;
  keys: string[];
}

export function getMp4FileInfo(filePath: string): Mp4FileInfo {
  let info: Mp4FileInfo = {
    filePath: filePath,
    isValid: false,
    hasMetadata: false,
    metadataCount: 0,
    keys: []
  };
  
  try {
    let mp4 = new Libmp4(filePath);
    info.isValid = true;
    
    let metadata = mp4.getMetadata();
    info.metadataCount = Object.keys(metadata).length;
    info.hasMetadata = info.metadataCount > 0;
    info.keys = Object.keys(metadata);
    
    mp4.close();
    
  } catch (error) {
    hilog.error(0x0001, TAG, `Failed to get file info: ${error}`);
  }
  
  return info;
}

/**
 * Example 7: Usage in a class/service
 */
export class Mp4MetadataService {
  private currentMp4: Libmp4 | null = null;
  
  openFile(filePath: string): boolean {
    try {
      this.closeCurrentFile();
      this.currentMp4 = new Libmp4(filePath);
      return true;
    } catch (error) {
      hilog.error(0x0001, TAG, `Failed to open: ${error}`);
      return false;
    }
  }
  
  getMetadata(): Record<string, string> {
    if (this.currentMp4 && this.currentMp4.isOpen()) {
      return this.currentMp4.getMetadata();
    }
    return {};
  }
  
  closeCurrentFile(): void {
    if (this.currentMp4 && this.currentMp4.isOpen()) {
      this.currentMp4.close();
      this.currentMp4 = null;
    }
  }
  
  isFileOpen(): boolean {
    return this.currentMp4 !== null && this.currentMp4.isOpen();
  }
}

/**
 * Example 8: Common metadata keys reference
 * 
 * MP4 files can contain various metadata keys. Here are some common ones:
 * 
 * Standard Keys:
 * - 'title' - Track title
 * - 'artist' - Artist/performer
 * - 'album' - Album name
 * - 'year' - Release year
 * - 'genre' - Music genre
 * - 'comment' - Comments
 * - 'track' - Track number
 * 
 * iTunes-style Keys (©xxx format):
 * - '©nam' - Title
 * - '©ART' - Artist
 * - '©alb' - Album
 * - '©day' - Year
 * - '©gen' - Genre
 * - '©cmt' - Comment
 * - 'trkn' - Track number
 */
export const COMMON_METADATA_KEYS = {
  TITLE: ['title', '©nam'],
  ARTIST: ['artist', '©ART'],
  ALBUM: ['album', '©alb'],
  YEAR: ['year', '©day'],
  GENRE: ['genre', '©gen'],
  COMMENT: ['comment', '©cmt']
};

export function getMetadataValue(metadata: Record<string, string>, ...possibleKeys: string[]): string | null {
  for (let key of possibleKeys) {
    if (metadata[key]) {
      return metadata[key];
    }
  }
  return null;
}
