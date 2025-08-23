import 'dart:async';
import 'package:flutter/material.dart';
import 'package:decky_core/providers/base_search_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchField extends StatefulWidget {
  final BaseSearchProvider searchProvider;

  const SearchField({super.key, required this.searchProvider});

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Listen to search provider changes to update the search field
    widget.searchProvider.addListener(_onSearchProviderChanged);
    _searchController.text = widget.searchProvider.query;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    widget.searchProvider.removeListener(_onSearchProviderChanged);
    super.dispose();
  }

  void _onSearchProviderChanged() {
    if (_searchController.text != widget.searchProvider.query) {
      _searchController.text = widget.searchProvider.query;
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    setState(() {
      _isTyping = true;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
        });
        widget.searchProvider.updateQuery(value);
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    setState(() {
      _isTyping = false;
    });
    _searchController.clear();
    widget.searchProvider.clearAll();
  }

  void _onSubmitted(String value) {
    _debounceTimer?.cancel();
    setState(() {
      _isTyping = false;
    });
    if (value.isNotEmpty) {
      widget.searchProvider.updateQuery(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search.hint'.tr(),
                prefixIcon: _isTyping
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _clearSearch)
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              onChanged: _onSearchChanged,
              onSubmitted: _onSubmitted,
            ),
          ),
          const SizedBox(width: 8),

          // const SizedBox(width: 8),
          // PopupMenuButton<String>(
          //   icon: const Icon(Icons.sort),
          //   onSelected: (value) {
          //     final parts = value.split(':');
          //     widget.searchProvider.applySortOrder(parts[0], parts[1]);
          //   },
          //   itemBuilder: (context) => [
          //     PopupMenuItem(value: 'name:asc', child: Text('search.sort.name_asc'.tr())),
          //     PopupMenuItem(value: 'name:desc', child: Text('search.sort.name_desc'.tr())),
          //     PopupMenuItem(value: 'mana_value:asc', child: Text('search.sort.mana_value_asc'.tr())),
          //     PopupMenuItem(value: 'mana_value:desc', child: Text('search.sort.mana_value_desc'.tr())),
          //     PopupMenuItem(value: '_score:desc', child: Text('search.sort.relevance'.tr())),
          //   ],
          // ),
        ],
      ),
    );
  }
}
