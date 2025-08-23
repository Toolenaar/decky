import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class CollectionView extends StatelessWidget {
  const CollectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('collection.title'.tr()),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Filter collection
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.collections, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('collection.empty_state.title'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 32),
            Text('collection.empty_state.subtitle'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open camera to scan cards
        },
        heroTag: "collection_fab",
        icon: const Icon(Icons.camera_alt),
        label: Text('collection.scan_cards'.tr()),
      ),
    );
  }
}
