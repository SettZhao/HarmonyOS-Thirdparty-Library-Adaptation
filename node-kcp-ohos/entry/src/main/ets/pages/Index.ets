/**
 * KCP Demo Application
 * Demonstrates basic KCP usage
 */

import { KCP, KCPContext } from 'kcp';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { socket } from '@kit.NetworkKit';
import { util } from '@kit.ArkTS';

const LOG_TAG = 'KCPDemo';

@Entry
@Component
struct Index {
  @State message: string = 'KCP Demo - Ready';
  @State resultText: string = '';
  @State isRunning: boolean = false;

  private kcpClient?: KCP;
  private udpSocket?: socket.UDPSocket;
  private updateTimer?: number;
  private serverAddress: string = '127.0.0.1';
  private serverPort: number = 41234;

  aboutToDisappear() {
    this.cleanup();
  }

  /**
   * Cleanup resources
   */
  cleanup() {
    if (this.updateTimer) {
      clearInterval(this.updateTimer);
      this.updateTimer = undefined;
    }

    if (this.kcpClient) {
      this.kcpClient.release();
      this.kcpClient = undefined;
    }

    if (this.udpSocket) {
      this.udpSocket.close();
      this.udpSocket = undefined;
    }

    this.isRunning = false;
  }

  /**
   * Run basic KCP test
   */
  async runBasicTest() {
    try {
      this.resultText = 'Running basic KCP test...\n';
      hilog.info(0x0000, LOG_TAG, 'Starting basic KCP test');

      // Test 1: Create KCP instance
      const conv = 123;
      const context: KCPContext = {
        address: this.serverAddress,
        port: this.serverPort
      };

      const kcp = new KCP(conv, context);
      this.resultText += `✓ Created KCP instance (conv=${conv})\n`;

      // Test 2: Configure KCP parameters
      kcp.nodelay(1, 10, 2, 1); // Fast mode
      kcp.wndsize(128, 128);
      kcp.setmtu(1400);
      this.resultText += '✓ Configured KCP parameters\n';

      // Test 3: Send data
      const testData = 'Hello KCP!';
      const sendResult = kcp.send(testData);
      this.resultText += `✓ Sent data: "${testData}" (result=${sendResult})\n`;

      // Test 4: Update and check
      kcp.update();
      const nextUpdate = kcp.check();
      this.resultText += `✓ Updated KCP (next update in ${nextUpdate}ms)\n`;

      // Test 5: Check status
      const waitsnd = kcp.waitsnd();
      const peeksize = kcp.peeksize();
      this.resultText += `✓ Status: waitsnd=${waitsnd}, peeksize=${peeksize}\n`;

      // Test 6: Release
      kcp.release();
      this.resultText += '✓ Released KCP instance\n';

      this.message = 'Basic test completed successfully!';
      hilog.info(0x0000, LOG_TAG, 'Basic KCP test completed');

    } catch (err) {
      const error = err as Error;
      this.resultText += `✗ Error: ${error.message}\n`;
      this.message = 'Test failed';
      hilog.error(0x0000, LOG_TAG, `Test error: ${error.message}`);
    }
  }

  /**
   * Run UDP echo test with KCP
   */
  async runUdpEchoTest() {
    try {
      if (this.isRunning) {
        this.cleanup();
        this.message = 'Stopped';
        return;
      }

      this.isRunning = true;
      this.resultText = 'Starting UDP echo test...\n';
      this.message = 'Running...';

      // Create UDP socket
      this.udpSocket = socket.constructUDPSocketInstance();
      await this.udpSocket.bind({ address: '0.0.0.0' });

      const localAddr = await this.udpSocket.getState();
      const bindAddr = localAddr.isBound ? '0.0.0.0:0' : 'pending';
      this.resultText += `✓ UDP socket bound to ${bindAddr}\n`;

      // Create KCP instance
      const conv = 123;
      const context: KCPContext = {
        address: this.serverAddress,
        port: this.serverPort
      };

      this.kcpClient = new KCP(conv, context);
      this.kcpClient.nodelay(1, 10, 2, 1);
      this.kcpClient.wndsize(128, 128);

      // Set output callback - KCP will call this to send data
      this.kcpClient.output((data: ArrayBuffer, size: number, ctx?: KCPContext) => {
        if (this.udpSocket && ctx) {
          const sendOptions: socket.UDPSendOptions = {
            data: data,
            address: {
              address: ctx.address!,
              port: ctx.port!
            }
          };
          this.udpSocket.send(sendOptions).then(() => {
            hilog.debug(0x0000, LOG_TAG, `Sent ${size} bytes to ${ctx.address}:${ctx.port}`);
          }).catch((err: Error) => {
            hilog.error(0x0000, LOG_TAG, `Send error: ${err.message}`);
          });
        }
      });

      this.resultText += '✓ KCP instance created and configured\n';

      // Set up message receiver
      this.udpSocket.on('message', (data: socket.SocketMessageInfo) => {
        try {
          if (this.kcpClient) {
            // Input received data to KCP
            this.kcpClient.input(data.message);

            // Try to receive
            const recvData = this.kcpClient.recv();
            if (recvData) {
              const decoder = new util.TextDecoder('utf-8');
              const text = decoder.decodeToString(new Uint8Array(recvData));
              this.resultText += `← Received: ${text}\n`;
              hilog.info(0x0000, LOG_TAG, `Received: ${text}`);
            }
          }
        } catch (err) {
          const error = err as Error;
          hilog.error(0x0000, LOG_TAG, `Receive error: ${error.message}`);
        }
      });

      // Start update timer
      this.updateTimer = setInterval(() => {
        if (this.kcpClient) {
          this.kcpClient.update();
        }
      }, 10);

      // Send test message
      const testMsg = `Hello from OpenHarmony at ${new Date().toISOString()}`;
      this.kcpClient.send(testMsg);
      this.resultText += `→ Sent: ${testMsg}\n`;

      this.message = 'UDP echo test running (click Stop to end)';

    } catch (err) {
      const error = err as Error;
      this.resultText += `✗ Error: ${error.message}\n`;
      this.message = 'Test failed';
      hilog.error(0x0000, LOG_TAG, `UDP test error: ${error.message}`);
      this.cleanup();
    }
  }

  build() {
    Column() {
      // Title
      Text('KCP Protocol Demo')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 10 });

      Text(this.message)
        .fontSize(16)
        .fontColor(Color.Gray)
        .margin({ bottom: 20 });

      // Test buttons
      Row() {
        Button('Basic Test')
          .fontSize(16)
          .width('45%')
          .onClick(() => this.runBasicTest());

        Button(this.isRunning ? 'Stop Echo' : 'UDP Echo')
          .fontSize(16)
          .width('45%')
          .backgroundColor(this.isRunning ? Color.Red : '#007DFF')
          .onClick(() => this.runUdpEchoTest());
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ top: 10, bottom: 20 });

      // Result display
      Scroll() {
        Text(this.resultText || 'Click a button to start testing')
          .fontSize(14)
          .fontFamily('monospace')
          .width('100%')
          .padding(10)
          .backgroundColor('#f5f5f5')
          .borderRadius(8);
      }
      .width('90%')
      .height('60%')
      .scrollBar(BarState.Auto)
      .scrollable(ScrollDirection.Vertical);

      // Info
      Text('Note: For UDP echo test, ensure a KCP server is running on 127.0.0.1:41234')
        .fontSize(12)
        .fontColor(Color.Orange)
        .margin({ top: 20 })
        .width('90%');
    }
    .width('100%')
    .height('100%')
    .padding(20);
  }
}
