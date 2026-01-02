import 'package:belanja_praktis/data/models/recipe_template_model.dart';
import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/models/user_model.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/presentation/widgets/recipe_templates.dart';
import 'package:belanja_praktis/services/ai_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class AddListOrGenerateScreen extends StatefulWidget {
  const AddListOrGenerateScreen({super.key});

  @override
  State<AddListOrGenerateScreen> createState() =>
      _AddListOrGenerateScreenState();
}

class _AddListOrGenerateScreenState extends State<AddListOrGenerateScreen> {
  final TextEditingController _listNameController = TextEditingController();
  final TextEditingController _recipeController = TextEditingController();
  final ShoppingListRepository _shoppingListRepository =
      GetIt.I<ShoppingListRepository>();
  final AIService _aiService = GetIt.I<AIService>();
  final AuthRepository _authRepository =
      GetIt.I<AuthRepository>(); // For premium check

  // State variables
  bool _isLoading = false;
  bool _isManualMode = true;
  UserModel? _currentUser; // To hold the current user
  List<ShoppingItem> _generatedShoppingItems = [];
  double _generatedTotal = 0;
  List<String> _generatedSteps = []; // To hold recipe steps
  int _quotaRefreshKey = 0; // Key to force FutureBuilder rebuild

  @override
  void initState() {
    super.initState();
    _fetchCurrentUser();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh quota when screen becomes visible again
    // Increment key to force FutureBuilder rebuild
    if (_currentUser != null && !_currentUser!.isPremium && mounted) {
      setState(() {
        _quotaRefreshKey++; // Force FutureBuilder to rebuild
      });
    }
  }

  Future<void> _fetchCurrentUser() async {
    final user = await _authRepository.getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  @override
  void dispose() {
    _listNameController.dispose();
    _recipeController.dispose();
    super.dispose();
  }

  Future<void> _generateListFromRecipe() async {
    if (_currentUser == null) {
      _showSnackBar('Could not verify user. Please try again.');
      return;
    }

    // Check premium status and AI usage limits
    if (!_currentUser!.isPremium) {
      // Calculate current quota dynamically
      final quota = await _authRepository.calculateAiQuota(_currentUser!.uid);
      if (quota <= 0) {
        _showUpgradeDialog(context);
        return;
      }
    }

    final query = _recipeController.text.trim(); // Moved this line here

    if (query.isEmpty) {
      _showSnackBar('Input tidak boleh kosong!');
      return;
    }

    setState(() {
      _isLoading = true;
      _generatedShoppingItems = [];
      _generatedTotal = 0;
      _generatedSteps = []; // Clear previous steps
    });

    try {
      final recipeQuery = _recipeController.text;
      final Map<String, dynamic> aiResponse = await _aiService
          .generateShoppingList(recipeQuery);

      final List<ShoppingItem> generatedItems =
          aiResponse['items'] as List<ShoppingItem>;
      final double total = aiResponse['total'] as double;
      final List<String> steps = aiResponse['steps'] as List<String>;

      if (mounted) {
        setState(() {
          _generatedShoppingItems = generatedItems;
          _generatedTotal = total;
          _generatedSteps = steps; // Save the steps
        });

        // Debug print
        debugPrint('Generated ${generatedItems.length} items');
        debugPrint('Total: $total');
        for (var item in generatedItems) {
          debugPrint(
            'Item: ${item.name}, Qty: ${item.quantity}, Price: ${item.price}',
          );
        }

        // No need to decrement - quota is calculated dynamically based on list count
      }
    } catch (e, stackTrace) {
      debugPrint('AI Generation Error: $e');
      debugPrint('Stack Trace: $stackTrace');
      if (mounted) {
        // Check if it's a rate limit error
        final errorMsg = e.toString();
        if (errorMsg.contains('429') ||
            errorMsg.contains('Rate limit exceeded') ||
            errorMsg.contains('temporarily unavailable') ||
            errorMsg.contains('Please wait and try again later')) {
          _showRateLimitDialog(context);
        } else {
          // Show user-friendly error dialog instead of scary technical message
          _showErrorDialog(
            context,
            'Gagal Menghasilkan Daftar',
            'Maaf, terjadi kesalahan saat membuat daftar belanja dengan AI. '
                'Silakan coba lagi atau gunakan mode manual.',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showRateLimitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('⏳ Batas Laju Tercapai'),
        content: const Text(
          'AI Service sedang sibuk dan telah mencapai batas penggunaan. '
          'Sistem sudah mencoba lagi secara otomatis, tetapi tetap gagal.\n\n'
          'Silakan coba lagi dalam beberapa menit. 🙏',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              // Refresh quota before retry
              if (mounted) {
                setState(() {
                  _quotaRefreshKey++;
                });
              }
              // Retry the generation
              await Future.delayed(const Duration(seconds: 2));
              if (mounted) {
                await _generateListFromRecipe();
              }
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  Future<void> _showRecipeStepsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Langkah Pembuatan: ${_recipeController.text}'),
          content: SingleChildScrollView(
            child: ListBody(
              children: _generatedSteps.asMap().entries.map((entry) {
                int idx = entry.key + 1;
                String step = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('$idx. $step'),
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Tutup'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // ... (other methods like _addShoppingList, _saveGeneratedList, _showSnackBar remain the same) ...

  Future<void> _addShoppingList() async {
    if (_listNameController.text.isEmpty) {
      _showSnackBar('Nama daftar tidak boleh kosong!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser == null) {
        _showSnackBar('Pengguna tidak login.');
        return;
      }

      final newList = ShoppingList(
        id: '', // Firestore will generate this
        userId: _currentUser!.uid,
        name: _listNameController.text,
        items: [],
        createdAt: DateTime.now(),
      );
      await _shoppingListRepository.addList(newList);
      _showSnackBar('Daftar belanja berhasil ditambahkan!');
      if (mounted) context.go('/'); // Navigate back to home
    } catch (e) {
      _showSnackBar('Gagal menambahkan daftar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batas AI Tercapai'),
        content: const Text(
          'Anda telah menghabiskan kuota AI gratis. Upgrade ke premium untuk penggunaan tanpa batas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await context.push('/upgrade');
              if (mounted) {
                await _fetchCurrentUser();
              }
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Refresh quota before retry
              if (mounted) {
                setState(() {
                  _quotaRefreshKey++;
                });
              }
              // Retry the generation
              _generateListFromRecipe();
            },
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveGeneratedList() async {
    if (_generatedShoppingItems.isEmpty) {
      _showSnackBar('Tidak ada item untuk disimpan!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_currentUser == null) {
        _showSnackBar('Pengguna tidak login.');
        setState(() => _isLoading = false);
        return;
      }

      // 1. Create the list object without items
      final listShell = ShoppingList(
        id: '', // Will be generated by Appwrite
        userId: _currentUser!.uid,
        name: _recipeController.text.isNotEmpty
            ? _recipeController.text
            : 'Daftar dari AI',
        createdAt: DateTime.now(),
      );

      // 2. Add the list to the repository and get the created list back with its ID
      final createdList = await _shoppingListRepository.addList(listShell);

      // 3. Loop through the generated items and add them to the new list
      for (final item in _generatedShoppingItems) {
        await _shoppingListRepository.addItemToList(createdList.id, item);
      }

      _showSnackBar('Daftar berhasil disimpan!');
      if (mounted) context.go('/'); // Navigate back to home
    } catch (e) {
      _showSnackBar('Gagal menyimpan daftar: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Daftar Belanja'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Manual'),
                      icon: Icon(Icons.edit),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Generate AI'),
                      icon: Icon(Icons.auto_awesome),
                    ),
                  ],
                  selected: <bool>{_isManualMode},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() {
                      _isManualMode = newSelection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_isManualMode) ..._buildManualListInput(),
              if (!_isManualMode) Column(children: _buildRecipeInput()),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildManualListInput() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = colorScheme.primary;

    return [
      Text(
        'Buat Daftar Belanja Baru',
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface, // Use theme's onSurface color
        ),
      ),
      const SizedBox(height: 20),
      Text(
        'Nama Daftar Belanja',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface.withOpacity(
            0.9,
          ), // Slightly transparent onSurface
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _listNameController,
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurface, // Use theme's onSurface color
          ),
          decoration: InputDecoration(
            hintText: 'Contoh: Belanja Bulanan, Daftar Bulan Ini, dll.',
            hintStyle: TextStyle(
              color: colorScheme.onSurface.withOpacity(
                0.6,
              ), // Use theme's onSurface with opacity
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: primaryColor.withOpacity(0.5),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.transparent, // Transparent background
          ),
        ),
      ),
      const SizedBox(height: 20),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _addShoppingList,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            shadowColor: primaryColor.withOpacity(0.3),
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          child: _isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('Tambah Daftar', style: TextStyle(fontSize: 18)),
        ),
      ),
    ];
  }

  List<Widget> _buildRecipeInput() {
    if (this._generatedShoppingItems.isNotEmpty) {
      return [
        const Text(
          'Daftar Item yang Dihasilkan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          'Total Perkiraan: Rp${_generatedTotal.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: 300,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.builder(
            itemCount: this._generatedShoppingItems.length,
            itemBuilder: (context, index) {
              final item = this._generatedShoppingItems[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 2),
                elevation: 1,
                child: ListTile(
                  dense: true,
                  title: Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    'Jumlah: ${item.quantity} | Harga: Rp${item.price.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        this._generatedShoppingItems.removeAt(index);
                        // Recalculate total when item is removed
                        _generatedTotal = _generatedShoppingItems.fold(
                          0.0,
                          (sum, item) => sum + (item.price * item.quantity),
                        );
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Premium feature button for recipe steps
        if (_generatedSteps.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showRecipeStepsDialog,
              icon: const Icon(Icons.menu_book, color: Colors.white),
              label: const Text(
                'Lihat Langkah Pembuatan',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveGeneratedList,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor:
                  Colors.green, // A different color for save button
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'Simpan Daftar yang Dihasilkan',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ];
    } else {
      return [
        const Text(
          'Buat daftar dengan AI',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (_currentUser != null && !_currentUser!.isPremium)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: FutureBuilder<int>(
              key: ValueKey(_quotaRefreshKey), // Force rebuild when key changes
              future: _authRepository.calculateAiQuota(_currentUser!.uid),
              builder: (context, snapshot) {
                final quota = snapshot.data ?? 0;
                return Text(
                  'Sisa kuota AI: $quota',
                  style: TextStyle(
                    fontSize: 13,
                    color: quota > 0 ? Colors.orange.shade800 : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                );
              },
            ),
          ),
        const SizedBox(height: 10),
        TextField(
          controller: _recipeController,
          decoration: InputDecoration(
            hintText: 'Contoh: Resep rendang, atau belanja bulanan',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<RecipeTemplate>>(
          future: GetIt.I<AIService>().getPopularTemplates(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Belum ada template tersedia.'));
            }

            return RecipeTemplates(
              templates: snapshot.data!,
              onTemplateSelected: (template) {
                _recipeController.text = template;
                _generateListFromRecipe();
              },
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _generateListFromRecipe,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor:
                  Colors.deepPurple, // A different color for AI button
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'AI Sedang Bekerja',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Mengoptimalkan daftar belanja Anda...',
                        style: TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  )
                : const Text(
                    'Generate Daftar dengan AI',
                    style: TextStyle(fontSize: 18),
                  ),
          ),
        ),
      ];
    }
  }
}
