import 'dart:io';
import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('SpidrCookieJar Tests', () {
    test('Set-Cookie header parsing and match queries', () {
      final jar = SpidrCookieJar();
      final uri = Uri.parse('https://example.com/api/v1');

      // Save cookie
      jar.saveFromResponse(uri, [
        'session=xyz123; Domain=example.com; Path=/api; Secure',
      ]);

      // Match correct path & host
      expect(
        jar.getCookieHeader(Uri.parse('https://example.com/api/users')),
        equals('session=xyz123'),
      );
      // Match subdomain
      expect(
        jar.getCookieHeader(Uri.parse('https://sub.example.com/api/users')),
        equals('session=xyz123'),
      );
      // Secure check
      expect(
        jar.getCookieHeader(Uri.parse('http://example.com/api/users')),
        isEmpty,
      );
      // Path mismatch
      expect(
        jar.getCookieHeader(Uri.parse('https://example.com/static')),
        isEmpty,
      );
    });
  });

  group('SpidrRateLimiter Tests', () {
    test('Rate limiting delays sequential invocations', () async {
      final limiter = SpidrRateLimiter(
        delayBetweenRequests: const Duration(milliseconds: 50),
      );
      final stopwatch = Stopwatch()..start();

      await limiter.acquire('example.com');
      await limiter.acquire('example.com');

      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(40));
    });
  });

  group('RetryConfig Tests', () {
    test('Backoff strategy calculates progressive delays', () {
      const config = RetryConfig(
        initialDelay: Duration(milliseconds: 100),
        backoffStrategy: BackoffStrategy.linear,
      );
      expect(config.getDelay(1).inMilliseconds, closeTo(100, 30));
      expect(config.getDelay(2).inMilliseconds, closeTo(200, 60));
    });
  });

  group('DioSpidrClient Local Server Integration Tests', () {
    late HttpServer server;
    late Uri serverUri;
    var serverRequestCount = 0;

    setUp(() async {
      serverRequestCount = 0;
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      serverUri = Uri.parse('http://localhost:${server.port}');

      server.listen((HttpRequest request) async {
        serverRequestCount++;
        if (request.uri.path == '/retry') {
          if (serverRequestCount == 1) {
            request.response.statusCode = 502;
          } else {
            request.response.statusCode = 200;
            request.response.write('success');
          }
        } else if (request.uri.path == '/cookie') {
          request.response.headers.add('Set-Cookie', 'theme=dark; Path=/');
          request.response.write('cookie_set');
        } else {
          request.response.write('hello');
        }
        await request.response.close();
      });
    });

    tearDown(() async {
      await server.close(force: true);
    });

    test('Client fetches body and resolves cookies', () async {
      final client = DioSpidrClient();

      // Request cookie page
      final response1 = await client.send(
        SpidrRequest(url: serverUri.resolve('/cookie')),
      );
      expect(response1.bodyString, equals('cookie_set'));
      expect(client.cookieJar.all.length, equals(1));

      client.close();
    });

    test('Retry policy triggers correctly on 502 response', () async {
      final client = DioSpidrClient(
        retryConfig: const RetryConfig(
          maxRetries: 2,
          initialDelay: Duration(milliseconds: 10),
          backoffStrategy: BackoffStrategy.linear,
        ),
      );

      final response = await client.send(
        SpidrRequest(url: serverUri.resolve('/retry')),
      );
      expect(response.statusCode, equals(200));
      expect(serverRequestCount, equals(2));
      client.close();
    });
  });
}
