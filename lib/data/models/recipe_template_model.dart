class RecipeTemplate {
  final String name;
  final String category;
  int useCount;
  DateTime lastUsed;

  RecipeTemplate({
    required this.name,
    required this.category,
    this.useCount = 0,
    DateTime? lastUsed,
  }) : lastUsed = lastUsed ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'name': name,
    'category': category,
    'useCount': useCount,
    'lastUsed': lastUsed.toIso8601String(),
  };

  factory RecipeTemplate.fromJson(Map<String, dynamic> json) => RecipeTemplate(
    name: json['name'] as String,
    category: json['category'] as String,
    useCount: json['useCount'] as int,
    lastUsed: DateTime.parse(json['lastUsed'] as String),
  );
}
