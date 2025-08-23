import 'package:flutter/material.dart';
import 'package:decky_core/model/deck_card.dart';

class ManaCostDistributionChart extends StatelessWidget {
  final List<DeckCard> cards;
  final int totalCards;
  final int requiredCards;
  final String title;

  const ManaCostDistributionChart({
    super.key,
    required this.cards,
    required this.totalCards,
    required this.requiredCards,
    this.title = 'Deck',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final manaCostCounts = _calculateManaCostDistribution();
    final maxCount = manaCostCounts.isEmpty ? 0 : manaCostCounts.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$title ($totalCards/${requiredCards == -1 ? '∞' : '$requiredCards'})',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text('Mana Cost', style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.5), width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(6, (index) {
                final cost = index == 0
                    ? '0-1'
                    : index == 5
                    ? '6+'
                    : (index + 1).toString();
                final count = manaCostCounts[index] ?? 0;
                final barHeight = maxCount == 0 ? 0.0 : (count / maxCount) * 40;

                return Column(
                  children: [
                    Container(
                      width: 20,
                      height: 50,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 20,
                        height: barHeight,
                        decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                        alignment: Alignment.bottomCenter,
                        child: count > 0 ? Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            count.toString(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ) : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(cost, style: theme.textTheme.labelSmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Map<int, int> _calculateManaCostDistribution() {
    final Map<int, int> distribution = {};

    for (final deckCard in cards) {
      if (deckCard.isInSideboard) continue;

      final cmc = deckCard.mtgCardReference.convertedManaCost.round();

      // Map CMC to chart index:
      // 0-1 cost -> index 0
      // 2 cost -> index 1
      // 3 cost -> index 2
      // 4 cost -> index 3
      // 5 cost -> index 4
      // 6+ cost -> index 5
      final int costIndex;
      if (cmc <= 1) {
        costIndex = 0; // 0-1 cost cards
      } else if (cmc >= 6) {
        costIndex = 5; // 6+ cost cards
      } else {
        costIndex = cmc - 1; // 2->1, 3->2, 4->3, 5->4
      }

      distribution[costIndex] = (distribution[costIndex] ?? 0) + deckCard.count;
    }

    return distribution;
  }
}
