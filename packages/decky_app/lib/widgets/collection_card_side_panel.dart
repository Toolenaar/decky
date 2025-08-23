import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/model/collection_card.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/controller/user_collection_controller.dart';
import 'collection_card_list_item.dart';

class CollectionCardSidePanel extends StatelessWidget {
  final UserCollectionController collectionController;
  final void Function(CollectionCard) onCardTap;
  final CollectionCard? selectedCard;
  final VoidCallback? onCardBack;

  const CollectionCardSidePanel({
    super.key,
    required this.collectionController,
    required this.onCardTap,
    this.selectedCard,
    this.onCardBack,
  });

  @override
  Widget build(BuildContext context) {
    // If a card is selected, show the card detail view
    if (selectedCard != null) {
      return _buildCardDetailView(context, selectedCard!);
    }

    // Default card list view
    return StreamBuilder<List<CollectionCard>>(
      stream: collectionController.collectionCardsStream,
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        
        if (cards.isEmpty) {
          return _buildEmptyState(context);
        }

        // Group cards by first letter for better organization
        final groupedCards = <String, List<CollectionCard>>{};
        for (final card in cards) {
          final firstLetter = card.mtgCardReference.name[0].toUpperCase();
          groupedCards.putIfAbsent(firstLetter, () => []).add(card);
        }

        final sortedKeys = groupedCards.keys.toList()..sort();
        final totalCards = cards.fold<int>(0, (total, card) => total + card.count);

        return Column(
          children: [
            // Collection stats
            Container(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'collection.unique_cards'.tr(),
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cards.length.toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'collection.total_cards'.tr(),
                              style: Theme.of(context).textTheme.bodySmall,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            totalCards.toString(),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Card list grouped by letter
            Expanded(
              child: ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  final letter = sortedKeys[index];
                  final letterCards = groupedCards[letter]!
                    ..sort((a, b) => a.mtgCardReference.name.compareTo(b.mtgCardReference.name));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Letter header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Text(
                          letter,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Cards for this letter
                      ...letterCards.map((card) => CollectionCardListItem(
                        collectionCard: card,
                        onTap: () => onCardTap(card),
                      )),
                    ],
                  );
                },
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
              Icons.collections_bookmark,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'collection.empty_state.title'.tr(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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

  Widget _buildCardDetailView(BuildContext context, CollectionCard card) {
    final mtgCard = card.mtgCardReference;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildCardImage(context, mtgCard),
            const SizedBox(height: 16),
            _buildCardInfo(context, mtgCard),
            const SizedBox(height: 24),
            _buildCardManagementButtons(context, card),
            if (card.notes != null && card.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildCardNotes(context, card),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardImage(BuildContext context, MtgCard mtgCard) {
    final imageUrl = mtgCard.firebaseImageUris?.normal;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => const SizedBox(
                  height: 200,
                  child: Center(
                    child: Icon(Icons.image_not_supported, size: 64),
                  ),
                ),
              )
            : const SizedBox(
                height: 200,
                child: Center(
                  child: Icon(Icons.image, size: 64),
                ),
              ),
      ),
    );
  }

  Widget _buildCardInfo(BuildContext context, MtgCard mtgCard) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              mtgCard.type,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (mtgCard.manaCost != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'collection.mana_cost'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    mtgCard.manaCost!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (mtgCard.power != null && mtgCard.toughness != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'collection.power_toughness'.tr(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${mtgCard.power}/${mtgCard.toughness}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            if (mtgCard.text != null) ...[
              const SizedBox(height: 12),
              Text(
                mtgCard.text!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardManagementButtons(BuildContext context, CollectionCard card) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quantity controls
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'collection.quantity'.tr(),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: card.count > 1 ? () => _updateCardCount(card, card.count - 1) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      card.count.toString(),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _updateCardCount(card, card.count + 1),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Foil toggle
        CheckboxListTile(
          title: Text('collection.foil_card'.tr()),
          value: card.isFoil ?? false,
          onChanged: (value) => _toggleFoil(card, value ?? false),
        ),
        const SizedBox(height: 8),
        
        // Remove from collection button
        OutlinedButton.icon(
          onPressed: () => _removeFromCollection(card),
          icon: const Icon(Icons.delete_outline),
          label: Text('collection.remove_from_collection'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  Widget _buildCardNotes(BuildContext context, CollectionCard card) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'collection.notes'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              card.notes!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  void _updateCardCount(CollectionCard card, int newCount) async {
    await collectionController.updateCardCount(card, newCount);
  }

  void _toggleFoil(CollectionCard card, bool isFoil) async {
    await card.update({'isFoil': isFoil});
  }

  void _removeFromCollection(CollectionCard card) async {
    await collectionController.removeCardFromCollection(
      cardUuid: card.cardUuid,
      count: card.count,
    );
    // Navigate back to list after removal
    onCardBack?.call();
  }
}