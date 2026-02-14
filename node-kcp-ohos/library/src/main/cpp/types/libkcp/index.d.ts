/**
 * KCP Native Module Type Definitions
 * Ported from node-kcp
 */

/**
 * Creates a new KCP instance
 * @param conv - Conversation ID (must be unique)
 * @returns KCP handle (pointer as number)
 */
export const kcpCreate: (conv: number) => number;

/**
 * Releases a KCP instance
 * @param kcp - KCP handle
 */
export const kcpRelease: (kcp: number) => void;

/**
 * Receives data from KCP
 * @param kcp - KCP handle
 * @returns Received data as ArrayBuffer
 */
export const kcpRecv: (kcp: number) => ArrayBuffer | null;

/**
 * Sends data through KCP
 * @param kcp - KCP handle
 * @param data - Data to send (ArrayBuffer)
 * @returns 0 on success, negative on error
 */
export const kcpSend: (kcp: number, data: ArrayBuffer) => number;

/**
 * Inputs data received from network
 * @param kcp - KCP handle
 * @param data - Network data (ArrayBuffer)
 * @returns 0 on success, negative on error
 */
export const kcpInput: (kcp: number, data: ArrayBuffer) => number;

/**
 * Updates KCP state
 * @param kcp - KCP handle
 * @param current - Current timestamp (milliseconds)
 */
export const kcpUpdate: (kcp: number, current: number) => void;

/**
 * Checks next update time
 * @param kcp - KCP handle
 * @param current - Current timestamp (milliseconds)
 * @returns Milliseconds until next update
 */
export const kcpCheck: (kcp: number, current: number) => number;

/**
 * Flushes pending data
 * @param kcp - KCP handle
 */
export const kcpFlush: (kcp: number) => void;

/**
 * Peeks the size of next message
 * @param kcp - KCP handle
 * @returns Size in bytes, or negative if no data
 */
export const kcpPeeksize: (kcp: number) => number;

/**
 * Sets MTU (Maximum Transmission Unit)
 * @param kcp - KCP handle
 * @param mtu - MTU size (default: 1400)
 * @returns 0 on success, negative on error
 */
export const kcpSetmtu: (kcp: number, mtu: number) => number;

/**
 * Sets window size
 * @param kcp - KCP handle
 * @param sndwnd - Send window size (default: 32)
 * @param rcvwnd - Receive window size (default: 32)
 * @returns 0 on success, negative on error
 */
export const kcpWndsize: (kcp: number, sndwnd: number, rcvwnd: number) => number;

/**
 * Gets the number of packets waiting to send
 * @param kcp - KCP handle
 * @returns Number of waiting packets
 */
export const kcpWaitsnd: (kcp: number) => number;

/**
 * Configures nodelay parameters
 * @param kcp - KCP handle
 * @param nodelay - 0: disable (default), 1: enable
 * @param interval - Internal update interval in ms (default: 100)
 * @param resend - 0: disable fast resend, 1: enable (default: 0)
 * @param nc - 0: normal congestion control, 1: disable (default: 0)
 * @returns 0 on success, negative on error
 */
export const kcpNodelay: (kcp: number, nodelay: number, interval: number, resend: number, nc: number) => number;

/**
 * Sets stream mode
 * @param kcp - KCP handle
 * @param stream - 0: message mode (default), 1: stream mode
 */
export const kcpSetStream: (kcp: number, stream: number) => void;

/**
 * Sets output callback context
 * @param kcp - KCP handle
 * @param context - Context string (JSON serialized)
 */
export const kcpSetContext: (kcp: number, context: string) => void;

/**
 * Gets output callback context
 * @param kcp - KCP handle
 * @returns Context string (JSON serialized)
 */
export const kcpGetContext: (kcp: number) => string;

/**
 * Sets output callback (Internal use only - Called by KCP class)
 * @param kcp - KCP handle
 * @param callback - Output callback function
 * @internal
 */
export const kcpSetOutputCallback: (kcp: number, callback: (data: ArrayBuffer, size: number, context: string) => void) => void;
