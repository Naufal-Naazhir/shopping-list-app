import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/presentation/bloc/list_detail_bloc.dart';
import 'package:belanja_praktis/presentation/widgets/native_ad_widget.dart';
import 'package:belanja_praktis/presentation/widgets/shopping_item_card.dart';
import 'package:belanja_praktis/utils/price_utils.dart';
import 'package:belanja_praktis/utils/shelf_life_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class ListDetailScreen extends StatefulWidget {
  final String listId;

  const ListDetailScreen({super.key, required this.listId});

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  final ShoppingListRepository _shoppingListRepository =
      GetIt.I<ShoppingListRepository>();
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    context.read<ListDetailBloc>().add(LoadListDetail(widget.listId));
    _checkPremiumStatus();
  }

  Future<void> _checkPremiumStatus() async {
    final isPremium = await _authRepository.isCurrentUserPremium();
    if (mounted) {
      setState(() {
        _isPremium = isPremium;
      });
    }
  }

  Future<void> _showDeleteConfirmationDialog(ShoppingItem item) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Delete Item?',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${item.name}"?',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'Delete',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              onPressed: () {
                context.read<ListDetailBloc>().add(
                  DeleteShoppingItem(widget.listId, item.id),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Helper function to get a smart expiry date suggestion
  DateTime _getSuggestedExpiryDate(String itemName) {
    final days = getSuggestedShelfLifeDays(itemName);
    return DateTime.now().add(Duration(days: days));
  }

  Future<void> _showMoveToPantryDialog(ShoppingItem item) async {
    // Get the smart suggestion automatically
    DateTime suggestedDate = _getSuggestedExpiryDate(item.name);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Pindahkan "${item.name}" ke Pantry?',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          content: Text(
            'Item ini akan dipindahkan ke pantry dengan tanggal kedaluwarsa otomatis: ${DateFormat('d MMMM yyyy').format(suggestedDate)}.',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Batal',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(
                'Pindahkan',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      context.read<ListDetailBloc>().add(
        MoveToPantry(widget.listId, item, expiryDate: suggestedDate),
      );
    }
  }

  Future<void> _showEditItemDialog(ShoppingItem item) async {
    final nameController = TextEditingController(text: item.name);
    final quantityController = TextEditingController(
      text: item.quantity.toString(),
    );
    final priceController = TextEditingController(text: item.price.toString());

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Edit Item',
            style: TextStyle(
              color: Theme.of(dialogContext).colorScheme.onSurface,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Item Name'),
                ),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              child: Text(
                'Save',
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.primary,
                ),
              ),
              onPressed: () {
                // TODO: Add validation
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirmed == true && mounted) {
      final updatedItem = item.copyWith(
        name: nameController.text,
        quantity: int.tryParse(quantityController.text) ?? item.quantity,
        price: double.tryParse(priceController.text) ?? item.price,
      );

      context.read<ListDetailBloc>().add(
        UpdateShoppingItem(widget.listId, updatedItem),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ListDetailBloc, ListDetailState>(
          builder: (context, state) {
            if (state is ListDetailLoaded) {
              // Find the list name from the loaded items or from a separate call
              // For now, we'll just display a generic title or fetch it from the repository
              return StreamBuilder<List<ShoppingList>>(
                stream: _shoppingListRepository.getShoppingLists(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final list = snapshot.data!.firstWhere(
                      (l) => l.id == widget.listId,
                      orElse: () => ShoppingList(
                        id: '',
                        userId: 'unknown',
                        name: 'My List',
                        items: [],
                        createdAt: DateTime.now(),
                      ),
                    );
                    return Text(list.name);
                  }
                  return const Text('My List');
                },
              );
            }
            return const Text('My List');
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement list options menu (edit list name, delete list)
            },
          ),
        ],
      ),
      body: BlocBuilder<ListDetailBloc, ListDetailState>(
        builder: (context, state) {
          if (state is ListDetailLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ListDetailLoaded) {
            if (state.items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '📝',
                        style: TextStyle(fontSize: 48, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No items yet',
                        style: TextStyle(
                          fontSize: 20,
                          color: theme.colorScheme.onBackground,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Start adding items to your list',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () async {
                          final result = await context.push<bool>(
                            '/add-item/${widget.listId}',
                          );
                          if (result == true && mounted) {
                            context.read<ListDetailBloc>().add(
                              LoadListDetail(widget.listId),
                            );
                          }
                        },
                        icon: Icon(
                          Icons.add,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          'ADD ITEM',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              // Calculate totals
              final totalItems = state.items.length;
              final checkedItems = state.items
                  .where((item) => item.isBought)
                  .length;
              double totalPrice = 0;
              double checkedPrice = 0;
              double uncheckedPrice = 0;

              for (var item in state.items) {
                final price = item.price;
                totalPrice += price;
                if (item.isBought) {
                  checkedPrice += price;
                } else {
                  uncheckedPrice += price;
                }
              }

              // Calculate total items including ads
              final totalItemsWithAds = _isPremium
                  ? state.items.length
                  : state.items.length + (state.items.length ~/ 6);

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: totalItemsWithAds,
                      itemBuilder: (context, index) {
                        // Show native ad every 6 items for non-premium users
                        if (!_isPremium && (index + 1) % 7 == 0) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: NativeAdWidget(),
                          );
                        }

                        // Calculate actual item index (accounting for ads)
                        final itemIndex = _isPremium
                            ? index
                            : index - (index ~/ 7);

                        // Safety check
                        if (itemIndex >= state.items.length) {
                          return const SizedBox.shrink();
                        }

                        final item = state.items[itemIndex];
                        return ShoppingItemCard(
                          item: item,
                          onToggle: (bool? value) {
                            if (value != null) {
                              context.read<ListDetailBloc>().add(
                                ToggleShoppingItem(
                                  widget.listId,
                                  item.id,
                                  value,
                                ),
                              );
                            }
                          },
                          onDelete: () => _showDeleteConfirmationDialog(item),
                          onMoveToPantry: () => _showMoveToPantryDialog(item),
                          onEdit: () => _showEditItemDialog(item),
                          formatPrice: (price) =>
                              PriceUtils.formatPrice(price.toInt()),
                        );
                      },
                    ),
                  ),
                  // Summary
                  Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Items Completed:',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              '$checkedItems/$totalItems',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Unchecked Total:',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              PriceUtils.formatPrice(uncheckedPrice.toInt()),
                              style: TextStyle(
                                color: theme.colorScheme.secondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (checkedItems > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Checked Total:',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                PriceUtils.formatPrice(checkedPrice.toInt()),
                                style: TextStyle(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Divider(
                            height: 24,
                            thickness: 1,
                            color: theme.colorScheme.outline.withOpacity(0.5),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Grand Total:',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onBackground,
                                ),
                              ),
                              Text(
                                PriceUtils.formatPrice(totalPrice.toInt()),
                                style: TextStyle(
                                  fontSize: 20,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Add Item Button
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await context.push<bool>(
                            '/add-item/${widget.listId}',
                          );
                          if (result == true && mounted) {
                            context.read<ListDetailBloc>().add(
                              LoadListDetail(widget.listId),
                            );
                          }
                        },
                        icon: Icon(
                          Icons.add,
                          color: theme.colorScheme.onPrimary,
                        ),
                        label: Text(
                          'ADD ITEM',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
          } else if (state is ListDetailError) {
            return Center(child: Text('Error: ${state.message}'));
          }
          return const Center(child: Text('Unknown state'));
        },
      ),
    );
  }
}
