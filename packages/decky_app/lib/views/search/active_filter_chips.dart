import 'package:decky_core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:decky_core/widgets/rarity_icon.dart';

class ActiveFilterChips extends StatelessWidget {
  final SearchProvider searchProvider;

  const ActiveFilterChips({super.key, required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 48, // Fixed height to prevent jumping
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
            children: [
              // Color filters section
              _ColorFiltersSection(searchProvider: searchProvider),
              const SizedBox(width: 16),
              // Rarity filters section
              _RarityFiltersSection(searchProvider: searchProvider),
              const SizedBox(width: 16),
              // Clear filters button with badge
              // if (searchProvider.hasActiveFilters) _ClearFiltersButton(searchProvider: searchProvider),
            ],
          ),
        ),
        Divider(color: AppTheme.silverGray),
      ],
    );
  }
}

class _ColorFiltersSection extends StatelessWidget {
  final SearchProvider searchProvider;

  const _ColorFiltersSection({required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
      children: [
        // Text('Colors:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        // const SizedBox(width: 8),
        ...searchProvider.filterOptions.colors.map((colorOption) {
          return _ColorFilterButton(
            colorOption: colorOption,
            isSelected: searchProvider.selectedColors.contains(colorOption.symbol),
            onTap: () {
              if (searchProvider.selectedColors.contains(colorOption.symbol)) {
                searchProvider.removeColorFilter(colorOption.symbol);
              } else {
                searchProvider.addColorFilter(colorOption.symbol);
              }
            },
          );
        }),
      ],
    );
  }
}

class _ColorFilterButton extends StatelessWidget {
  final dynamic colorOption;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorFilterButton({required this.colorOption, required this.isSelected, required this.onTap});

  // Map MTG colors to their actual colors
  Color _getColorForSymbol(String colorSymbol) {
    switch (colorSymbol.toUpperCase()) {
      case 'W':
        return const Color(0xFFFFFBD5); // White
      case 'U':
        return const Color(0xFF0E68AB); // Blue
      case 'B':
        return const Color(0xFF150B00); // Black
      case 'R':
        return const Color(0xFFD3202A); // Red
      case 'G':
        return const Color(0xFF00733E); // Green
      case 'C':
        return const Color(0xFFCCC2C0); // Colorless
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _getColorForSymbol(colorOption.symbol);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 32, // Match rarity button width
        height: 32, // Match rarity button height
        decoration: BoxDecoration(
          color: baseColor.withOpacity(isSelected ? 0.8 : 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: baseColor, width: 2), // Match rarity button border width
          boxShadow: isSelected
              ? [BoxShadow(color: baseColor.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            colorOption.symbol,
            style: TextStyle(
              color: colorOption.symbol == 'W' || colorOption.symbol == 'C' ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _RarityFiltersSection extends StatelessWidget {
  final SearchProvider searchProvider;

  const _RarityFiltersSection({required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Center vertically
      children: [
        Text('Rarity:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        ...searchProvider.filterOptions.rarities.map((rarity) {
          return _RarityFilterButton(
            rarity: rarity,
            isSelected: searchProvider.selectedRarities.contains(rarity),
            onTap: () {
              if (searchProvider.selectedRarities.contains(rarity)) {
                searchProvider.removeRarityFilter(rarity);
              } else {
                searchProvider.addRarityFilter(rarity);
              }
            },
          );
        }),
      ],
    );
  }
}

class _RarityFilterButton extends StatelessWidget {
  final String rarity;
  final bool isSelected;
  final VoidCallback onTap;

  const _RarityFilterButton({required this.rarity, required this.isSelected, required this.onTap});

  // Get rarity color
  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey[600]!;
      case 'uncommon':
        return Colors.blue[600]!;
      case 'rare':
        return Colors.amber[600]!;
      case 'mythic':
        return Colors.orange[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 32, // Fixed width
        height: 32, // Fixed height
        decoration: BoxDecoration(
          color: isSelected ? _getRarityColor(rarity).withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? _getRarityColor(rarity) : Colors.grey.withOpacity(0.3),
            width: 2, // Always use same border width
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: _getRarityColor(rarity).withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: RarityIcon(rarity: rarity, size: 18, isSelected: isSelected),
        ),
      ),
    );
  }
}

class _ClearFiltersButton extends StatelessWidget {
  final SearchProvider searchProvider;

  const _ClearFiltersButton({required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: searchProvider.clearFilters,
          icon: const Icon(Icons.close, size: 16),

          style: IconButton.styleFrom(foregroundColor: AppTheme.obsidianBlack),
        ),
        if (searchProvider.activeFilterCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${searchProvider.activeFilterCount}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
