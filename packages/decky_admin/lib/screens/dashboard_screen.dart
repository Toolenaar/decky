import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_controller.dart';
import '../controllers/card_controller.dart';
import '../controllers/deck_controller.dart';
import '../controllers/set_controller.dart';
import 'dashboard/side_menu.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Controllers should already be initialized in main.dart
    // No need to initialize them again here
  }

  @override
  Widget build(BuildContext context) {
    final userController = GetIt.instance<UserController>();
    final user = userController.currentUser;
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MTG Data Admin'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: SideMenu(currentPath: currentLocation),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to MTG Data Admin',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            if (user != null)
              Text(
                'Logged in as: ${user.email}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 32),
            
            Text(
              'Data Management',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
              children: [
                _buildDashboardCard(
                  context,
                  icon: Icons.style,
                  title: 'Cards',
                  description: 'Manage MTG cards',
                  path: '/dashboard/cards',
                  color: Colors.blue,
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.layers,
                  title: 'Decks',
                  description: 'Manage preconstructed decks',
                  path: '/dashboard/decks',
                  color: Colors.green,
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.inventory_2,
                  title: 'Sealed Products',
                  description: 'Manage sealed products',
                  path: '/dashboard/sealed-products',
                  color: Colors.orange,
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.collections,
                  title: 'Sets',
                  description: 'Manage card sets',
                  path: '/dashboard/sets',
                  color: Colors.purple,
                ),
                _buildDashboardCard(
                  context,
                  icon: Icons.token,
                  title: 'Tokens',
                  description: 'Manage token cards',
                  path: '/dashboard/tokens',
                  color: Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            _buildStatsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String path,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => context.go(path),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Stats',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cards',
                    _getSafeControllerCount<CardController>((c) => c.cards.length),
                    Icons.style,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Decks',
                    _getSafeControllerCount<DeckController>((c) => c.decks.length),
                    Icons.layers,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sets',
                    _getSafeControllerCount<SetController>((c) => c.sets.length),
                    Icons.collections,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSafeControllerCount<T extends Object>(int Function(T) accessor) {
    try {
      final controller = GetIt.instance<T>();
      return accessor(controller).toString();
    } catch (e) {
      return '-';
    }
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}