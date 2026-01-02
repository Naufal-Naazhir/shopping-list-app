import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/presentation/bloc/shopping_list_bloc.dart';
import 'package:belanja_praktis/presentation/widgets/list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  bool _isCurrentUserPremium = false;

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
    // Ensure lists are loaded when the screen initializes
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
  }

  Future<void> _checkPremiumStatus() async {
    _isCurrentUserPremium = await _authRepository.isCurrentUserPremium();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _showEditListModal(
    BuildContext context,
    ShoppingList list,
  ) async {
    final TextEditingController _editController = TextEditingController(
      text: list.name,
    );
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Edit List Name'),
          content: TextField(
            controller: _editController,
            decoration: const InputDecoration(hintText: 'Enter new name'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                if (_editController.text.isNotEmpty) {
                  context.read<ShoppingListBloc>().add(
                    UpdateShoppingList(
                      list.copyWith(name: _editController.text),
                    ),
                  );
                  Navigator.of(dialogContext).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteListModal(
    BuildContext context,
    ShoppingList list,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete List?'),
          content: Text('Are you sure you want to delete "${list.name}"?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                context.read<ShoppingListBloc>().add(
                  DeleteShoppingList(list.id.toString()),
                );
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batas Tercapai'),
        content: const Text(
          'Anda telah mencapai batas 5 daftar. Upgrade ke premium untuk membuat daftar tanpa batas.',
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
              _checkPremiumStatus();
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header for "Daftar Ku"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Ku',
                        style: TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lihat dan kelola daftar belanja Anda',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Center(
                    child: Text('📝', style: TextStyle(fontSize: 28)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ShoppingListBloc, ShoppingListState>(
              builder: (context, state) {
                if (state is ShoppingListLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is ShoppingListLoaded) {
                  if (state.lists.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Belum ada daftar',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Klik tombol + di bawah untuk membuat daftar pertama Anda',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: state.lists.length,
                      itemBuilder: (context, index) {
                        final list = state.lists[index];
                        return ListCard(
                          list: list,
                          index: index,
                          onEdit: () => _showEditListModal(context, list),
                          onDelete: () => _showDeleteListModal(context, list),
                        );
                      },
                    );
                  }
                } else if (state is ShoppingListError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                return const Center(child: Text('Unknown state'));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<ShoppingListBloc, ShoppingListState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (state is ShoppingListLoaded) {
                if (!_isCurrentUserPremium && state.lists.length >= 5) {
                  _showUpgradeDialog(context);
                } else {
                  context.go('/add-list');
                }
              } else {
                context.go('/add-list');
              }
            },
            label: const Text(
              'DAFTAR BARU',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            backgroundColor: Theme.of(
              context,
            ).colorScheme.primary, // Changed to theme purple
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            elevation: 6,
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
