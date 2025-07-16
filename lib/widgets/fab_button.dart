import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// 浮动添加按钮组件
/// 具有渐变背景的圆形浮动按钮
class FabButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? heroTag;
  final double? size;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const FabButton({
    super.key,
    this.onPressed,
    this.icon = Icons.add,
    this.heroTag,
    this.size,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<FabButton> createState() => _FabButtonState();
}

class _FabButtonState extends State<FabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _shadowAnimation = Tween<double>(begin: 4.0, end: 8.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size ?? 56.0;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                  blurRadius: _shadowAnimation.value,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(size / 2),
                child: Icon(
                  widget.icon,
                  color: widget.foregroundColor ?? Colors.white,
                  size: size * 0.4,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 扩展浮动按钮
/// 支持展开多个子按钮
class ExpandableFab extends StatefulWidget {
  final List<FabAction> actions;
  final Widget closedIcon;
  final Widget openIcon;
  final double distance;
  final Duration animationDuration;

  const ExpandableFab({
    super.key,
    required this.actions,
    this.closedIcon = const Icon(Icons.add, color: Colors.white),
    this.openIcon = const Icon(Icons.close, color: Colors.white),
    this.distance = 70.0,
    this.animationDuration = const Duration(milliseconds: 250),
  });

  @override
  State<ExpandableFab> createState() => _ExpandableFabState();
}

class _ExpandableFabState extends State<ExpandableFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotateAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        // 背景遮罩
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return _isExpanded
                ? GestureDetector(
                    onTap: _toggle,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: Colors.black.withValues(
                        alpha: 0.3 * _expandAnimation.value,
                      ),
                    ),
                  )
                : const SizedBox.shrink();
          },
        ),

        // 子按钮
        ...widget.actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;

          return AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              final offset = Offset(
                0,
                -(widget.distance * (index + 1) * _expandAnimation.value),
              );

              return Transform.translate(
                offset: offset,
                child: AnimatedOpacity(
                  opacity: _expandAnimation.value,
                  duration: widget.animationDuration,
                  child: FabButton(
                    onPressed: () {
                      action.onPressed();
                      _toggle();
                    },
                    icon: action.icon,
                    size: 48,
                    heroTag: 'fab_action_$index',
                  ),
                ),
              );
            },
          );
        }),

        // 主按钮
        AnimatedBuilder(
          animation: _rotateAnimation,
          builder: (context, child) {
            return Transform.rotate(
              angle: _rotateAnimation.value * 3.14159,
              child: FabButton(
                onPressed: _toggle,
                icon: _isExpanded ? Icons.close : Icons.add,
                heroTag: 'main_fab',
              ),
            );
          },
        ),
      ],
    );
  }
}

/// 浮动按钮操作
class FabAction {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const FabAction({required this.icon, required this.onPressed, this.tooltip});
}

/// 小型浮动按钮
/// 用于次要操作
class MiniFabButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String? tooltip;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MiniFabButton({
    super.key,
    this.onPressed,
    required this.icon,
    this.tooltip,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Icon(icon, color: foregroundColor ?? Colors.white, size: 20),
        ),
      ),
    );
  }
}
