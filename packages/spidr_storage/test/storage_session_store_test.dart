import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';
import 'package:spidr_storage/spidr_storage.dart';

void main() {
  group('StorageSessionStore Tests', () {
    late StorageAdapter storage;
    late StorageSessionStore store;

    setUp(() async {
      storage = MemoryStorageAdapter();
      await storage.open();
      store = StorageSessionStore(storage);
    });

    tearDown(() async {
      await storage.close();
    });

    test('should save, load, and delete session successfully', () async {
      const session = SpidrSession(
        sessionId: 'session_user_5',
        cookies: [
          {'name': 'auth', 'value': 'secret_token_val'}
        ],
        headers: {'User-Agent': 'MobileClient'},
        localStorage: {'theme': 'dark'},
        indexedDb: {'cart_db': '{}'},
      );

      await store.save(session);
      final loaded = await store.load('session_user_5');

      expect(loaded, isNotNull);
      expect(loaded!.sessionId, equals('session_user_5'));
      expect(loaded.cookies.first['name'], equals('auth'));
      expect(loaded.headers['User-Agent'], equals('MobileClient'));
      expect(loaded.localStorage['theme'], equals('dark'));

      await store.delete('session_user_5');
      final afterDelete = await store.load('session_user_5');
      expect(afterDelete, isNull);
    });
  });
}
