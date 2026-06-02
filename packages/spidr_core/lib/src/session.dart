/// Represents a complete snapshot of network/browser states, including cookies, headers, local storage, and IndexedDB data.
class SpidrSession {
  /// Unique identifier of the session.
  final String sessionId;

  /// List of serialized cookies.
  final List<Map<String, dynamic>> cookies;

  /// Custom request headers associated with the session.
  final Map<String, String> headers;

  /// Serialized key-value entries representing local storage state.
  final Map<String, String> localStorage;

  /// Serialized databases representing IndexedDB state.
  final Map<String, String> indexedDb;

  /// Session context metadata containing extra environment properties.
  final Map<String, dynamic> metadata;

  /// Creates a new [SpidrSession].
  const SpidrSession({
    required this.sessionId,
    this.cookies = const [],
    this.headers = const {},
    this.localStorage = const {},
    this.indexedDb = const {},
    this.metadata = const {},
  });

  /// Serializes the session context to a standard JSON-compatible Map.
  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'cookies': cookies,
        'headers': headers,
        'localStorage': localStorage,
        'indexedDb': indexedDb,
        'metadata': metadata,
      };

  /// Deserializes a session context from a JSON-compatible Map.
  factory SpidrSession.fromJson(Map<String, dynamic> json) {
    return SpidrSession(
      sessionId: json['sessionId'] as String,
      cookies: List<Map<String, dynamic>>.from(
        (json['cookies'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)),
      ),
      headers: Map<String, String>.from(json['headers'] as Map? ?? const {}),
      localStorage: Map<String, String>.from(json['localStorage'] as Map? ?? const {}),
      indexedDb: Map<String, String>.from(json['indexedDb'] as Map? ?? const {}),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? const {}),
    );
  }
}

/// Abstract contract for managing session storage environments.
abstract class SpidrSessionStore {
  /// Saves the [session] snapshot to the store.
  Future<void> save(SpidrSession session);

  /// Loads the [SpidrSession] associated with [sessionId].
  /// Returns null if missing.
  Future<SpidrSession?> load(String sessionId);

  /// Discards the session data associated with [sessionId].
  Future<void> delete(String sessionId);
}

/// Volatile in-memory implementation of [SpidrSessionStore].
class MemorySessionStore implements SpidrSessionStore {
  final Map<String, SpidrSession> _store = {};

  @override
  Future<void> save(SpidrSession session) async {
    _store[session.sessionId] = session;
  }

  @override
  Future<SpidrSession?> load(String sessionId) async {
    return _store[sessionId];
  }

  @override
  Future<void> delete(String sessionId) async {
    _store.remove(sessionId);
  }
}

/// Global registry for configuring the active session storage manager.
class SpidrSessionRegistry {
  /// The active [SpidrSessionStore].
  static SpidrSessionStore store = MemorySessionStore();
}
