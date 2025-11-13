import 'package:flutter/material.dart';

import '../../data/models/recipe_template_model.dart';

class RecipeTemplates extends StatelessWidget {
  final List<RecipeTemplate> templates;
  final Function(String) onTemplateSelected;

  const RecipeTemplates({
    Key? key,
    required this.templates,
    required this.onTemplateSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Populer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: templates.length,
            itemBuilder: (context, index) {
              final template = templates[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(template.name),
                  onPressed: () => onTemplateSelected(template.name),
                  avatar: const Icon(Icons.restaurant_menu, size: 16),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
