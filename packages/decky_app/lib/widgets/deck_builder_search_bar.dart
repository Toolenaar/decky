import 'dart:async';
import 'package:flutter/material.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:decky_app/views/search/active_filter_chips.dart';

class DeckBuilderSearchBar extends StatefulWidget {
  final SearchProvider searchProvider;
  final VoidCallback onBack;
  final VoidCallback onToggleDrawer;
  final String deckName;

  const DeckBuilderSearchBar({
    super.key,
    required this.searchProvider,
    required this.onBack,
    required this.onToggleDrawer,
    required this.deckName,
  });

  @override
  State<DeckBuilderSearchBar> createState() => _DeckBuilderSearchBarState();
}

class _DeckBuilderSearchBarState extends State<DeckBuilderSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: widget.onBack,
                  tooltip: 'common.back'.tr(),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'decks.detail.search_hint'.tr(),
                      prefixIcon: _isTyping
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainer,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: _onSearchChanged,
                    onSubmitted: _onSubmitted,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: widget.onToggleDrawer,
                  tooltip: 'decks.detail.stats'.tr(),
                ),
              ],
            ),
            // Quick filter chips when searching
            if (_searchController.text.isNotEmpty) 
              ActiveFilterChips(searchProvider: widget.searchProvider),
          ],
        ),
      ),
    );
  }
}