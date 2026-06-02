import 'package:test/test.dart';
import 'package:spidr_crawler/spidr_crawler.dart';
import 'package:spidr_core/spidr_core.dart';

class MockSpider extends Spider {
  @override
  String get name => 'mock_spider';

  @override
  List<Uri> get startUrls => [Uri.parse('https://example.com')];

  @override
  Future<void> parse(SpidrResponse response, SpidrCrawler crawler) async {}
}

class MockScheduler implements CrawlerScheduler {
  final List<SpidrRequest> queue = [];
  final Set<Uri> visited = {};

  @override
  bool get isEmpty => queue.isEmpty;

  @override
  void add(SpidrRequest request) => queue.add(request);

  @override
  SpidrRequest? next() => queue.isEmpty ? null : queue.removeAt(0);

  @override
  bool isVisited(Uri url) => visited.contains(url);

  @override
  void markVisited(Uri url) => visited.add(url);

  @override
  void clear() {
    queue.clear();
    visited.clear();
  }
}

class MockClient implements SpidrClient {
  @override
  Future<SpidrResponse> send(SpidrRequest request) async {
    return SpidrResponse(
      request: request,
      statusCode: 200,
      statusMessage: 'OK',
      headers: const {},
      bodyBytes: const [],
      bodyString: '<html></html>',
      duration: Duration.zero,
    );
  }

  @override
  void close() {}

  @override
  Future<SpidrSession> saveSession(String sessionId, {Map<String, String>? headers}) async {
    return SpidrSession(
      sessionId: sessionId,
      headers: headers ?? const {},
    );
  }

  @override
  Future<void> restoreSession(SpidrSession session) async {}
}

void main() {
  group('SpidrCrawler Smoke Tests', () {
    test('Crawler completes successfully with single start url', () async {
      final spider = MockSpider();
      final scheduler = MockScheduler();
      final client = MockClient();

      final crawler = SpidrCrawler(
        spider: spider,
        client: client,
        scheduler: scheduler,
      );

      await crawler.run();
      expect(scheduler.isVisited(Uri.parse('https://example.com')), isTrue);
    });
  });
}
