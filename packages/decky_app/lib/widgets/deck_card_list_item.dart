import 'package:flutter/material.dart';
import 'package:decky_core/model/deck_card.dart';

class DeckCardListItem extends StatelessWidget {
  final DeckCard deckCard;
  final VoidCallback? onTap;

  const DeckCardListItem({super.key, required this.deckCard, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = deckCard.mtgCardReference.colors;
    final backgroundColor = _getCardBackgroundColor(colors);
    final borderGradient = _getCardBorderGradient(colors);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        gradient: borderGradient,
        border: borderGradient == null ? Border.all(color: backgroundColor.withValues(alpha: 0.3), width: 2) : null,
      ),
      child: Container(
        margin: borderGradient != null ? const EdgeInsets.all(2) : EdgeInsets.zero,
        decoration: borderGradient != null
            ? BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(3))
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${deckCard.count}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(backgroundColor),
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deckCard.mtgCardReference.name,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _getTextColor(backgroundColor),
                        fontSize: 12,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildManaCost(theme, backgroundColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManaCost(ThemeData theme, Color backgroundColor) {
    final manaCost = deckCard.mtgCardReference.manaCost;
    if (manaCost == null || manaCost.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor = _getTextColor(backgroundColor);
    return Text(
      manaCost,
      style: theme.textTheme.labelSmall?.copyWith(
        color: textColor.withValues(alpha: 0.8),
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _getCardBackgroundColor(List<String> colors) {
    if (colors.isEmpty) {
      return const Color(0xFFCCC2C0);
    }

    if (colors.length == 1) {
      switch (colors.first.toUpperCase()) {
        case 'W':
          return const Color(0xFFFFFBD5);
        case 'U':
          return const Color(0xFF0E68AB);
        case 'B':
          return const Color(0xFF150B00);
        case 'R':
          return const Color(0xFFD3202A);
        case 'G':
          return const Color(0xFF00733E);
        default:
          return const Color(0xFFCCC2C0);
      }
    }

    return const Color(0xFFFFD700);
  }

  LinearGradient? _getCardBorderGradient(List<String> colors) {
    if (colors.length <= 1) {
      return null;
    }

    final gradientColors = colors.map((colorSymbol) {
      switch (colorSymbol.toUpperCase()) {
        case 'W':
          return const Color(0xFFFFFBD5);
        case 'U':
          return const Color(0xFF0E68AB);
        case 'B':
          return const Color(0xFF150B00);
        case 'R':
          return const Color(0xFFD3202A);
        case 'G':
          return const Color(0xFF00733E);
        default:
          return const Color(0xFFCCC2C0);
      }
    }).toList();

    return LinearGradient(colors: gradientColors, stops: _generateStops(gradientColors.length));
  }

  List<double> _generateStops(int colorCount) {
    if (colorCount <= 1) return [1.0];

    final stops = <double>[];
    for (int i = 0; i < colorCount; i++) {
      stops.add(i / (colorCount - 1));
    }
    return stops;
  }

  Color _getTextColor(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }
}
