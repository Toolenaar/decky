import 'package:flutter/material.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class EmptySearchState extends StatelessWidget {
  final SearchProvider searchProvider;

  const EmptySearchState({super.key, required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    if (searchProvider.query.isEmpty && !searchProvider.hasActiveFilters) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('search.empty_state.title'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'search.empty_state.subtitle'.tr(),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('search.no_results.title'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          Text('search.no_results.subtitle'.tr(), style: const TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: searchProvider.clearFilters, child: Text('search.no_results.clear_filters'.tr())),
        ],
      ),
    );
  }
}
