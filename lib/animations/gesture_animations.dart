import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 可点击的动画容器
class AnimatedTapContainer extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;
  final double scaleValue;
  final Color? highlightColor;
  final BorderRadius? borderRadius;

  const AnimatedTapContainer({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 150),
    this.scaleValue = 0.95,
    this.highlightColor,
    this.borderRadius,
  });

  @override
  State<AnimatedTapContainer> createState() => _AnimatedTapContainerState();
}

class _AnimatedTapContainerState extends State<AnimatedTapContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleValue,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.highlightColor ?? AppColors.primary.withValues(alpha: 0.1),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: _colorAnimation.value,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// 滑动删除组件
class SwipeToDeleteAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDelete;
  final Color? backgroundColor;
  final IconData icon;
  final Color? iconColor;
  final double threshold;

  const SwipeToDeleteAnimation({
    super.key,
    required this.child,
    this.onDelete,
    this.backgroundColor,
    this.icon = Icons.delete,
    this.iconColor,
    this.threshold = 0.4,
  });

  @override
  State<SwipeToDeleteAnimation> createState() => _SwipeToDeleteAnimationState();
}

class _SwipeToDeleteAnimationState extends State<SwipeToDeleteAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-1.0, 0.0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final progress = details.primaryDelta! / screenWidth;

    if (progress < 0) {
      _controller.value = (_controller.value - progress).clamp(0.0, 1.0);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_controller.value > widget.threshold) {
      _controller.forward().then((_) {
        widget.onDelete?.call();
      });
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: [
          // 背景删除区域
          Container(
            decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.red,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Icon(
                    widget.icon,
                    color: widget.iconColor ?? Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          // 前景内容
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.translate(
                offset: _offsetAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: widget.child,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// 拖拽排序动画组件
class DragReorderAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;
  final ValueChanged<Offset>? onDragUpdate;

  const DragReorderAnimation({
    super.key,
    required this.child,
    this.onDragStart,
    this.onDragEnd,
    this.onDragUpdate,
  });

  @override
  State<DragReorderAnimation> createState() => _DragReorderAnimationState();
}

class _DragReorderAnimationState extends State<DragReorderAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _shadowAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.forward();
    widget.onDragStart?.call();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    widget.onDragUpdate?.call(details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    _controller.reverse();
    widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: _shadowAnimation.value,
                    offset: const Offset(0, 2),
                  ),
                ],
                borderRadius: BorderRadius.circular(8),
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}

/// 长按菜单动画组件
class LongPressMenuAnimation extends StatefulWidget {
  final Widget child;
  final List<Widget> menuItems;
  final Duration duration;

  const LongPressMenuAnimation({
    super.key,
    required this.child,
    required this.menuItems,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<LongPressMenuAnimation> createState() => _LongPressMenuAnimationState();
}

class _LongPressMenuAnimationState extends State<LongPressMenuAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  bool _isMenuVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onLongPress() {
    setState(() {
      _isMenuVisible = true;
    });
    _controller.forward();
  }

  void _hideMenu() {
    _controller.reverse().then((_) {
      setState(() {
        _isMenuVisible = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _onLongPress,
      onTap: _isMenuVisible ? _hideMenu : null,
      child: Stack(
        children: [
          widget.child,
          if (_isMenuVisible)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: widget.menuItems,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// 双击缩放动画组件
class DoubleTapZoomAnimation extends StatefulWidget {
  final Widget child;
  final double maxScale;
  final Duration duration;

  const DoubleTapZoomAnimation({
    super.key,
    required this.child,
    this.maxScale = 2.0,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<DoubleTapZoomAnimation> createState() => _DoubleTapZoomAnimationState();
}

class _DoubleTapZoomAnimationState extends State<DoubleTapZoomAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.maxScale,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
    setState(() {
      _isZoomed = !_isZoomed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 悬浮动画组件
class HoverAnimation extends StatefulWidget {
  final Widget child;
  final double scale;
  final Duration duration;
  final Curve curve;

  const HoverAnimation({
    super.key,
    required this.child,
    this.scale = 1.05,
    this.duration = const Duration(milliseconds: 200),
    this.curve = Curves.easeInOut,
  });

  @override
  State<HoverAnimation> createState() => _HoverAnimationState();
}

class _HoverAnimationState extends State<HoverAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scale,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.curve));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() {
    _controller.forward();
  }

  void _onExit() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}
