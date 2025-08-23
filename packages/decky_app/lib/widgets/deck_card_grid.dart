import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/widgets/rarity_icon.dart';

class DeckCardGrid extends StatefulWidget {
  final String deckId;
  final UserDecksController decksController;
  final Function(DeckCard)? onCardTap;
  final Function(DeckCard)? onCardLongPress;

  // Static fields for easy experimentation with grid layout
  static int mobileColumns = 2;          // Mobile: 2 cards per row
  static int tabletColumns = 3;          // Tablet: 3 cards per row  
  static int smallDesktopColumns = 4;    // Small desktop: 4 cards per row
  static int largeDesktopColumns = 6;    // Large desktop: 6 cards per row
  static double minCardWidth = 140;      // Minimum card width in pixels
  static double cardSpacing = 8;         // Spacing between cards

  const DeckCardGrid({
    super.key,
    required this.deckId,
    required this.decksController,
    this.onCardTap,
    this.onCardLongPress,
  });

  @override
  State<DeckCardGrid> createState() => _DeckCardGridState();
}

class _DeckCardGridState extends State<DeckCardGrid> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DeckCard>>(
      stream: widget.decksController.getDeckCardsStream(widget.deckId),
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
                  'decks.detail.error_loading_cards'.tr(),
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
              ],
            ),
          );
        }

        final cards = snapshot.data ?? [];

        if (cards.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group cards by category
        final commanders = cards.where((card) => card.isCommander).toList();
        final mainboard = cards.where((card) => !card.isCommander && !card.isInSideboard).toList();
        final sideboard = cards.where((card) => card.isInSideboard).toList();

        // Calculate total counts (including duplicates)
        final commanderCount = commanders.fold<int>(0, (total, card) => total + card.count);
        final mainboardCount = mainboard.fold<int>(0, (total, card) => total + card.count);
        final sideboardCount = sideboard.fold<int>(0, (total, card) => total + card.count);

        // Determine available tabs based on cards present - Commander first
        final availableTabs = <({String title, List<DeckCard> cards, int count, bool isEmpty})>[];
        
        // Always add Commander tab first (if commanders exist)
        if (commanders.isNotEmpty) {
          availableTabs.add((
            title: 'decks.detail.commander'.tr(), 
            cards: commanders, 
            count: commanderCount,
            isEmpty: false
          ));
        }
        
        // Add Mainboard tab
        if (mainboard.isNotEmpty) {
          availableTabs.add((
            title: 'decks.detail.mainboard'.tr(), 
            cards: mainboard, 
            count: mainboardCount,
            isEmpty: false
          ));
        }
        
        // Add Sideboard tab
        if (sideboard.isNotEmpty) {
          availableTabs.add((
            title: 'decks.detail.sideboard'.tr(), 
            cards: sideboard, 
            count: sideboardCount,
            isEmpty: false
          ));
        }

        // Always add Brainstorm tab (empty for now)
        availableTabs.add((
          title: 'Brainstorm', 
          cards: <DeckCard>[], 
          count: 0,
          isEmpty: true
        ));

        // If no actual cards, show empty state
        if (commanders.isEmpty && mainboard.isEmpty && sideboard.isEmpty) {
          return _buildEmptyState(context);
        }

        // Update tab controller if needed
        if (_tabController.length != availableTabs.length) {
          _tabController.dispose();
          _tabController = TabController(length: availableTabs.length, vsync: this);
        }

        return Column(
          children: [
            // Tab bar - left aligned and sized to content
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true, // Makes tabs size to content
                  tabAlignment: TabAlignment.start, // Left align tabs
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  labelColor: Theme.of(context).colorScheme.onPrimary,
                  unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: availableTabs.map((tab) => Tab(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(tab.title),
                          if (!tab.isEmpty) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${tab.count}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )).toList(),
                ),
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: availableTabs.map((tab) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: tab.isEmpty 
                        ? _buildBrainstormContent(context)
                        : _buildCardGrid(context, tab.cards),
                  )
                ).toList(),
              ),
            ),
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
              Icons.style,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'decks.detail.no_cards'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'decks.detail.search_to_add_cards'.tr(),
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

  Widget _buildBrainstormContent(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lightbulb_outline,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Brainstorm',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'AI-powered deck suggestions and improvements coming soon!',
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

  Widget _buildCardGrid(BuildContext context, List<DeckCard> cards) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double cardWidth;

        // Responsive grid calculations using static fields
        if (width < 600) {
          // Mobile
          crossAxisCount = DeckCardGrid.mobileColumns;
        } else if (width < 900) {
          // Tablet
          crossAxisCount = DeckCardGrid.tabletColumns;
        } else if (width < 1200) {
          // Small desktop
          crossAxisCount = DeckCardGrid.smallDesktopColumns;
        } else {
          // Large desktop - use either fixed columns or calculate based on min width
          final calculatedColumns = (width / DeckCardGrid.minCardWidth).floor();
          crossAxisCount = calculatedColumns > DeckCardGrid.largeDesktopColumns ? DeckCardGrid.largeDesktopColumns : calculatedColumns;
        }

        // Calculate actual card width based on available space
        final totalSpacing = DeckCardGrid.cardSpacing * (crossAxisCount - 1);
        cardWidth = (width - totalSpacing) / crossAxisCount;
        
        // Ensure minimum card width
        if (cardWidth < DeckCardGrid.minCardWidth) {
          cardWidth = DeckCardGrid.minCardWidth;
        }

        final cardHeight = cardWidth * 1.4;

        return GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: DeckCardGrid.cardSpacing,
            mainAxisSpacing: DeckCardGrid.cardSpacing,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return DeckCardTile(
              card: card,
              width: cardWidth,
              onTap: widget.onCardTap != null ? () => widget.onCardTap!(card) : null,
              onLongPress: widget.onCardLongPress != null ? () => widget.onCardLongPress!(card) : null,
              onRemove: () => _removeCard(card),
            );
          },
        );
      },
    );
  }

  void _removeCard(DeckCard card) async {
    try {
      await widget.decksController.removeCardFromDeck(
        deckId: widget.deckId,
        cardUuid: card.cardUuid,
        count: 1,
        isCommander: card.isCommander,
        isInSideboard: card.isInSideboard,
      );
    } catch (e) {
      // Handle error - could show snackbar
      debugPrint('Error removing card: $e');
    }
  }
}

class DeckCardTile extends StatelessWidget {
  final DeckCard card;
  final double width;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onRemove;

  const DeckCardTile({
    super.key,
    required this.card,
    required this.width,
    this.onTap,
    this.onLongPress,
    this.onRemove,
  });

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
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _buildCardImage(),
            ),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          
          // Commander indicator
          if (card.isCommander)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),

          // Remove button (on long press or hover)
          if (onRemove != null)
            Positioned(
              bottom: 4,
              right: 4,
              child: GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
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
          Icon(
            Icons.image,
            size: width * 0.3,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              card.mtgCardReference.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          if (card.mtgCardReference.rarity.isNotEmpty)
            RarityIcon(
              rarity: card.mtgCardReference.rarity,
              size: 12,
            ),
        ],
      ),
    );
  }
}