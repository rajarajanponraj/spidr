import 'package:test/test.dart';
import 'package:spidr_stealth/spidr_stealth.dart';

void main() {
  group('UserAgentGenerator Tests', () {
    test('randomDesktop returns a valid desktop user agent string', () {
      final ua = UserAgentGenerator.randomDesktop();
      expect(ua, isNotEmpty);
      expect(ua, contains('Mozilla'));
    });
  });

  group('StealthConfig Tests', () {
    test('default settings are correct', () {
      const config = StealthConfig();
      expect(config.enableUserAgentRotation, isTrue);
      expect(config.language, equals('en-US'));
    });
  });
}
