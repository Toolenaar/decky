import 'package:decky_app/views/login_screen.dart';
import 'package:decky_app/views/navigation_shell.dart';
import 'package:decky_app/views/decks_view.dart';
import 'package:decky_app/views/search/find_cards_view.dart';
import 'package:decky_app/views/collection_view.dart';
import 'package:decky_app/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';

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
          return '/decks';
        }

        return null;
      } catch (e) {
        // If services aren't ready yet, go to login
        return '/login';
      }
    },
    refreshListenable: _AuthStateNotifier.instance,
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigationShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/decks', builder: (context, state) => const DecksView())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/find-cards', builder: (context, state) => const FindCardsView())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/collection', builder: (context, state) => const CollectionView())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (context, state) => const ProfileView())],
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
