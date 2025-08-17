import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import '../../services/service_locator.dart';

class SideMenu extends StatelessWidget {
  final String currentPath;
  
  const SideMenu({
    super.key,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    final userController = GetIt.instance<UserController>();
    
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(userController.currentUser?.displayName ?? 'Admin'),
            accountEmail: Text(userController.currentUser?.email ?? ''),
            currentAccountPicture: CircleAvatar(
              child: Text(
                (userController.currentUser?.displayName ?? 'A')[0].toUpperCase(),
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context,
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  path: '/dashboard',
                ),
                const Divider(),
                _buildMenuItem(
                  context,
                  icon: Icons.style,
                  title: 'Cards',
                  path: '/dashboard/cards',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.layers,
                  title: 'Decks',
                  path: '/dashboard/decks',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Sealed Products',
                  path: '/dashboard/sealed-products',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.collections,
                  title: 'Sets',
                  path: '/dashboard/sets',
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.token,
                  title: 'Tokens',
                  path: '/dashboard/tokens',
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () async {
              disposeControllers();
              await userController.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String path,
  }) {
    final isSelected = currentPath == path;
    
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop(); // Close drawer
        context.go(path);
      },
    );
  }
}