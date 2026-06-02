import 'package:test/test.dart';
import 'package:spidr_crawler/spidr_crawler.dart';

void main() {
  group('RobotsTxt Parser Tests', () {
    test('should parse basic directives and user agents', () {
      const content = '''
User-agent: spidr
Disallow: /admin/
Allow: /admin/login

User-agent: *
Disallow: /temp/
Crawl-delay: 10
''';

      final robots = RobotsTxt.parse(content);

      // Check spidr specific rules
      expect(robots.isAllowed('spidr', '/admin/dashboard'), isFalse);
      expect(robots.isAllowed('spidr', '/admin/login'), isTrue);
      expect(robots.isAllowed('spidr', '/public/index.html'), isTrue);
      expect(robots.getCrawlDelay('spidr'), isNull);

      // Check generic agent fallback *
      expect(robots.isAllowed('other-bot', '/temp/cache'), isFalse);
      expect(robots.isAllowed('other-bot', '/public/index.html'), isTrue);
      expect(robots.getCrawlDelay('other-bot'), equals(10.0));
    });

    test('should select the longest matching path prefix precedence', () {
      const content = '''
User-agent: *
Allow: /images/avatars/default.png
Disallow: /images/avatars/
Allow: /images/
Disallow: /
''';

      final robots = RobotsTxt.parse(content);

      // Matches: Allow /images/avatars/default.png (len 30) over Disallow /images/avatars/ (len 17)
      expect(robots.isAllowed('spidr', '/images/avatars/default.png'), isTrue);

      // Matches: Disallow /images/avatars/ (len 17) over Allow /images/ (len 8)
      expect(robots.isAllowed('spidr', '/images/avatars/user123.jpg'), isFalse);

      // Matches: Allow /images/ (len 8) over Disallow / (len 1)
      expect(robots.isAllowed('spidr', '/images/logo.png'), isTrue);

      // Matches: Disallow / (len 1)
      expect(robots.isAllowed('spidr', '/secret.txt'), isFalse);
    });

    test('should ignore comments and empty lines', () {
      const content = '''
# This is a comment
User-agent: spidr # End of line comment
Disallow: /private/ # Block this

# Another empty comment line
''';

      final robots = RobotsTxt.parse(content);
      expect(robots.isAllowed('spidr', '/private/file'), isFalse);
      expect(robots.isAllowed('spidr', '/public/file'), isTrue);
    });

    test('should return default allowed when user agent has no rules and no * fallback exists', () {
      const content = '''
User-agent: googlebot
Disallow: /
''';

      final robots = RobotsTxt.parse(content);
      expect(robots.isAllowed('spidr', '/secret/data'), isTrue);
    });
  });
}
