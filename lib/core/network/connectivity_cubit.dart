import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Emits `true` while the device has no network connection.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._connectivity) : super(false) {
    // Connectivity is best-effort: if the platform check fails we simply
    // assume "online" and let real requests surface network failures.
    _sub = _connectivity.onConnectivityChanged.listen(
      _update,
      onError: (Object _) {},
    );
    unawaited(
      _connectivity.checkConnectivity().then(_update).catchError((Object _) {}),
    );
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _sub;

  void _update(List<ConnectivityResult> results) {
    if (isClosed) return;
    emit(results.every((r) => r == ConnectivityResult.none));
  }

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
