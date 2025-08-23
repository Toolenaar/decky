import 'package:decky_app/widgets/card_grid.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:decky_core/model/collection_card.dart';
import 'package:decky_core/controller/user_collection_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/widgets/rarity_icon.dart';

class CollectionCardGrid extends StatefulWidget {
  final UserCollectionController collectionController;
  final Function(CollectionCard)? onCardTap;
  final Function(CollectionCard)? onCardLongPress;

  const CollectionCardGrid({super.key, required this.collectionController, this.onCardTap, this.onCardLongPress});

  @override
  State<CollectionCardGrid> createState() => _CollectionCardGridState();
}

class _CollectionCardGridState extends State<CollectionCardGrid> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      // Load more cards when near the bottom
      widget.collectionController.loadMoreCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CollectionCard>>(
      stream: widget.collectionController.collectionCardsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  'collection.error_loading_cards'.tr(),
                  style: TextStyle(fontSize: 18, color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return _buildEmptyState(context);
        }

        return Column(
          children: [
            // Cards grid
            Expanded(child: _buildCardGrid(context, cards)),

            // Loading more indicator
            if (widget.collectionController.isLoadingMore)
              Container(padding: const EdgeInsets.all(16), child: const CircularProgressIndicator()),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.collections,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'collection.empty_state.title'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              'collection.empty_state.subtitle'.tr(),
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

  Widget _buildCardGrid(BuildContext context, List<CollectionCard> cards) {
    return CardGrid(
      length: cards.length,
      builder: (index, cardWidth) {
        final card = cards[index];
        return CollectionCardTile(
          card: card,
          width: cardWidth,
          onTap: widget.onCardTap != null ? () => widget.onCardTap!(card) : null,
          onLongPress: widget.onCardLongPress != null ? () => widget.onCardLongPress!(card) : null,
        );
      },
    );
  }
}

class CollectionCardTile extends StatelessWidget {
  final CollectionCard card;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const CollectionCardTile({super.key, required this.card, required this.width, this.onTap, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final cardHeight = width * 1.4;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        children: [
          Container(
            width: width,
            height: cardHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildCardImage()),
          ),

          // Count badge
          if (card.count > 1)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${card.count}',
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),

          // Foil indicator
          if (card.isFoil == true)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardImage() {
    // Use card image if available
    final imageUris = card.mtgCardReference.firebaseImageUris;
    final imageUrl = imageUris?.normal ?? imageUris?.large ?? imageUris?.small;

    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildPlaceholder(),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: width * 0.3, color: Colors.grey[600]),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              card.mtgCardReference.name,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[800]),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          if (card.mtgCardReference.rarity.isNotEmpty) RarityIcon(rarity: card.mtgCardReference.rarity, size: 12),
        ],
      ),
    );
  }
}
