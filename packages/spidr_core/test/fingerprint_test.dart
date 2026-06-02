import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('ElementFingerprint Tests', () {
    late HtmlSpidrPage page;

    setUp(() {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
          <!DOCTYPE html>
          <html>
          <head><title>Test Page</title></head>
          <body>
            <div id="container" class="main wrapper">
              <span class="text-label">Hello</span>
              <button id="submit-btn" name="action" disabled>Click Me</button>
              <p>Paragraph text</p>
            </div>
          </body>
          </html>
        ''',
        duration: Duration.zero,
      );
      page = HtmlSpidrPage(response);
    });

    test('should capture element fingerprint correctly', () {
      final buttonElement = page.root.css('#submit-btn');
      expect(buttonElement, isNotNull);

      final fingerprint = ElementFingerprint.capture(buttonElement!);

      expect(fingerprint.tagName, equals('button'));
      expect(fingerprint.classes, isEmpty);
      expect(fingerprint.attributes['name'], equals('action'));
      expect(fingerprint.attributes['disabled'], equals(''));
      expect(fingerprint.attributes['id'], equals('submit-btn'));

      // Check depth
      // html(0) -> body(1) -> div(2) -> button(3)
      expect(fingerprint.depth, equals(3));

      // Check sibling tags (siblings are span and p)
      expect(fingerprint.siblingTags, equals(['span', 'p']));

      // Check parent hash
      expect(fingerprint.parentHash, isNotNull);
      expect(fingerprint.parentHash!.length, equals(64)); // SHA-256 length in hex is 64 characters

      // Check XPath
      expect(fingerprint.xpath, equals('/html/body[1]/div[1]/button[1]'));

      // Check CSS Selector path
      expect(fingerprint.cssSelector, equals('#submit-btn'));
    });

    test('should fall back safely for simple elements', () {
      const element = SimpleSpidrElement(
        tagName: 'div',
        attributes: {'class': 'foo bar', 'id': 'my-id'},
      );

      final fingerprint = ElementFingerprint.capture(element);
      expect(fingerprint.tagName, equals('div'));
      expect(fingerprint.classes, equals(['foo', 'bar']));
      expect(fingerprint.attributes['id'], equals('my-id'));
      expect(fingerprint.depth, equals(0));
      expect(fingerprint.siblingTags, isEmpty);
    });

    test('should serialize and deserialize symmetrically', () {
      final spanElement = page.root.css('.text-label');
      expect(spanElement, isNotNull);

      final original = ElementFingerprint.capture(spanElement!);
      final json = original.toJson();
      final reconstructed = ElementFingerprint.fromJson(json);

      expect(reconstructed.tagName, equals(original.tagName));
      expect(reconstructed.classes, equals(original.classes));
      expect(reconstructed.attributes, equals(original.attributes));
      expect(reconstructed.xpath, equals(original.xpath));
      expect(reconstructed.cssSelector, equals(original.cssSelector));
      expect(reconstructed.siblingTags, equals(original.siblingTags));
      expect(reconstructed.depth, equals(original.depth));
      expect(reconstructed.parentHash, equals(original.parentHash));
      expect(reconstructed.hash, equals(original.hash));
    });

    test('should produce unique, stable hashes', () {
      final button = page.root.css('#submit-btn')!;
      final p = page.root.css('p')!;

      final fp1 = ElementFingerprint.capture(button);
      final fp2 = ElementFingerprint.capture(button);
      final fp3 = ElementFingerprint.capture(p);

      expect(fp1.hash, equals(fp2.hash));
      expect(fp1.hash, isNot(equals(fp3.hash)));
    });

    test('MemoryFingerprintStore saves and loads correctly', () async {
      final store = MemoryFingerprintStore();
      final button = page.root.css('#submit-btn')!;
      final fingerprint = ElementFingerprint.capture(button);

      await store.save('test_btn', fingerprint);
      final loaded = await store.load('test_btn');

      expect(loaded, isNotNull);
      expect(loaded!.hash, equals(fingerprint.hash));

      final nonExistent = await store.load('non_existent');
      expect(nonExistent, isNull);
    });
  });
}
