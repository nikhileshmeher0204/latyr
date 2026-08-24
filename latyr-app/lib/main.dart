import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/app.dart';
import 'package:latyr_app/config/environment_config.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('Starting Latyr in ${EnvironmentConfig.environment.toUpperCase()} environment');
  debugPrint('API URL: ${EnvironmentConfig.apiUrl}');

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

    return const LatyrApp();
  }
}
