import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import 'package:decky_admin/screens/login_screen.dart';
import 'package:decky_admin/screens/dashboard_screen.dart';
import 'package:decky_admin/screens/cards/cards_list_screen.dart';
import 'package:decky_admin/screens/cards/card_edit_screen.dart';
import 'package:decky_admin/screens/decks/decks_list_screen.dart';
import 'package:decky_admin/screens/decks/deck_edit_screen.dart';
import 'package:decky_admin/screens/sealed_products/sealed_products_list_screen.dart';
import 'package:decky_admin/screens/sets/sets_list_screen.dart';
import 'package:decky_admin/screens/tokens/tokens_list_screen.dart';

class AppRouter {
  static void initializeAuthNotifier() {
    _AuthStateNotifier.instance.initialize();
  }

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      try {
        final userController = GetIt.instance<UserController>();
        final isLoggedIn = userController.currentUser != null;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isLoggedIn && !isLoginRoute) {
          return '/login';
        }

        if (isLoggedIn && isLoginRoute) {
          return '/dashboard';
        }

        return null;
      } catch (e) {
        // If services aren't ready yet, go to login
        return '/login';
      }
    },
    refreshListenable: _AuthStateNotifier.instance,
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          // Cards routes
          GoRoute(
            path: 'cards',
            builder: (context, state) => const CardsListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const CardEditScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => CardEditScreen(
                  cardId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          // Decks routes
          GoRoute(
            path: 'decks',
            builder: (context, state) => const DecksListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const DeckEditScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) => DeckEditScreen(
                  deckId: state.pathParameters['id'],
                ),
              ),
            ],
          ),
          // Sealed Products routes
          GoRoute(
            path: 'sealed-products',
            builder: (context, state) => const SealedProductsListScreen(),
          ),
          // Sets routes
          GoRoute(
            path: 'sets',
            builder: (context, state) => const SetsListScreen(),
          ),
          // Tokens routes
          GoRoute(
            path: 'tokens',
            builder: (context, state) => const TokensListScreen(),
          ),
        ],
      ),
    ],
  );
}

class _AuthStateNotifier extends ChangeNotifier {
  static final _AuthStateNotifier instance = _AuthStateNotifier._();
  
  _AuthStateNotifier._();

  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    _initialized = true;
    
    try {
      final userController = GetIt.instance<UserController>();
      userController.authStateChanges.listen((user) {
        notifyListeners();
      });
    } catch (e) {
      // Services not ready yet, will be initialized later
    }
  }
}