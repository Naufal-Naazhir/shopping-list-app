import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/presentation/widgets/banner_ad_widget.dart';
import 'package:belanja_praktis/services/iap_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

class ShellScreen extends StatefulWidget {
  final Widget child;

  const ShellScreen({super.key, required this.child});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> with WidgetsBindingObserver {
  bool _isPremium = false;
  final AuthRepository _authRepository = GetIt.I<AuthRepository>();
  final IapService _iapService = GetIt.I<IapService>(); // Get IapService

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initial check
    _updatePremiumStatus();

    // Listen to IapService for real-time updates
    _iapService.isPremiumNotifier.addListener(_updatePremiumStatus);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _iapService.isPremiumNotifier.removeListener(_updatePremiumStatus); // Remove listener
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh premium status when app resumes
      _authRepository.refreshUser().then((_) => _updatePremiumStatus());
    }
  }

  void _updatePremiumStatus() {
    // Get real-time status from IAP Service (useful for immediate update after purchase)
    final isIapPremium = _iapService.isPremiumNotifier.value;

    // Check persistent status from AuthRepository
    _authRepository.isCurrentUserPremium().then((isAuthPremium) {
      if (mounted) {
        setState(() {
          // User is premium if EITHER AuthRepository (DB) OR IapService (Session) says so
          _isPremium = isAuthPremium || isIapPremium;
        });
        debugPrint('🔍 Shell Screen - State updated, _isPremium = $_isPremium');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_isPremium) const BannerAdWidget(),
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: 'Daftar Belanja',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.kitchen),
                label: 'Pantry',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
            currentIndex: _calculateSelectedIndex(context),
            onTap: (int index) {
              _onItemTapped(index, context);
            },
          ),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/pantry')) {
      return 1;
    }
    if (location.startsWith('/profile')) {
      return 2;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/pantry');
        break;
      case 2:
        context.go('/profile');
        break;
    }
  }
}
