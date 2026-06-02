import 'dart:convert';
import 'package:spidr_core/spidr_core.dart';
import 'storage.dart';

/// Persistent implementation of [SpidrSessionStore] backed by a [StorageAdapter].
class StorageSessionStore implements SpidrSessionStore {
  final StorageAdapter _storage;
  final String _keyPrefix;

  /// Creates a new [StorageSessionStore] wrapping the [_storage] adapter.
  StorageSessionStore(
    this._storage, {
    String keyPrefix = 'session:',
  }) : _keyPrefix = keyPrefix;

  @override
  Future<void> save(SpidrSession session) async {
    final data = jsonEncode(session.toJson());
    await _storage.write('$_keyPrefix${session.sessionId}', data);
  }

  @override
  Future<SpidrSession?> load(String sessionId) async {
    final data = await _storage.read('$_keyPrefix$sessionId');
    if (data == null) return null;

    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      return SpidrSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> delete(String sessionId) async {
    await _storage.delete('$_keyPrefix$sessionId');
  }
}
