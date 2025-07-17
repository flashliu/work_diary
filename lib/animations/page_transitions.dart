import 'package:flutter/material.dart';

/// 页面切换动画类型
enum PageTransitionType {
  fade,
  slide,
  scale,
  rotate,
  slideUp,
  slideDown,
  slideLeft,
  slideRight,
}

/// 自定义页面切换动画
class CustomPageTransition extends PageRouteBuilder {
  final Widget child;
  final PageTransitionType transitionType;
  final Duration duration;
  final Curve curve;

  CustomPageTransition({
    required this.child,
    this.transitionType = PageTransitionType.slide,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    super.barrierDismissible = true,
    super.barrierColor,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration,
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    switch (transitionType) {
      case PageTransitionType.fade:
        return FadeTransition(opacity: animation, child: child);
      case PageTransitionType.slide:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case PageTransitionType.scale:
        return ScaleTransition(scale: animation, child: child);
      case PageTransitionType.rotate:
        return RotationTransition(turns: animation, child: child);
      case PageTransitionType.slideUp:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case PageTransitionType.slideDown:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -1.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case PageTransitionType.slideLeft:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
      case PageTransitionType.slideRight:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: curve)),
          child: child,
        );
    }
  }
}

/// 页面切换动画扩展
extension PageTransitionExtension on Widget {
  /// 使用淡入动画
  PageRouteBuilder fadeTransition({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomPageTransition(
      child: this,
      transitionType: PageTransitionType.fade,
      duration: duration,
      curve: curve,
    );
  }

  /// 使用滑动动画
  PageRouteBuilder slideTransition({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomPageTransition(
      child: this,
      transitionType: PageTransitionType.slide,
      duration: duration,
      curve: curve,
    );
  }

  /// 使用缩放动画
  PageRouteBuilder scaleTransition({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomPageTransition(
      child: this,
      transitionType: PageTransitionType.scale,
      duration: duration,
      curve: curve,
    );
  }

  /// 使用向上滑动动画
  PageRouteBuilder slideUpTransition({
    Duration duration = const Duration(milliseconds: 300),
    Curve curve = Curves.easeInOut,
  }) {
    return CustomPageTransition(
      child: this,
      transitionType: PageTransitionType.slideUp,
      duration: duration,
      curve: curve,
    );
  }
}

/// 弹出动画
class PopupAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final bool autoStart;

  const PopupAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.elasticOut,
    this.autoStart = true,
  });

  @override
  State<PopupAnimation> createState() => _PopupAnimationState();
}

class _PopupAnimationState extends State<PopupAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.autoStart) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void start() {
    _controller.forward();
  }

  void reverse() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(opacity: _opacityAnimation.value, child: widget.child),
        );
      },
    );
  }
}

/// 波纹展开动画
class RippleAnimation extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final double radius;
  final Color color;
  final VoidCallback? onTap;

  const RippleAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600),
    this.radius = 100.0,
    this.color = Colors.blue,
    this.onTap,
  });

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _radiusAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _radiusAnimation = Tween<double>(
      begin: 0.0,
      end: widget.radius,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.8,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _startAnimation();
        widget.onTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          widget.child,
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(
                      alpha: _opacityAnimation.value,
                    ),
                  ),
                  width: _radiusAnimation.value * 2,
                  height: _radiusAnimation.value * 2,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
