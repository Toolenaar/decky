import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/controller/user_collection_controller.dart';
import 'package:decky_core/providers/collection_search_provider.dart';
import 'package:decky_core/model/collection_card.dart';
import 'package:decky_app/widgets/filtered_collection_grid.dart';
import 'package:decky_app/widgets/animated_collection_side_panel.dart';
import '../search/search_field.dart';
import '../search/active_filter_chips.dart';

class CollectionView extends StatefulWidget {
  const CollectionView({super.key});

  @override
  State<CollectionView> createState() => _CollectionViewState();
}

class _CollectionViewState extends State<CollectionView> {
  final UserCollectionController _collectionController = GetIt.instance<UserCollectionController>();
  late final CollectionSearchProvider _searchProvider;
  CollectionCard? _selectedCard;

  @override
  void initState() {
    super.initState();
    _searchProvider = CollectionSearchProvider(_collectionController);
  }

  @override
  void dispose() {
    _searchProvider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Search bar
          SearchField(searchProvider: _searchProvider),
          
          // Active filter chips
          ListenableBuilder(
            listenable: _searchProvider,
            builder: (context, child) {
              return ActiveFilterChips(searchProvider: _searchProvider);
            },
          ),
          
          // Collection content
          Expanded(
            child: AnimatedCollectionSidePanel(
              collectionController: _collectionController,
              onCardTap: (card) {
                setState(() {
                  _selectedCard = card;
                });
              },
              selectedCard: _selectedCard,
              onCardBack: () {
                setState(() {
                  _selectedCard = null;
                });
              },
              child: FilteredCollectionGrid(
                searchProvider: _searchProvider,
                collectionController: _collectionController,
                onCardTap: (card) {
                  setState(() {
                    _selectedCard = card;
                  });
                },
              ),
            ),
          ),
        ],
      ),
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () {
      //     // Navigate to search to add cards
      //     // TODO: Navigate to search with collection mode
      //   },
      //   heroTag: "collection_fab",
      //   icon: const Icon(Icons.add),
      //   label: Text('collection.add_cards'.tr()),
      // ),
    );
  }
}
