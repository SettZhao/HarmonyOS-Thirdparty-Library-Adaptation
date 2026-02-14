/**
 * KCP - A Fast and Reliable ARQ Protocol
 * OpenHarmony Port of node-kcp
 */

import {
  kcpCreate,
  kcpRelease,
  kcpRecv,
  kcpSend,
  kcpInput,
  kcpUpdate,
  kcpCheck,
  kcpFlush,
  kcpPeeksize,
  kcpSetmtu,
  kcpWndsize,
  kcpWaitsnd,
  kcpNodelay,
  kcpSetStream,
  kcpSetContext,
  kcpGetContext,
  kcpSetOutputCallback
} from 'libkcp.so';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';

const LOG_TAG = 'KCP';

/**
 * Context information for KCP (e.g., remote address and port)
 */
export interface KCPContext {
  address?: string;
  port?: number;
}

/**
 * Output callback type
 * Called when KCP needs to send data to the network
 */
export type OutputCallback = (data: ArrayBuffer, size: number, context?: KCPContext) => void;

/**
 * KCP Protocol Class
 * Provides reliable transmission over UDP
 */
export class KCP {
  private handle: number = 0;
  private outputCallback?: OutputCallback;
  private context?: KCPContext;
  private released: boolean = false;

  /**
   * Creates a new KCP instance
   * @param conv - Conversation ID (must be the same on both ends)
   * @param context - Optional context information (e.g., remote address)
   */
  constructor(conv: number, context?: KCPContext) {
    this.handle = kcpCreate(conv);
    this.context = context;

    if (context) {
      kcpSetContext(this.handle, JSON.stringify(context));
    }

    // Set up internal output callback bridge
    this.setupOutputBridge();

    hilog.info(0x0000, LOG_TAG, `KCP instance created, conv=${conv}`);
  }

  /**
   * Sets up the output callback bridge to native code
   * This is an internal method - DO NOT expose to external users
   */
  private setupOutputBridge(): void {
    try {
      kcpSetOutputCallback(this.handle, (data: ArrayBuffer, size: number, contextStr: string) => {
        if (this.outputCallback) {
          try {
            const ctx = contextStr ? JSON.parse(contextStr) as KCPContext : this.context;
            this.outputCallback(data, size, ctx);
          } catch (err) {
            const error = err as Error;
            hilog.error(0x0000, LOG_TAG, `Output callback error: ${error.message}`);
          }
        }
      });
    } catch (err) {
      const error = err as Error;
      hilog.warn(0x0000, LOG_TAG, `Failed to setup output bridge: ${error.message}`);
    }
  }

  /**
   * Sets the output callback
   * This callback is called when KCP needs to send data to the network
   * @param callback - Output callback function
   */
  output(callback: OutputCallback): void {
    this.outputCallback = callback;
  }

  /**
   * Gets the context information
   * @returns Context object
   */
  getContext(): KCPContext | undefined {
    return this.context;
  }

  /**
   * Receives data from KCP
   * @returns Received data or null if no data available
   */
  recv(): ArrayBuffer | null {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    return kcpRecv(this.handle);
  }

  /**
   * Sends data through KCP
   * @param data - Data to send (ArrayBuffer or string)
   * @returns 0 on success, negative on error
   */
  send(data: ArrayBuffer | string): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }

    let buffer: ArrayBuffer;
    if (typeof data === 'string') {
      const encoder = new util.TextEncoder();
      buffer = encoder.encode(data);
    } else {
      buffer = data;
    }

    return kcpSend(this.handle, buffer);
  }

  /**
   * Inputs data received from network
   * @param data - Network data (ArrayBuffer or string)
   * @returns 0 on success, negative on error
   */
  input(data: ArrayBuffer | string): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }

    let buffer: ArrayBuffer;
    if (typeof data === 'string') {
      const encoder = new util.TextEncoder();
      buffer = encoder.encode(data);
    } else {
      buffer = data;
    }

    return kcpInput(this.handle, buffer);
  }

  /**
   * Updates KCP state (should be called periodically)
   * @param current - Current timestamp in milliseconds (default: Date.now())
   */
  update(current?: number): void {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    const timestamp = current !== undefined ? current : Date.now();
    kcpUpdate(this.handle, timestamp);
  }

  /**
   * Checks when the next update should be called
   * @param current - Current timestamp in milliseconds (default: Date.now())
   * @returns Milliseconds until next update
   */
  check(current?: number): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    const timestamp = current !== undefined ? current : Date.now();
    return kcpCheck(this.handle, timestamp);
  }

  /**
   * Flushes pending data immediately
   */
  flush(): void {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    kcpFlush(this.handle);
  }

  /**
   * Peeks the size of the next message
   * @returns Size in bytes, or negative if no data
   */
  peeksize(): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    return kcpPeeksize(this.handle);
  }

  /**
   * Sets MTU (Maximum Transmission Unit)
   * @param mtu - MTU size (default: 1400)
   * @returns 0 on success, negative on error
   */
  setmtu(mtu: number = 1400): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    return kcpSetmtu(this.handle, mtu);
  }

  /**
   * Sets window size
   * @param sndwnd - Send window size (default: 32)
   * @param rcvwnd - Receive window size (default: 32)
   * @returns 0 on success, negative on error
   */
  wndsize(sndwnd: number = 32, rcvwnd: number = 32): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    return kcpWndsize(this.handle, sndwnd, rcvwnd);
  }

  /**
   * Gets the number of packets waiting to send
   * @returns Number of waiting packets
   */
  waitsnd(): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    return kcpWaitsnd(this.handle);
  }

  /**
   * Configures fast mode parameters
   * @param nodelay - 0: disable (default), 1: enable
   * @param interval - Internal update interval in ms (default: 100)
   * @param resend - 0: disable fast resend, 1: enable (default: 0)
   * @param nc - 0: normal congestion control, 1: disable (default: 0)
   * @returns 0 on success, negative on error
   */
  nodelay(nodelay: number = 0, interval: number = 100, resend: number = 0, nc: number = 0): number {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    return kcpNodelay(this.handle, nodelay, interval, resend, nc);
  }

  /**
   * Sets stream mode
   * @param stream - 0: message mode (default), 1: stream mode
   */
  stream(stream: number): void {
    if (this.released) {
      throw new Error('KCP instance has been released');
    }
    kcpSetStream(this.handle, stream);
  }

  /**
   * Releases the KCP instance
   * Must be called when done to free native resources
   */
  release(): void {
    if (!this.released) {
      kcpRelease(this.handle);
      this.released = true;
      this.handle = 0;
      this.outputCallback = undefined;
      hilog.info(0x0000, LOG_TAG, 'KCP instance released');
    }
  }
}
