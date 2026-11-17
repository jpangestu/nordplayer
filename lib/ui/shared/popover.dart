import 'package:flutter/services.dart' show KeyDownEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:nordplayer/ui/shell/adaptive_surface.dart';

/// Preferred horizontal alignment of the popover relative to its anchor.
enum PopoverAlignment {
  /// Aligns the leading edge of the popover with the anchor's leading edge.
  /// Flips to [end] if crowded on the right.
  start,

  /// Centers the popover horizontally relative to the anchor widget.
  /// Falls back to [start] or [end] if too close to either screen boundary.
  center,

  /// Aligns the trailing edge of the popover with the anchor's trailing edge.
  /// Flips to [start] if crowded on the left.
  end,
}

/// A lightweight handle to programmatically open, close, or toggle a [Popover].
///
/// If no controller is provided to [Popover], an internal instance is automatically
/// created and forwarded to both the [Popover.anchorBuilder] and [Popover.popoverBuilder]
/// callbacks so children can dismiss the popover without extra boilerplate.
class PopoverController {
  _PopoverState? _state;

  PopoverController();

  void _attach(_PopoverState state) => _state = state;
  void _detach() => _state = null;

  /// Whether the popover is currently open or animating in.
  bool get isShowing => _state?._overlayPortalController.isShowing ?? false;

  /// Opens the popover.
  void show() => _state?._show();

  /// Closes the popover.
  void hide() => _state?._hide();

  /// Toggles between shown and hidden.
  void toggle() => _state?._toggle();
}

/// A popover widget anchored to [anchorWidget].
///
/// [Popover] renders floating content inside an [AdaptiveSurface] via Flutter's
/// root [OverlayPortal], linked to its anchor position with [LayerLink].
///
/// ### Basic Usage (Tap-to-Toggle):
/// Pass an [anchorWidget] and a [popoverBuilder] builder. The [anchorWidget] is
/// automatically wrapped to toggle the popover on tap:
/// ```dart
/// Popover(
///   anchorWidget: const IconButton(icon: Icon(Icons.more_vert), onPressed: null),
///   content: (context, controller) => Column(
///     mainAxisSize: MainAxisSize.min,
///     children: [
///       ListTile(
///         title: const Text('Add to Queue'),
///         onTap: () {
///           addToQueue();
///           controller.hide(); // Dismisses the popover
///         },
///       ),
///     ],
///   ),
/// )
/// ```
///
/// ### Advanced Trigger (Custom Styling / Gestures):
/// Use [anchorBuilder] when the anchor button needs access to [PopoverController]
/// (e.g. to highlight the button while open):
/// ```dart
/// Popover(
///   builder: (context, controller, child) => IconButton(
///     icon: const Icon(Icons.tune),
///     isSelected: controller.isShowing,
///     onPressed: controller.toggle,
///   ),
///   content: (context, controller) => const EqualizerPanel(),
/// )
/// ```
class const Popover({
  super.key,

  /// Optional external controller to programmatically open/close this popover.
  final PopoverController? controller,

  /// The anchor widget. If provided without a [anchorBuilder], tapping it automatically
  /// toggles the popover.
  ///
  /// Optimization tip: if the anchorWidget is an expensive widget, put it as parameter to
  /// anchorWidget so it only get instantiated once. If you only put it in anchorBuilder,
  /// it'll get reinstantiated every time popover update.
  final Widget? anchorWidget,

  /// Builder for dynamic triggers that need direct access to [PopoverController]
  /// (e.g. for active button highlighting or custom gestures).
  ///
  /// Optimization tip: if the anchorWidget is an expensive widget, put it as parameter to
  /// anchorWidget so it only get instantiated once. If you only put it in anchorBuilder,
  /// it'll get reinstantiated every time popover update.
  final Widget Function(BuildContext context, PopoverController controller, Widget? anchorWidget)?
  anchorBuilder,

  /// Preferred horizontal alignment relative to the anchor widget.
  /// Automatically adjusts to keep the popover within viewport bounds.
  final PopoverAlignment preferredAlignment = PopoverAlignment.start,

  /// Offset applied to the popover relative to the anchor point.
  /// When flipped above the target, the vertical offset is inverted automatically.
  final Offset offset = const Offset(0, 6),

  /// The corner radius of the popover's [AdaptiveSurface].
  final double cornerRadius = 8.0,

  /// Padding applied inside the popover's [AdaptiveSurface].
  final EdgeInsetsGeometry padding = const EdgeInsets.all(8.0),

  /// Whether to disable the entrance and exit animations.
  /// Defaults to `false` (animations enabled).
  final bool disableAnimation = false,

  /// Builds the floating popup content.
  /// Receives the [PopoverController] so actions inside can call `controller.hide()`.
  required final Widget Function(BuildContext context, PopoverController controller) popoverBuilder,
}) extends StatefulWidget {
  this
    : assert(
        anchorWidget != null || anchorBuilder != null,
        'Popover requires either an anchorWidget or a builder to serve as its trigger anchor.',
      );
  @override
  State<Popover> createState() => _PopoverState();
}

class _PopoverState extends State<Popover> with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  final OverlayPortalController _overlayPortalController = OverlayPortalController();

  // anchorWidget and popover should be wrapped in TapRegion and given the same group id.
  // This way, both are considered the same and will not trigger onTapOutside and the
  // [controller.toggle()] will not clash with TapRegion when set in anchor widget onTap.
  final Object _regionGroupId = Object();

  /// Is popover being shown
  bool _isShown = false;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 90),
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  late final Animation<double> _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
    CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ),
  );

  late PopoverController _popoverController;

  @override
  void initState() {
    super.initState();
    _popoverController = widget.controller ?? PopoverController();
    _popoverController._attach(this);
  }

  @override
  void didUpdateWidget(Popover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _popoverController._detach();
      }
      _popoverController = widget.controller ?? PopoverController();
      _popoverController._attach(this);
    }
  }

  @override
  void dispose() {
    _popoverController._detach();
    _animationController.dispose();
    super.dispose();
  }

  void _show() {
    if (_isShown) return;
    _isShown = true;

    _overlayPortalController.show();
    if (widget.disableAnimation) {
      _animationController.value = 1.0;
    } else {
      _animationController.forward(from: 0.0);
    }
  }

  void _hide() {
    if (!_isShown) return;
    _isShown = false;

    if (widget.disableAnimation) {
      _animationController.value = 0.0;
      _overlayPortalController.hide();
    } else {
      _animationController.reverse().then((_) {
        if (mounted && !_isShown) {
          _overlayPortalController.hide();
        }
      });
    }
  }

  void _toggle() {
    if (_isShown) {
      _hide();
    } else {
      _show();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget triggerWidget;

    if (widget.anchorBuilder != null) {
      triggerWidget = widget.anchorBuilder!(context, _popoverController, widget.anchorWidget);
    } else if (widget.anchorWidget != null) {
      triggerWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _popoverController.toggle,
        child: widget.anchorWidget!,
      );
    } else {
      triggerWidget = const SizedBox.shrink();
    }

    return OverlayPortal(
      controller: _overlayPortalController,
      overlayChildBuilder: (context) {
        final anchors = _resolveAnchors(context);

        final popover = AdaptiveSurface(
          elevation: SurfaceElevation.high,
          showShadow: true,
          cornerRadius: widget.cornerRadius,
          padding: widget.padding,
          child: widget.popoverBuilder(context, _popoverController),
        );

        return TapRegion(
          groupId: _regionGroupId,
          onTapOutside: (_) => _hide(),
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              // Esc to hide/dismiss the popover
              if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.escape) {
                _hide();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Stack(
              children: [
                CompositedTransformFollower(
                  link: _layerLink,
                  showWhenUnlinked: false,
                  targetAnchor: anchors.target,
                  followerAnchor: anchors.follower,
                  offset: anchors.offset,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: anchors.maxHeight),
                    child: widget.disableAnimation
                        ? popover
                        : FadeTransition(
                            opacity: _fade,
                            child: ScaleTransition(
                              scale: _scale,
                              alignment: anchors.follower,
                              child: popover,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: CompositedTransformTarget(
        link: _layerLink,
        child: TapRegion(groupId: _regionGroupId, child: triggerWidget),
      ),
    );
  }

  /// Calculates optimal alignment, offset, and max height to keep the popover on-screen.
  ///
  /// Inspects the anchor widget's global position and available viewport space:
  /// - **Vertical**: Drops below by default. Flips above if crowded below (< 220px)
  ///   and there's more room above.
  /// - **Horizontal**: Evaluates [widget.preferredAlignment] and automatically falls back
  ///   if crowded against the left or right edges of the screen (< 240px space).
  /// - **Max Height**: Clamps the height so the popover never extends off-screen.
  ({Alignment target, Alignment follower, Offset offset, double maxHeight}) _resolveAnchors(
    BuildContext overlayContext,
  ) {
    final screenSize = MediaQuery.sizeOf(overlayContext);

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) {
      return (
        target: Alignment.bottomLeft,
        follower: Alignment.topLeft,
        offset: widget.offset,
        maxHeight: screenSize.height - 32,
      );
    }

    final targetPos = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    final spaceBelow = screenSize.height - (targetPos.dy + targetSize.height);
    final spaceAbove = targetPos.dy;
    final spaceRight = screenSize.width - targetPos.dx;
    final spaceLeft = targetPos.dx + targetSize.width;
    final centerX = targetPos.dx + (targetSize.width / 2);

    // Flip to top if crowded below (< 220px) and there's more space above
    final bool showOnTop = spaceBelow < 220 && spaceAbove > spaceBelow;

    // Resolve horizontal alignment safely with edge fallback
    final PopoverAlignment resolvedHAlign = switch (widget.preferredAlignment) {
      PopoverAlignment.center => () {
        final spaceRightOfCenter = screenSize.width - centerX;
        final spaceLeftOfCenter = centerX;
        // If centered placement would overflow either screen border (< 120px on either side):
        if (spaceRightOfCenter < 120 && spaceLeft > spaceRight) {
          return PopoverAlignment.end;
        } else if (spaceLeftOfCenter < 120 && spaceRight > spaceLeft) {
          return PopoverAlignment.start;
        }
        return PopoverAlignment.center;
      }(),
      PopoverAlignment.start =>
        (spaceRight < 240 && spaceLeft > spaceRight)
            ? PopoverAlignment.end
            : PopoverAlignment.start,
      PopoverAlignment.end =>
        (spaceLeft < 240 && spaceRight > spaceLeft) ? PopoverAlignment.start : PopoverAlignment.end,
    };

    final autoTarget = switch ((showOnTop, resolvedHAlign)) {
      (true, PopoverAlignment.start) => Alignment.topLeft,
      (true, PopoverAlignment.center) => Alignment.topCenter,
      (true, PopoverAlignment.end) => Alignment.topRight,
      (false, PopoverAlignment.start) => Alignment.bottomLeft,
      (false, PopoverAlignment.center) => Alignment.bottomCenter,
      (false, PopoverAlignment.end) => Alignment.bottomRight,
    };

    final autoFollower = switch ((showOnTop, resolvedHAlign)) {
      (true, PopoverAlignment.start) => Alignment.bottomLeft,
      (true, PopoverAlignment.center) => Alignment.bottomCenter,
      (true, PopoverAlignment.end) => Alignment.bottomRight,
      (false, PopoverAlignment.start) => Alignment.topLeft,
      (false, PopoverAlignment.center) => Alignment.topCenter,
      (false, PopoverAlignment.end) => Alignment.topRight,
    };

    final double gap = widget.offset.dy != 0 ? widget.offset.dy.abs() : 6.0;
    final effectiveOffset = Offset(widget.offset.dx, showOnTop ? -gap : gap);
    final double availableHeight = (showOnTop ? spaceAbove : spaceBelow) - gap - 16;

    return (
      target: autoTarget,
      follower: autoFollower,
      offset: effectiveOffset,
      maxHeight: availableHeight.clamp(80.0, screenSize.height),
    );
  }
}
