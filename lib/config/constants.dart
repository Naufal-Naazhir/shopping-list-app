import 'package:flutter/material.dart';

class AppConstants {
  // Template Categories
  static const List<String> recipeCategories = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Beverages',
    'Other',
  ];

  // Max templates per category to show
  static const int maxTemplatesPerCategory = 5;

  // Max recent templates to show
  static const int maxRecentTemplates = 5;

  // Colors for categories
  static const Map<String, Color> categoryColors = {
    'Breakfast': Colors.orange,
    'Lunch': Colors.green,
    'Dinner': Colors.blue,
    'Snacks': Colors.purple,
    'Beverages': Colors.teal,
    'Other': Colors.grey,
  };
}
