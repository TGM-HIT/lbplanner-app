part of lbplanner_widgets;

/// Wrapper that inserts the given [popupBuilder] into the stack.
class LpPopup extends StatefulWidget {
  /// Wrapper that inserts the given [popupBuilder] into the stack.
  const LpPopup({
    Key? key,
    required this.popupBuilder,
    required this.child,
    this.backgroundDismissable = true,
    this.animationDuration = kSlowAnimationDuration,
    this.animationCurve = kAnimationCurve,
    this.backgroundColor = Colors.transparent,
    this.offset = Offset.zero,
    this.cursor = SystemMouseCursors.click,
    this.onHide,
    this.onShow,
    this.hoverChild,
  }) : super(key: key);

  /// Builds the popup to insert.
  final PopupBuilder popupBuilder;

  /// The cursor to show when [child] is hovered.
  final MouseCursor cursor;

  /// The offset of the popup.
  final Offset offset;

  /// The child to wrap.
  final Widget child;

  /// The duration of the popup animation.
  final Duration animationDuration;

  /// The curve of the popup animation.
  final Curve animationCurve;

  /// Whether the popup can be dismissed by tapping the background.
  final bool backgroundDismissable;

  /// The background color of the popup.
  final Color backgroundColor;

  /// Called when the popup is dismissed.
  final VoidCallback? onHide;

  /// Called when the popup is shown.
  final VoidCallback? onShow;

  /// The child that is displayd whihle hovering over [chiild].
  final Widget? hoverChild;

  @override
  State<LpPopup> createState() => _LpPopupState();
}

class _LpPopupState extends State<LpPopup> with WindowListener, RouteAware {
  OverlayEntry? _popup;
  OverlayEntry? _dissmissArea;
  final GlobalKey _key = GlobalKey();
  bool _isShowing = false;

  void close() {
    if (!_isShowing) return;

    _popup?.remove();
    _popup = null;

    _dissmissArea?.remove();
    _dissmissArea = null;
    _isShowing = false;

    if (mounted) widget.onHide?.call();
  }

  void show() {
    if (_isShowing) return;

    _isShowing = true;

    var screen = MediaQuery.of(context).size;
    _popup = OverlayEntry(
      builder: (context) {
        RenderBox box = _key.currentContext!.findRenderObject() as RenderBox;
        Offset position = box.localToGlobal(Offset.zero);

        return _PopupAnimator(
          triggerHeight: box.size.height,
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          right: screen.width - position.dx - box.size.width + widget.offset.dx,
          top: position.dy + widget.offset.dy,
          child: widget.popupBuilder(context, close),
        );
      },
    );

    if (widget.backgroundDismissable) {
      _dissmissArea = OverlayEntry(
        builder: (context) => GestureDetector(
          onTap: close,
          child: Container(
            color: widget.backgroundColor,
            width: screen.width,
            height: screen.height,
          ),
        ),
      );

      Overlay.of(context)!.insert(_dissmissArea!);
    }

    Overlay.of(context)!.insert(_popup!);

    widget.onShow?.call();
  }

  @override
  void dispose() {
    close();
    windowManager.removeListener(this);
    kRouteObserver.unsubscribe(this);

    super.dispose();
  }

  @override
  void didPop() {
    close();
  }

  @override
  didPopNext() {
    close();
  }

  @override
  void onWindowResized() {
    close();

    super.onWindowResized();
  }

  @override
  void onWindowMaximize() {
    close();

    super.onWindowMaximize();
  }

  @override
  void onWindowUnmaximize() {
    close();

    super.onWindowUnmaximize();
  }

  @override
  initState() {
    windowManager.addListener(this);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) kRouteObserver.subscribe(this, ModalRoute.of(context)!);
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.cursor,
      child: Listener(
        key: _key,
        onPointerDown: (event) => show(),
        child: HoverBuilder(
          builder: (context, hovering) => hovering && widget.hoverChild != null && !_isShowing ? widget.hoverChild! : widget.child,
        ),
      ),
    );
  }
}

class _PopupAnimator extends StatefulWidget {
  const _PopupAnimator({Key? key, required this.child, required this.duration, required this.curve, required this.right, required this.top, required this.triggerHeight}) : super(key: key);

  final Widget child;

  final Duration duration;

  final Curve curve;

  final double right;

  final double top;

  final double triggerHeight;

  @override
  State<_PopupAnimator> createState() => __PopupAnimatorState();
}

class __PopupAnimatorState extends State<_PopupAnimator> with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      _controller = AnimationController(duration: widget.duration, vsync: this);
      _controller!.forward();
    }

    return AnimatedBuilder(
      animation: _controller!,
      child: widget.child,
      builder: (context, child) {
        var value = Tween(begin: (widget.top - widget.triggerHeight) / widget.top, end: 1.0).animate(CurvedAnimation(parent: _controller!, curve: widget.curve)).value;

        return Positioned(
          right: widget.right,
          top: widget.top * value,
          child: Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child!,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

/// Builds the popup to insert.
typedef PopupBuilder = Widget Function(BuildContext context, VoidCallback hide);
