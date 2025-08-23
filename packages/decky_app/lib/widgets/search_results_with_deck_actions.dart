import 'package:flutter/material.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'card_image_tile_with_deck_actions.dart';

class SearchResultsWithDeckActions extends StatelessWidget {
  final SearchProvider searchProvider;
  final ScrollController scrollController;
  final UserDecksController decksController;
  final String deckId;
  final Function(CardSearchResult) onCardTap;

  const SearchResultsWithDeckActions({
    super.key,
    required this.searchProvider,
    required this.scrollController,
    required this.decksController,
    required this.deckId,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    if (searchProvider.isLoading && searchProvider.results.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchProvider.hasError) {
      return Center(
        child: SelectableRegion(
          selectionControls: MaterialTextSelectionControls(),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'search.error.title'.tr(namedArgs: {'message': searchProvider.errorMessage}),
                style: const TextStyle(fontSize: 16, color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: searchProvider.refresh, child: Text('search.error.retry'.tr())),
            ],
          ),
        ),
      );
    }

    if (searchProvider.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'search.no_results.title'.tr(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'search.no_results.subtitle'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: searchProvider.refresh,
      child: CardImageGridWithDeckActions(
        cards: searchProvider.results,
        onCardTap: onCardTap,
        onAddToDeck: _addCardToDeck,
        showDetails: true,
        controller: scrollController,
        isLoadingMore: searchProvider.isLoading && searchProvider.results.isNotEmpty,
        deckId: deckId,
        decksController: decksController,
      ),
    );
  }

  Future<void> _addCardToDeck(CardSearchResult cardResult, {
    int count = 1,
    bool isCommander = false,
    bool isInSideboard = false,
  }) async {
    try {
      // Fetch the complete MTG card using the static method
      final mtgCard = await MtgCard.fetchById(cardResult.id);
      
      if (mtgCard == null) {
        throw Exception('Card not found in database: ${cardResult.id}');
      }

      await decksController.addCardToDeck(
        deckId: deckId,
        mtgCard: mtgCard,
        count: count,
        isCommander: isCommander,
        isInSideboard: isInSideboard,
      );
    } catch (e) {
      debugPrint('Error adding card to deck: $e');
    }
  }

}