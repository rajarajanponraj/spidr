import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';
import 'package:spidr_crawler/spidr_crawler.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('Phase 10: Concurrent Execution Tests', () {
    late HttpServer server;
    late String serverUrl;

    setUpAll(() async {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUrl = 'http://localhost:${server.port}';
      server.listen((HttpRequest request) {
        final path = request.uri.path;
        final delayMs = int.tryParse(request.uri.queryParameters['delay'] ?? '0') ?? 0;
        Future.delayed(Duration(milliseconds: delayMs), () {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({
            'path': path,
            'success': true,
          }));
          request.response.close();
        });
      });
    });

    tearDownAll(() async {
      await server.close(force: true);
    });

    test('SpidrWorkerPool executes HTTP fetches concurrently in background isolates', () async {
      final pool = SpidrWorkerPool(size: 2);
      await pool.start();

      try {
        final stopwatch = Stopwatch()..start();

        // Fire 2 concurrent requests with 200ms latency each
        final f1 = pool.execute(SpidrRequest(url: Uri.parse('$serverUrl/page1?delay=200')));
        final f2 = pool.execute(SpidrRequest(url: Uri.parse('$serverUrl/page2?delay=200')));

        final results = await Future.wait([f1, f2]);
        stopwatch.stop();

        expect(results.every((r) => r.isSuccess), isTrue);
        expect(results[0].response?.bodyString, contains('/page1'));
        expect(results[1].response?.bodyString, contains('/page2'));

        // If they ran sequentially, total time would be >= 400ms.
        // Concurrently, they should complete in around 200ms - 350ms.
        expect(stopwatch.elapsedMilliseconds, lessThan(400));
      } finally {
        await pool.dispose();
      }
    });

    test('ConcurrentStreamTransformer limits active tasks and processes concurrently', () async {
      final input = Stream.fromIterable([1, 2, 3, 4]);
      final activeTasks = <int>{};
      var maxConcurrent = 0;

      final transformer = ConcurrentStreamTransformer<int, int>(
        (val) async {
          activeTasks.add(val);
          if (activeTasks.length > maxConcurrent) {
            maxConcurrent = activeTasks.length;
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
          activeTasks.remove(val);
          return val * 10;
        },
        concurrency: 2,
      );

      final stream = input.transform(transformer);
      final results = await stream.toList();

      expect(results, equals([10, 20, 30, 40]));
      // The concurrency limit should strictly limit active parallel conversions to 2
      expect(maxConcurrent, equals(2));
    });

    test('SpidrCrawler processes queued requests concurrently', () async {
      final client = _DelayClient();
      final spider = _LinkSpider(startUrls: [
        Uri.parse('http://host/a'),
        Uri.parse('http://host/b'),
      ]);

      final crawler = SpidrCrawler(
        spider: spider,
        client: client,
        scheduler: DefaultCrawlerScheduler(),
        concurrency: 2,
        respectRobots: false,
      );

      final stopwatch = Stopwatch()..start();
      await crawler.run();
      stopwatch.stop();

      // We have 2 seed URLs. DelayClient simulates 150ms delay for each.
      // With concurrency = 2, they should execute concurrently and complete in < 250ms.
      expect(stopwatch.elapsedMilliseconds, lessThan(250));
      expect(client.requestedUrls.length, equals(2));
    });
  });
}

class _LinkSpider extends Spider {
  @override
  final String name = 'concurrency_spider';
  @override
  final List<Uri> startUrls;

  _LinkSpider({required this.startUrls});

  @override
  Future<void> parse(SpidrResponse response, SpidrCrawler crawler) async {}
}

class _DelayClient implements SpidrClient {
  final List<Uri> requestedUrls = [];

  @override
  Future<SpidrResponse> send(SpidrRequest request) async {
    requestedUrls.add(request.url);
    await Future<void>.delayed(const Duration(milliseconds: 150));
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
