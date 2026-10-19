import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Emits `true` while the device has no network connection.
class ConnectivityCubit extends Cubit<bool> {
  ConnectivityCubit(this._connectivity) : super(false) {
    _sub = _connectivity.onConnectivityChanged.listen(_update);
    unawaited(_connectivity.checkConnectivity().then(_update));
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
