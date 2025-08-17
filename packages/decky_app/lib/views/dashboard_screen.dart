import 'package:decky_core/controller/user_controller.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

import '../service_locator.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final UserController _userController = locator<UserController>();
  bool _isLoggingOut = false;

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('auth.confirm_logout'.tr()),
          content: Text('auth.confirm_logout_message'.tr()),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('auth.cancel'.tr())),
            FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text('auth.logout'.tr())),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    setState(() {
      _isLoggingOut = true;
    });

    try {
      await _userController.signOut();
      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auth.logout_failed'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _userController.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('dashboard.title'.tr()),
        actions: [
          if (user != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Chip(
                avatar: const Icon(Icons.person, size: 18),
                label: Text(user.email ?? 'common.user'.tr(), style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
          IconButton(
            onPressed: _isLoggingOut ? null : _handleLogout,
            icon: _isLoggingOut
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.logout),
            tooltip: 'auth.logout'.tr(),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard, size: 80, color: Theme.of(context).primaryColor),
              const SizedBox(height: 24),
              Text('app.welcome'.tr(), style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                user?.email ?? 'dashboard.unknown_user'.tr(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.style),
                        title: Text('dashboard.my_decks'.tr()),
                        subtitle: Text('dashboard.my_decks_subtitle'.tr()),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('dashboard.coming_soon.decks'.tr())));
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.search),
                        title: Text('dashboard.card_search'.tr()),
                        subtitle: Text('dashboard.card_search_subtitle'.tr()),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('dashboard.coming_soon.card_search'.tr())));
                        },
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.auto_awesome),
                        title: Text('dashboard.ai_deck_builder'.tr()),
                        subtitle: Text('dashboard.ai_deck_builder_subtitle'.tr()),
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('dashboard.coming_soon.ai_builder'.tr())));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
