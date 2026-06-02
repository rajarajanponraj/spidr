import 'dart:io';
import 'package:test/test.dart';
import 'package:spidr_browser/spidr_browser.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('SpidrBrowser Integration Tests', () {
    late HttpServer server;
    late String serverUrl;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://localhost:${server.port}';
      server.listen((HttpRequest request) {
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
          <!DOCTYPE html>
          <html>
          <head>
            <title>SPIDR Integration Test</title>
          </head>
          <body>
            <h1 id="header">Initial State</h1>
            <input type="text" id="textbox" value="" />
            <button id="btn" onclick="document.getElementById('header').innerText = 'Action Executed'">Action</button>
          </body>
          </html>
        ''');
        request.response.close();
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
    });

    test(
      'should launch browser, navigate, type, click, evaluate, and screenshot',
      () async {
        // 1. Launch local headless Chrome
        final browser = await SpidrBrowser.launch(headless: true);

        try {
          // 2. Fetch pages and get target page
          final initialPages = await browser.pages();
          expect(initialPages.isNotEmpty, isTrue);
          final page = initialPages.first;

          // 3. Navigate to test page
          final response = await page.goto(serverUrl);
          expect(response.statusCode, equals(200));
          expect(page.url.toString(), startsWith(serverUrl));

          // 4. Evaluate document title
          final title = await page.evaluate<String>('document.title');
          expect(title, equals('SPIDR Integration Test'));

          // 5. Type text in textbox
          await page.type('#textbox', 'SPIDR is awesome!');
          final textValue = await page.evaluate<String>(
            'document.getElementById("textbox").value',
          );
          expect(textValue, equals('SPIDR is awesome!'));

          // 6. Click button to trigger event
          await page.click('#btn');
          final headerText = await page.evaluate<String>(
            'document.getElementById("header").innerText',
          );
          expect(headerText, equals('Action Executed'));

          // 7. Capture screenshot
          final screenshotBytes = await page.screenshot();
          expect(screenshotBytes.isNotEmpty, isTrue);
          expect(screenshotBytes.length, greaterThan(100)); // basic size check
        } finally {
          // 8. Cleanly terminate Chrome
          await browser.close();
        }
      },
    );

    test(
      'UnsupportedCapabilityException matches capabilities configuration',
      () {
        final capabilities = SpidrCapabilities.current();
        if (!capabilities.supportsLocalBrowser) {
          expect(
            () => SpidrBrowser.launch(),
            throwsA(isA<UnsupportedCapabilityException>()),
          );
        }
      },
    );
  });
}
