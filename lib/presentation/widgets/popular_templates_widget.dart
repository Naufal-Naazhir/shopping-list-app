import 'package:flutter/material.dart';

import '../../config/constants.dart';
import '../../data/models/recipe_template_model.dart';
import '../../services/template_manager.dart';

class PopularTemplatesWidget extends StatelessWidget {
  final TemplateManager templateManager;
  final void Function(RecipeTemplate) onTemplateSelected;

  const PopularTemplatesWidget({
    super.key,
    required this.templateManager,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context) {
    final popularTemplates = templateManager.getMostUsedTemplates(
      limit: AppConstants.maxTemplatesPerCategory,
    );

    if (popularTemplates.isEmpty) {
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
              'Most Used Templates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: popularTemplates.length,
            itemBuilder: (context, index) {
              final template = popularTemplates[index];
              final categoryColor =
                  AppConstants.categoryColors[template.category] ??
                  AppConstants.categoryColors['Other']!;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: categoryColor.withOpacity(0.2),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: categoryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(template.name),
                subtitle: Text(
                  '${template.category} • Used ${template.useCount} times',
                  style: TextStyle(color: categoryColor.withOpacity(0.7)),
                ),
                onTap: () => onTemplateSelected(template),
              );
            },
          ),
        ],
      ),
    );
  }
}
