/**
 * KCP Unit Tests
 */

import { describe, it, expect } from '@ohos/hypium';
import { KCP, KCPContext } from 'kcp';
import { hilog } from '@kit.PerformanceAnalysisKit';

const LOG_TAG = 'KCPTest';

export default function kcpTests() {
  describe('KCPTests', () => {
    
    it('testKcpCreateAndRelease', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP create and release');
      
      const conv = 123;
      const kcp = new KCP(conv);
      
      expect(kcp).not().assertNull();
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP create and release test passed');
    });
    
    it('testKcpSendData', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP send data');
      
      const conv = 456;
      const kcp = new KCP(conv);
      
      const testData = 'Hello KCP Test';
      const result = kcp.send(testData);
      
      expect(result).assertEqual(0);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP send data test passed');
    });
    
    it('testKcpConfiguration', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP configuration');
      
      const conv = 789;
      const kcp = new KCP(conv);
      
      // Test nodelay
      const nodelayResult = kcp.nodelay(1, 10, 2, 1);
      expect(nodelayResult).assertEqual(0);
      
      // Test wndsize
      const wndsizeResult = kcp.wndsize(128, 128);
      expect(wndsizeResult).assertEqual(0);
      
      // Test setmtu
      const setmtuResult = kcp.setmtu(1400);
      expect(setmtuResult).assertEqual(0);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP configuration test passed');
    });
    
    it('testKcpUpdateAndCheck', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP update and check');
      
      const conv = 101;
      const kcp = new KCP(conv);
      
      const currentTime = Date.now();
      kcp.update(currentTime);
      
      const nextUpdate = kcp.check(currentTime);
      expect(nextUpdate).assertLarger(0);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP update and check test passed');
    });
    
    it('testKcpWaitsnd', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP waitsnd');
      
      const conv = 202;
      const kcp = new KCP(conv);
      
      const waitsnd = kcp.waitsnd();
      expect(waitsnd).assertLarger(-1);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP waitsnd test passed');
    });
    
    it('testKcpPeeksize', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP peeksize');
      
      const conv = 303;
      const kcp = new KCP(conv);
      
      const peeksize = kcp.peeksize();
      expect(peeksize).assertLess(1);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP peeksize test passed');
    });
    
    it('testKcpContext', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP context');
      
      const conv = 404;
      const context: KCPContext = {
        address: '127.0.0.1',
        port: 41234
      };
      const kcp = new KCP(conv, context);
      
      const retrievedContext = kcp.getContext();
      expect(retrievedContext).not().assertNull();
      expect(retrievedContext?.address).assertEqual('127.0.0.1');
      expect(retrievedContext?.port).assertEqual(41234);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP context test passed');
    });
    
    it('testKcpStreamMode', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP stream mode');
      
      const conv = 505;
      const kcp = new KCP(conv);
      
      // Set stream mode
      kcp.stream(1);
      
      // Normal operation after setting stream mode
      const result = kcp.send('test stream');
      expect(result).assertEqual(0);
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP stream mode test passed');
    });
    
    it('testKcpFlush', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP flush');
      
      const conv = 606;
      const kcp = new KCP(conv);
      
      kcp.send('test flush');
      kcp.flush();
      
      kcp.release();
      
      hilog.info(0x0000, LOG_TAG, 'KCP flush test passed');
    });
    
    it('testKcpReleaseThrowsError', 0, () => {
      hilog.info(0x0000, LOG_TAG, 'Testing KCP release error handling');
      
      const conv = 707;
      const kcp = new KCP(conv);
      kcp.release();
      
      try {
        kcp.send('should fail');
        expect(false).assertTrue();
      } catch (err) {
        const error = err as Error;
        expect(error.message).assertEqual('KCP instance has been released');
      }
      
      hilog.info(0x0000, LOG_TAG, 'KCP release error handling test passed');
    });
    
  });
}
