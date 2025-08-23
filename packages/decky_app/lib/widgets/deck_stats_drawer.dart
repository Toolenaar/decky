import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/model/mtg/mtg_card.dart';
import 'package:decky_core/controller/user_decks_controller.dart';

class DeckStatsDrawer extends StatelessWidget {
  final UserDeck? deck;
  final UserDecksController decksController;
  final DeckCard? selectedCard;
  final VoidCallback onEdit;
  final VoidCallback onShare;
  final VoidCallback onDuplicate;
  final VoidCallback onExport;
  final VoidCallback onDelete;
  final VoidCallback? onCardBack;

  const DeckStatsDrawer({
    super.key,
    required this.deck,
    required this.decksController,
    this.selectedCard,
    required this.onEdit,
    required this.onShare,
    required this.onDuplicate,
    required this.onExport,
    required this.onDelete,
    this.onCardBack,
  });

  final Map<MtgFormat, String> _formatDisplayNames = const {
    MtgFormat.standard: 'Standard',
    MtgFormat.pioneer: 'Pioneer',
    MtgFormat.modern: 'Modern',
    MtgFormat.legacy: 'Legacy',
    MtgFormat.vintage: 'Vintage',
    MtgFormat.commander: 'Commander',
    MtgFormat.commanderOnehundred: 'Commander 1v1',
    MtgFormat.pauper: 'Pauper',
    MtgFormat.pauperCommander: 'Pauper Commander',
    MtgFormat.historic: 'Historic',
    MtgFormat.alchemy: 'Alchemy',
    MtgFormat.explorer: 'Explorer',
    MtgFormat.brawl: 'Brawl',
    MtgFormat.standardBrawl: 'Standard Brawl',
    MtgFormat.limited: 'Limited',
    MtgFormat.cube: 'Cube',
    MtgFormat.custom: 'Custom',
  };

  @override
  Widget build(BuildContext context) {
    // If a card is selected, show card detail view
    if (selectedCard != null) {
      return _buildCardDetailView(context);
    }

    // Default deck stats view (only show if deck is not null)
    if (deck == null) {
      return const Drawer(
        width: 350,
        child: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final formatName = _formatDisplayNames[deck!.format] ?? deck!.format.toString();
    final isValid = decksController.isDeckValid(deck!);

    return Drawer(
      width: 350,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              _buildDeckHeader(context, formatName, isValid),
              const SizedBox(height: 24),
              
              // Stats
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildDeckStats(context),
                      const SizedBox(height: 24),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeckHeader(BuildContext context, String formatName, bool isValid) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    deck!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isValid)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 24,
                  )
                else
                  const Icon(
                    Icons.warning,
                    color: Colors.orange,
                    size: 24,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(formatName),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                ),
                if (deck!.isTemplate)
                  Chip(
                    label: Text('decks.detail.template'.tr()),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                Chip(
                  label: Text(deck!.metadata.status.toString().split('.').last),
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ],
            ),
            if (deck!.metadata.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                deck!.metadata.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeckStats(BuildContext context) {
    return StreamBuilder<List<DeckCard>>(
      stream: decksController.getDeckCardsStream(deck!.id),
      builder: (context, snapshot) {
        final cards = snapshot.data ?? [];
        final cardCount = cards.fold<int>(0, (total, card) => total + (card.isInSideboard ? 0 : card.count));
        final mainboardCount = cards.fold<int>(0, (total, card) => total + (!card.isInSideboard && !card.isCommander ? card.count : 0));
        final sideboardCount = cards.fold<int>(0, (total, card) => total + (card.isInSideboard ? card.count : 0));
        final commanderCount = cards.where((card) => card.isCommander).fold<int>(0, (total, card) => total + card.count);
        final requiredCards = _getRequiredCardCount(deck!.format);
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'decks.detail.stats'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildStatRow(
                  context,
                  'decks.detail.total_cards'.tr(),
                  '$cardCount / $requiredCards',
                  requiredCards == '∞' ? true : cardCount >= (int.tryParse(requiredCards.replaceAll('+', '')) ?? 0),
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  'decks.detail.mainboard'.tr(),
                  mainboardCount.toString(),
                  true,
                ),
                const SizedBox(height: 8),
                _buildStatRow(
                  context,
                  'decks.detail.sideboard'.tr(),
                  sideboardCount.toString(),
                  true,
                ),
                if (deck!.isCommanderFormat) ...[
                  const SizedBox(height: 8),
                  _buildStatRow(
                    context,
                    'decks.detail.commander'.tr(),
                    commanderCount.toString(),
                    commanderCount > 0,
                  ),
                ],
                if (deck!.estimatedValue != null) ...[
                  const Divider(height: 24),
                  _buildStatRow(
                    context,
                    'decks.detail.estimated_value'.tr(),
                    '\$${deck!.estimatedValue!.toStringAsFixed(2)}',
                    true,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, bool isValid) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Row(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isValid ? null : Theme.of(context).colorScheme.error,
              ),
            ),
            if (!isValid) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.error_outline,
                size: 16,
                color: Theme.of(context).colorScheme.error,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'decks.detail.actions'.tr(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        
        // Primary actions
        FilledButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: Text('decks.detail.edit'.tr()),
        ),
        const SizedBox(height: 8),
        
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share),
          label: Text('decks.detail.share'.tr()),
        ),
        const SizedBox(height: 16),
        
        // Secondary actions
        Text(
          'decks.detail.more_actions'.tr(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        
        ListTile(
          leading: const Icon(Icons.copy),
          title: Text('decks.detail.duplicate'.tr()),
          onTap: onDuplicate,
          contentPadding: EdgeInsets.zero,
        ),
        ListTile(
          leading: const Icon(Icons.download),
          title: Text('decks.detail.export'.tr()),
          onTap: onExport,
          contentPadding: EdgeInsets.zero,
        ),
        
        const Divider(height: 24),
        
        // Danger zone
        ListTile(
          leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
          title: Text(
            'decks.detail.delete'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          onTap: onDelete,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  String _getRequiredCardCount(MtgFormat format) {
    switch (format) {
      case MtgFormat.commander:
      case MtgFormat.commanderOnehundred:
      case MtgFormat.pauperCommander:
      case MtgFormat.brawl:
      case MtgFormat.standardBrawl:
        return '100';
      case MtgFormat.standard:
      case MtgFormat.pioneer:
      case MtgFormat.modern:
      case MtgFormat.legacy:
      case MtgFormat.vintage:
      case MtgFormat.historic:
      case MtgFormat.alchemy:
      case MtgFormat.explorer:
      case MtgFormat.pauper:
        return '60+';
      case MtgFormat.limited:
        return '40+';
      case MtgFormat.cube:
      case MtgFormat.custom:
        return '∞';
    }
  }

  Widget _buildCardDetailView(BuildContext context) {
    if (selectedCard == null) return Container();

    final card = selectedCard!;
    final mtgCard = card.mtgCardReference;
    final isCommanderFormat = deck?.isCommanderFormat ?? false;

    return Drawer(
      width: 350,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    onPressed: onCardBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Expanded(
                    child: Text(
                      mtgCard.name,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Card content
              Expanded(
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(BuildContext context, MtgCard mtgCard) {
    final imageUrl = mtgCard.firebaseImageUris?.normal;
    
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) => const Center(
                  child: CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => const Center(
                  child: Icon(Icons.image_not_supported, size: 64),
                ),
              )
            : const Center(
                child: Icon(Icons.image, size: 64),
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
}