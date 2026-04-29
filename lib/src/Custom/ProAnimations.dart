import 'package:flutter/material.dart';

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

  const ProPressable({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 120),
    this.pressedScale = 0.98,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<ProPressable> createState() => _ProPressableState();
}

class _ProPressableState extends State<ProPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return GestureDetector(onTap: widget.onTap, child: widget.child);
    }

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: widget.duration,
        curve: widget.curve,
        scale: _pressed ? widget.pressedScale : 1,
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

