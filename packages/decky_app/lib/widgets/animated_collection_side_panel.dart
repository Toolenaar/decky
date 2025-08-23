import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:decky_core/model/collection_card.dart';
import 'package:decky_core/controller/user_collection_controller.dart';
import 'collection_card_side_panel.dart';

class AnimatedCollectionSidePanel extends StatefulWidget {
  final UserCollectionController collectionController;
  final void Function(CollectionCard) onCardTap;
  final CollectionCard? selectedCard;
  final VoidCallback? onCardBack;
  final bool initiallyVisible;
  final Widget child;

  const AnimatedCollectionSidePanel({
    super.key,
    required this.collectionController,
    required this.onCardTap,
    this.selectedCard,
    this.onCardBack,
    required this.child,
    this.initiallyVisible = false,
  });

  @override
  State<AnimatedCollectionSidePanel> createState() => _AnimatedCollectionSidePanelState();
}

class _AnimatedCollectionSidePanelState extends State<AnimatedCollectionSidePanel> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late bool _isVisible;

  final double _panelWidth = 320;

  @override
  void initState() {
    super.initState();
    _isVisible = widget.initiallyVisible;

    _animationController = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    if (_isVisible) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_isVisible) {
      // Closing: reverse animation first, then hide
      _animationController.reverse().then((_) {
        setState(() {
          _isVisible = false;
        });
      });
    } else {
      // Opening: show first, then animate
      setState(() {
        _isVisible = true;
      });
      _animationController.forward();
    }
  }

  bool _isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 768;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = _isMobile(context);
    final theme = Theme.of(context);

    if (isMobile) {
      // Mobile: Stack with overlay
      return Stack(
        children: [
          // Main content
          widget.child,

          // Mobile drawer overlay
          if (_isVisible)
            AnimatedBuilder(
              animation: _slideAnimation,
              builder: (context, child) {
                return Stack(
                  children: [
                    // Semi-transparent overlay
                    GestureDetector(
                      onTap: _togglePanel,
                      child: Container(color: Colors.black.withValues(alpha: 0.3 * _slideAnimation.value)),
                    ),
                    // Sliding panel from right
                    Positioned(
                      top: 0,
                      bottom: 0,
                      right: -300 + (300 * _slideAnimation.value),
                      child: SizedBox(width: 300, child: _buildPanelContent()),
                    ),
                  ],
                );
              },
            ),

          // Mobile toggle button when closed
          if (!_isVisible)
            Positioned(
              top: 16,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: _togglePanel,
                heroTag: "mobile_collection_panel_fab",
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.list),
              ),
            ),
        ],
      );
    } else {
      // Desktop: Row layout
      return AnimatedBuilder(
        animation: _slideAnimation,
        builder: (context, child) {
          return Stack(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main content
                  Expanded(child: widget.child),

                  // Side panel
                  if (_isVisible)
                    Transform.translate(
                      offset: Offset(_panelWidth * (1 - _slideAnimation.value), 0),
                      child: SizedBox(
                        width: _panelWidth * _slideAnimation.value,
                        child: _slideAnimation.value > 0.8 ? _buildPanelContent() : const SizedBox.shrink(),
                      ),
                    ),
                ],
              ),

              // Desktop floating toggle button when panel is closed
              if (!_isVisible)
                Positioned(
                  top: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    onPressed: _togglePanel,
                    heroTag: "collection_panel_fab",
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.list),
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  Widget _buildPanelContent() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(left: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
        boxShadow: _isMobile(context)
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(-2, 0))]
            : [],
      ),
      child: Column(
        children: [
          // Panel header with close button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 0.5)),
            ),
            child: Row(
              children: [
                // Show back button if card is selected, otherwise no leading button
                if (widget.selectedCard != null) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back, size: 20),
                    onPressed: widget.onCardBack,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    widget.selectedCard?.mtgCardReference.name ?? 'collection.title'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Show close button only if no card is selected
                if (widget.selectedCard == null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _togglePanel,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          // Panel content
          Expanded(
            child: CollectionCardSidePanel(
              collectionController: widget.collectionController,
              onCardTap: widget.onCardTap,
              selectedCard: widget.selectedCard,
              onCardBack: widget.onCardBack,
            ),
          ),
        ],
      ),
    );
  }
}