import 'package:flutter/material.dart';

class PaginatedListView<T> extends StatefulWidget {
  final Stream<List<T>> itemsStream;
  final Stream<bool> loadingStream;
  final Stream<bool> hasMoreStream;
  final Stream<String?> errorStream;
  final Future<void> Function() onLoadMore;
  final Widget Function(BuildContext, T) itemBuilder;
  final Widget Function(BuildContext)? emptyBuilder;
  final Widget Function(BuildContext, String)? errorBuilder;
  final Widget Function(T) Function(BuildContext)? itemActionBuilder;
  final String emptyMessage;

  const PaginatedListView({
    super.key,
    required this.itemsStream,
    required this.loadingStream,
    required this.hasMoreStream,
    required this.errorStream,
    required this.onLoadMore,
    required this.itemBuilder,
    this.emptyBuilder,
    this.errorBuilder,
    this.itemActionBuilder,
    this.emptyMessage = 'No items found',
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    try {
      await widget.onLoadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: widget.errorStream,
      builder: (context, errorSnapshot) {
        if (errorSnapshot.hasData && errorSnapshot.data != null) {
          return widget.errorBuilder?.call(context, errorSnapshot.data!) ??
              _buildDefaultError(errorSnapshot.data!);
        }

        return StreamBuilder<List<T>>(
          stream: widget.itemsStream,
          builder: (context, itemsSnapshot) {
            return StreamBuilder<bool>(
              stream: widget.loadingStream,
              builder: (context, loadingSnapshot) {
                final isLoading = loadingSnapshot.data ?? false;
                final items = itemsSnapshot.data ?? [];

                if (items.isEmpty && isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (items.isEmpty && !isLoading) {
                  return widget.emptyBuilder?.call(context) ??
                      _buildDefaultEmpty();
                }

                return StreamBuilder<bool>(
                  stream: widget.hasMoreStream,
                  builder: (context, hasMoreSnapshot) {
                    final hasMore = hasMoreSnapshot.data ?? false;

                    return RefreshIndicator(
                      onRefresh: widget.onLoadMore,
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: items.length + (hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index >= items.length) {
                            return _buildLoadingIndicator();
                          }

                          final item = items[index];
                          final child = widget.itemBuilder(context, item);
                          
                          if (widget.itemActionBuilder != null) {
                            return Dismissible(
                              key: ValueKey(index),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                ),
                              ),
                              child: child,
                              onDismissed: (direction) {
                                final action = widget.itemActionBuilder!(context)(item);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: action),
                                );
                              },
                            );
                          }
                          
                          return child;
                        },
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyMessage,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultError(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading data',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.onLoadMore,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}