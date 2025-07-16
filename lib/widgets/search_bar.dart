import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 搜索栏组件
/// 支持搜索输入和筛选功能
class SearchBar extends StatefulWidget {
  final String? hintText;
  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClearPressed;
  final VoidCallback? onFilterPressed;
  final bool showFilterButton;
  final bool showClearButton;
  final bool autofocus;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const SearchBar({
    super.key,
    this.hintText,
    this.initialValue,
    this.onChanged,
    this.onSubmitted,
    this.onClearPressed,
    this.onFilterPressed,
    this.showFilterButton = true,
    this.showClearButton = true,
    this.autofocus = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _isEmpty = true;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _isEmpty = _controller.text.isEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isEmpty = _controller.text.isEmpty;
    if (_isEmpty != isEmpty) {
      setState(() {
        _isEmpty = isEmpty;
      });
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onClearPressed() {
    _controller.clear();
    widget.onClearPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        keyboardType: widget.keyboardType,
        inputFormatters: widget.inputFormatters,
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText ?? '搜索日记...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          prefixIcon:
              widget.prefixIcon ??
              Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showClearButton && !_isEmpty)
                IconButton(
                  onPressed: _onClearPressed,
                  icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                  tooltip: '清除',
                ),
              if (widget.showFilterButton)
                IconButton(
                  onPressed: widget.onFilterPressed,
                  icon: Icon(
                    Icons.filter_list,
                    color: Colors.grey[400],
                    size: 20,
                  ),
                  tooltip: '筛选',
                ),
              if (widget.suffixIcon != null) widget.suffixIcon!,
            ],
          ),
        ),
      ),
    );
  }
}

/// 搜索筛选组件
/// 提供多种筛选选项
class SearchFilter extends StatefulWidget {
  final List<String> tags;
  final List<String> selectedTags;
  final DateTimeRange? dateRange;
  final ValueChanged<List<String>>? onTagsChanged;
  final ValueChanged<DateTimeRange?>? onDateRangeChanged;
  final VoidCallback? onReset;
  final VoidCallback? onApply;

  const SearchFilter({
    super.key,
    required this.tags,
    required this.selectedTags,
    this.dateRange,
    this.onTagsChanged,
    this.onDateRangeChanged,
    this.onReset,
    this.onApply,
  });

  @override
  State<SearchFilter> createState() => _SearchFilterState();
}

class _SearchFilterState extends State<SearchFilter> {
  void _toggleTag(String tag) {
    final newSelectedTags = List<String>.from(widget.selectedTags);
    if (newSelectedTags.contains(tag)) {
      newSelectedTags.remove(tag);
    } else {
      newSelectedTags.add(tag);
    }
    widget.onTagsChanged?.call(newSelectedTags);
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: widget.dateRange,
      locale: const Locale('zh', 'CN'),
    );

    if (picked != null) {
      widget.onDateRangeChanged?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            children: [
              const Text(
                '筛选',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(onPressed: widget.onReset, child: const Text('重置')),
            ],
          ),

          const SizedBox(height: 16),

          // 日期范围
          const Text(
            '日期范围',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.date_range, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.dateRange != null
                          ? '${_formatDate(widget.dateRange!.start)} - ${_formatDate(widget.dateRange!.end)}'
                          : '选择日期范围',
                      style: TextStyle(
                        color: widget.dateRange != null
                            ? Colors.black87
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 标签
          const Text(
            '标签',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              final isSelected = widget.selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) => _toggleTag(tag),
                selectedColor: Theme.of(
                  context,
                ).primaryColor.withValues(alpha: 0.2),
                checkmarkColor: Theme.of(context).primaryColor,
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // 操作按钮
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    widget.onApply?.call();
                    Navigator.of(context).pop();
                  },
                  child: const Text('应用'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 搜索结果为空的占位组件
class SearchEmptyPlaceholder extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;
  final VoidCallback? onRetry;

  const SearchEmptyPlaceholder({
    super.key,
    this.message = '没有找到相关内容',
    this.subtitle,
    this.icon = Icons.search_off,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ],
      ),
    );
  }
}

/// 搜索建议组件
/// 显示搜索建议和历史记录
class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final List<String> recentSearches;
  final ValueChanged<String>? onSuggestionSelected;
  final ValueChanged<String>? onRecentSearchSelected;
  final VoidCallback? onClearRecentSearches;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    required this.recentSearches,
    this.onSuggestionSelected,
    this.onRecentSearchSelected,
    this.onClearRecentSearches,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索建议
          if (suggestions.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                '搜索建议',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ...suggestions.map((suggestion) {
              return ListTile(
                leading: const Icon(Icons.search, size: 20),
                title: Text(suggestion),
                onTap: () => onSuggestionSelected?.call(suggestion),
              );
            }),
          ],

          // 最近搜索
          if (recentSearches.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    '最近搜索',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: onClearRecentSearches,
                    child: const Text('清除'),
                  ),
                ],
              ),
            ),
            ...recentSearches.map((search) {
              return ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(search),
                onTap: () => onRecentSearchSelected?.call(search),
              );
            }),
          ],
        ],
      ),
    );
  }
}
