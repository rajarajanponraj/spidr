import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('Adaptive Selector Self-Healing Tests', () {
    late FingerprintStore store;

    setUp(() {
      store = MemoryFingerprintStore();
      SpidrFingerprintRegistry.store = store;
    });

    test('should save fingerprint on successful standard lookup', () async {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
          <html>
          <body>
            <button id="submit-btn" class="btn active">Submit</button>
          </body>
          </html>
        ''',
        duration: Duration.zero,
      );
      final page = HtmlSpidrPage(response);

      // Verify that no fingerprint exists in store yet
      final initialFp = await store.load('#submit-btn');
      expect(initialFp, isNull);

      // Call adaptive - standard lookup should work
      final element = await page.adaptive('#submit-btn');
      expect(element, isNotNull);
      expect(element!.tagName, equals('button'));

      // Verify that fingerprint was saved to store
      final savedFp = await store.load('#submit-btn');
      expect(savedFp, isNotNull);
      expect(savedFp!.tagName, equals('button'));
      expect(savedFp.classes, equals(['btn', 'active']));
      expect(savedFp.cssSelector, equals('#submit-btn'));
    });

    test('should self-heal when CSS selector is modified', () async {
      // 1. Initial page load (saves fingerprint)
      final initialResponse = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
          <html>
          <body>
            <div id="wrapper">
              <span class="label">Username</span>
              <input type="text" id="username-input" name="user" class="form-field" placeholder="Enter username" />
              <p class="hint">Must be alphanumeric</p>
            </div>
          </body>
          </html>
        ''',
        duration: Duration.zero,
      );
      final initialPage = HtmlSpidrPage(initialResponse);
      final initialElement = await initialPage.adaptive('#username-input');
      expect(initialElement, isNotNull);

      // Verify initial fingerprint is saved
      final historicalFp = await store.load('#username-input');
      expect(historicalFp, isNotNull);
      expect(historicalFp!.cssSelector, equals('#username-input'));

      // 2. Subsequent page load where target element has changed id and class!
      final modifiedResponse = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
          <html>
          <body>
            <div id="wrapper">
              <span class="label">Username</span>
              <!-- ID is now login-user, class is now text-input -->
              <input type="text" id="login-user" name="user" class="text-input" placeholder="Enter username" />
              <p class="hint">Must be alphanumeric</p>
            </div>
          </body>
          </html>
        ''',
        duration: Duration.zero,
      );
      final modifiedPage = HtmlSpidrPage(modifiedResponse);

      // Verify standard CSS lookup fails
      final cssLookup = modifiedPage.css('#username-input');
      expect(cssLookup, isNull);

      // Call adaptive on broken selector -> should self-heal and resolve the modified element!
      final healedElement = await modifiedPage.adaptive('#username-input');
      expect(healedElement, isNotNull);
      expect(healedElement!.tagName, equals('input'));
      expect(healedElement.attribute('id'), equals('login-user'));
      expect(healedElement.attribute('name'), equals('user'));

      // Verify store has been updated with the healed element's new fingerprint
      final newSavedFp = await store.load('#username-input');
      expect(newSavedFp, isNotNull);
      expect(newSavedFp!.cssSelector, equals('#login-user'));
      expect(newSavedFp.classes, equals(['text-input']));
    });

    test('should return null if element cannot be healed (fails confidence threshold)', () async {
      // 1. Save fingerprint
      final initialResponse = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
          <html>
          <body>
            <a href="/logout" id="logout-link">Logout</a>
          </body>
          </html>
        ''',
        duration: Duration.zero,
      );
      final initialPage = HtmlSpidrPage(initialResponse);
      await initialPage.adaptive('#logout-link');

      // 2. Load page where target is completely removed and replaced by unrelated element
      final modifiedResponse = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
          <html>
          <body>
            <div id="footer">Copyright 2026</div>
          </body>
          </html>
        ''',
        duration: Duration.zero,
      );
      final modifiedPage = HtmlSpidrPage(modifiedResponse);

      // Try adaptive -> should fail to find any close match and return null
      final result = await modifiedPage.adaptive('#logout-link');
      expect(result, isNull);
    });
  });
}
