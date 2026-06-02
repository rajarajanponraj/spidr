import 'request.dart';
import 'response.dart';
import 'session.dart';

/// The core interface for components executing network requests.
abstract class SpidrClient {
  /// Sends the given [request] asynchronously and returns the [SpidrResponse].
  Future<SpidrResponse> send(SpidrRequest request);

  /// Closes the client, releasing any underlying resources.
  void close();

  /// Captures the current client session context (cookies, custom headers, etc.).
  Future<SpidrSession> saveSession(String sessionId, {Map<String, String>? headers});

  /// Restores a previously saved session context to the client.
  Future<void> restoreSession(SpidrSession session);
}
