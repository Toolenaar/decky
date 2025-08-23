import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'mana_cost_distribution_chart.dart';
import 'deck_card_list_item.dart';

class DeckCardSidePanel extends StatelessWidget {
  final UserDeck deck;
  final UserDecksController decksController;
  final void Function(DeckCard) onCardTap;
  final DeckCard? selectedCard;
  final VoidCallback? onCardBack;

  const DeckCardSidePanel({
    super.key,
    required this.deck,
    required this.decksController,
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
    return StreamBuilder<List<DeckCard>>(
        stream: decksController.getDeckCardsStream(deck.id),
        builder: (context, snapshot) {
          final cards = snapshot.data ?? [];
          final mainboardCards = cards
              .where((card) => !card.isInSideboard && !card.isCommander)
              .toList()
            ..sort((a, b) => a.mtgCardReference.convertedManaCost
                .compareTo(b.mtgCardReference.convertedManaCost));

          final sideboardCards = cards
              .where((card) => card.isInSideboard)
              .toList()
            ..sort((a, b) => a.mtgCardReference.convertedManaCost
                .compareTo(b.mtgCardReference.convertedManaCost));

          final mainboardTotal = mainboardCards.fold<int>(
              0, (total, card) => total + card.count);
          final sideboardTotal = sideboardCards.fold<int>(
              0, (total, card) => total + card.count);
          final requiredCards = _getRequiredCardCount(deck.format);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mainboard section
                ManaCostDistributionChart(
                  title: 'decks.detail.mainboard'.tr(),
                  cards: mainboardCards,
                  totalCards: mainboardTotal,
                  requiredCards: requiredCards,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: mainboardCards.length,
                    itemBuilder: (context, index) {
                      final deckCard = mainboardCards[index];
                      return DeckCardListItem(
                        deckCard: deckCard,
                        onTap: () => onCardTap(deckCard),
                      );
                    },
                  ),
                ),
                
                // Sideboard section
                if (sideboardCards.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  ManaCostDistributionChart(
                    title: 'decks.detail.sideboard'.tr(),
                    cards: sideboardCards,
                    totalCards: sideboardTotal,
                    requiredCards: 15, // Standard sideboard limit
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sideboardCards.length,
                      itemBuilder: (context, index) {
                        final deckCard = sideboardCards[index];
                        return DeckCardListItem(
                          deckCard: deckCard,
                          onTap: () => onCardTap(deckCard),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      );
  }

  Widget _buildCardDetailView(BuildContext context, DeckCard card) {
    final mtgCard = card.mtgCardReference;
    final isCommanderFormat = deck.isCommanderFormat;

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
            _buildCardManagementButtons(context, card, isCommanderFormat),
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
                fit: BoxFit.contain, // Changed from cover to contain to show full card
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
                    'decks.detail.mana_cost'.tr(),
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
                    'decks.detail.power_toughness'.tr(),
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

  Widget _buildCardManagementButtons(BuildContext context, DeckCard card, bool isCommanderFormat) {
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
                  'decks.detail.quantity'.tr(),
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
                      onPressed: card.count < 4 ? () => _updateCardCount(card, card.count + 1) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Card location controls
        if (isCommanderFormat) ...[
          CheckboxListTile(
            title: Text('decks.detail.commander'.tr()),
            value: card.isCommander,
            onChanged: (value) => _toggleCommander(card),
          ),
          const SizedBox(height: 8),
        ],
        
        OutlinedButton.icon(
          onPressed: () => _toggleSideboard(card),
          icon: Icon(card.isInSideboard ? Icons.swap_horiz : Icons.swap_horiz_outlined),
          label: Text(card.isInSideboard 
              ? 'decks.detail.move_to_mainboard'.tr()
              : 'decks.detail.move_to_sideboard'.tr()),
        ),
        const SizedBox(height: 8),
        
        OutlinedButton.icon(
          onPressed: () => _deleteCard(card),
          icon: const Icon(Icons.delete_outline),
          label: Text('decks.detail.delete_card'.tr()),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

  void _updateCardCount(DeckCard card, int newCount) async {
    await card.update({'count': newCount});
  }

  void _toggleCommander(DeckCard card) async {
    await card.update({'isCommander': !card.isCommander});
  }

  void _toggleSideboard(DeckCard card) async {
    await card.update({'isInSideboard': !card.isInSideboard});
  }

  void _deleteCard(DeckCard card) async {
    await card.delete();
  }

  int _getRequiredCardCount(MtgFormat format) {
    switch (format) {
      case MtgFormat.commander:
      case MtgFormat.commanderOnehundred:
      case MtgFormat.pauperCommander:
      case MtgFormat.brawl:
      case MtgFormat.standardBrawl:
        return 100;
      case MtgFormat.standard:
      case MtgFormat.pioneer:
      case MtgFormat.modern:
      case MtgFormat.legacy:
      case MtgFormat.vintage:
      case MtgFormat.historic:
      case MtgFormat.alchemy:
      case MtgFormat.explorer:
      case MtgFormat.pauper:
        return 60;
      case MtgFormat.limited:
        return 40;
      case MtgFormat.cube:
      case MtgFormat.custom:
        return -1;
    }
  }
}