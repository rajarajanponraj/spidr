import 'package:test/test.dart';
import 'package:spidr_storage/spidr_storage.dart';

void main() {
  group('MemoryStorageAdapter Tests', () {
    test('standard write/read operations function properly', () async {
      final storage = MemoryStorageAdapter();
      await storage.open();

      await storage.write('test_key', 'test_value');
      final val = await storage.read('test_key');
      expect(val, equals('test_value'));

      await storage.delete('test_key');
      final deletedVal = await storage.read('test_key');
      expect(deletedVal, isNull);

      await storage.close();
    });
  });
}
