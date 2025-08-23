import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:decky_core/widgets/rarity_icon.dart';
import 'card_image_tile.dart';

class CardImageTileWithDeckActions extends StatefulWidget {
  final CardSearchResult card;
  final VoidCallback? onTap;
  final Future<void> Function(CardSearchResult, {int count, bool isCommander, bool isInSideboard}) onAddToDeck;
  final double? width;
  final double? height;
  final bool showDetails;
  final String deckId;
  final UserDecksController decksController;

  const CardImageTileWithDeckActions({
    super.key,
    required this.card,
    required this.onAddToDeck,
    required this.deckId,
    required this.decksController,
    this.onTap,
    this.width,
    this.height,
    this.showDetails = false,
  });

  @override
  State<CardImageTileWithDeckActions> createState() => _CardImageTileWithDeckActionsState();
}

class _CardImageTileWithDeckActionsState extends State<CardImageTileWithDeckActions> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final cardWidth = widget.width ?? 160.0;
    final cardHeight = widget.height ?? (cardWidth * 1.4);

    return StreamBuilder<List<DeckCard>>(
      stream: widget.decksController.getDeckCardsStream(widget.deckId),
      builder: (context, snapshot) {
        final cardCount = widget.decksController.getCardCountInDeck(widget.deckId, widget.card.id);

        return SizedBox(
          width: cardWidth,
          height: cardHeight + (widget.showDetails ? 60 : 0) + 40, // Extra space for add button
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: widget.onTap,
                    child: _buildCardImage(cardWidth, cardHeight - 40, cardWidth * 1.4),
                  ),
                ),
                if (widget.showDetails) _buildCardDetails(),
                _buildAddToDeckButton(cardCount),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardImage(double width, double height, [double? hoverHeight]) {
    return HoverableCardImage(
      card: widget.card,
      cardWidth: width,
      cardHeight: hoverHeight ?? height, // Use hoverHeight for proper aspect ratio if provided
      child: SizedBox(
        width: width,
        height: height,
        child: widget.card.mediumImageUrl != null 
            ? _buildNetworkImage(widget.card.mediumImageUrl!) 
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildNetworkImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLoadingPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text(
            'cards.image_not_available'.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 48, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              widget.card.name,
              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.card.type,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetails() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.card.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (widget.card.manaCost?.isNotEmpty == true)
                Text(widget.card.manaCost!, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const Spacer(),
              RarityIcon(rarity: widget.card.rarity, size: 10),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.card.setCode.toUpperCase()} • ${widget.card.type}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAddToDeckButton(int currentCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          if (currentCount > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$currentCount',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: SizedBox(
              height: 32,
              child: FilledButton.tonalIcon(
                onPressed: _isLoading ? null : () => _addToDeck(),
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Icon(Icons.add, size: 16),
                label: Text(
                  currentCount > 0 
                      ? 'decks.detail.add_more'.tr()
                      : 'decks.detail.add_to_deck'.tr(),
                  style: const TextStyle(fontSize: 12),
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addToDeck({int count = 1, bool isCommander = false, bool isInSideboard = false}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onAddToDeck(
        widget.card,
        count: count,
        isCommander: isCommander,
        isInSideboard: isInSideboard,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('decks.detail.error_adding_card'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class CardImageGridWithDeckActions extends StatelessWidget {
  final List<CardSearchResult> cards;
  final Function(CardSearchResult)? onCardTap;
  final Future<void> Function(CardSearchResult, {int count, bool isCommander, bool isInSideboard}) onAddToDeck;
  final bool showDetails;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool isLoadingMore;
  final String deckId;
  final UserDecksController decksController;

  const CardImageGridWithDeckActions({
    super.key,
    required this.cards,
    required this.onAddToDeck,
    required this.deckId,
    required this.decksController,
    this.onCardTap,
    this.showDetails = false,
    this.padding,
    this.controller,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double cardWidth;

        // Responsive grid calculations
        if (width < 600) {
          // Mobile: 2 columns
          crossAxisCount = 2;
          cardWidth = (width - 32 - 8) / 2; // Account for padding and spacing
        } else if (width < 900) {
          // Tablet: 3-4 columns
          crossAxisCount = 3;
          cardWidth = (width - 48 - 16) / 3;
        } else if (width < 1200) {
          // Small desktop: 4-5 columns
          crossAxisCount = 4;
          cardWidth = (width - 64 - 24) / 4;
        } else {
          // Large desktop: 5-6 columns
          crossAxisCount = 5;
          cardWidth = (width - 80 - 32) / 5;
        }

        final cardHeight = cardWidth * 1.4 + (showDetails ? 60 : 0) + 40; // Extra height for add button

        return Column(
          children: [
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: padding ?? const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: cardWidth / cardHeight,
                ),
                itemCount: cards.length,
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return CardImageTileWithDeckActions(
                    card: card,
                    width: cardWidth,
                    showDetails: showDetails,
                    onTap: onCardTap != null ? () => onCardTap!(card) : null,
                    onAddToDeck: onAddToDeck,
                    deckId: deckId,
                    decksController: decksController,
                  );
                },
              ),
            ),
            if (isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    const SizedBox(width: 12),
                    Text('search.loading_more'.tr()),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}