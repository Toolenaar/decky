import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_token.dart';
import '../../controllers/token_controller.dart';
import '../../widgets/paginated_list_view.dart';
import '../dashboard/side_menu.dart';

class TokensListScreen extends StatefulWidget {
  const TokensListScreen({super.key});

  @override
  State<TokensListScreen> createState() => _TokensListScreenState();
}

class _TokensListScreenState extends State<TokensListScreen> {
  final TokenController _controller = GetIt.instance<TokenController>();

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tokens'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: SideMenu(currentPath: currentLocation),
      body: PaginatedListView<MtgToken>(
        itemsStream: _controller.tokensStream,
        loadingStream: _controller.loadingStream,
        hasMoreStream: _controller.hasMoreStream,
        errorStream: _controller.errorStream,
        onLoadMore: _controller.loadMoreTokens,
        emptyMessage: 'No tokens available',
        itemBuilder: (context, token) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.red,
              child: Icon(Icons.token, color: Colors.white),
            ),
            title: Text(
              token.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${token.type}'),
                Text('Set: ${token.setCode.toUpperCase()}'),
                if (token.power != null && token.toughness != null)
                  Text('P/T: ${token.power}/${token.toughness}'),
              ],
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }
}