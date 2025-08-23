import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import 'package:decky_core/providers/search_provider.dart';
import '../../widgets/deck_builder_search_bar.dart';
import '../../widgets/deck_card_grid.dart';
import '../../widgets/search_results_with_deck_actions.dart';
import '../../widgets/animated_deck_side_panel.dart';

class DeckDetailView extends StatefulWidget {
  final String deckId;
  
  const DeckDetailView({
    super.key,
    required this.deckId,
  });

  @override
  State<DeckDetailView> createState() => _DeckDetailViewState();
}

class _DeckDetailViewState extends State<DeckDetailView> {
  late final UserDecksController _decksController;
  late final SearchProvider _searchProvider;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _searchScrollController = ScrollController();
  
  UserDeck? _deck;
  bool _isSearching = false;
  DeckCard? _selectedCard;

  @override
  void initState() {
    super.initState();
    _decksController = GetIt.instance<UserDecksController>();
    _searchProvider = GetIt.instance<SearchProvider>();
    _loadDeck();
    
    // Listen to search provider to show search results when searching
    _searchProvider.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchProvider.removeListener(_onSearchChanged);
    _searchScrollController.dispose();
    super.dispose();
  }

  void _loadDeck() {
    setState(() {
      _deck = _decksController.getDeckById(widget.deckId);
    });
  }

  void _onSearchChanged() {
    final newIsSearching = _searchProvider.query.isNotEmpty || _searchProvider.results.isNotEmpty;
    if (_isSearching != newIsSearching) {
      setState(() {
        _isSearching = newIsSearching;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_deck == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () {
        // Tap outside to deselect card
        if (_selectedCard != null) {
          setState(() {
            _selectedCard = null;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        body: Column(
          children: [
            // Search bar replacing the app bar
            DeckBuilderSearchBar(
              searchProvider: _searchProvider,
              onBack: () => context.go('/decks'),
              onToggleDrawer: () => _scaffoldKey.currentState?.openEndDrawer(),
              deckName: _deck!.name,
            ),
            
            // Main content area with animated side panel
            Expanded(
              child: AnimatedDeckSidePanel(
                deck: _deck!,
                decksController: _decksController,
                onCardTap: _onDeckCardTap,
                selectedCard: _selectedCard,
                onCardBack: () {
                  setState(() {
                    _selectedCard = null;
                  });
                },
                initiallyVisible: true,
                child: _isSearching ? _buildSearchResults() : _buildDeckContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return ListenableBuilder(
      listenable: _searchProvider,
      builder: (context, child) {
        return SearchResultsWithDeckActions(
          searchProvider: _searchProvider,
          scrollController: _searchScrollController,
          decksController: _decksController,
          deckId: widget.deckId,
          onCardTap: _onCardTap,
        );
      },
    );
  }

  Widget _buildDeckContent() {
    return DeckCardGrid(
      deckId: widget.deckId,
      decksController: _decksController,
      onCardTap: _onDeckCardTap,
    );
  }

  void _onCardTap(CardSearchResult card) {
    // Handle card tap from search results - could show card details
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tapped ${card.name}')),
    );
  }

  void _onDeckCardTap(DeckCard deckCard) {
    setState(() {
      _selectedCard = deckCard;
    });
  }

}