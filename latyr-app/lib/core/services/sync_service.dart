import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

class SyncService {
  final CaptureRepository captureRepository;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  SyncService({
    required this.captureRepository,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity() {
    _startListening();
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        triggerSync();
      }
    });
  }

  Future<void> triggerSync() async {
    await captureRepository.syncPending();
  }

  void dispose() {
    _subscription?.cancel();
  }
}
