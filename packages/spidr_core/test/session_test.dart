import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';

void main() {
  group('Session Layer Tests', () {
    test('SpidrSession JSON Serialization Symmetry', () {
      final session = SpidrSession(
        sessionId: 'session_123',
        cookies: [
          {
            'name': 'token',
            'value': 'abc',
            'domain': 'example.com',
            'path': '/',
            'expires': DateTime(2026, 12, 31).toIso8601String(),
            'httpOnly': true,
            'secure': true,
          }
        ],
        headers: {'User-Agent': 'Mozilla/5.0'},
        localStorage: {'key': 'value'},
        indexedDb: {'db_name': '{"records":[]}'},
        metadata: {'extra': 42},
      );

      final json = session.toJson();
      final decoded = SpidrSession.fromJson(json);

      expect(decoded.sessionId, equals(session.sessionId));
      expect(decoded.cookies, equals(session.cookies));
      expect(decoded.headers, equals(session.headers));
      expect(decoded.localStorage, equals(session.localStorage));
      expect(decoded.indexedDb, equals(session.indexedDb));
      expect(decoded.metadata, equals(session.metadata));
    });

    test('MemorySessionStore basic CRUD operations', () async {
      final store = MemorySessionStore();
      final session = SpidrSession(sessionId: 'session_a');

      await store.save(session);
      expect(await store.load('session_a'), isNotNull);

      await store.delete('session_a');
      expect(await store.load('session_a'), isNull);
    });

    test('DioSpidrClient save/restore session cookies', () async {
      final client = DioSpidrClient();

      // Add a test cookie manually
      client.cookieJar.addCookie(SpidrCookie(
        name: 'session_id',
        value: 'xyz987',
        domain: 'foo.com',
        path: '/api',
      ));

      final session = await client.saveSession('client_session_1', headers: {'X-Custom': 'val'});

      expect(session.sessionId, equals('client_session_1'));
      expect(session.headers['X-Custom'], equals('val'));
      expect(session.cookies, isNotEmpty);
      expect(session.cookies.first['name'], equals('session_id'));
      expect(session.cookies.first['value'], equals('xyz987'));

      // Close and create new client to restore
      final newClient = DioSpidrClient();
      expect(newClient.cookieJar.all, isEmpty);

      await newClient.restoreSession(session);
      expect(newClient.cookieJar.all, isNotEmpty);
      expect(newClient.cookieJar.all.first.name, equals('session_id'));
      expect(newClient.cookieJar.all.first.value, equals('xyz987'));
    });
  });
}
