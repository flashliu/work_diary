import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../animations/loading_animations.dart';

/// 懒加载列表组件
class LazyLoadingList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final VoidCallback? onLoadMore;
  final bool hasMore;
  final bool isLoading;
  final int itemsPerPage;
  final ScrollController? scrollController;
  final EdgeInsets? padding;
  final Widget? separator;
  final Widget? loadingWidget;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const LazyLoadingList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.hasMore = true,
    this.isLoading = false,
    this.itemsPerPage = 20,
    this.scrollController,
    this.padding,
    this.separator,
    this.loadingWidget,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && widget.hasMore && !widget.isLoading) {
        setState(() {
          _isLoadingMore = true;
        });
        widget.onLoadMore?.call();

        // 模拟加载延迟
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _isLoadingMore = false;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty && !widget.isLoading) {
      return widget.emptyWidget ?? _buildEmptyWidget();
    }

    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length + (widget.hasMore ? 1 : 0),
      separatorBuilder: (context, index) {
        if (index < widget.items.length - 1) {
          return widget.separator ?? const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
      itemBuilder: (context, index) {
        if (index < widget.items.length) {
          return widget.itemBuilder(context, widget.items[index], index);
        } else {
          // 加载更多指示器
          return _buildLoadingIndicator();
        }
      },
    );
  }

  Widget _buildEmptyWidget() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('暂无数据', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: _isLoadingMore
          ? const LoadingAnimation(type: LoadingType.dots, size: 32)
          : const SizedBox.shrink(),
    );
  }
}

/// 缓存图片组件
class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Duration cacheDuration;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheDuration = const Duration(days: 7),
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  bool _hasError = false;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_isLoading) widget.placeholder ?? _buildPlaceholder(),
            Image.network(
              widget.imageUrl,
              width: widget.width,
              height: widget.height,
              fit: widget.fit,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  });
                  return child;
                }
                return widget.placeholder ?? _buildPlaceholder();
              },
              errorBuilder: (context, error, stackTrace) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {
                      _hasError = true;
                      _isLoading = false;
                    });
                  }
                });
                return widget.errorWidget ?? _buildErrorWidget();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: LoadingAnimation(type: LoadingType.circular, size: 32),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.error_outline, size: 32, color: Colors.grey),
      ),
    );
  }
}

/// 内存优化的文本组件
class OptimizedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final bool enableCaching;

  const OptimizedText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
    this.enableCaching = true,
  });

  @override
  Widget build(BuildContext context) {
    if (enableCaching && text.length > 1000) {
      // 对于长文本，使用 RichText 进行优化
      return RichText(
        text: TextSpan(
          text: text,
          style: style ?? DefaultTextStyle.of(context).style,
        ),
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.clip,
        textAlign: textAlign ?? TextAlign.start,
      );
    }

    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
}

/// 防抖动按钮组件
class DebouncedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Duration debounceDuration;
  final ButtonStyle? style;

  const DebouncedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.debounceDuration = const Duration(milliseconds: 300),
    this.style,
  });

  @override
  State<DebouncedButton> createState() => _DebouncedButtonState();
}

class _DebouncedButtonState extends State<DebouncedButton> {
  bool _isPressed = false;

  void _handlePress() {
    if (_isPressed) return;

    setState(() {
      _isPressed = true;
    });

    widget.onPressed?.call();

    Future.delayed(widget.debounceDuration, () {
      if (mounted) {
        setState(() {
          _isPressed = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: _isPressed ? null : _handlePress,
      style: widget.style,
      child: widget.child,
    );
  }
}

/// 虚拟列表组件
class VirtualizedList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext, T, int) itemBuilder;
  final double itemHeight;
  final int bufferSize;
  final ScrollController? scrollController;
  final EdgeInsets? padding;

  const VirtualizedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.itemHeight,
    this.bufferSize = 10,
    this.scrollController,
    this.padding,
  });

  @override
  State<VirtualizedList<T>> createState() => _VirtualizedListState<T>();
}

class _VirtualizedListState<T> extends State<VirtualizedList<T>> {
  late ScrollController _scrollController;
  int _firstVisibleIndex = 0;
  int _lastVisibleIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _updateVisibleRange();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    _updateVisibleRange();
  }

  void _updateVisibleRange() {
    final viewportHeight = MediaQuery.of(context).size.height;
    final scrollOffset = _scrollController.offset;

    final firstIndex = (scrollOffset / widget.itemHeight).floor();
    final lastIndex = ((scrollOffset + viewportHeight) / widget.itemHeight)
        .ceil();

    final bufferedFirstIndex = (firstIndex - widget.bufferSize).clamp(
      0,
      widget.items.length - 1,
    );
    final bufferedLastIndex = (lastIndex + widget.bufferSize).clamp(
      0,
      widget.items.length - 1,
    );

    if (bufferedFirstIndex != _firstVisibleIndex ||
        bufferedLastIndex != _lastVisibleIndex) {
      setState(() {
        _firstVisibleIndex = bufferedFirstIndex;
        _lastVisibleIndex = bufferedLastIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items.sublist(
      _firstVisibleIndex,
      _lastVisibleIndex + 1,
    );

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        if (index < _firstVisibleIndex || index > _lastVisibleIndex) {
          return SizedBox(height: widget.itemHeight);
        }

        final adjustedIndex = index - _firstVisibleIndex;
        return widget.itemBuilder(context, visibleItems[adjustedIndex], index);
      },
    );
  }
}

/// 预加载组件
class PreloadWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPreload;
  final double threshold;

  const PreloadWidget({
    super.key,
    required this.child,
    this.onPreload,
    this.threshold = 200.0,
  });

  @override
  State<PreloadWidget> createState() => _PreloadWidgetState();
}

class _PreloadWidgetState extends State<PreloadWidget> {
  bool _hasPreloaded = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollUpdateNotification) {
          final scrollable = notification.metrics;
          if (scrollable.pixels >=
              scrollable.maxScrollExtent - widget.threshold) {
            if (!_hasPreloaded) {
              _hasPreloaded = true;
              widget.onPreload?.call();
            }
          }
        }
        return false;
      },
      child: widget.child,
    );
  }
}

/// 性能监控组件
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final Function(String)? onPerformanceReport;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = false,
    this.onPerformanceReport,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      _startTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    if (widget.enabled) {
      final duration = DateTime.now().difference(_startTime);
      final report = 'Widget lifecycle: ${duration.inMilliseconds}ms';
      widget.onPerformanceReport?.call(report);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

/// 内存管理辅助类
class MemoryManager {
  static final Map<String, dynamic> _cache = {};
  static const int _maxCacheSize = 100;

  /// 缓存数据
  static void cacheData(String key, dynamic data) {
    if (_cache.length >= _maxCacheSize) {
      // 清除最旧的缓存项
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
    _cache[key] = data;
  }

  /// 获取缓存数据
  static T? getCachedData<T>(String key) {
    return _cache[key] as T?;
  }

  /// 清除指定缓存
  static void clearCache(String key) {
    _cache.remove(key);
  }

  /// 清除所有缓存
  static void clearAllCache() {
    _cache.clear();
  }

  /// 获取缓存大小
  static int getCacheSize() {
    return _cache.length;
  }

  /// 强制垃圾回收
  static void forceGC() {
    // 触发系统消息以释放内存
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }
}
