import 'package:belanja_praktis/data/models/shopping_list_model.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/presentation/bloc/payment_status_bloc.dart';
import 'package:belanja_praktis/presentation/bloc/payment_status_event.dart';
import 'package:belanja_praktis/presentation/bloc/payment_status_state.dart';
import 'package:belanja_praktis/presentation/bloc/shopping_list_bloc.dart';
import 'package:belanja_praktis/presentation/widgets/list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  bool _isCurrentUserPremium = false;
  BannerAd? _bannerAd;

  @override
  void initState() {
    super.initState();
    _startPaymentMonitoring();
    _checkPremiumStatus();
    // Ensure lists are loaded when the screen initializes
    context.read<ShoppingListBloc>().add(LoadShoppingLists());
    _loadBannerAd();
  }

  Future<void> _startPaymentMonitoring() async {
    final user = await _authRepository.getCurrentUser();
    if (user != null && mounted) {
      context
          .read<PaymentStatusBloc>()
          .add(StartPaymentStatusMonitoring(user.uid));
    }
  }

  void _loadBannerAd() async {
    // Only load ads if user is not premium
    final isPremium = await _authRepository.isCurrentUserPremium();
    if (!isPremium) {
      _bannerAd = BannerAd(
        adUnitId: 'ca-app-pub-3940256099942544/6300978111',
        request: const AdRequest(),
        size: AdSize.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            setState(() {});
          },
          onAdFailedToLoad: (ad, err) {
            ad.dispose();
          },
        ),
      )..load();
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPremiumStatus(); // Re-check premium status when dependencies change (e.g., returning from another screen)
  }

  Future<void> _checkPremiumStatus() async {
    final wasPremium = _isCurrentUserPremium;
    _isCurrentUserPremium = await _authRepository.isCurrentUserPremium();
    
    // If user just became premium, dispose the ad
    if (!wasPremium && _isCurrentUserPremium) {
      _bannerAd?.dispose();
      _bannerAd = null;
    }
    
    setState(() {}); // Rebuild to reflect premium status
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.exit_to_app),
          //   onPressed: () async {
          //     await _authRepository.logout();
          //     context.go('/login');
          //   },
          // ),
        ],
      ),
      body: BlocListener<PaymentStatusBloc, PaymentStatusState>(
        listener: (context, state) {
          if (state is PaymentStatusSuccess) {
            _checkPremiumStatus(); // Refresh the UI to reflect premium status
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Pembayaran Berhasil! 👑"),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("OK"),
                  )
                ],
              ),
            );
          }
        },
        child: Column(
          children: [
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
                                'No lists yet',
                                style:
                                    TextStyle(fontSize: 20, color: Colors.grey),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Tap the + button below to create your first list',
                                textAlign: TextAlign.center,
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
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
            if (_bannerAd != null && !_isCurrentUserPremium)
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  child: SizedBox(
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: BlocBuilder<ShoppingListBloc, ShoppingListState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            onPressed: () {
              if (state is ShoppingListLoaded) {
                if (!_isCurrentUserPremium && state.lists.length >= 5) {
                  _showPremiumDialog(context);
                } else {
                  context.go('/add-list');
                }
              } else {
                context.go('/add-list');
              }
            },
            label: const Text(
              'NEW LIST',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            icon: const Icon(Icons.add, color: Colors.white),
            backgroundColor: const Color(0xFF22B14C),
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

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Premium Feature'),
          content: const Text('You have reached the maximum number of lists for free users. Upgrade to premium to create more lists.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Upgrade'),
              onPressed: () async {
                final user = await _authRepository.getCurrentUser();
                Navigator.of(context).pop(); // Close the dialog first
                if (user != null) {
                  // Wait for the user to return from the payment page
                  await context.push(
                    '/upgrade',
                    extra: {'userEmail': user.email, 'userId': user.uid},
                  );
                  // After returning, force a refresh of the premium status
                  _checkPremiumStatus();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not get user data. Please try again.')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}

