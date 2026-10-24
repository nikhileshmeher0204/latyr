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
    // Receive and reject signed-out shares without opening a library or queue.
    ref.watch(shareIntentServiceProvider);

    return const LatyrApp();
  }
}
