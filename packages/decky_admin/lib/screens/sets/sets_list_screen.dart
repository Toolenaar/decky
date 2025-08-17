import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_set.dart';
import '../../controllers/set_controller.dart';
import '../../widgets/paginated_list_view.dart';
import '../dashboard/side_menu.dart';

class SetsListScreen extends StatefulWidget {
  const SetsListScreen({super.key});

  @override
  State<SetsListScreen> createState() => _SetsListScreenState();
}

class _SetsListScreenState extends State<SetsListScreen> {
  final SetController _controller = GetIt.instance<SetController>();

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: SideMenu(currentPath: currentLocation),
      body: PaginatedListView<MtgSet>(
        itemsStream: _controller.setsStream,
        loadingStream: _controller.loadingStream,
        hasMoreStream: _controller.hasMoreStream,
        errorStream: _controller.errorStream,
        onLoadMore: _controller.loadMoreSets,
        emptyMessage: 'No sets available',
        itemBuilder: (context, set) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.purple,
              child: Icon(Icons.collections, color: Colors.white),
            ),
            title: Text(
              set.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Code: ${set.code.toUpperCase()}'),
                Text('Type: ${set.type}'),
                Text('Release Date: ${set.releaseDate}'),
                Text('Cards: ${set.cardCount}'),
              ],
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }
}