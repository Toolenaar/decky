import 'package:decky_app/widgets/deck_card_grid.dart';
import 'package:flutter/material.dart';

class CardGrid extends StatelessWidget {
  final int length;
  final Widget Function(int index, double cardWidth) builder;
  // Static fields for easy experimentation with grid layout
  static int mobileColumns = 2; // Mobile: 2 cards per row
  static int tabletColumns = 3; // Tablet: 3 cards per row
  static int smallDesktopColumns = 4; // Small desktop: 4 cards per row
  static int largeDesktopColumns = 6; // Large desktop: 6 cards per row
  static double minCardWidth = 140; // Minimum card width in pixels
  static double cardSpacing = 8; // Spacing between cards
  const CardGrid({super.key, required this.length, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount;
        double cardWidth;

        // Responsive grid calculations using static fields
        if (width < 600) {
          // Mobile
          crossAxisCount = CardGrid.mobileColumns;
        } else if (width < 900) {
          // Tablet
          crossAxisCount = CardGrid.tabletColumns;
        } else if (width < 1200) {
          // Small desktop
          crossAxisCount = CardGrid.smallDesktopColumns;
        } else {
          // Large desktop - use either fixed columns or calculate based on min width
          final calculatedColumns = (width / CardGrid.minCardWidth).floor();
          crossAxisCount = calculatedColumns > CardGrid.largeDesktopColumns
              ? CardGrid.largeDesktopColumns
              : calculatedColumns;
        }

        // Calculate actual card width based on available space
        final totalSpacing = CardGrid.cardSpacing * (crossAxisCount - 1);
        cardWidth = (width - totalSpacing) / crossAxisCount;

        // Ensure minimum card width
        if (cardWidth < CardGrid.minCardWidth) {
          cardWidth = CardGrid.minCardWidth;
        }

        final cardHeight = cardWidth * 1.4;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: CardGrid.cardSpacing,
            mainAxisSpacing: CardGrid.cardSpacing,
            childAspectRatio: cardWidth / cardHeight,
          ),
          itemCount: length,
          itemBuilder: (context, index) {
            return builder(index, cardWidth);
          },
        );
      },
    );
  }
}
