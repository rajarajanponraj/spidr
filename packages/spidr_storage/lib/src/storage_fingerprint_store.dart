import 'dart:convert';
import 'package:spidr_core/spidr_core.dart';
import 'storage.dart';

/// Persistent implementation of [FingerprintStore] backed by a [StorageAdapter].
class StorageFingerprintStore implements FingerprintStore {
  final StorageAdapter _storage;
  final String _keyPrefix;

  /// Creates a new [StorageFingerprintStore] wrapping the [_storage] adapter.
  StorageFingerprintStore(
    this._storage, {
    String keyPrefix = 'fingerprint:',
  }) : _keyPrefix = keyPrefix;

  @override
  Future<void> save(String key, ElementFingerprint fingerprint) async {
    final data = jsonEncode(fingerprint.toJson());
    await _storage.write('$_keyPrefix$key', data);
  }

  @override
  Future<ElementFingerprint?> load(String key) async {
    final data = await _storage.read('$_keyPrefix$key');
    if (data == null) return null;
    
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return ElementFingerprint.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
