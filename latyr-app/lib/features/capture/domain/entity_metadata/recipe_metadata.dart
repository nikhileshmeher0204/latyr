/// Strongly-typed domain metadata model for Recipe entities.
class RecipeMetadata {
  final List<String> ingredients;
  final List<String> instructions;
  final String? prepTime;
  final String? cookTime;
  final String? totalTime;
  final String? servings;
  final String? cuisine;
  final String? difficulty;
  final String? calories;
  final String? sourceUrl;
  final String? imageUrl;

  const RecipeMetadata({
    this.ingredients = const [],
    this.instructions = const [],
    this.prepTime,
    this.cookTime,
    this.totalTime,
    this.servings,
    this.cuisine,
    this.difficulty,
    this.calories,
    this.sourceUrl,
    this.imageUrl,
  });

  factory RecipeMetadata.fromMap(
    Map<String, dynamic>? rawMeta, {
    String? fallbackDescription,
  }) {
    final meta = rawMeta ?? const <String, dynamic>{};

    final rawIngredients = meta['ingredients'];
    final List<String> ingredients = (rawIngredients is List)
        ? rawIngredients.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    final rawInstructions = meta['instructions'] ?? meta['steps'];
    final List<String> instructions = (rawInstructions is List)
        ? rawInstructions.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : const [];

    return RecipeMetadata(
      ingredients: ingredients,
      instructions: instructions,
      prepTime: meta['prep_time']?.toString(),
      cookTime: meta['cook_time']?.toString(),
      totalTime: meta['total_time']?.toString(),
      servings: meta['servings']?.toString(),
      cuisine: meta['cuisine']?.toString(),
      difficulty: meta['difficulty']?.toString(),
      calories: meta['calories']?.toString(),
      sourceUrl: meta['source_url']?.toString(),
      imageUrl: meta['image_url']?.toString() ?? meta['thumbnail']?.toString(),
    );
  }
}
