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

    test('should save and restore browser page session states (cookies, localStorage, IndexedDB)', () async {
      final browser = await SpidrBrowser.launch(headless: true);

      try {
        final initialPages = await browser.pages();
        final page = initialPages.first;
        await page.goto(serverUrl);

        // 1. Write cookies, localStorage, and IndexedDB in browser page context
        await page.evaluate<void>('document.cookie = "auth_token=my_secret_token_123; path=/";');
        await page.evaluate<void>('localStorage.setItem("user_theme", "dark");');
        
        await page.evaluate<void>('''
          (async () => {
            return new Promise((resolve, reject) => {
              try {
                const req = indexedDB.open('test_db', 1);
                req.onerror = () => reject(new Error('Open error: ' + req.error));
                req.onupgradeneeded = () => {
                  try {
                    req.result.createObjectStore('cache');
                  } catch (e) {
                    reject(new Error('Upgrade store creation error: ' + e));
                  }
                };
                req.onsuccess = () => {
                  try {
                    const db = req.result;
                    const tx = db.transaction('cache', 'readwrite');
                    tx.onerror = () => reject(new Error('Tx error: ' + tx.error));
                    const store = tx.objectStore('cache');
                    const putReq = store.put('bar', 'foo');
                    putReq.onerror = () => reject(new Error('Put error: ' + putReq.error));
                    tx.oncomplete = () => {
                      db.close();
                      resolve();
                    };
                  } catch (e) {
                    reject(new Error('Success handler error: ' + e));
                  }
                };
              } catch (e) {
                reject(new Error('Outer catch: ' + e));
              }
            });
          })()
        ''');

        // 2. Capture session
        final session = await page.saveSession('browser-session-xyz');
        expect(session.sessionId, equals('browser-session-xyz'));
        expect(session.cookies, isNotEmpty);
        expect(session.localStorage['user_theme'], equals('dark'));
        expect(session.indexedDb['test_db'], isNotNull);

        // 3. Clear browser state completely
        await page.evaluate<void>('document.cookie = "auth_token=; expires=Thu, 01 Jan 1970 00:00:00 UTC; path=/";');
        await page.evaluate<void>('localStorage.clear();');
        await page.evaluate<void>('''
          (async () => {
            return new Promise((resolve) => {
              const req = indexedDB.deleteDatabase('test_db');
              req.onsuccess = () => resolve();
              req.onerror = () => resolve();
            });
          })()
        ''');

        // Verify cleared state
        final clearedCookie = await page.evaluate<String>('document.cookie');
        final clearedTheme = await page.evaluate<String?>('localStorage.getItem("user_theme")');
        expect(clearedCookie, isNot(contains('auth_token=my_secret_token_123')));
        expect(clearedTheme, isNull);

        // 4. Restore session
        await page.restoreSession(session);

        // 5. Assert states are fully recovered
        final restoredCookie = await page.evaluate<String>('document.cookie');
        expect(restoredCookie, contains('auth_token=my_secret_token_123'));

        final restoredTheme = await page.evaluate<String?>('localStorage.getItem("user_theme")');
        expect(restoredTheme, equals('dark'));

        final restoredDbVal = await page.evaluate<String?>('''
          (async () => {
            return new Promise((resolve) => {
              const req = indexedDB.open('test_db');
              req.onsuccess = () => {
                const db = req.result;
                try {
                  const tx = db.transaction('cache', 'readonly');
                  const getReq = tx.objectStore('cache').get('foo');
                  getReq.onsuccess = () => {
                    db.close();
                    resolve(getReq.result);
                  };
                  getReq.onerror = () => {
                    db.close();
                    resolve(null);
                  };
                } catch (_) {
                  db.close();
                  resolve(null);
                }
              };
              req.onerror = () => resolve(null);
            });
          })()
        ''');
        expect(restoredDbVal, equals('bar'));
      } finally {
        await browser.close();
      }
    });

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
