import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/widgets/latyr_progressive_blur.dart';
import 'package:latyr_app/app.dart';
import 'package:latyr_app/config/environment_config.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Starting Latyr in ${EnvironmentConfig.environment.toUpperCase()} environment');
  debugPrint('API URL: ${EnvironmentConfig.apiUrl}');

  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully on mobile.');
  } catch (e) {
    debugPrint('Firebase initialization: $e');
  }

  try {
    await LatyrProgressiveBlur.precache();
    debugPrint('LatyrProgressiveBlur shader precached successfully.');
  } catch (e) {
    debugPrint('LatyrProgressiveBlur precache: $e');
  }

  runApp(
    const ProviderScope(
      child: LatyrAppInitializer(),
    ),
  );
}

class LatyrAppInitializer extends ConsumerWidget {
  const LatyrAppInitializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize sync service to listen to network connectivity
    ref.watch(syncServiceProvider);
    // Eagerly initialize Android share sheet receiver
    ref.watch(shareIntentServiceProvider);
    // Eagerly initialize real-time SSE stream
    ref.watch(sseClientProvider);

    return const LatyrApp();
  }
}
