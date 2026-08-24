import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/core/services/sync_service.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final sseClientProvider = Provider<SseClient>((ref) {
  final client = SseClient();
  ref.onDispose(() => client.dispose());
  return client;
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  return CaptureRepository(
    db: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  );
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final sync = SyncService(
    captureRepository: ref.watch(captureRepositoryProvider),
  );
  ref.onDispose(() => sync.dispose());
  return sync;
});

final captureListStreamProvider = StreamProvider<List<LocalCapture>>((ref) {
  final repo = ref.watch(captureRepositoryProvider);
  return repo.watchCaptures();
});
