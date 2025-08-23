import 'package:flutter/material.dart';
import 'package:decky_core/model/collection_card.dart';

class CollectionCardListItem extends StatelessWidget {
  final CollectionCard collectionCard;
  final VoidCallback? onTap;

  const CollectionCardListItem({
    super.key,
    required this.collectionCard,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = collectionCard.mtgCardReference.colors;
    final backgroundColor = _getCardBackgroundColor(colors);
    final borderGradient = _getCardBorderGradient(colors);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        gradient: borderGradient,
        border: borderGradient == null 
            ? Border.all(color: backgroundColor.withValues(alpha: 0.3), width: 2) 
            : null,
      ),
      child: Container(
        margin: borderGradient != null ? const EdgeInsets.all(2) : EdgeInsets.zero,
        decoration: borderGradient != null
            ? BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(3),
              )
            : null,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  // Count badge
                  Container(
                    width: 28,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${collectionCard.count}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _getTextColor(backgroundColor),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Card name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          collectionCard.mtgCardReference.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getTextColor(backgroundColor),
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (collectionCard.mtgCardReference.type.isNotEmpty)
                          Text(
                            collectionCard.mtgCardReference.type,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _getTextColor(backgroundColor).withValues(alpha: 0.7),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Additional info
                  SizedBox(
                    width: 60,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (collectionCard.isFoil == true)
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.purple.withValues(alpha: 0.8),
                          ),
                        _buildManaCost(theme, backgroundColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildManaCost(ThemeData theme, Color backgroundColor) {
    final manaCost = collectionCard.mtgCardReference.manaCost;
    if (manaCost == null || manaCost.isEmpty) {
      return const SizedBox.shrink();
    }

    final textColor = _getTextColor(backgroundColor);
    return Text(
      manaCost,
      style: theme.textTheme.labelSmall?.copyWith(
        color: textColor.withValues(alpha: 0.8),
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Color _getCardBackgroundColor(List<String> colors) {
    if (colors.isEmpty) {
      return const Color(0xFFCCC2C0).withValues(alpha: 0.15);
    }

    if (colors.length == 1) {
      switch (colors.first.toUpperCase()) {
        case 'W':
          return const Color(0xFFFFFBD5).withValues(alpha: 0.3);
        case 'U':
          return const Color(0xFF0E68AB).withValues(alpha: 0.15);
        case 'B':
          return const Color(0xFF150B00).withValues(alpha: 0.15);
        case 'R':
          return const Color(0xFFD3202A).withValues(alpha: 0.15);
        case 'G':
          return const Color(0xFF00733E).withValues(alpha: 0.15);
        default:
          return const Color(0xFFCCC2C0).withValues(alpha: 0.15);
      }
    }

    return const Color(0xFFFFD700).withValues(alpha: 0.15);
  }

  LinearGradient? _getCardBorderGradient(List<String> colors) {
    if (colors.length <= 1) {
      return null;
    }

    final gradientColors = colors.map((colorSymbol) {
      switch (colorSymbol.toUpperCase()) {
        case 'W':
          return const Color(0xFFFFFBD5).withValues(alpha: 0.5);
        case 'U':
          return const Color(0xFF0E68AB).withValues(alpha: 0.5);
        case 'B':
          return const Color(0xFF150B00).withValues(alpha: 0.5);
        case 'R':
          return const Color(0xFFD3202A).withValues(alpha: 0.5);
        case 'G':
          return const Color(0xFF00733E).withValues(alpha: 0.5);
        default:
          return const Color(0xFFCCC2C0).withValues(alpha: 0.5);
      }
    }).toList();

    return LinearGradient(
      colors: gradientColors,
      stops: _generateStops(gradientColors.length),
    );
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
    // For these light/transparent backgrounds, always use dark text
    return Colors.black87;
  }
}