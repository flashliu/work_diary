import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/search_filter_service.dart';
import '../models/diary_entry.dart';

/// 高级搜索组件
/// 提供多条件搜索和筛选功能
class AdvancedSearchWidget extends StatefulWidget {
  final List<DiaryEntry> entries;
  final List<String> availableTags;
  final AdvancedFilterOptions initialFilters;
  final ValueChanged<List<DiaryEntry>>? onResultsChanged;
  final ValueChanged<AdvancedFilterOptions>? onFiltersChanged;

  const AdvancedSearchWidget({
    super.key,
    required this.entries,
    required this.availableTags,
    required this.initialFilters,
    this.onResultsChanged,
    this.onFiltersChanged,
  });

  @override
  State<AdvancedSearchWidget> createState() => _AdvancedSearchWidgetState();
}

class _AdvancedSearchWidgetState extends State<AdvancedSearchWidget> {
  final SearchFilterService _searchService = SearchFilterService();
  late TextEditingController _keywordController;
  late AdvancedFilterOptions _currentFilters;
  List<DiaryEntry> _filteredResults = [];
  List<String> _searchSuggestions = [];
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(
      text: widget.initialFilters.keyword,
    );
    _currentFilters = widget.initialFilters;
    _applyFilters();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  /// 应用筛选条件
  void _applyFilters() {
    _filteredResults = _searchService.advancedFilter(
      entries: widget.entries,
      filters: _currentFilters,
    );

    widget.onResultsChanged?.call(_filteredResults);
    widget.onFiltersChanged?.call(_currentFilters);
  }

  /// 更新关键词
  void _updateKeyword(String keyword) {
    setState(() {
      _currentFilters = _currentFilters.copyWith(keyword: keyword);

      if (keyword.isNotEmpty) {
        _searchSuggestions = _searchService.getSearchSuggestions(
          entries: widget.entries,
          keyword: keyword,
        );
        _showSuggestions = _searchSuggestions.isNotEmpty;
      } else {
        _showSuggestions = false;
      }
    });

    _applyFilters();
  }

  /// 清除所有筛选条件
  void _clearFilters() {
    setState(() {
      _keywordController.clear();
      _currentFilters = const AdvancedFilterOptions();
      _showSuggestions = false;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [AppShadows.light],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索输入框
          _buildSearchInput(),

          // 搜索建议
          if (_showSuggestions) _buildSearchSuggestions(),

          // 筛选选项
          _buildFilterOptions(),

          // 搜索结果统计
          _buildResultsStatistics(),
        ],
      ),
    );
  }

  /// 构建搜索输入框
  Widget _buildSearchInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _keywordController,
        onChanged: _updateKeyword,
        decoration: InputDecoration(
          hintText: '搜索日记内容、标题或标签...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_keywordController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _keywordController.clear();
                    _updateKeyword('');
                  },
                  icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                ),
              IconButton(
                onPressed: _showFilterDialog,
                icon: Icon(
                  Icons.tune,
                  color: _currentFilters.hasActiveFilters
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
      ),
    );
  }

  /// 构建搜索建议
  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        children: _searchSuggestions.map((suggestion) {
          return ListTile(
            dense: true,
            leading: const Icon(Icons.search, size: 16),
            title: Text(suggestion, style: AppTextStyles.bodySecondary),
            onTap: () {
              _keywordController.text = suggestion;
              _updateKeyword(suggestion);
              setState(() {
                _showSuggestions = false;
              });
            },
          );
        }).toList(),
      ),
    );
  }

  /// 构建筛选选项
  Widget _buildFilterOptions() {
    if (!_currentFilters.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('筛选条件', style: AppTextStyles.h4),
              const Spacer(),
              TextButton(onPressed: _clearFilters, child: const Text('清除全部')),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              // 标签筛选
              if (_currentFilters.selectedTags.isNotEmpty)
                ..._currentFilters.selectedTags.map(
                  (tag) => Chip(
                    label: Text(tag),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => _removeTagFilter(tag),
                  ),
                ),

              // 日期范围筛选
              if (_currentFilters.startDate != null ||
                  _currentFilters.endDate != null)
                Chip(
                  label: Text(_getDateRangeText()),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: _removeDateRangeFilter,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果统计
  Widget _buildResultsStatistics() {
    final statistics = _searchService.getSearchStatistics(
      originalEntries: widget.entries,
      filteredEntries: _filteredResults,
      filters: _currentFilters,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '找到 ${statistics.filteredEntries} 条结果（共 ${statistics.totalEntries} 条）',
            style: AppTextStyles.caption,
          ),
          if (statistics.hasActiveFilters) ...[
            const Spacer(),
            Text(
              '筛选比例：${(statistics.filterRatio * 100).toStringAsFixed(1)}%',
              style: AppTextStyles.caption.copyWith(color: AppColors.primary),
            ),
          ],
        ],
      ),
    );
  }

  /// 显示筛选对话框
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => _FilterDialog(
        currentFilters: _currentFilters,
        availableTags: widget.availableTags,
        onFiltersChanged: (filters) {
          setState(() {
            _currentFilters = filters;
          });
          _applyFilters();
        },
      ),
    );
  }

  /// 移除标签筛选
  void _removeTagFilter(String tag) {
    final newTags = List<String>.from(_currentFilters.selectedTags);
    newTags.remove(tag);
    setState(() {
      _currentFilters = _currentFilters.copyWith(selectedTags: newTags);
    });
    _applyFilters();
  }

  /// 移除日期范围筛选
  void _removeDateRangeFilter() {
    setState(() {
      _currentFilters = _currentFilters.copyWith(
        startDate: null,
        endDate: null,
      );
    });
    _applyFilters();
  }

  /// 获取日期范围文本
  String _getDateRangeText() {
    if (_currentFilters.startDate != null && _currentFilters.endDate != null) {
      return '${_formatDate(_currentFilters.startDate!)} - ${_formatDate(_currentFilters.endDate!)}';
    } else if (_currentFilters.startDate != null) {
      return '从 ${_formatDate(_currentFilters.startDate!)}';
    } else if (_currentFilters.endDate != null) {
      return '到 ${_formatDate(_currentFilters.endDate!)}';
    }
    return '';
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.month}月${date.day}日';
  }
}

/// 筛选对话框
class _FilterDialog extends StatefulWidget {
  final AdvancedFilterOptions currentFilters;
  final List<String> availableTags;
  final ValueChanged<AdvancedFilterOptions> onFiltersChanged;

  const _FilterDialog({
    required this.currentFilters,
    required this.availableTags,
    required this.onFiltersChanged,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  late AdvancedFilterOptions _filters;

  @override
  void initState() {
    super.initState();
    _filters = widget.currentFilters;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('高级筛选'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 搜索范围选择
              _buildSearchScopeSection(),
              const SizedBox(height: AppSpacing.lg),

              // 标签选择
              _buildTagSelectionSection(),
              const SizedBox(height: AppSpacing.lg),

              // 日期范围选择
              _buildDateRangeSection(),
              const SizedBox(height: AppSpacing.lg),

              // 内容长度筛选
              _buildContentLengthSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () {
            widget.onFiltersChanged(_filters);
            Navigator.of(context).pop();
          },
          child: const Text('应用'),
        ),
      ],
    );
  }

  /// 构建搜索范围选择
  Widget _buildSearchScopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('搜索范围', style: AppTextStyles.h4),
        CheckboxListTile(
          title: const Text('搜索标题'),
          value: _filters.searchInTitle,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(searchInTitle: value);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('搜索内容'),
          value: _filters.searchInContent,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(searchInContent: value);
            });
          },
        ),
        CheckboxListTile(
          title: const Text('搜索标签'),
          value: _filters.searchInTags,
          onChanged: (value) {
            setState(() {
              _filters = _filters.copyWith(searchInTags: value);
            });
          },
        ),
      ],
    );
  }

  /// 构建标签选择
  Widget _buildTagSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('标签筛选', style: AppTextStyles.h4),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: widget.availableTags.map((tag) {
            final isSelected = _filters.selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                final newTags = List<String>.from(_filters.selectedTags);
                if (selected) {
                  newTags.add(tag);
                } else {
                  newTags.remove(tag);
                }
                setState(() {
                  _filters = _filters.copyWith(selectedTags: newTags);
                });
              },
            );
          }).toList(),
        ),
        if (_filters.selectedTags.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          SwitchListTile(
            title: const Text('匹配所有标签'),
            subtitle: const Text('开启后需要同时包含所有选中的标签'),
            value: _filters.matchAllTags,
            onChanged: (value) {
              setState(() {
                _filters = _filters.copyWith(matchAllTags: value);
              });
            },
          ),
        ],
      ],
    );
  }

  /// 构建日期范围选择
  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('日期范围', style: AppTextStyles.h4),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('开始日期'),
                subtitle: Text(
                  _filters.startDate?.toString().split(' ')[0] ?? '未选择',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(isStartDate: true),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('结束日期'),
                subtitle: Text(
                  _filters.endDate?.toString().split(' ')[0] ?? '未选择',
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectDate(isStartDate: false),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建内容长度筛选
  Widget _buildContentLengthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('内容长度', style: AppTextStyles.h4),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '最小字数',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final minLength = int.tryParse(value);
                  setState(() {
                    _filters = _filters.copyWith(minContentLength: minLength);
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '最大字数',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final maxLength = int.tryParse(value);
                  setState(() {
                    _filters = _filters.copyWith(maxContentLength: maxLength);
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 选择日期
  Future<void> _selectDate({required bool isStartDate}) async {
    final initialDate = isStartDate
        ? _filters.startDate ?? DateTime.now()
        : _filters.endDate ?? DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        if (isStartDate) {
          _filters = _filters.copyWith(startDate: selectedDate);
        } else {
          _filters = _filters.copyWith(endDate: selectedDate);
        }
      });
    }
  }
}
