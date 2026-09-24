import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/core/services/share_intent_service.dart';
import 'package:latyr_app/core/services/sync_service.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final tokenProviderProvider = Provider<TokenProvider>((ref) {
  bool authAttempted = false;
  return () async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null && !authAttempted) {
        authAttempted = true;
        debugPrint('Signing in user with Firebase Authentication...');
        final credential = await FirebaseAuth.instance.signInAnonymously();
        user = credential.user;
      }
      final token = await user?.getIdToken();
      if (token != null) {
        return token;
      }
      return 'dev-user-001';
    } catch (e) {
      debugPrint('Firebase Auth note: using local dev token (dev-user-001): $e');
      return 'dev-user-001';
    }
  };
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  return ApiClient(tokenProvider: tokenProvider);
});

final sseClientProvider = Provider<SseClient>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  final client = SseClient(tokenProvider: tokenProvider);
  client.connect();
  ref.onDispose(() => client.dispose());
  return client;
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  final repo = CaptureRepository(
    db: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final sync = SyncService(
    captureRepository: ref.watch(captureRepositoryProvider),
  );
  ref.onDispose(() => sync.dispose());
  return sync;
});

final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  final service = ShareIntentService(
    captureRepository: ref.watch(captureRepositoryProvider),
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final captureListStreamProvider = StreamProvider<List<LocalCapture>>((ref) {
  final repo = ref.watch(captureRepositoryProvider);
  return repo.watchCaptures();
});
