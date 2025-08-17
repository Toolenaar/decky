import 'package:flutter/material.dart';
import 'package:decky_core/providers/search_provider.dart';
import 'package:easy_localization/easy_localization.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final SearchProvider searchProvider;

  const SearchAppBar({super.key, required this.searchProvider});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text('search.title'.tr()),
      automaticallyImplyLeading: false,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          onSelected: (value) {
            final parts = value.split(':');
            searchProvider.applySortOrder(parts[0], parts[1]);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'name:asc', child: Text('search.sort.name_asc'.tr())),
            PopupMenuItem(value: 'name:desc', child: Text('search.sort.name_desc'.tr())),
            PopupMenuItem(value: 'mana_value:asc', child: Text('search.sort.mana_value_asc'.tr())),
            PopupMenuItem(value: 'mana_value:desc', child: Text('search.sort.mana_value_desc'.tr())),
            PopupMenuItem(value: '_score:desc', child: Text('search.sort.relevance'.tr())),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
