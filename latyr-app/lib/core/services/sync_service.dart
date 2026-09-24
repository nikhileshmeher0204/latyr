import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

class SyncService {
  final CaptureRepository captureRepository;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _processingTimer;
  Timer? _feedSyncTimer;

  SyncService({
    required this.captureRepository,
    Connectivity? connectivity,
  }) : _connectivity = connectivity ?? Connectivity() {
    _startListening();
    _startTimers();
    // Initial fetch on start
    triggerSync();
  }

  void _startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      if (hasConnection) {
        captureRepository.sseClient?.connect();
        triggerSync();
      }
    });
  }

  void _startTimers() {
    // 1. Check in-flight processing or pending offline uploads every 6s only when active
    _processingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      await captureRepository.syncPending();
      if (await captureRepository.hasActiveProcessingCaptures()) {
        await captureRepository.checkProcessingCaptures();
      }
    });

    // 2. Relaxed background feed sync (every 5 minutes)
    _feedSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      await captureRepository.fetchRemoteFeed();
    });
  }

  Future<void> triggerSync() async {
    await captureRepository.syncPending();
    await captureRepository.checkProcessingCaptures();
    await captureRepository.fetchRemoteFeed();
  }

  void dispose() {
    _subscription?.cancel();
    _processingTimer?.cancel();
    _feedSyncTimer?.cancel();
  }
}
