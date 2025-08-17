import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:decky_core/widgets/search/filter_panel.dart';
import 'package:decky_core/model/search/card_search_result.dart';
import 'package:easy_localization/easy_localization.dart';
import 'search_app_bar.dart';
import 'search_field.dart';
import 'active_filter_chips.dart';
import 'search_results.dart';
import 'empty_search_state.dart';

class FindCardsView extends StatefulWidget {
  const FindCardsView({super.key});

  @override
  State<FindCardsView> createState() => _FindCardsViewState();
}

class _FindCardsViewState extends State<FindCardsView> {
  late SearchProvider searchProvider;
  final ScrollController _scrollController = ScrollController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    searchProvider = GetIt.instance<SearchProvider>();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      searchProvider.loadMore();
    }
  }

  void _onCardTap(CardSearchResult card) {
    // TODO: Navigate to card details view
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('search.card_tapped'.tr(namedArgs: {'cardName': card.name}))));
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: SearchAppBar(searchProvider: searchProvider),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth > 900;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return _buildMainContent();
  }

  Widget _buildMobileLayout() {
    return _buildMainContent();
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Search bar
        SearchField(searchProvider: searchProvider, showFilters: _showFilters, onToggleFilters: _toggleFilters),

        // Collapsible filter panel
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _showFilters
              ? Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: CompactFilterPanel(searchProvider: searchProvider),
                )
              : const SizedBox.shrink(),
        ),
        // Active filter chips
        ListenableBuilder(
          listenable: searchProvider,
          builder: (context, child) {
            return ActiveFilterChips(searchProvider: searchProvider);
          },
        ),
        // Search results
        Expanded(
          child: ListenableBuilder(
            listenable: searchProvider,
            builder: (context, child) {
              if (searchProvider.isEmpty) {
                return EmptySearchState(searchProvider: searchProvider);
              }
              return SearchResults(
                searchProvider: searchProvider,
                scrollController: _scrollController,
                onCardTap: _onCardTap,
              );
            },
          ),
        ),
      ],
    );
  }
}
