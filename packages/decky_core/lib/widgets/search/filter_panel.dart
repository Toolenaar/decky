import 'package:flutter/material.dart';
import '../../providers/search_provider.dart';
import '../../model/search/filter_options.dart';
import 'color_filter.dart';
import 'type_filter.dart';
import 'range_filter.dart';

class FilterPanel extends StatefulWidget {
  final SearchProvider searchProvider;
  final bool isCompact;

  const FilterPanel({super.key, required this.searchProvider, this.isCompact = false});

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  final Map<String, bool> _expandedSections = {
    'colors': true,
    'types': true,
    'rarities': true,
    'manaValue': false,
    'price': false,
    'formats': false,
    'advanced': false,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.searchProvider,
      builder: (context, child) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (!widget.isCompact) _buildQuickFilters(),
              _buildFilterSection('colors', 'Colors', Icons.palette, _buildColorFilters()),
              _buildFilterSection('types', 'Types', Icons.category, _buildTypeFilters()),
              _buildFilterSection(
                'rarities',
                'Rarity',
                Icons.star,
                RarityFilter(searchProvider: widget.searchProvider),
              ),
              _buildFilterSection(
                'manaValue',
                'Mana Value',
                Icons.functions,
                ManaValueFilter(searchProvider: widget.searchProvider),
              ),
              _buildFilterSection(
                'price',
                'Price',
                Icons.attach_money,
                PriceFilter(searchProvider: widget.searchProvider),
              ),
              _buildFilterSection('formats', 'Format Legality', Icons.gavel, _buildFormatFilters()),
              _buildFilterSection('advanced', 'Advanced', Icons.settings, _buildAdvancedFilters()),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(Icons.filter_list, color: Theme.of(context).primaryColor),
        const SizedBox(width: 8),
        Text('Filters', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        if (widget.searchProvider.hasActiveFilters)
          TextButton.icon(
            onPressed: widget.searchProvider.clearFilters,
            icon: const Icon(Icons.clear),
            label: Text('Clear (${widget.searchProvider.activeFilterCount})'),
          ),
      ],
    );
  }

  Widget _buildQuickFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Filters', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: QuickFilter.defaults.map((quickFilter) {
            return ActionChip(
              avatar: Text(quickFilter.icon),
              label: Text(quickFilter.name),
              onPressed: () {
                widget.searchProvider.applyQuickFilter(quickFilter.filters);
              },
              backgroundColor: Colors.blue[50],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildFilterSection(String key, String title, IconData icon, Widget content) {
    final isExpanded = _expandedSections[key] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(title),
            trailing: IconButton(
              icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _expandedSections[key] = !isExpanded;
                });
              },
            ),
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
          ),
          if (isExpanded) Padding(padding: const EdgeInsets.all(16.0), child: content),
        ],
      ),
    );
  }

  Widget _buildColorFilters() {
    return ColorFilter(searchProvider: widget.searchProvider, colors: widget.searchProvider.filterOptions.colors);
  }

  Widget _buildTypeFilters() {
    return CreatureTypeFilter(searchProvider: widget.searchProvider);
  }

  Widget _buildFormatFilters() {
    final formats = widget.searchProvider.filterOptions.formats;

    return Column(
      children: formats.map((format) {
        final currentLegality = widget.searchProvider.selectedFormats[format];

        return ListTile(
          title: Text(format.toUpperCase()),
          trailing: DropdownButton<String?>(
            value: currentLegality,
            hint: const Text('Any'),
            items: const [
              DropdownMenuItem(value: null, child: Text('Any')),
              DropdownMenuItem(value: 'legal', child: Text('Legal')),
              DropdownMenuItem(value: 'restricted', child: Text('Restricted')),
              DropdownMenuItem(value: 'banned', child: Text('Banned')),
            ],
            onChanged: (value) {
              widget.searchProvider.setFormatLegality(format, value);
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        CheckboxListTile(
          title: const Text('Reserved List'),
          value: widget.searchProvider.filters.isReserved,
          tristate: true,
          onChanged: (value) {
            final filters = widget.searchProvider.filters.copyWith(isReserved: value);
            widget.searchProvider.updateFilters(filters);
          },
        ),
        CheckboxListTile(
          title: const Text('Promo Cards'),
          value: widget.searchProvider.filters.isPromo,
          tristate: true,
          onChanged: (value) {
            final filters = widget.searchProvider.filters.copyWith(isPromo: value);
            widget.searchProvider.updateFilters(filters);
          },
        ),
        CheckboxListTile(
          title: const Text('Full Art'),
          value: widget.searchProvider.filters.isFullArt,
          tristate: true,
          onChanged: (value) {
            final filters = widget.searchProvider.filters.copyWith(isFullArt: value);
            widget.searchProvider.updateFilters(filters);
          },
        ),
        CheckboxListTile(
          title: const Text('Reprints'),
          value: widget.searchProvider.filters.isReprint,
          tristate: true,
          onChanged: (value) {
            final filters = widget.searchProvider.filters.copyWith(isReprint: value);
            widget.searchProvider.updateFilters(filters);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Oracle Text',
            hintText: 'Search card text...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final filters = widget.searchProvider.filters.copyWith(oracleText: value.isEmpty ? null : value);
            widget.searchProvider.updateFilters(filters);
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          decoration: const InputDecoration(
            labelText: 'Artist',
            hintText: 'Artist name...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            final filters = widget.searchProvider.filters.copyWith(artist: value.isEmpty ? null : value);
            widget.searchProvider.updateFilters(filters);
          },
        ),
      ],
    );
  }
}

class CompactFilterPanel extends StatefulWidget {
  final SearchProvider searchProvider;

  const CompactFilterPanel({super.key, required this.searchProvider});

  @override
  State<CompactFilterPanel> createState() => _CompactFilterPanelState();
}

class _CompactFilterPanelState extends State<CompactFilterPanel> {
  final Map<String, bool> _expandedSections = {
    'quick': true,
    'colors': false,
    'types': false,
    'rarities': false,
    'advanced': false,
  };

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.searchProvider,
      builder: (context, child) {
        return Container(
          constraints: const BoxConstraints(maxHeight: 400),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCompactHeader(),
                  const SizedBox(height: 12),
                  _buildQuickFiltersSection(),
                  _buildCompactSection('colors', 'Colors', Icons.palette, _buildColorFilters()),
                  _buildCompactSection('types', 'Types', Icons.category, _buildTypeFilters()),
                  _buildCompactSection(
                    'rarities',
                    'Rarity',
                    Icons.star,
                    RarityFilter(searchProvider: widget.searchProvider),
                  ),
                  _buildCompactSection('advanced', 'Advanced', Icons.settings, _buildAdvancedFilters()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactHeader() {
    return Row(
      children: [
        Icon(Icons.filter_list, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(width: 8),
        Text('Filters', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Spacer(),
        if (widget.searchProvider.hasActiveFilters)
          TextButton.icon(
            onPressed: widget.searchProvider.clearFilters,
            icon: const Icon(Icons.clear, size: 16),
            label: Text('Clear (${widget.searchProvider.activeFilterCount})'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _buildQuickFiltersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on, size: 16),
            const SizedBox(width: 4),
            Text('Quick Filters', style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6.0,
          runSpacing: 4.0,
          children: QuickFilter.defaults.map((quickFilter) {
            return ActionChip(
              avatar: Text(quickFilter.icon, style: const TextStyle(fontSize: 12)),
              label: Text(quickFilter.name, style: const TextStyle(fontSize: 11)),
              onPressed: () {
                widget.searchProvider.applyQuickFilter(quickFilter.filters);
              },
              backgroundColor: Colors.blue[50],
              padding: const EdgeInsets.symmetric(horizontal: 4),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCompactSection(String key, String title, IconData icon, Widget content) {
    final isExpanded = _expandedSections[key] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedSections[key] = !isExpanded;
              });
            },
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, size: 16),
                  const SizedBox(width: 8),
                  Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 20),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[25],
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildColorFilters() {
    return ColorFilter(searchProvider: widget.searchProvider, colors: widget.searchProvider.filterOptions.colors);
  }

  Widget _buildTypeFilters() {
    return CreatureTypeFilter(searchProvider: widget.searchProvider);
  }

  Widget _buildAdvancedFilters() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCompactCheckbox('Reserved List', widget.searchProvider.filters.isReserved, (value) {
                final filters = widget.searchProvider.filters.copyWith(isReserved: value);
                widget.searchProvider.updateFilters(filters);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactCheckbox('Promo', widget.searchProvider.filters.isPromo, (value) {
                final filters = widget.searchProvider.filters.copyWith(isPromo: value);
                widget.searchProvider.updateFilters(filters);
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildCompactCheckbox('Full Art', widget.searchProvider.filters.isFullArt, (value) {
                final filters = widget.searchProvider.filters.copyWith(isFullArt: value);
                widget.searchProvider.updateFilters(filters);
              }),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildCompactCheckbox('Reprints', widget.searchProvider.filters.isReprint, (value) {
                final filters = widget.searchProvider.filters.copyWith(isReprint: value);
                widget.searchProvider.updateFilters(filters);
              }),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Oracle Text',
                  hintText: 'Search text...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (value) {
                  final filters = widget.searchProvider.filters.copyWith(oracleText: value.isEmpty ? null : value);
                  widget.searchProvider.updateFilters(filters);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Artist',
                  hintText: 'Artist name...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  isDense: true,
                ),
                style: const TextStyle(fontSize: 12),
                onChanged: (value) {
                  final filters = widget.searchProvider.filters.copyWith(artist: value.isEmpty ? null : value);
                  widget.searchProvider.updateFilters(filters);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactCheckbox(String title, bool? value, Function(bool?) onChanged) {
    return InkWell(
      onTap: () {
        bool? newValue;
        if (value == null) {
          newValue = true;
        } else if (value == true) {
          newValue = false;
        } else {
          newValue = null;
        }
        onChanged(newValue);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(4),
          color: value == true ? Colors.blue[50] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value == true
                  ? Icons.check_box
                  : value == false
                  ? Icons.check_box_outline_blank
                  : Icons.indeterminate_check_box,
              size: 16,
              color: value == true ? Theme.of(context).primaryColor : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}
