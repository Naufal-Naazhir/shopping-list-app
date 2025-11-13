import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/presentation/widgets/suggestion_chip.dart'; // Corrected import
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Added for context.read
import 'package:go_router/go_router.dart';

class AddItemScreen extends StatefulWidget {
  final String listId;
  final String listName;

  const AddItemScreen({
    super.key,
    required this.listId,
    required this.listName,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  // Removed _shoppingListRepository field, will use context.read directly

  bool _isLoading = false; // Defined _isLoading

  final List<String> _suggestions = [
    'Susu',
    'Roti',
    'Telur',
    'Nasi',
    'Ayam',
    'Daging',
    'Ikan',
    'Sayur',
    'Buah',
    'Minyak',
    'Gula',
    'Garam',
    'Kopi',
    'Teh',
    'Mie Instan',
    'Sabun',
    'Shampo',
    'Pasta Gigi',
  ];

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _itemNameController.text = suggestion;
    });
  }

  Future<void> _addItemToList() async {
    if (_itemNameController.text.isEmpty) {
      _showSnackBar('Nama item tidak boleh kosong!');
      return;
    }
    if (_quantityController.text.isEmpty ||
        int.tryParse(_quantityController.text) == null) {
      _showSnackBar('Jumlah harus angka!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final newItem = ShoppingItem(
        id: '', // Firestore will generate this
        name: _itemNameController.text,
        quantity: int.parse(_quantityController.text),
        price: 0.0, // Default price for now
      );
      await context.read<ShoppingListRepository>().addItemToList(
        widget.listId,
        newItem,
      );
      _showSnackBar('Item berhasil ditambahkan!');
      if (mounted)
        context.pop(true); // Check mounted before pop, return true on success
    } catch (e) {
      _showSnackBar('Gagal menambahkan item: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tambah Item ke ${widget.listName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nama Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _itemNameController,
              decoration: InputDecoration(
                hintText: 'Contoh: Apel',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Jumlah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 2',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Saran Item',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: _suggestions.map((suggestion) {
                return SuggestionChip(
                  text: suggestion,
                  onTap: _selectSuggestion,
                );
              }).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addItemToList,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: _isLoading
                    ? CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.onPrimary,
                      )
                    : Text(
                        'Tambah Item',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
