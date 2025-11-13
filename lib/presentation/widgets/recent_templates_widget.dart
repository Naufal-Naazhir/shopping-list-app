import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/recipe_template_model.dart';
import '../../services/template_manager.dart';

class RecentTemplatesWidget extends StatelessWidget {
  final TemplateManager templateManager;
  final void Function(RecipeTemplate) onTemplateSelected;

  const RecentTemplatesWidget({
    super.key,
    required this.templateManager,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final recentTemplates = templateManager.getRecentlyUsedTemplates(
      limit: AppConstants.maxRecentTemplates,
    );

    if (recentTemplates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Recent Templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recentTemplates.length,
              itemBuilder: (context, index) {
                final template = recentTemplates[index];
                final categoryColor =
                    AppConstants.categoryColors[template.category] ??
                    AppConstants.categoryColors['Other']!;

                return Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Material(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      onTap: () => onTemplateSelected(template),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 120,
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              template.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: categoryColor,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              template.category,
                              style: TextStyle(
                                color: categoryColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
