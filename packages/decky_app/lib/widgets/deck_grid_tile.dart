import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:easy_localization/easy_localization.dart';

class DeckGridTile extends StatelessWidget {
  final UserDeck deck;
  final VoidCallback? onTap;
  final bool isValid;
  final int cardCount;

  const DeckGridTile({
    super.key,
    required this.deck,
    this.onTap,
    required this.isValid,
    required this.cardCount,
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

  final Map<MtgFormat, Color> _formatColors = const {
    MtgFormat.standard: Colors.blue,
    MtgFormat.pioneer: Colors.orange,
    MtgFormat.modern: Colors.red,
    MtgFormat.legacy: Colors.purple,
    MtgFormat.vintage: Colors.deepPurple,
    MtgFormat.commander: Colors.green,
    MtgFormat.commanderOnehundred: Colors.teal,
    MtgFormat.pauper: Colors.brown,
    MtgFormat.pauperCommander: Colors.lime,
    MtgFormat.historic: Colors.indigo,
    MtgFormat.alchemy: Colors.amber,
    MtgFormat.explorer: Colors.cyan,
    MtgFormat.brawl: Colors.pink,
    MtgFormat.standardBrawl: Colors.lightBlue,
    MtgFormat.limited: Colors.grey,
    MtgFormat.cube: Colors.blueGrey,
    MtgFormat.custom: Colors.deepOrange,
  };

  @override
  Widget build(BuildContext context) {
    final formatName = _formatDisplayNames[deck.format] ?? deck.format.toString();
    final formatColor = _formatColors[deck.format] ?? Theme.of(context).colorScheme.primary;
    
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildCoverImage(context),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildValidationIndicator(context),
                  ),
                  if (deck.isTemplate)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'decks.template'.tr(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deck.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: formatColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: formatColor.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            formatName,
                            style: TextStyle(
                              color: formatColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$cardCount ${cardCount == 1 ? 'decks.card'.tr() : 'decks.cards'.tr()}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (deck.metadata.description.isNotEmpty)
                      Text(
                        deck.metadata.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverImage(BuildContext context) {
    if (deck.coverImageUrl != null && deck.coverImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: deck.coverImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholderImage(context),
      );
    }
    return _buildPlaceholderImage(context);
  }

  Widget _buildPlaceholderImage(BuildContext context) {
    final formatColor = _formatColors[deck.format] ?? Theme.of(context).colorScheme.primary;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            formatColor.withValues(alpha: 0.3),
            formatColor.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          _getFormatIcon(deck.format),
          size: 48,
          color: formatColor.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  IconData _getFormatIcon(MtgFormat format) {
    switch (format) {
      case MtgFormat.commander:
      case MtgFormat.commanderOnehundred:
      case MtgFormat.pauperCommander:
        return Icons.star;
      case MtgFormat.standard:
      case MtgFormat.pioneer:
      case MtgFormat.modern:
        return Icons.sports_esports;
      case MtgFormat.legacy:
      case MtgFormat.vintage:
        return Icons.auto_awesome;
      case MtgFormat.pauper:
        return Icons.savings;
      case MtgFormat.limited:
        return Icons.inventory_2;
      case MtgFormat.cube:
        return Icons.casino;
      case MtgFormat.brawl:
      case MtgFormat.standardBrawl:
        return Icons.group;
      case MtgFormat.historic:
      case MtgFormat.alchemy:
      case MtgFormat.explorer:
        return Icons.explore;
      case MtgFormat.custom:
        return Icons.tune;
    }
  }

  Widget _buildValidationIndicator(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isValid 
            ? Colors.green.withValues(alpha: 0.9)
            : Colors.orange.withValues(alpha: 0.9),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        isValid ? Icons.check : Icons.warning,
        color: Colors.white,
        size: 18,
      ),
    );
  }
}