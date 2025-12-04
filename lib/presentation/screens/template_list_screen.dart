import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/constants.dart';
import '../../data/models/recipe_template_model.dart';
import '../../presentation/widgets/popular_templates_widget.dart';
import '../../presentation/widgets/recent_templates_widget.dart';
import '../../services/template_manager.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TemplateManager _templateManager;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: AppConstants.recipeCategories.length,
      vsync: this,
    );
    _initializeTemplateManager();
  }

  Future<void> _initializeTemplateManager() async {
    final prefs = await SharedPreferences.getInstance();
    _templateManager = TemplateManager(prefs);
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Template Resep')),
      body: Column(
        children: [
          RecentTemplatesWidget(
            templateManager: _templateManager,
            onTemplateSelected: _useTemplate,
          ),
          PopularTemplatesWidget(
            templateManager: _templateManager,
            onTemplateSelected: _useTemplate,
          ),
          const SizedBox(height: 8),
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: AppConstants.recipeCategories
                .map((category) => Tab(text: category))
                .toList(),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: AppConstants.recipeCategories.map((category) {
                return _buildCategoryTemplates(category);
              }).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTemplateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryTemplates(String category) {
    final templates = _templateManager.getTemplatesByCategory(category);

    if (templates.isEmpty) {
      return Center(child: Text('Tidak ada template di kategori $category'));
    }

    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) {
        final template = templates[index];
        final categoryColor =
            AppConstants.categoryColors[template.category] ??
            AppConstants.categoryColors['Other']!;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: categoryColor.withOpacity(0.2),
              child: Icon(Icons.restaurant_menu, color: categoryColor),
            ),
            title: Text(
              template.name,
              style: TextStyle(
                color: categoryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Digunakan ${template.useCount} kali',
              style: TextStyle(color: categoryColor.withOpacity(0.7)),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: categoryColor),
                  onPressed: () => _showEditTemplateDialog(context, template),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: categoryColor.withOpacity(0.7),
                  ),
                  onPressed: () =>
                      _showDeleteConfirmationDialog(context, template),
                ),
              ],
            ),
            onTap: () => _useTemplate(template),
          ),
        );
      },
    );
  }

  Future<void> _showAddTemplateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    String selectedCategory = AppConstants.recipeCategories.first;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Template Baru'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Template'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: AppConstants.recipeCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final template = RecipeTemplate(
                  name: nameController.text,
                  category: selectedCategory,
                );
                await _templateManager.addTemplate(template);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTemplateDialog(
    BuildContext context,
    RecipeTemplate template,
  ) async {
    final nameController = TextEditingController(text: template.name);
    String selectedCategory = template.category;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Template'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              items: AppConstants.recipeCategories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  selectedCategory = value;
                }
              },
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _templateManager.deleteTemplate(template.name);
                final newTemplate = RecipeTemplate(
                  name: nameController.text,
                  category: selectedCategory,
                  useCount: template.useCount,
                  lastUsed: template.lastUsed,
                );
                await _templateManager.addTemplate(newTemplate);
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    BuildContext context,
    RecipeTemplate template,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Template'),
        content: Text(
          'Apakah Anda yakin ingin menghapus template "${template.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () async {
              await _templateManager.deleteTemplate(template.name);
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _useTemplate(RecipeTemplate template) async {
    await _templateManager.updateTemplateUsage(template.name);
    setState(() {});
    // TODO: Implement template usage functionality
  }
}
