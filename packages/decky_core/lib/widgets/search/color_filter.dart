import 'package:flutter/material.dart';
import '../../model/search/filter_options.dart';
import '../../providers/search_provider.dart';

class ColorFilter extends StatelessWidget {
  final SearchProvider searchProvider;
  final List<ColorOption> colors;

  const ColorFilter({
    super.key,
    required this.searchProvider,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 4.0,
      children: colors.map((color) {
        final isSelected = searchProvider.selectedColors.contains(color.symbol);
        return FilterChip(
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              searchProvider.addColorFilter(color.symbol);
            } else {
              searchProvider.removeColorFilter(color.symbol);
            }
          },
          avatar: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Color(color.color),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.black26,
                width: 1,
              ),
            ),
          ),
          label: Text(
            color.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          backgroundColor: Colors.grey[100],
          selectedColor: Color(color.color).withOpacity(0.3),
          checkmarkColor: Colors.black87,
        );
      }).toList(),
    );
  }
}

class ManaSymbolIcon extends StatelessWidget {
  final String symbol;
  final double size;
  final Color? backgroundColor;

  const ManaSymbolIcon({
    super.key,
    required this.symbol,
    this.size = 24,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColorForSymbol(symbol);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.black26,
          width: 1,
        ),
      ),
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            color: _getTextColorForBackground(backgroundColor ?? color),
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getColorForSymbol(String symbol) {
    switch (symbol.toUpperCase()) {
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
      case 'C':
        return const Color(0xFFCCC2C0);
      default:
        return Colors.grey;
    }
  }

  Color _getTextColorForBackground(Color backgroundColor) {
    // Calculate brightness and return appropriate text color
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black : Colors.white;
  }
}