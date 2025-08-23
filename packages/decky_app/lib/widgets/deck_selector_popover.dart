import 'package:flutter/material.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'package:easy_localization/easy_localization.dart';

class DeckSelectorPopover extends StatelessWidget {
  final UserDecksController decksController;
  final String? currentDeckId;
  final Function(UserDeck) onDeckSelected;
  final Widget child;

  const DeckSelectorPopover({
    super.key,
    required this.decksController,
    required this.onDeckSelected,
    required this.child,
    this.currentDeckId,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<UserDeck>(
      itemBuilder: (context) => _buildMenuItems(context),
      onSelected: onDeckSelected,
      position: PopupMenuPosition.under,
      child: child,
    );
  }

  List<PopupMenuEntry<UserDeck>> _buildMenuItems(BuildContext context) {
    final decks = decksController.decks;
    final items = <PopupMenuEntry<UserDeck>>[];

    if (decks.isEmpty) {
      items.add(
        PopupMenuItem<UserDeck>(
          enabled: false,
          child: Text(
            'decks.selector.no_decks'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
      return items;
    }

    // Add header
    items.add(
      PopupMenuItem<UserDeck>(
        enabled: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'decks.selector.select_deck'.tr(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    );

    // Add separator
    items.add(const PopupMenuDivider());

    // Add deck items
    for (int i = 0; i < decks.length; i++) {
      final deck = decks[i];
      final isCurrentDeck = deck.id == currentDeckId;
      final cardCount = decksController.getDeckCardCount(deck.id);
      final isValid = decksController.isDeckValid(deck);

      items.add(
        PopupMenuItem<UserDeck>(
          value: deck,
          enabled: !isCurrentDeck,
          child: _buildDeckItem(context, deck, cardCount, isValid, isCurrentDeck),
        ),
      );

      // Add separator between items (except for the last one)
      if (i < decks.length - 1) {
        items.add(const PopupMenuDivider());
      }
    }

    return items;
  }

  Widget _buildDeckItem(
    BuildContext context,
    UserDeck deck,
    int cardCount,
    bool isValid,
    bool isCurrentDeck,
  ) {
    final formatColors = <MtgFormat, Color>{
      MtgFormat.standard: Colors.blue,
      MtgFormat.pioneer: Colors.orange,
      MtgFormat.modern: Colors.red,
      MtgFormat.legacy: Colors.purple,
      MtgFormat.vintage: Colors.brown,
      MtgFormat.commander: Colors.green,
      MtgFormat.commanderOnehundred: Colors.teal,
      MtgFormat.pauper: Colors.grey,
      MtgFormat.pauperCommander: Colors.blueGrey,
      MtgFormat.historic: Colors.indigo,
      MtgFormat.alchemy: Colors.pink,
      MtgFormat.explorer: Colors.amber,
      MtgFormat.brawl: Colors.lime,
      MtgFormat.standardBrawl: Colors.cyan,
      MtgFormat.limited: Colors.deepPurple,
      MtgFormat.cube: Colors.deepOrange,
      MtgFormat.custom: Colors.black54,
    };

    final formatColor = formatColors[deck.format] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Format indicator
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: formatColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              
              // Deck info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deck.name,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isCurrentDeck 
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentDeck) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Chip(
                          label: Text(
                            _getFormatDisplayName(deck.format),
                            style: const TextStyle(fontSize: 10),
                          ),
                          backgroundColor: formatColor.withValues(alpha: 0.1),
                          side: BorderSide(color: formatColor, width: 1),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'decks.selector.card_count'.tr(namedArgs: {'count': cardCount.toString()}),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          isValid ? Icons.check_circle : Icons.warning,
                          size: 14,
                          color: isValid ? Colors.green : Colors.orange,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isCurrentDeck) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'decks.selector.current_deck'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getFormatDisplayName(MtgFormat format) {
    const formatDisplayNames = {
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

    return formatDisplayNames[format] ?? format.toString().split('.').last;
  }
}

class DeckSelectorButton extends StatelessWidget {
  final UserDecksController decksController;
  final String? currentDeckId;
  final Function(UserDeck) onDeckSelected;
  final String? label;
  final IconData? icon;

  const DeckSelectorButton({
    super.key,
    required this.decksController,
    required this.onDeckSelected,
    this.currentDeckId,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DeckSelectorPopover(
      decksController: decksController,
      currentDeckId: currentDeckId,
      onDeckSelected: onDeckSelected,
      child: OutlinedButton.icon(
        icon: Icon(icon ?? Icons.folder),
        label: Text(label ?? 'decks.selector.choose_deck'.tr()),
        onPressed: () {}, // The popover handles the interaction
      ),
    );
  }
}

class DeckSelectorIconButton extends StatelessWidget {
  final UserDecksController decksController;
  final String? currentDeckId;
  final Function(UserDeck) onDeckSelected;
  final IconData? icon;
  final String? tooltip;

  const DeckSelectorIconButton({
    super.key,
    required this.decksController,
    required this.onDeckSelected,
    this.currentDeckId,
    this.icon,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return DeckSelectorPopover(
      decksController: decksController,
      currentDeckId: currentDeckId,
      onDeckSelected: onDeckSelected,
      child: IconButton(
        icon: Icon(icon ?? Icons.swap_horiz),
        tooltip: tooltip ?? 'decks.selector.switch_deck'.tr(),
        onPressed: () {}, // The popover handles the interaction
      ),
    );
  }
}