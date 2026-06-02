import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  const sampleHtml = '''
  <div class="container" id="main">
    <h1>SPIDR Scraping</h1>
    <p class="desc">SPIDR is a framework.</p>
    <a href="https://example.com" class="link">Link text</a>
    <ul>
      <li class="item">Item 1</li>
      <li class="item">Item 2</li>
    </ul>
  </div>
  ''';

  group('CSS Selectors Tests', () {
    test('Select headers and paragraphs successfully', () {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: sampleHtml,
        duration: Duration.zero,
      );

      final page = HtmlSpidrPage(response);

      final title = page.css('h1');
      expect(title, isNotNull);
      expect(title!.tagName, equals('h1'));
      expect(title.text, equals('SPIDR Scraping'));

      final desc = page.css('p.desc');
      expect(desc, isNotNull);
      expect(desc!.text, equals('SPIDR is a framework.'));

      final items = page.cssAll('li.item');
      expect(items.length, equals(2));
      expect(items[0].text, equals('Item 1'));
      expect(items[1].text, equals('Item 2'));
    });

    test('Attribute extractions', () {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: sampleHtml,
        duration: Duration.zero,
      );

      final page = HtmlSpidrPage(response);
      final link = page.css('a.link');
      expect(link, isNotNull);
      expect(link!.attribute('href'), equals('https://example.com'));
      expect(link.attributes['class'], equals('link'));
    });
  });

  group('XPath Evaluator Tests', () {
    test('Tag matches and descendants select', () {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: sampleHtml,
        duration: Duration.zero,
      );

      final page = HtmlSpidrPage(response);

      final title = page.xpath('//h1');
      expect(title, isNotNull);
      expect(title!.text, equals('SPIDR Scraping'));

      final listItems = page.xpathAll('//li[@class="item"]');
      expect(listItems.length, equals(2));
    });

    test('Predicate and text contains matches', () {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: sampleHtml,
        duration: Duration.zero,
      );

      final page = HtmlSpidrPage(response);

      final matchingP = page.xpath('//p[contains(text(), "framework")]');
      expect(matchingP, isNotNull);
      expect(matchingP!.text, equals('SPIDR is a framework.'));

      final exactLi = page.xpath('//li[text()="Item 2"]');
      expect(exactLi, isNotNull);
      expect(exactLi!.text, equals('Item 2'));
    });

    test('Attribute extraction syntax', () {
      final response = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('https://example.com')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: sampleHtml,
        duration: Duration.zero,
      );

      final page = HtmlSpidrPage(response);
      final hrefAttr = page.xpathAll('//a[@class="link"]/@href');
      expect(hrefAttr.length, equals(1));
      expect(hrefAttr[0].text, equals('https://example.com'));
    });
  });
}
