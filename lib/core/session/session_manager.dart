import 'dart:async';

/// Broadcasts "session expired" events from the network layer
/// (e.g. refresh token rejected with 403) so the [AuthBloc] can sign the
/// user out without the network layer depending on presentation code.
class SessionManager {
  final _expired = StreamController<String>.broadcast();

  Stream<String> get onSessionExpired => _expired.stream;

  void expire([
    String reason = 'Your session has expired. Please sign in again.',
  ]) {
    if (!_expired.isClosed) _expired.add(reason);
  }

  Future<void> dispose() => _expired.close();
}
