import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:decky_core/model/mtg/mtg_sealed_product.dart';
import '../../controllers/sealed_product_controller.dart';
import '../../widgets/paginated_list_view.dart';
import '../dashboard/side_menu.dart';

class SealedProductsListScreen extends StatefulWidget {
  const SealedProductsListScreen({super.key});

  @override
  State<SealedProductsListScreen> createState() => _SealedProductsListScreenState();
}

class _SealedProductsListScreenState extends State<SealedProductsListScreen> {
  final SealedProductController _controller = GetIt.instance<SealedProductController>();

  @override
  Widget build(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sealed Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      drawer: SideMenu(currentPath: currentLocation),
      body: PaginatedListView<MtgSealedProduct>(
        itemsStream: _controller.productsStream,
        loadingStream: _controller.loadingStream,
        hasMoreStream: _controller.hasMoreStream,
        errorStream: _controller.errorStream,
        onLoadMore: _controller.loadMoreProducts,
        emptyMessage: 'No sealed products available',
        itemBuilder: (context, product) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.orange,
              child: Icon(Icons.inventory_2, color: Colors.white),
            ),
            title: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set: ${product.setCode.toUpperCase()}'),
                if (product.category != null)
                  Text('Category: ${product.category}'),
                if (product.cardCount != null)
                  Text('Cards: ${product.cardCount}'),
              ],
            ),
            isThreeLine: true,
          ),
        ),
      ),
    );
  }
}