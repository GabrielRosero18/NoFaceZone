import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:nofacezone/src/Custom/PlatformUI.dart';

class ProEntrance extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;

  const ProEntrance({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 500),
    this.beginOffset = const Offset(0, 0.04),
    this.beginScale = 0.985,
  });

  @override
  State<ProEntrance> createState() => _ProEntranceState();
}

class _ProEntranceState extends State<ProEntrance> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }

    return AnimatedOpacity(
      duration: widget.duration,
      curve: Curves.easeOutCubic,
      opacity: _visible ? 1 : 0,
      child: AnimatedSlide(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : widget.beginOffset,
        child: TweenAnimationBuilder<double>(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          tween: Tween<double>(begin: widget.beginScale, end: _visible ? 1 : widget.beginScale),
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

class ProPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double pressedScale;
  final Curve curve;
  final bool enableHover;
  final double hoverScale;
  final MouseCursor? mouseCursor;

  const ProPressable({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 120),
    this.pressedScale = 0.98,
    this.curve = Curves.easeOutCubic,
    this.enableHover = true,
    this.hoverScale = 1.012,
    this.mouseCursor,
  });

  @override
  State<ProPressable> createState() => _ProPressableState();
}

class _ProPressableState extends State<ProPressable> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }

    final canHover = kIsWeb && widget.enableHover;
    final baseScale = _pressed
        ? widget.pressedScale
        : ((canHover && _hovered) ? widget.hoverScale : 1.0);

    return MouseRegion(
      cursor: widget.mouseCursor ??
          (widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer),
      onEnter: canHover ? (_) => setState(() => _hovered = true) : null,
      onExit: canHover ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: widget.duration,
          curve: widget.curve,
          scale: baseScale,
          child: widget.child,
        ),
      ),
    );
  }
}

class ProHoverCard extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double hoverLift;
  final double hoverScale;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? baseShadow;
  final List<BoxShadow>? hoverShadow;

  const ProHoverCard({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 180),
    this.hoverLift = WebMotionTokens.hoverLiftMedium,
    this.hoverScale = WebMotionTokens.hoverScaleSoft,
    this.borderRadius,
    this.baseShadow,
    this.hoverShadow,
  });

  @override
  State<ProHoverCard> createState() => _ProHoverCardState();
}

class _ProHoverCardState extends State<ProHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final canHover = kIsWeb && !MediaQuery.disableAnimationsOf(context);
    final base = widget.baseShadow ?? const <BoxShadow>[];
    final hover = widget.hoverShadow ?? WebMotionTokens.hoverShadowSoft;

    return MouseRegion(
      onEnter: canHover ? (_) => setState(() => _hovered = true) : null,
      onExit: canHover ? (_) => setState(() => _hovered = false) : null,
      child: AnimatedContainer(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..translateByDouble(0.0, (canHover && _hovered) ? -widget.hoverLift : 0.0, 0.0, 1.0)
          ..scaleByDouble(
            (canHover && _hovered) ? widget.hoverScale : 1.0,
            (canHover && _hovered) ? widget.hoverScale : 1.0,
            1.0,
            1.0,
          ),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(18),
          boxShadow: (canHover && _hovered) ? hover : base,
        ),
        child: widget.child,
      ),
    );
  }
}

class ProScrollReveal extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final Duration duration;
  final Offset beginOffset;
  final double beginScale;
  final bool revealOnce;

  const ProScrollReveal({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 480),
    this.beginOffset = const Offset(0, 0.05),
    this.beginScale = 0.985,
    this.revealOnce = true,
  });

  @override
  State<ProScrollReveal> createState() => _ProScrollRevealState();
}

class _ProScrollRevealState extends State<ProScrollReveal> {
  final GlobalKey _childKey = GlobalKey();
  ScrollPosition? _scrollPosition;
  bool _visible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (_scrollPosition != nextPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = nextPosition;
      _scrollPosition?.addListener(_onScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    if (widget.revealOnce && _visible) return;
    _checkVisibility();
  }

  void _checkVisibility() {
    final childContext = _childKey.currentContext;
    if (childContext == null) return;
    final renderBox = childContext.findRenderObject();
    if (renderBox is! RenderBox || !renderBox.hasSize) return;

    final viewportHeight = MediaQuery.of(context).size.height;
    final topLeft = renderBox.localToGlobal(Offset.zero);
    final top = topLeft.dy;
    final bottom = top + renderBox.size.height;
    final thresholdTop = viewportHeight * 0.92;
    final thresholdBottom = viewportHeight * 0.08;
    final isInViewport = top < thresholdTop && bottom > thresholdBottom;

    if (isInViewport && !_visible) {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (!mounted) return;
        setState(() => _visible = true);
      });
      return;
    }

    if (!widget.revealOnce && !isInViewport && _visible) {
      setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return KeyedSubtree(key: _childKey, child: widget.child);
    }

    return KeyedSubtree(
      key: _childKey,
      child: AnimatedOpacity(
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        opacity: _visible ? 1 : 0,
        child: AnimatedSlide(
          duration: widget.duration,
          curve: Curves.easeOutCubic,
          offset: _visible ? Offset.zero : widget.beginOffset,
          child: TweenAnimationBuilder<double>(
            duration: widget.duration,
            curve: Curves.easeOutCubic,
            tween: Tween<double>(begin: widget.beginScale, end: _visible ? 1 : widget.beginScale),
            builder: (context, value, child) => Transform.scale(scale: value, child: child),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

