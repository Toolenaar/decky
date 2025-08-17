import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/controller/elasticsearch_service.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import '../../controllers/card_controller.dart';
import '../../widgets/paginated_list_view.dart';
import '../../widgets/bulk_import_dialog.dart';
import '../dashboard/side_menu.dart';

class CardsListScreen extends StatefulWidget {
  const CardsListScreen({super.key});

  @override
  State<CardsListScreen> createState() => _CardsListScreenState();
}

class _CardsListScreenState extends State<CardsListScreen> {
  final CardController _cardController = GetIt.instance<CardController>();
  final TextEditingController _searchController = TextEditingController();
  final ElasticsearchService _elasticsearchService = ElasticsearchService();

  bool _isSearching = false;
  bool _isElasticsearchEnabled = false;
  List<CardSearchResult> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _checkElasticsearchHealth();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _elasticsearchService.dispose();
    super.dispose();
  }

  Future<void> _checkElasticsearchHealth() async {
    try {
      final isHealthy = await _elasticsearchService.isHealthy();
      setState(() {
        _isElasticsearchEnabled = isHealthy;
      });
    } catch (e) {
      setState(() {
        _isElasticsearchEnabled = false;
      });
    }
  }

  void _onSearch(String query) {
    if (query.isEmpty) {
      // Only clear Firestore search if not using Elasticsearch
      if (!_isElasticsearchEnabled) {
        _cardController.clearSearch();
      }
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    } else {
      setState(() {
        _isSearching = true;
      });

      if (_isElasticsearchEnabled) {
        // Clear any existing Firestore results when using Elasticsearch
        _cardController.clearSearch();
        _performElasticsearchSearch(query);
      } else {
        _cardController.searchCards(query);
      }
    }
  }

  Future<void> _performElasticsearchSearch(String query) async {
    setState(() {
      _isSearchLoading = true;
    });

    try {
      final results = await _elasticsearchService.searchCards(query: query, size: 10);
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });

      // Results will be shown in main list
    } catch (e) {
      setState(() {
        _isSearchLoading = false;
        _searchResults = [];
      });

      // Fallback to Firestore search
      _cardController.searchCards(query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    // Only clear Firestore search if not using Elasticsearch
    if (!_isElasticsearchEnabled) {
      _cardController.clearSearch();
    }
    setState(() {
      _isSearching = false;
      _searchResults = [];
    });
  }

  void _onSearchResultTap(CardSearchResult result) {
    print(result);
    context.go('/dashboard/cards/${result.id}');
  }

  Future<void> _deleteCard(MtgCard card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Card'),
        content: Text('Are you sure you want to delete "${card.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await _cardController.deleteCard(card.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Card deleted successfully' : 'Failed to delete card'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  void _openBulkImport() {
    showDialog(context: context, barrierDismissible: false, builder: (context) => const BulkImportDialog());
  }

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cards'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.cloud_sync), onPressed: _openBulkImport, tooltip: 'Bulk Import Images'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.go('/dashboard/cards/new'),
            tooltip: 'Add New Card',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: _isElasticsearchEnabled ? 'Search cards (Elasticsearch enabled)...' : 'Search cards...',
                prefixIcon: _isSearchLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                    : _isElasticsearchEnabled
                    ? const Icon(Icons.bolt, color: Colors.orange)
                    : null,
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      drawer: SideMenu(currentPath: currentLocation),
      body: _isSearching && _isElasticsearchEnabled && _searchResults.isNotEmpty
          ? ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (context, index) {
                final result = _searchResults[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _buildSearchResultTile(result),
                );
              },
            )
          : _isSearching && _isElasticsearchEnabled && _searchResults.isEmpty && !_isSearchLoading
          ? const Center(
              child: Text('No cards found for your search', style: TextStyle(fontSize: 16, color: Colors.grey)),
            )
          : _isSearching && _isElasticsearchEnabled && _isSearchLoading
          ? const Center(child: CircularProgressIndicator())
          : PaginatedListView<MtgCard>(
              itemsStream: _cardController.cardsStream,
              loadingStream: _cardController.loadingStream,
              hasMoreStream: _cardController.hasMoreStream,
              errorStream: _cardController.errorStream,
              onLoadMore: _isSearching
                  ? () async {} // Don't load more when searching
                  : _cardController.loadMoreCards,
              emptyMessage: _isSearching ? 'No cards found for your search' : 'No cards available',
              itemBuilder: (context, card) => _buildCardTile(card),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/dashboard/cards/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCardTile(MtgCard card) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: _getColorForCard(card),
              child: Text(
                card.name.isNotEmpty ? card.name[0].toUpperCase() : '?',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            if (card.imageDataStatus == 'synced' && card.firebaseImageUris?.hasAnyImage == true)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.cloud_done, size: 10, color: Colors.white),
                ),
              )
            else if (card.imageDataStatus == 'syncing')
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const SizedBox(
                    width: 8,
                    height: 8,
                    child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white),
                  ),
                ),
              )
            else if (card.imageDataStatus == 'error')
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(Icons.error, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
        title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${card.type} • ${card.setCode.toUpperCase()}'),
            if (card.manaCost != null) Text('Mana Cost: ${card.manaCost}'),
            Row(
              children: [
                Text('Rarity: ${card.rarity}'),
                if (card.imageDataStatus == 'synced' && card.firebaseImageUris?.hasAnyImage == true)
                  const Text(' • Images: Synced', style: TextStyle(color: Colors.green, fontSize: 12))
                else if (card.imageDataStatus == 'syncing')
                  const Text(' • Images: Syncing...', style: TextStyle(color: Colors.orange, fontSize: 12))
                else if (card.imageDataStatus == 'error')
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(' • Images: Error', style: TextStyle(color: Colors.red, fontSize: 12)),
                      if (card.importError != null && card.importError!.isNotEmpty)
                        Text(
                          'Error: ${card.importError!.length > 50 ? '${card.importError!.substring(0, 50)}...' : card.importError!}',
                          style: const TextStyle(color: Colors.red, fontSize: 10),
                        ),
                    ],
                  ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                context.go('/dashboard/cards/${card.id}');
                break;
              case 'delete':
                await _deleteCard(card);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
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
        onTap: () => context.go('/dashboard/cards/${card.id}'),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildSearchResultTile(CardSearchResult result) {
    return ListTile(
      leading: result.imageUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                result.imageUrl!,
                width: 40,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 40,
                  height: 56,
                  color: _getColorForSearchResult(result),
                  child: Center(
                    child: Text(
                      result.name.isNotEmpty ? result.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            )
          : Container(
              width: 40,
              height: 56,
              decoration: BoxDecoration(
                color: _getColorForSearchResult(result),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: Text(
                  result.name.isNotEmpty ? result.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
      title: Text(result.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${result.displayType} • ${result.setCode.toUpperCase()}'),
          if (result.manaCost != null) Text('Mana Cost: ${result.manaCost}'),
          Text('Rarity: ${result.rarity}'),
        ],
      ),
      trailing: result.score != null
          ? Text('Score: ${result.score!.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodySmall)
          : null,
      onTap: () => _onSearchResultTap(result),
      isThreeLine: true,
    );
  }

  Color _getColorForCard(MtgCard card) {
    if (card.colors.isEmpty) return Colors.grey;
    try {
      switch (card.colors.first) {
        case 'W':
          return Colors.amber;
        case 'U':
          return Colors.blue;
        case 'B':
          return Colors.black87;
        case 'R':
          return Colors.red;
        case 'G':
          return Colors.green;
        default:
          return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getColorForSearchResult(CardSearchResult result) {
    if (result.colors.isEmpty) return Colors.grey;
    try {
      switch (result.colors.first) {
        case 'W':
          return Colors.amber;
        case 'U':
          return Colors.blue;
        case 'B':
          return Colors.black87;
        case 'R':
          return Colors.red;
        case 'G':
          return Colors.green;
        default:
          return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }
}
