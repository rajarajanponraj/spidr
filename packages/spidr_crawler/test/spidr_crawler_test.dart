import 'package:test/test.dart';
import 'package:spidr_crawler/spidr_crawler.dart';
import 'package:spidr_core/spidr_core.dart';

class LinkSpider extends Spider {
  @override
  final String name;
  @override
  final List<Uri> startUrls;

  LinkSpider({required this.name, required this.startUrls});

  @override
  Future<void> parse(SpidrResponse response, SpidrCrawler crawler) async {
    final body = response.bodyString;
    if (body.isNotEmpty) {
      final links = body.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
      for (final link in links) {
        crawler.submit(SpidrRequest(url: Uri.parse(link)));
      }
    }
  }
}

class FakeClient implements SpidrClient {
  final Map<String, SpidrResponse> responses = {};
  final List<Uri> requestedUrls = [];

  @override
  Future<SpidrResponse> send(SpidrRequest request) async {
    requestedUrls.add(request.url);
    final key = request.url.toString();
    if (responses.containsKey(key)) {
      return responses[key]!;
    }
    return SpidrResponse(
      request: request,
      statusCode: 200,
      statusMessage: 'OK',
      headers: const {},
      bodyBytes: const [],
      bodyString: '',
      duration: Duration.zero,
    );
  }

  @override
  void close() {}

  @override
  Future<SpidrSession> saveSession(String sessionId, {Map<String, String>? headers}) async {
    return SpidrSession(sessionId: sessionId, headers: headers ?? const {});
  }

  @override
  Future<void> restoreSession(SpidrSession session) async {}
}

void main() {
  group('SpidrCrawler Integration Tests', () {
    test('BFS strategy processes URLs in FIFO order', () async {
      final client = FakeClient();
      client.responses['http://host/'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/a, http://host/b',
        duration: Duration.zero,
      );
      client.responses['http://host/a'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/a')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/a1',
        duration: Duration.zero,
      );
      client.responses['http://host/b'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/b')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/b1',
        duration: Duration.zero,
      );

      final spider = LinkSpider(
        name: 'bfs_spider',
        startUrls: [Uri.parse('http://host/')],
      );

      final crawler = SpidrCrawler(
        spider: spider,
        client: client,
        scheduler: DefaultCrawlerScheduler(strategy: CrawlStrategy.bfs),
        respectRobots: false,
      );

      await crawler.run();

      expect(
        client.requestedUrls.map((u) => u.toString()).toList(),
        equals([
          'http://host/',
          'http://host/a',
          'http://host/b',
          'http://host/a1',
          'http://host/b1',
        ]),
      );
    });

    test('DFS strategy processes URLs in LIFO order', () async {
      final client = FakeClient();
      client.responses['http://host/'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/a, http://host/b',
        duration: Duration.zero,
      );
      client.responses['http://host/a'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/a')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/a1',
        duration: Duration.zero,
      );
      client.responses['http://host/b'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/b')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/b1',
        duration: Duration.zero,
      );

      final spider = LinkSpider(
        name: 'dfs_spider',
        startUrls: [Uri.parse('http://host/')],
      );

      final crawler = SpidrCrawler(
        spider: spider,
        client: client,
        scheduler: DefaultCrawlerScheduler(strategy: CrawlStrategy.dfs),
        respectRobots: false,
      );

      await crawler.run();

      expect(
        client.requestedUrls.map((u) => u.toString()).toList(),
        equals([
          'http://host/',
          'http://host/b',
          'http://host/b1',
          'http://host/a',
          'http://host/a1',
        ]),
      );
    });

    test('enforces maxDepth boundaries during traversal', () async {
      final client = FakeClient();
      client.responses['http://host/depth0'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/depth0')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/depth1',
        duration: Duration.zero,
      );
      client.responses['http://host/depth1'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/depth1')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/depth2',
        duration: Duration.zero,
      );
      client.responses['http://host/depth2'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/depth2')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: 'http://host/depth3',
        duration: Duration.zero,
      );

      final spider = LinkSpider(
        name: 'depth_spider',
        startUrls: [Uri.parse('http://host/depth0')],
      );

      final crawler = SpidrCrawler(
        spider: spider,
        client: client,
        scheduler: DefaultCrawlerScheduler(),
        maxDepth: 2,
        respectRobots: false,
      );

      await crawler.run();

      // depth0 is depth 0 (visited)
      // depth1 is depth 1 (visited)
      // depth2 is depth 2 (visited)
      // depth3 would be depth 3 (which exceeds maxDepth 2, so it is not visited)
      expect(
        client.requestedUrls.map((u) => u.toString()).toList(),
        equals([
          'http://host/depth0',
          'http://host/depth1',
          'http://host/depth2',
        ]),
      );
    });

    test('respects robots.txt exclusions', () async {
      final client = FakeClient();
      client.responses['http://host/robots.txt'] = SpidrResponse(
        request: SpidrRequest(url: Uri.parse('http://host/robots.txt')),
        statusCode: 200,
        statusMessage: 'OK',
        headers: const {},
        bodyBytes: const [],
        bodyString: '''
User-agent: spidr
Disallow: /disallowed
''',
        duration: Duration.zero,
      );

      final spider = LinkSpider(
        name: 'robots_spider',
        startUrls: [
          Uri.parse('http://host/allowed'),
          Uri.parse('http://host/disallowed'),
        ],
      );

      final crawler = SpidrCrawler(
        spider: spider,
        client: client,
        scheduler: DefaultCrawlerScheduler(),
        userAgent: 'spidr',
        respectRobots: true,
      );

      await crawler.run();

      // Robots.txt is fetched first, then /allowed is fetched. /disallowed is skipped.
      expect(
        client.requestedUrls.map((u) => u.toString()).toList(),
        containsAllInOrder([
          'http://host/robots.txt',
          'http://host/allowed',
        ]),
      );
      expect(
        client.requestedUrls.map((u) => u.toString()).toList(),
        isNot(contains('http://host/disallowed')),
      );
    });
  });
}
