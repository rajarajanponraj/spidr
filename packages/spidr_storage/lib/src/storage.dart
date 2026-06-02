import 'package:spidr_core/spidr_core.dart';

/// Database adapter interface for storing crawl checkpoint frontiers, dynamic cookies, and fingerprints.
abstract class StorageAdapter implements SpidrPlugin {
  /// Initializes the database connection context.
  Future<void> open();

  /// Writes a value to the storage key-space.
  Future<void> write(String key, String value);

  /// Retrieves a value by its key. Returns null if missing.
  Future<String?> read(String key);

  /// Deletes a key-value entry.
  Future<void> delete(String key);

  /// Discards all keys.
  Future<void> clear();

  /// Closes database connection resources.
  Future<void> close();
}

/// Fallback key-value storage implementation executing entirely in volatile heap memory.
class MemoryStorageAdapter implements StorageAdapter {
  final Map<String, String> _db = {};

  @override
  String get name => 'spidr_storage';

  @override
  void initialize(SpidrPluginRegistry registry) {}

  @override
  Future<void> open() async {}

  @override
  Future<void> write(String key, String value) async {
    _db[key] = value;
  }

  @override
  Future<String?> read(String key) async => _db[key];

  @override
  Future<void> delete(String key) async {
    _db.remove(key);
  }

  @override
  Future<void> clear() async {
    _db.clear();
  }

  @override
  Future<void> close() async {}
}
