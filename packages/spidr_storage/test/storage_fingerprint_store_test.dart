import 'package:test/test.dart';
import 'package:spidr_core/spidr_core.dart';
import 'package:spidr_storage/spidr_storage.dart';

void main() {
  group('StorageFingerprintStore Tests', () {
    late StorageAdapter storage;
    late StorageFingerprintStore store;

    setUp(() async {
      storage = MemoryStorageAdapter();
      await storage.open();
      store = StorageFingerprintStore(storage);
    });

    tearDown(() async {
      await storage.close();
    });

    test('should save and load fingerprint successfully from storage', () async {
      const fingerprint = ElementFingerprint(
        tagName: 'input',
        classes: ['input-field', 'form-control'],
        attributes: {'type': 'text', 'placeholder': 'Username'},
        xpath: '/html/body/form/input[1]',
        cssSelector: 'form > input:nth-of-type(1)',
        siblingTags: ['label', 'button'],
        depth: 3,
        parentHash: 'abc123parentsha',
      );

      await store.save('username_input', fingerprint);
      final loaded = await store.load('username_input');

      expect(loaded, isNotNull);
      expect(loaded!.tagName, equals('input'));
      expect(loaded.classes, equals(['input-field', 'form-control']));
      expect(loaded.attributes['type'], equals('text'));
      expect(loaded.attributes['placeholder'], equals('Username'));
      expect(loaded.xpath, equals(fingerprint.xpath));
      expect(loaded.cssSelector, equals(fingerprint.cssSelector));
      expect(loaded.siblingTags, equals(['label', 'button']));
      expect(loaded.depth, equals(3));
      expect(loaded.parentHash, equals('abc123parentsha'));
      expect(loaded.hash, equals(fingerprint.hash));
    });

    test('should return null for non-existent key', () async {
      final loaded = await store.load('missing_key');
      expect(loaded, isNull);
    });

    test('should handle corrupted json data gracefully', () async {
      await storage.write('fingerprint:corrupted_key', 'invalid-json-content{');
      final loaded = await store.load('corrupted_key');
      expect(loaded, isNull);
    });
  });
}
