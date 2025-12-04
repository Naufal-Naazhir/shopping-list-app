import 'package:belanja_praktis/presentation/screens/list_detail_screen.dart';
import 'package:belanja_praktis/presentation/screens/pantry_screen.dart';
import 'package:belanja_praktis/presentation/screens/premium_analytics_screen.dart';
import 'package:belanja_praktis/presentation/screens/settings_screen.dart';
import 'package:belanja_praktis/presentation/screens/shell_screen.dart';
import 'package:belanja_praktis/presentation/screens/splash_screen.dart';
import 'package:belanja_praktis/presentation/screens/saweria_webview_page.dart';
import 'package:belanja_praktis/presentation/screens/payment_webview_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:belanja_praktis/presentation/screens/home_screen.dart';

import 'package:belanja_praktis/presentation/screens/profile_screen.dart';
import 'package:belanja_praktis/presentation/screens/login_screen.dart';
import 'package:belanja_praktis/presentation/screens/register_screen.dart';
import 'package:belanja_praktis/presentation/screens/add_list_or_generate_screen.dart';
import 'package:belanja_praktis/presentation/screens/add_item_screen.dart';
import 'package:belanja_praktis/presentation/screens/admin_screen.dart';
import 'package:belanja_praktis/data/repositories/auth_repository.dart';
import 'package:belanja_praktis/presentation/bloc/list_detail_bloc.dart';
import 'package:belanja_praktis/data/repositories/shopping_list_repository.dart';
import 'package:belanja_praktis/presentation/screens/payment_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    refreshListenable: GetIt.I<AuthRepository>(),
    initialLocation: '/splash',
    routes: <RouteBase>[
      GoRoute(
        path: '/splash',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: '/login',
        builder: (BuildContext context, GoRouterState state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: '/register',
        builder: (BuildContext context, GoRouterState state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: '/add-list',
        builder: (BuildContext context, GoRouterState state) {
          return AddListOrGenerateScreen();
        },
      ),
      GoRoute(
        path: '/add-item/:listId',
        builder: (BuildContext context, GoRouterState state) {
          final listId = state.pathParameters['listId']!;
          return AddItemScreen(
            listId: listId,
            listName: state.extra as String? ?? 'Shopping List',
          );
        },
      ),
      GoRoute(
        // New Admin Route
        path: '/admin',
        builder: (BuildContext context, GoRouterState state) {
          return const AdminScreen();
        },
      ),
      ShellRoute(
        builder: (BuildContext context, GoRouterState state, Widget child) {
          return ShellScreen(child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: '/',
            builder: (BuildContext context, GoRouterState state) {
              return const HomeScreen();
            },
            routes: <RouteBase>[
              GoRoute(
                path: 'list/:listId',
                builder: (BuildContext context, GoRouterState state) {
                  final listId = state.pathParameters['listId']!;
                  return BlocProvider<ListDetailBloc>(
                    create: (context) =>
                        ListDetailBloc(GetIt.I<ShoppingListRepository>()),
                    child: ListDetailScreen(listId: listId),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/pantry',
            builder: (BuildContext context, GoRouterState state) {
              return const PantryScreen();
            },
          ),
          GoRoute(
            path: '/profile',
            builder: (BuildContext context, GoRouterState state) {
              return const ProfileScreen();
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsScreen();
        },
      ),
      GoRoute(
        path: '/premium-analytics',
        builder: (BuildContext context, GoRouterState state) {
          return const PremiumAnalyticsScreen();
        },
      ),
      GoRoute(
        path: '/upgrade',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userEmail = extra?['userEmail'] as String?;
          final userId = extra?['userId'] as String?;
          
          if (userEmail == null || userId == null) {
            return const Text('Error: User data missing for PaymentPage');
          }
          final authRepository = GetIt.I<AuthRepository>();
          return PaymentPage(
            userEmail: userEmail,
            userId: userId,
            client: authRepository.client, // Pass the authenticated client
          );
        },
      ),
      GoRoute(
        path: '/payment-webview',
        builder: (BuildContext context, GoRouterState state) {
          final extra = state.extra as Map<String, String>?;
          final paymentUrl = extra?['paymentUrl'] ?? '';
          final merchantOrderId = extra?['merchantOrderId'] ?? '';
          return PaymentWebViewScreen(
            paymentUrl: paymentUrl,
            merchantOrderId: merchantOrderId,
          );
        },
      ),
      GoRoute(
        path: '/saweria-webview',
        builder: (BuildContext context, GoRouterState state) {
          final url = state.extra as String? ?? 'https://saweria.co';
          return SaweriaWebviewPage(url: url);
        },
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) async {
      final auth = GetIt.I<AuthRepository>();
      final isLoggedIn = await auth.isLoggedIn();
      final onAuthScreen =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isonSplashScreen = state.matchedLocation == '/splash';

      if (isonSplashScreen) {
        return isLoggedIn ? '/' : '/login';
      }

      // --- LOGGED OUT USERS ---
      if (!isLoggedIn) {
        // If a logged-out user tries to go anywhere but the login/register
        // screens, redirect them to login.
        return onAuthScreen ? null : '/login';
      }

      // --- LOGGED IN USERS ---
      // At this point, we know isLoggedIn is true.
      final user = await auth.getCurrentUser();
      final isAdmin = user != null ? await auth.isAdmin(user.uid) : false;

      // If a logged-in user is on an auth screen (which can happen after the refresh),
      // redirect them to their correct home page.
      if (onAuthScreen) {
        return isAdmin ? '/admin' : '/';
      }

      // If a non-admin tries to access the /admin route directly, block them.
      if (state.matchedLocation == '/admin' && !isAdmin) {
        return '/';
      }

      // No other redirection is needed.
      return null;
    },
  );
}
