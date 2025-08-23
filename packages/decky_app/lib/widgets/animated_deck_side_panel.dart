import 'package:flutter/material.dart';
import 'package:decky_core/model/user_deck.dart';
import 'package:decky_core/model/deck_card.dart';
import 'package:decky_core/controller/user_decks_controller.dart';
import 'deck_card_side_panel.dart';

class AnimatedDeckSidePanel extends StatefulWidget {
  final UserDeck deck;
  final UserDecksController decksController;
  final void Function(DeckCard) onCardTap;
  final DeckCard? selectedCard;
  final VoidCallback? onCardBack;
  final bool initiallyVisible;
  final Widget child;

  const AnimatedDeckSidePanel({
    super.key,
    required this.deck,
    required this.decksController,
    required this.onCardTap,
    this.selectedCard,
    this.onCardBack,
    required this.child,
    this.initiallyVisible = true,
  });

  @override
  State<AnimatedDeckSidePanel> createState() => _AnimatedDeckSidePanelState();
}

class _AnimatedDeckSidePanelState extends State<AnimatedDeckSidePanel> with SingleTickerProviderStateMixin {
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
    setState(() {
      _isVisible = !_isVisible;
    });

    if (_isVisible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
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
                heroTag: "mobile_side_panel_fab",
                backgroundColor: theme.colorScheme.primaryContainer,
                foregroundColor: theme.colorScheme.onPrimaryContainer,
                child: const Icon(Icons.view_sidebar),
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
                        child: _slideAnimation.value > 0.1 ? _buildPanelContent() : const SizedBox.shrink(),
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
                    heroTag: "side_panel_fab",
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                    child: const Icon(Icons.view_sidebar),
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
                    widget.selectedCard?.mtgCardReference.name ?? 'Deck Cards',
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
            child: DeckCardSidePanel(
              deck: widget.deck,
              decksController: widget.decksController,
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
