import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Emits `true` when the device has any usable network path.
final connectivityStatusProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  final initial = await connectivity.checkConnectivity();
  yield _hasConnection(initial);
  yield* connectivity.onConnectivityChanged.map(_hasConnection);
});

/// Synchronous-friendly read: defaults to online while the stream loads.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStatusProvider).maybeWhen(
        data: (online) => online,
        orElse: () => true,
      );
});

bool _hasConnection(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any(
    (r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn,
  );
}
