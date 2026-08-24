import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latyr_app/core/database/app_database.dart';
import 'package:latyr_app/core/theme/app_theme.dart';
import 'package:latyr_app/features/capture/presentation/capture_providers.dart';
import 'package:latyr_app/features/feed/presentation/widgets/capture_card_widget.dart';

class CollectionsScreen extends ConsumerWidget {
  const CollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final capturesAsync = ref.watch(captureListStreamProvider);

    final collections = [
      _CollectionItem(
        code: 'WATCHLIST',
        name: 'Weekend Watchlist',
        description: 'Movies and TV series saved from Reels',
        icon: Icons.movie_outlined,
        color: AppTheme.primary,
        matches: (c) => c.intent?.toUpperCase() == 'WATCH' || c.category?.toLowerCase() == 'entertainment',
      ),
      _CollectionItem(
        code: 'RECIPES',
        name: 'Recipe Box',
        description: 'Dishes, ingredients, and cooking steps',
        icon: Icons.restaurant_outlined,
        color: AppTheme.warning,
        matches: (c) => c.intent?.toUpperCase() == 'COOK' || c.category?.toLowerCase() == 'food',
      ),
      _CollectionItem(
        code: 'DEV_TOOLS',
        name: 'Dev Tools & Repos',
        description: 'GitHub repositories, CLI tools, and libraries',
        icon: Icons.code_rounded,
        color: AppTheme.accent,
        matches: (c) => c.category?.toLowerCase() == 'technology' || c.category?.toLowerCase() == 'tools',
      ),
      _CollectionItem(
        code: 'PLACES',
        name: 'Places to Visit',
        description: 'Cafes, travel spots, and destinations',
        icon: Icons.place_outlined,
        color: AppTheme.info,
        matches: (c) => c.intent?.toUpperCase() == 'VISIT' || c.category?.toLowerCase() == 'places',
      ),
      _CollectionItem(
        code: 'QUOTES',
        name: 'Wisdom & Quotes',
        description: 'Notable insights and quotes from creators',
        icon: Icons.format_quote_rounded,
        color: const Color(0xFFA855F7),
        matches: (c) => c.category?.toLowerCase() == 'quotes' || (c.entitiesJson?.contains('QUOTE') ?? false),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Collections'),
      ),
      body: capturesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primary)),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (allCaptures) {
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final col = collections[index];
              final matchingCaptures = allCaptures.where(col.matches).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: col.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(col.icon, color: col.color, size: 24),
                  ),
                  title: Text(
                    col.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  subtitle: Text(
                    col.description,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${matchingCaptures.length}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => _CollectionDetailScreen(
                          collection: col,
                          captures: matchingCaptures,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _CollectionItem {
  final String code;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(LocalCapture) matches;

  _CollectionItem({
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.matches,
  });
}

class _CollectionDetailScreen extends StatelessWidget {
  final _CollectionItem collection;
  final List<LocalCapture> captures;

  const _CollectionDetailScreen({required this.collection, required this.captures});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(collection.name),
      ),
      body: captures.isEmpty
          ? Center(
              child: Text(
                'No captures in ${collection.name} yet.',
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: captures.length,
              itemBuilder: (context, index) {
                return CaptureCardWidget(capture: captures[index]);
              },
            ),
    );
  }
}
