import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/network/api_client.dart';
import 'package:latyr_app/core/network/auth_interceptor.dart';
import 'package:latyr_app/core/network/authentication_required_exception.dart';
import 'package:latyr_app/core/network/sse_client.dart';
import 'package:latyr_app/core/services/share_intent_service.dart';
import 'package:latyr_app/core/services/sync_service.dart';
import 'package:latyr_app/features/capture/data/capture_repository.dart';
import 'package:latyr_app/features/auth/presentation/auth_providers.dart';

export 'package:latyr_app/features/auth/presentation/auth_providers.dart'
    show firebaseAuthProvider;

String? _sessionUid(AuthState state) =>
    state.phase == AuthPhase.signedIn && state.session?.isSupported == true
        ? state.session!.uid
        : null;

final authenticatedUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authControllerProvider.select(_sessionUid));
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final uid = ref.watch(authenticatedUserIdProvider);
  if (uid == null) throw const AuthenticationRequiredException();
  final db = AppDatabase.forAccount(uid);
  ref.listen(authControllerProvider, (_, next) {
    if (_sessionUid(next) != uid) ref.invalidateSelf();
  });
  ref.onDispose(() => db.close());
  return db;
});

final tokenProviderProvider = Provider<TokenProvider>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final uid = ref.watch(authenticatedUserIdProvider);
  var active = true;
  ref.onDispose(() => active = false);
  ref.listen(authControllerProvider, (_, next) {
    if (_sessionUid(next) != uid) {
      active = false;
      ref.invalidateSelf();
    }
  });

  bool ownsSession() => active && uid != null &&
      ref.read(authenticatedUserIdProvider) == uid &&
      auth.currentUser?.uid == uid && auth.currentUser?.isAnonymous == false;
  return () async {
    if (!ownsSession()) return null;
    final user = auth.currentUser;
    final token = await user!.getIdToken();
    return ownsSession() ? token : null;
  };
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  final client = ApiClient(tokenProvider: tokenProvider);
  ref.onDispose(() => client.dio.close(force: true));
  return client;
});

final sseClientProvider = Provider<SseClient>((ref) {
  final tokenProvider = ref.watch(tokenProviderProvider);
  final uid = ref.watch(authenticatedUserIdProvider);
  final client = SseClient(tokenProvider: tokenProvider);
  var active = true;
  if (uid != null) client.connect();
  ref.listen(authControllerProvider, (previous, next) {
    if (!active) return;
    if (_sessionUid(next) != uid) {
      active = false;
      client.disconnect();
      ref.invalidateSelf();
      return;
    }
    if (uid != null && previous?.revision != next.revision) {
      client.disconnect();
      client.connect();
    }
  });
  ref.onDispose(() {
    active = false;
    client.dispose();
  });
  return client;
});

final captureRepositoryProvider = Provider<CaptureRepository>((ref) {
  final uid = ref.watch(authenticatedUserIdProvider);
  final auth = ref.watch(firebaseAuthProvider);
  var active = true;
  ref.onDispose(() => active = false);
  ref.listen(authControllerProvider, (_, next) {
    if (_sessionUid(next) != uid) {
      active = false;
      ref.invalidateSelf();
    }
  });
  final repo = CaptureRepository(
    db: ref.watch(appDatabaseProvider),
    apiClient: ref.watch(apiClientProvider),
    sseClient: ref.watch(sseClientProvider),
    canCapture: () {
      return active && uid != null &&
          ref.read(authenticatedUserIdProvider) == uid &&
          auth.currentUser?.uid == uid && auth.currentUser?.isAnonymous == false;
    },
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

final shareSignInNoticeProvider = StateProvider<bool>((ref) => false);

final shareIntentServiceProvider = Provider<ShareIntentService>((ref) {
  final service = ShareIntentService(
    canCapture: () => ref.read(authenticatedUserIdProvider) != null,
    captureUrl: (url, {caption}) async {
      if (ref.read(authenticatedUserIdProvider) == null) {
        throw const AuthenticationRequiredException();
      }
      await ref.read(captureRepositoryProvider).captureUrl(url, caption: caption);
    },
    onAuthenticationRequired: () => ref.read(shareSignInNoticeProvider.notifier).state = true,
  );
  ref.onDispose(() => service.dispose());
  return service;
});

final captureListStreamProvider = StreamProvider<List<LocalCapture>>((ref) {
  final repo = ref.watch(captureRepositoryProvider);
  return repo.watchCaptures();
});
