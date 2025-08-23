import 'package:decky_app/views/login_screen.dart';
import 'package:decky_app/views/navigation_shell.dart';
import 'package:decky_app/views/decks/decks_view.dart';
import 'package:decky_app/views/decks/deck_detail_view.dart';
import 'package:decky_app/views/search/find_cards_view.dart';
import 'package:decky_app/views/collection_view.dart';
import 'package:decky_app/views/profile_view.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import 'package:easy_localization/easy_localization.dart';

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
        final hasAccount = userController.account != null;
        final isLoginRoute = state.matchedLocation == '/login';
        final isLoadingRoute = state.matchedLocation == '/loading';

        // If user is logged in but account not loaded yet, show loading
        if (isLoggedIn && !hasAccount && !isLoadingRoute) {
          return '/loading';
        }

        // If not logged in and not on login page, redirect to login
        if (!isLoggedIn && !isLoginRoute && !isLoadingRoute) {
          return '/login';
        }

        // If logged in with account and on login or loading page, go to decks
        if (isLoggedIn && hasAccount && (isLoginRoute || isLoadingRoute)) {
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
      GoRoute(
        path: '/loading', 
        builder: (context, state) => const _LoadingScreen()
      ),
      GoRoute(
        path: '/decks/:deckId',
        builder: (context, state) {
          final deckId = state.pathParameters['deckId']!;
          return DeckDetailView(deckId: deckId);
        },
      ),
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
      
      // Listen to auth state changes
      userController.authStateChanges.listen((user) {
        notifyListeners();
      });
      
      // Also listen to account changes
      userController.accountSink.listen((account) {
        notifyListeners();
      });
    } catch (e) {
      // Services not ready yet, will be initialized later
    }
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(
              'common.loading'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
