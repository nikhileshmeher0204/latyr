import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';

class WeatherContext {
  final String city;
  final double temperature;
  final String condition;

  WeatherContext({required this.city, required this.temperature, required this.condition});

  factory WeatherContext.fromJson(Map<String, dynamic> json) {
    return WeatherContext(
      city: json['city'] as String,
      temperature: (json['temperature'] as num).toDouble(),
      condition: json['condition'] as String,
    );
  }
}

final weatherProvider = FutureProvider<WeatherContext>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  // Ideally fetch location here, but falling back to IP based via API if null
  final response = await apiClient.getWeatherContext(null, null);
  if (response.statusCode == 200 && response.data != null) {
    return WeatherContext.fromJson(response.data as Map<String, dynamic>);
  }
  throw Exception('Failed to fetch weather');
});



class HomeStats {
  final int capturesToday;
  final int categoriesDiscovered;
  final int processingQueue;

  HomeStats(this.capturesToday, this.categoriesDiscovered, this.processingQueue);
}

final homeStatsProvider = StreamProvider.autoDispose<HomeStats>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.watchAllCaptures().map((captures) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    int todayCount = 0;
    int processingCount = 0;
    final categories = <String>{};

    for (var c in captures) {
      if (c.createdAt.isAfter(todayStart)) {
        todayCount++;
      }
      if (c.status == 'PROCESSING' || c.status == 'PENDING' || c.status == 'PENDING_SYNC') {
        processingCount++;
      }
      if (c.category != null && c.category!.isNotEmpty) {
        categories.add(c.category!);
      }
    }
    
    return HomeStats(todayCount, categories.length, processingCount);
  });
});




