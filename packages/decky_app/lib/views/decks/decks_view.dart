import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:decky_core/controller/user_controller.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_app/views/decks/create_deck_dialog.dart';
import 'package:decky_app/widgets/deck_grid_tile.dart';

class DecksView extends StatefulWidget {
  const DecksView({super.key});

  @override
  State<DecksView> createState() => _DecksViewState();
}

class _DecksViewState extends State<DecksView> {
  late final UserDecksController _decksController;
  late final UserController _userController;

  @override
  void initState() {
    super.initState();
    _userController = GetIt.instance<UserController>();
    _decksController = GetIt.instance<UserDecksController>();
    
    // Initialize decks controller with account ID
    _initializeDecksController();
    
    // Listen to account changes in case it loads after this widget
    _userController.accountSink.listen((account) {
      if (account != null && mounted) {
        _initializeDecksController();
      }
    });
  }
  
  void _initializeDecksController() {
    if (_userController.account != null) {
      _decksController.initialize(_userController.account!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text('decks.title'.tr()),
          automaticallyImplyLeading: false,
          actions: [
            PopupMenuButton<String>(
              onSelected: _handleSortOption,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'name',
                  child: Row(
                    children: [
                      const Icon(Icons.sort_by_alpha, size: 20),
                      const SizedBox(width: 12),
                      Text('decks.sort.name'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'date',
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20),
                      const SizedBox(width: 12),
                      Text('decks.sort.date'.tr()),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'format',
                  child: Row(
                    children: [
                      const Icon(Icons.category, size: 20),
                      const SizedBox(width: 12),
                      Text('decks.sort.format'.tr()),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      body: StreamBuilder<List<UserDeck>>(
        stream: _decksController.decksStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'decks.error.loading'.tr(),
                    style: TextStyle(
                      fontSize: 18,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _retryLoad,
                    icon: const Icon(Icons.refresh),
                    label: Text('common.retry'.tr()),
                  ),
                ],
              ),
            );
          }

          final decks = snapshot.data ?? [];

          if (decks.isEmpty) {
            return _buildEmptyState();
          }

          return _buildDeckGrid(decks);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewDeck,
        heroTag: "decks_fab",
        icon: const Icon(Icons.add),
        label: Text('decks.new_deck'.tr()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.style,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'decks.empty_state.title'.tr(),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'decks.empty_state.subtitle'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _createNewDeck,
              icon: const Icon(Icons.add),
              label: Text('decks.create_first_deck'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckGrid(List<UserDeck> decks) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double childAspectRatio;

        // Minimum width for tiles
        const double minTileWidth = 280.0;
        
        // Responsive grid calculations with max 5 columns
        if (width < 600) {
          // Mobile: 1 column
          crossAxisCount = 1;
          childAspectRatio = 1.8;
        } else if (width < 900) {
          // Tablet: 2 columns
          crossAxisCount = 2;
          childAspectRatio = 1.5;
        } else if (width < 1200) {
          // Small desktop: 3 columns
          crossAxisCount = 3;
          childAspectRatio = 1.3;
        } else {
          // Large desktop: Calculate columns based on minimum width, max 5
          final maxPossibleColumns = (width / minTileWidth).floor();
          crossAxisCount = maxPossibleColumns > 5 ? 5 : maxPossibleColumns;
          childAspectRatio = 1.2;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: decks.length,
          itemBuilder: (context, index) {
            final deck = decks[index];
            final cardCount = _decksController.getDeckCardCount(deck.id);
            final isValid = _decksController.isDeckValid(deck);
            
            return DeckGridTile(
              deck: deck,
              cardCount: cardCount,
              isValid: isValid,
              onTap: () => _openDeck(deck),
            );
          },
        );
      },
    );
  }

  void _createNewDeck() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const CreateDeckDialog(),
    );

    if (result != null) {
      try {
        final deck = await _decksController.createDeck(
          name: result['name'],
          format: result['format'],
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('decks.created_success'.tr(namedArgs: {'name': deck.name})),
              action: SnackBarAction(
                label: 'decks.open'.tr(),
                onPressed: () => _openDeck(deck),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('decks.error.create'.tr(namedArgs: {'error': e.toString()})),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _openDeck(UserDeck deck) {
    context.go('/decks/${deck.id}');
  }

  void _handleSortOption(String option) {
    // TODO: Implement sorting
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('decks.sort.coming_soon'.tr())),
    );
  }

  void _retryLoad() {
    _initializeDecksController();
  }

}
