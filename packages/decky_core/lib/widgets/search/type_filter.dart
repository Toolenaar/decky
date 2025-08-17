import 'package:flutter/material.dart';
import '../../providers/search_provider.dart';
import '../rarity_icon.dart';

class TypeFilter extends StatelessWidget {
  final SearchProvider searchProvider;
  final List<String> types;
  final String title;
  final Function(String) onAdd;
  final Function(String) onRemove;
  final List<String> selectedValues;

  const TypeFilter({
    super.key,
    required this.searchProvider,
    required this.types,
    required this.title,
    required this.onAdd,
    required this.onRemove,
    required this.selectedValues,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: types.map((type) {
            final isSelected = selectedValues.contains(type);
            return FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  onAdd(type);
                } else {
                  onRemove(type);
                }
              },
              label: Text(
                type,
                style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.3),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CreatureTypeFilter extends StatelessWidget {
  final SearchProvider searchProvider;

  const CreatureTypeFilter({super.key, required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    return TypeFilter(
      searchProvider: searchProvider,
      types: searchProvider.filterOptions.types,
      title: 'Card Types',
      selectedValues: searchProvider.selectedTypes,
      onAdd: searchProvider.addTypeFilter,
      onRemove: searchProvider.removeTypeFilter,
    );
  }
}

class RarityFilter extends StatelessWidget {
  final SearchProvider searchProvider;

  const RarityFilter({super.key, required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    final rarityColors = {
      'common': Colors.grey[600]!,
      'uncommon': Colors.grey[400]!,
      'rare': Colors.amber[600]!,
      'mythic': Colors.deepOrange[600]!,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rarity', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: searchProvider.filterOptions.rarities.map((rarity) {
            final isSelected = searchProvider.selectedRarities.contains(rarity);
            final color = rarityColors[rarity.toLowerCase()] ?? Colors.grey;

            return FilterChip(
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  searchProvider.addRarityFilter(rarity);
                } else {
                  searchProvider.removeRarityFilter(rarity);
                }
              },
              avatar: RarityIcon(rarity: rarity, size: 12, isSelected: isSelected),
              label: Text(
                rarity.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: color.withOpacity(0.3),
            );
          }).toList(),
        ),
      ],
    );
  }
}
