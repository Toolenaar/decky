import 'package:flutter/material.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../widgets/card_image_tile.dart';

class SearchResults extends StatelessWidget {
  final SearchProvider searchProvider;
  final ScrollController scrollController;
  final Function(CardSearchResult) onCardTap;

  const SearchResults({
    super.key,
    required this.searchProvider,
    required this.scrollController,
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
      return const SizedBox.shrink(); // Empty state is handled separately
    }

    return RefreshIndicator(
      onRefresh: searchProvider.refresh,
      child: CardImageGrid(
        cards: searchProvider.results,
        onCardTap: onCardTap,
        showDetails: true,
        controller: scrollController,
        isLoadingMore: searchProvider.isLoading && searchProvider.results.isNotEmpty,
      ),
    );
  }
}
