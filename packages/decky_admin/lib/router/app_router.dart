import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import 'package:decky_admin/screens/login_screen.dart';
import 'package:decky_admin/screens/dashboard_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
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
    },
    refreshListenable: AuthStateNotifier(),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
}

class AuthStateNotifier extends ChangeNotifier {
  AuthStateNotifier() {
    final userController = GetIt.instance<UserController>();
    userController.authStateChanges.listen((user) {
      notifyListeners();
    });
  }
}