import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 加载动画类型
enum LoadingType { circular, dots, wave, pulse, bounce, fade, gradient }

/// 通用加载动画组件
class LoadingAnimation extends StatefulWidget {
  final LoadingType type;
  final Color? color;
  final double size;
  final Duration duration;
  final String? text;
  final TextStyle? textStyle;

  const LoadingAnimation({
    super.key,
    this.type = LoadingType.circular,
    this.color,
    this.size = 40.0,
    this.duration = const Duration(milliseconds: 1000),
    this.text,
    this.textStyle,
  });

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: _buildLoadingWidget(color),
        ),
        if (widget.text != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.text!,
            style:
                widget.textStyle ??
                TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingWidget(Color color) {
    switch (widget.type) {
      case LoadingType.circular:
        return _buildCircularLoading(color);
      case LoadingType.dots:
        return _buildDotsLoading(color);
      case LoadingType.wave:
        return _buildWaveLoading(color);
      case LoadingType.pulse:
        return _buildPulseLoading(color);
      case LoadingType.bounce:
        return _buildBounceLoading(color);
      case LoadingType.fade:
        return _buildFadeLoading(color);
      case LoadingType.gradient:
        return _buildGradientLoading();
    }
  }

  Widget _buildCircularLoading(Color color) {
    return CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(color),
      strokeWidth: 3.0,
    );
  }

  Widget _buildDotsLoading(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final animValue = (_animation.value - (index * 0.1)) % 1.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: animValue),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildWaveLoading(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final animValue = (_animation.value - (index * 0.1)) % 1.0;
            final height = 4 + (animValue * 16);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildPulseLoading(Color color) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 0.5 + (_animation.value * 0.5);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 1.0 - _animation.value),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildBounceLoading(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final animValue = (_animation.value - (index * 0.2)) % 1.0;
            final bounceValue = (animValue < 0.5)
                ? animValue * 2
                : 2 - (animValue * 2);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.translate(
                offset: Offset(0, -bounceValue * 10),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildFadeLoading(Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(8, (index) {
        final angle = (index * 45.0) * (3.14159 / 180.0);
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final animValue = (_animation.value - (index * 0.125)) % 1.0;
            return Transform.rotate(
              angle: angle,
              child: Container(
                width: 2,
                height: 8,
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: animValue),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildGradientLoading() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              startAngle: _animation.value * 2 * 3.14159,
              endAngle: (_animation.value * 2 * 3.14159) + (3.14159 / 2),
              colors: [Colors.transparent, AppColors.primary],
            ),
          ),
        );
      },
    );
  }
}

/// 骨架屏动画组件
class SkeletonAnimation extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  const SkeletonAnimation({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1000),
  });

  @override
  State<SkeletonAnimation> createState() => _SkeletonAnimationState();
}

class _SkeletonAnimationState extends State<SkeletonAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: -1.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isLoading) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(SkeletonAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _controller.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    final baseColor = widget.baseColor ?? Colors.grey[300]!;
    final highlightColor = widget.highlightColor ?? Colors.grey[100]!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, baseColor],
              stops: [0.0, 0.5, 1.0],
              transform: GradientRotation(_animation.value * 3.14159),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// 刷新动画组件
class RefreshAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onRefresh;
  final bool isRefreshing;
  final Color? color;

  const RefreshAnimation({
    super.key,
    required this.child,
    this.onRefresh,
    this.isRefreshing = false,
    this.color,
  });

  @override
  State<RefreshAnimation> createState() => _RefreshAnimationState();
}

class _RefreshAnimationState extends State<RefreshAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));

    if (widget.isRefreshing) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(RefreshAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRefreshing && !oldWidget.isRefreshing) {
      _controller.repeat();
    } else if (!widget.isRefreshing && oldWidget.isRefreshing) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onRefresh,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// 进度条动画组件
class ProgressAnimation extends StatefulWidget {
  final double progress;
  final Duration duration;
  final Color? color;
  final Color? backgroundColor;
  final double height;
  final BorderRadius? borderRadius;

  const ProgressAnimation({
    super.key,
    required this.progress,
    this.duration = const Duration(milliseconds: 300),
    this.color,
    this.backgroundColor,
    this.height = 4.0,
    this.borderRadius,
  });

  @override
  State<ProgressAnimation> createState() => _ProgressAnimationState();
}

class _ProgressAnimationState extends State<ProgressAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.forward();
  }

  @override
  void didUpdateWidget(ProgressAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress != oldWidget.progress) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? AppColors.primary;
    final backgroundColor = widget.backgroundColor ?? AppColors.surfaceVariant;
    final borderRadius =
        widget.borderRadius ?? BorderRadius.circular(widget.height / 2);

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _animation.value,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius,
              ),
            ),
          );
        },
      ),
    );
  }
}
