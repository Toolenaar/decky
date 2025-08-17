import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';

class NavigationShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const NavigationShell({super.key, required this.navigationShell});

  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> with TickerProviderStateMixin {
  bool _isDrawerExpanded = true;
  bool _showText = true;
  late AnimationController _drawerAnimationController;
  late AnimationController _textAnimationController;
  late Animation<double> _drawerAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();
    _drawerAnimationController = AnimationController(duration: const Duration(milliseconds: 200), vsync: this);
    _textAnimationController = AnimationController(duration: const Duration(milliseconds: 150), vsync: this);
    _drawerAnimation = Tween<double>(
      begin: 72,
      end: 250,
    ).animate(CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut));
    _textAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _textAnimationController, curve: Curves.easeIn));

    // Set initial state
    if (_isDrawerExpanded) {
      _drawerAnimationController.value = 1.0;
      _textAnimationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    _textAnimationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      if (_isDrawerExpanded) {
        // Closing: fade out text first, then close drawer
        _showText = false;
        _textAnimationController.reverse().then((_) {
          if (mounted) {
            setState(() {
              _isDrawerExpanded = false;
            });
            _drawerAnimationController.reverse();
          }
        });
      } else {
        // Opening: open drawer first, then fade in text
        _isDrawerExpanded = true;
        _drawerAnimationController.forward().then((_) {
          if (mounted) {
            setState(() {
              _showText = true;
            });
            _textAnimationController.forward();
          }
        });
      }
    });
  }

  List<NavigationItem> get _navigationItems => [
    NavigationItem(icon: Icons.style, label: 'navigation.decks'.tr(), route: '/decks'),
    NavigationItem(icon: Icons.search, label: 'navigation.find_cards'.tr(), route: '/find-cards'),
    NavigationItem(icon: Icons.collections, label: 'navigation.collection'.tr(), route: '/collection'),
    NavigationItem(icon: Icons.person, label: 'navigation.profile'.tr(), route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 768;
        final bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 768;

        if (isDesktop || isTablet) {
          return _buildDesktopLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  Widget _buildDesktopLayout() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Row(
        children: [
          AnimatedBuilder(
            animation: _drawerAnimation,
            builder: (context, child) {
              return Container(
                width: _drawerAnimation.value,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border(right: BorderSide(color: colorScheme.outlineVariant, width: 1)),
                ),
                child: Column(
                  children: [
                    Container(
                      height: 64,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(_isDrawerExpanded ? Icons.menu_open : Icons.menu),
                            onPressed: _toggleDrawer,
                          ),
                          if (_showText) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: FadeTransition(
                                opacity: _textAnimation,
                                child: Text(
                                  'app.title'.tr(),
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _navigationItems.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final isSelected = widget.navigationShell.currentIndex == index;

                          return _buildNavigationItem(
                            item: item,
                            isSelected: isSelected,
                            onTap: () => _onItemTapped(index),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }

  Widget _buildNavigationItem({required NavigationItem item, required bool isSelected, required VoidCallback onTap}) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.6);

    return Tooltip(
      message: _showText ? '' : item.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          padding: const EdgeInsets.only(left: 12),
          child: OverflowBox(
            maxWidth: double.infinity,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: color, size: 24),
                if (_showText) ...[
                  const SizedBox(width: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: _isDrawerExpanded ? 180 : 0),
                    child: FadeTransition(
                      opacity: _textAnimation,
                      child: Text(
                        item.label,
                        style: TextStyle(color: color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) => _onItemTapped(index),
        destinations: _navigationItems.map((item) {
          return NavigationDestination(icon: Icon(item.icon), label: item.label);
        }).toList(),
      ),
    );
  }

  void _onItemTapped(int index) {
    widget.navigationShell.goBranch(index, initialLocation: index == widget.navigationShell.currentIndex);
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  NavigationItem({required this.icon, required this.label, required this.route});
}
