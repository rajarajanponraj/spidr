import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('SpidrCapabilities Tests', () {
    test('Current capabilities are resolved successfully', () {
      final caps = SpidrCapabilities.current();
      expect(caps.supportsRemoteBrowser, isTrue);
      expect(caps.toString(), contains('SpidrCapabilities'));
    });
  });

  group('SpidrRequest & SpidrResponse Tests', () {
    test('Request copyWith works as expected', () {
      final req = SpidrRequest(url: Uri.parse('https://example.com'));
      expect(req.method, equals('GET'));

      final postReq = req.copyWith(method: 'POST');
      expect(postReq.method, equals('POST'));
      expect(postReq.url, equals(req.url));
    });

    test('Response helper isSuccess evaluates correctly', () {
      final req = SpidrRequest(url: Uri.parse('https://example.com'));
      final response = SpidrResponse(
        request: req,
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '',
        duration: Duration.zero,
      );
      expect(response.isSuccess, isTrue);
    });
  });
}
