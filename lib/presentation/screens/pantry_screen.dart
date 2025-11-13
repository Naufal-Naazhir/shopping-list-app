import 'package:belanja_praktis/data/models/pantry_item.dart';
import 'package:belanja_praktis/presentation/bloc/pantry_bloc.dart';
import 'package:belanja_praktis/presentation/bloc/pantry_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class PantryScreen extends StatefulWidget {
  const PantryScreen({super.key});

  @override
  State<PantryScreen> createState() => _PantryScreenState();
}

class _PantryScreenState extends State<PantryScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data every time the screen is initialized.
    context.read<PantryBloc>().add(LoadPantry());
  }

  // Helper function to show the confirmation dialog for returning an item
  Future<void> _showReturnToListDialog(
    BuildContext context,
    PantryItem item,
  ) async {
    if (item.originalListId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item ini tidak memiliki daftar asal.')),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Kembalikan ke Daftar?'),
          content: Text(
            'Apakah Anda yakin ingin mengembalikan ${item.name} ke daftar belanja asalnya?',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                context.read<PantryBloc>().add(ReturnItemToList(item));
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Kembalikan'),
            ),
          ],
        );
      },
    );
    // Optional: show a confirmation snackbar if you want
    if (confirmed == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} dikembalikan ke daftar.')),
      );
    }
  }

  // Helper function to determine the color for the expiry date text
  Color _getExpiryDateColor(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now).inDays;
    if (difference < 0) {
      return Colors.grey; // Expired
    } else if (difference <= 3) {
      return Colors.red; // Expires within 3 days
    } else if (difference <= 7) {
      return Colors.orange; // Expires within a week
    } else {
      return Colors.green; // Good
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat dateFormatter = DateFormat(
      'd MMMM yyyy',
    ); // Date formatter

    return Scaffold(
      appBar: AppBar(title: const Text('Pantry')),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<PantryBloc, PantryState>(
              listener: (context, state) {
                if (state is PantryError) {
                  if (state.message ==
                      'Original shopping list no longer exists.') {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Gagal Mengembalikan Item'),
                        content: const Text(
                          'Daftar belanja asal untuk item ini sudah dihapus. Item tidak dapat dikembalikan ke daftar tersebut.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            child: const Text('Oke'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.message}')),
                    );
                  }
                }
              },
              builder: (context, state) {
                if (state is PantryLoading || state is PantryInitial) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is PantryLoaded || state is PantryError) {
                  // Handle both loaded and error states here
                  final itemsToDisplay = (state as PantryLoaded)
                      .items; // Access items directly from state

                  if (itemsToDisplay.isEmpty) {
                    return const Center(
                      child: Text('Tidak ada item di pantry.'),
                    );
                  }
                  return ListView.builder(
                    itemCount: itemsToDisplay.length,
                    itemBuilder: (context, index) {
                      final item = itemsToDisplay[index];
                      final expiryDateColor = item.expiryDate != null
                          ? _getExpiryDateColor(item.expiryDate!)
                          : Colors.grey;

                      return Dismissible(
                        key: Key(item.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Konfirmasi Hapus'),
                                content: Text(
                                  'Apakah Anda yakin ingin menghapus ${item.name} dari pantry?',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Batal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      context.read<PantryBloc>().add(
                                        DeletePantryItem(item.id),
                                      );
                                      Navigator.of(context).pop(true);
                                    },
                                    child: const Text(
                                      'Hapus',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                          return confirmed ?? false;
                        },
                        child: ListTile(
                          leading: IconButton(
                            icon: Icon(
                              Icons.shopping_cart_checkout,
                              color: Colors.blueAccent,
                            ),
                            tooltip: 'Kembalikan ke Daftar Belanja',
                            onPressed: () =>
                                _showReturnToListDialog(context, item),
                          ),
                          title: Text(item.name),
                          subtitle: Text(
                            'Dibeli pada ${dateFormatter.format(item.purchaseDate)}',
                          ),
                          trailing: item.expiryDate != null
                              ? Text(
                                  'Exp: ${dateFormatter.format(item.expiryDate!)}',
                                  style: TextStyle(
                                    color: expiryDateColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  );
                }
                // Fallback for any other unexpected state
                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
