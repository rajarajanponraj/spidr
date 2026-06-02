import 'dart:io';
import 'package:test/test.dart';
import 'package:spidr/spidr.dart';

void main() {
  group('Umbrella Spidr Tests', () {
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
            <title>SPA Test Page</title>
          </head>
          <body>
            <div id="target-div">Static Content</div>
            <script>
              setTimeout(() => {
                const el = document.createElement('div');
                el.id = 'dynamic-div';
                el.innerText = 'Dynamic Content!';
                document.body.appendChild(el);
              }, 200);
            </script>
          </body>
          </html>
        ''');
        request.response.close();
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
      await Spidr.close();
    });

    test('capabilities exposed matches core capabilities', () {
      final caps = Spidr.capabilities;
      expect(caps.supportsRemoteBrowser, isTrue);
    });

    test(
      'get request throws SpidrNetworkException on unreachable host',
      () async {
        expect(
          () => Spidr.get('http://localhost:9999/nonexistent'),
          throwsA(isA<SpidrNetworkException>()),
        );
      },
    );

    test(
      'static get followed by page.render() promotes to dynamic content',
      () async {
        // 1. Static fetch via HTTP GET
        final page = await Spidr.get(serverUrl);
        expect(page.css('#target-div')?.text, equals('Static Content'));
        expect(page.css('#dynamic-div'), isNull);

        // 2. Render page dynamically in Chrome, waiting for DOM script timer
        final rendered = await page.render(
          waitSelector: '#dynamic-div',
          timeout: const Duration(seconds: 5),
        );

        // Verify that waitSelector and JS timer ran and updated the DOM
        expect(rendered.css('#dynamic-div')?.text, equals('Dynamic Content!'));

        // 3. Render with script triggers modifying state
        final triggered = await rendered.render(
          scriptTriggers: [
            "document.getElementById('dynamic-div').innerText = 'Triggered State!'",
          ],
        );
        expect(triggered.css('#dynamic-div')?.text, equals('Triggered State!'));
      },
    );
  });
}
