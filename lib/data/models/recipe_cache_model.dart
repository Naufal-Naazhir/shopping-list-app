class RecipeCache {
  final String recipe;
  final String result;
  final DateTime timestamp;

  RecipeCache({
    required this.recipe,
    required this.result,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'recipe': recipe,
    'result': result,
    'timestamp': timestamp.toIso8601String(),
  };

  factory RecipeCache.fromJson(Map<String, dynamic> json) => RecipeCache(
    recipe: json['recipe'] as String,
    result: json['result'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );
}
