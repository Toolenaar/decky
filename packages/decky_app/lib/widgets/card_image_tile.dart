import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:decky_core/widgets/rarity_icon.dart';

class HoverableCardImage extends StatefulWidget {
  final Widget child;
  final CardSearchResult card;
  final double cardWidth;
  final double cardHeight;

  const HoverableCardImage({
    super.key,
    required this.child,
    required this.card,
    required this.cardWidth,
    required this.cardHeight,
  });

  @override
  State<HoverableCardImage> createState() => _HoverableCardImageState();
}

class _HoverableCardImageState extends State<HoverableCardImage> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  static const double _overlayScale = 1.5;
  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  void _showOverlay() {
    _removeOverlay();

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final Offset globalPosition = renderBox.localToGlobal(Offset.zero);
    final Size screenSize = MediaQuery.of(context).size;
    final double overlayWidth = widget.cardWidth * _overlayScale;
    final double overlayHeight = widget.cardHeight * _overlayScale;

    // Get the available content area bounds (accounting for navigation drawer)
    final RenderBox? overlayRenderBox = Overlay.of(context).context.findRenderObject() as RenderBox?;
    final Offset contentAreaOffset = overlayRenderBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size contentAreaSize = overlayRenderBox?.size ?? screenSize;

    // Calculate ideal position (centered above the card)
    double idealX = globalPosition.dx - (overlayWidth - widget.cardWidth) / 2;
    double idealY = globalPosition.dy - (overlayHeight - widget.cardHeight) / 2;

    // Clamp X position to stay within content area bounds
    double clampedX = idealX;
    if (idealX < contentAreaOffset.dx + 8) {
      clampedX = contentAreaOffset.dx + 8; // Margin from left edge of content area
    } else if (idealX + overlayWidth > contentAreaOffset.dx + contentAreaSize.width - 8) {
      clampedX = contentAreaOffset.dx + contentAreaSize.width - overlayWidth - 8; // Margin from right edge
    }

    // Clamp Y position to stay within content area bounds
    double clampedY = idealY;
    if (idealY < contentAreaOffset.dy + 8) {
      clampedY = contentAreaOffset.dy + 8; // Margin from top edge of content area
    } else if (idealY + overlayHeight > contentAreaOffset.dy + contentAreaSize.height - 8) {
      clampedY = contentAreaOffset.dy + contentAreaSize.height - overlayHeight - 8; // Margin from bottom edge
    }

    // Calculate offset relative to the original card position
    final Offset dynamicOffset = Offset(clampedX - globalPosition.dx, clampedY - globalPosition.dy);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: overlayWidth,
        height: overlayHeight,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: dynamicOffset,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: overlayWidth,
                height: overlayHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: widget.card.largeImageUrl != null ? _buildLargeImage() : _buildLargePlaceholder(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(onEnter: (_) => _showOverlay(), onExit: (_) => _removeOverlay(), child: widget.child),
    );
  }

  Widget _buildLargeImage() {
    return CachedNetworkImage(
      imageUrl: widget.card.largeImageUrl!,
      fit: BoxFit.cover,
      placeholder: (context, url) => _buildLargePlaceholder(),
      errorWidget: (context, url, error) => _buildLargePlaceholder(),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildLargePlaceholder() {
    return Container(
      color: Colors.grey[800],
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.image, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            widget.card.name,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (widget.card.manaCost?.isNotEmpty == true) ...[
            Text(
              'cards.mana_cost'.tr(namedArgs: {'cost': widget.card.manaCost ?? ''}),
              style: TextStyle(color: Colors.grey[300], fontSize: 14),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            widget.card.type,
            style: TextStyle(color: Colors.grey[300], fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                widget.card.setCode.toUpperCase(),
                style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              RarityIcon(rarity: widget.card.rarity, size: 12),
              const SizedBox(width: 4),
              Text(widget.card.rarity.toUpperCase(), style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
          const Spacer(),
          Center(
            child: Text(
              'cards.no_image'.tr(),
              style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}

class CardImageTile extends StatelessWidget {
  final CardSearchResult card;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final bool showDetails;

  const CardImageTile({super.key, required this.card, this.onTap, this.width, this.height, this.showDetails = false});

  @override
  Widget build(BuildContext context) {
    final cardWidth = width ?? 160.0;
    final cardHeight = height ?? (cardWidth * 1.4); // Magic card aspect ratio

    return SizedBox(
      width: cardWidth,
      height: cardHeight + (showDetails ? 60 : 0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildCardImage(cardWidth, cardHeight)),
              if (showDetails) _buildCardDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(double width, double height) {
    return HoverableCardImage(
      card: card,
      cardWidth: width,
      cardHeight: height,
      child: SizedBox(
        width: width,
        height: height,
        child: card.mediumImageUrl != null ? _buildNetworkImage(card.mediumImageUrl!) : _buildPlaceholder(),
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
              card.name,
              style: TextStyle(color: Colors.grey[800], fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            card.type,
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
            card.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (card.manaCost?.isNotEmpty == true)
                Text(card.manaCost!, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
              const Spacer(),
              _buildRarityIndicator(),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${card.setCode.toUpperCase()} • ${card.type}',
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRarityIndicator() {
    return RarityIcon(rarity: card.rarity, size: 10);
  }
}

class CardImageGrid extends StatelessWidget {
  final List<CardSearchResult> cards;
  final Function(CardSearchResult)? onCardTap;
  final bool showDetails;
  final EdgeInsets? padding;
  final ScrollController? controller;
  final bool isLoadingMore;

  const CardImageGrid({
    super.key,
    required this.cards,
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

        final cardHeight = cardWidth * 1.4 + (showDetails ? 60 : 0);

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
                  return CardImageTile(
                    card: card,
                    width: cardWidth,
                    showDetails: showDetails,
                    onTap: onCardTap != null ? () => onCardTap!(card) : null,
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

class CardImageListTile extends StatelessWidget {
  final CardSearchResult card;
  final VoidCallback? onTap;

  const CardImageListTile({super.key, required this.card, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HoverableCardImage(
        card: card,
        cardWidth: 40,
        cardHeight: 56,
        child: SizedBox(width: 40, height: 56, child: CardImageTile(card: card, width: 40, height: 56)),
      ),
      title: Text(card.name, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.type),
          if (card.manaCost?.isNotEmpty == true)
            Text(
              'cards.mana_cost'.tr(namedArgs: {'cost': card.manaCost ?? ''}),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(card.setCode.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          RarityIcon(rarity: card.rarity, size: 14),
        ],
      ),
      onTap: onTap,
    );
  }
}
