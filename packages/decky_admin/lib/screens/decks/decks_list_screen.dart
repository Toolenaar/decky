import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_deck.dart';
import '../../controllers/deck_controller.dart';
import '../../widgets/paginated_list_view.dart';
import '../dashboard/side_menu.dart';

class DecksListScreen extends StatefulWidget {
  const DecksListScreen({super.key});

  @override
  State<DecksListScreen> createState() => _DecksListScreenState();
}

class _DecksListScreenState extends State<DecksListScreen> {
  final DeckController _deckController = GetIt.instance<DeckController>();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      _deckController.clearSearch();
      setState(() {
        _isSearching = false;
      });
    } else {
      _deckController.searchDecks(query);
      setState(() {
        _isSearching = true;
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _deckController.clearSearch();
    setState(() {
      _isSearching = false;
    });
  }

  Future<void> _deleteDeck(MtgDeck deck) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _deckController.deleteDeck(deck.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Deck deleted successfully'
                : 'Failed to delete deck'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Decks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/dashboard/decks/new'),
            tooltip: 'Add New Deck',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search decks...',
              onChanged: _onSearch,
              leading: const Icon(Icons.search),
              trailing: _isSearching
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      ),
                    ]
                  : null,
            ),
          ),
        ),
      ),
      drawer: SideMenu(currentPath: currentLocation),
      body: PaginatedListView<MtgDeck>(
        itemsStream: _deckController.decksStream,
        loadingStream: _deckController.loadingStream,
        hasMoreStream: _deckController.hasMoreStream,
        errorStream: _deckController.errorStream,
        onLoadMore: _isSearching
            ? () async {} // Don't load more when searching
            : _deckController.loadMoreDecks,
        emptyMessage: _isSearching
            ? 'No decks found for your search'
            : 'No decks available',
        itemBuilder: (context, deck) => _buildDeckTile(deck),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/dashboard/decks/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDeckTile(MtgDeck deck) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(
            Icons.layers,
            color: Colors.white,
          ),
        ),
        title: Text(
          deck.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${deck.type}'),
            Text('Set: ${deck.setCode.toUpperCase()}'),
            Text('Main Board: ${deck.mainBoard.length} cards'),
            if (deck.sideBoard.isNotEmpty)
              Text('Side Board: ${deck.sideBoard.length} cards'),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                context.go('/dashboard/decks/${deck.id}');
                break;
              case 'delete':
                await _deleteDeck(deck);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: Icon(Icons.edit),
                title: Text('Edit'),
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete'),
              ),
            ),
          ],
        ),
        onTap: () => context.go('/dashboard/decks/${deck.id}'),
        isThreeLine: true,
      ),
    );
  }
}