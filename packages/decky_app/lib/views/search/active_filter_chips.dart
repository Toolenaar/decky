import 'package:decky_core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:decky_core/providers/base_search_provider.dart';
import 'package:decky_core/widgets/rarity_icon.dart';

class ActiveFilterChips extends StatefulWidget {
  final BaseSearchProvider searchProvider;

  const ActiveFilterChips({super.key, required this.searchProvider});

  @override
  State<ActiveFilterChips> createState() => _ActiveFilterChipsState();
}

class _ActiveFilterChipsState extends State<ActiveFilterChips> {
  @override
  void initState() {
    super.initState();
    widget.searchProvider.addListener(_onSearchProviderChanged);
  }

  @override
  void dispose() {
    widget.searchProvider.removeListener(_onSearchProviderChanged);
    super.dispose();
  }

  void _onSearchProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

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
              _ColorFiltersSection(searchProvider: widget.searchProvider),
              const SizedBox(width: 16),
              // Mana cost filters section
              _ManaCostFiltersSection(searchProvider: widget.searchProvider),
              const SizedBox(width: 16),
              // Rarity filters section
              _RarityFiltersSection(searchProvider: widget.searchProvider),
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
  final BaseSearchProvider searchProvider;

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
          color: baseColor.withValues(alpha: isSelected ? 0.8 : 0.3),
          shape: BoxShape.circle,
          border: Border.all(color: baseColor, width: 2), // Match rarity button border width
          boxShadow: isSelected
              ? [BoxShadow(color: baseColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
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
  final BaseSearchProvider searchProvider;

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
          color: isSelected ? _getRarityColor(rarity).withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? _getRarityColor(rarity) : Colors.grey.withValues(alpha: 0.3),
            width: 2, // Always use same border width
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: _getRarityColor(rarity).withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: RarityIcon(rarity: rarity, size: 18, isSelected: isSelected),
        ),
      ),
    );
  }
}

class _ManaCostFiltersSection extends StatelessWidget {
  final BaseSearchProvider searchProvider;

  const _ManaCostFiltersSection({required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    // Define the mana cost options
    final manaCostOptions = ['1-', '2', '3', '4', '5', '6+'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('Mana:', style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        ...manaCostOptions.map((manaCost) {
          return _ManaCostFilterButton(
            manaCost: manaCost,
            isSelected: searchProvider.selectedConvertedManaCosts.contains(manaCost),
            onTap: () {
              if (searchProvider.selectedConvertedManaCosts.contains(manaCost)) {
                searchProvider.removeConvertedManaCostFilter(manaCost);
              } else {
                searchProvider.addConvertedManaCostFilter(manaCost);
              }
            },
          );
        }),
      ],
    );
  }
}

class _ManaCostFilterButton extends StatelessWidget {
  final String manaCost;
  final bool isSelected;
  final VoidCallback onTap;

  const _ManaCostFilterButton({
    required this.manaCost,
    required this.isSelected,
    required this.onTap,
  });

  Color _getManaCostColor(String manaCost) {
    switch (manaCost) {
      case '1-':
        return Colors.grey[600]!;
      case '2':
        return Colors.blue[400]!;
      case '3':
        return Colors.green[500]!;
      case '4':
        return Colors.orange[500]!;
      case '5':
        return Colors.red[500]!;
      case '6+':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getManaCostColor(manaCost);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            manaCost,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[700],
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearFiltersButton extends StatelessWidget {
  final BaseSearchProvider searchProvider;

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
