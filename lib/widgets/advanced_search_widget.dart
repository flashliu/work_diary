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

    // 使用 WidgetsBinding.instance.addPostFrameCallback 确保回调在构建完成后执行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onResultsChanged?.call(_filteredResults);
      widget.onFiltersChanged?.call(_currentFilters);
    });
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

  /// 切换标签筛选
  void _toggleTagFilter(String tag) {
    final newTags = List<String>.from(_currentFilters.selectedTags);
    if (newTags.contains(tag)) {
      newTags.remove(tag);
    } else {
      newTags.add(tag);
    }
    setState(() {
      _currentFilters = _currentFilters.copyWith(selectedTags: newTags);
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索输入框
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: AppColors.border.withValues(alpha: 0.3),
              ),
            ),
            child: TextField(
              controller: _keywordController,
              onChanged: _updateKeyword,
              decoration: InputDecoration(
                hintText: '搜索日记内容、标题或标签...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.textSecondary,
                ),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_keywordController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _keywordController.clear();
                          _updateKeyword('');
                        },
                        icon: const Icon(
                          Icons.clear,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: Material(
                        color: _currentFilters.hasActiveFilters
                            ? AppColors.primary
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          onTap: _showFilterDialog,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.tune,
                              size: 20,
                              color: _currentFilters.hasActiveFilters
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // 快捷筛选按钮
          if (widget.availableTags.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快捷筛选',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: widget.availableTags.take(6).map((tag) {
                      final isSelected = _currentFilters.selectedTags.contains(
                        tag,
                      );
                      return GestureDetector(
                        onTap: () => _toggleTagFilter(tag),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.tag,
                                size: 14,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// 构建搜索建议
  Widget _buildSearchSuggestions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '搜索建议',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ..._searchSuggestions.map((suggestion) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _keywordController.text = suggestion;
                  _updateKeyword(suggestion);
                  setState(() {
                    _showSuggestions = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          suggestion,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.north_west,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 构建筛选选项
  Widget _buildFilterOptions() {
    if (!_currentFilters.hasActiveFilters) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.filter_list, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '当前筛选',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _clearFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.clear_all, size: 12, color: AppColors.error),
                      const SizedBox(width: 4),
                      Text(
                        '清除',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
                  (tag) => _buildFilterChip(
                    label: tag,
                    icon: Icons.tag,
                    onRemove: () => _removeTagFilter(tag),
                  ),
                ),

              // 日期范围筛选
              if (_currentFilters.startDate != null ||
                  _currentFilters.endDate != null)
                _buildFilterChip(
                  label: _getDateRangeText(),
                  icon: Icons.date_range,
                  onRemove: _removeDateRangeFilter,
                ),

              // 内容长度筛选
              if (_currentFilters.minContentLength != null ||
                  _currentFilters.maxContentLength != null)
                _buildFilterChip(
                  label: _getContentLengthText(),
                  icon: Icons.text_fields,
                  onRemove: _removeContentLengthFilter,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建筛选芯片
  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.close, size: 12, color: AppColors.primary),
            ),
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
      margin: const EdgeInsets.all(AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '找到 ${statistics.filteredEntries} 条结果',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (statistics.hasActiveFilters)
                  Text(
                    '共 ${statistics.totalEntries} 条 · 筛选比例 ${(statistics.filterRatio * 100).toStringAsFixed(1)}%',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (statistics.hasActiveFilters && statistics.filteredEntries > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                '${((statistics.filteredEntries / statistics.totalEntries) * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ),
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

  /// 获取内容长度文本
  String _getContentLengthText() {
    if (_currentFilters.minContentLength != null &&
        _currentFilters.maxContentLength != null) {
      return '${_currentFilters.minContentLength}-${_currentFilters.maxContentLength}字';
    } else if (_currentFilters.minContentLength != null) {
      return '≥${_currentFilters.minContentLength}字';
    } else if (_currentFilters.maxContentLength != null) {
      return '≤${_currentFilters.maxContentLength}字';
    }
    return '';
  }

  /// 移除内容长度筛选
  void _removeContentLengthFilter() {
    setState(() {
      _currentFilters = _currentFilters.copyWith(
        minContentLength: null,
        maxContentLength: null,
      );
    });
    _applyFilters();
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.tune, color: AppColors.primary, size: 24),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '高级筛选',
                    style: AppTextStyles.h3.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      onTap: () => Navigator.of(context).pop(),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 搜索范围选择
                    _buildSearchScopeSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // 标签选择
                    _buildTagSelectionSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // 日期范围选择
                    _buildDateRangeSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // 内容长度筛选
                    _buildContentLengthSection(),
                  ],
                ),
              ),
            ),

            // 按钮栏
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.lg),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppColors.border),
                      ),
                      child: Text(
                        '取消',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onFiltersChanged(_filters);
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text('应用'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建搜索范围选择
  Widget _buildSearchScopeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.search, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '搜索范围',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildCheckboxTile(
                title: '搜索标题',
                subtitle: '在日记标题中搜索',
                icon: Icons.title,
                value: _filters.searchInTitle,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(searchInTitle: value);
                  });
                },
              ),
              const Divider(height: 1),
              _buildCheckboxTile(
                title: '搜索内容',
                subtitle: '在日记正文中搜索',
                icon: Icons.description,
                value: _filters.searchInContent,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(searchInContent: value);
                  });
                },
              ),
              const Divider(height: 1),
              _buildCheckboxTile(
                title: '搜索标签',
                subtitle: '在日记标签中搜索',
                icon: Icons.tag,
                value: _filters.searchInTags,
                onChanged: (value) {
                  setState(() {
                    _filters = _filters.copyWith(searchInTags: value);
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建复选框列表项
  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Material(
      color: Colors.transparent,
      child: CheckboxListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        title: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: value ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              title,
              style: AppTextStyles.body.copyWith(
                color: value ? AppColors.primary : AppColors.textPrimary,
                fontWeight: value ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
        checkColor: Colors.white,
      ),
    );
  }

  /// 构建标签选择
  Widget _buildTagSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_offer, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '标签筛选',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.availableTags.isEmpty)
                Text(
                  '暂无可用标签',
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: widget.availableTags.map((tag) {
                    final isSelected = _filters.selectedTags.contains(tag);
                    return GestureDetector(
                      onTap: () {
                        final newTags = List<String>.from(
                          _filters.selectedTags,
                        );
                        if (isSelected) {
                          newTags.remove(tag);
                        } else {
                          newTags.add(tag);
                        }
                        setState(() {
                          _filters = _filters.copyWith(selectedTags: newTags);
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.2,
                                    ),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.tag,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              tag,
                              style: TextStyle(
                                fontSize: 13,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: isSelected
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

              if (_filters.selectedTags.length > 1) ...[
                const SizedBox(height: AppSpacing.lg),
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      Icon(
                        Icons.link,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '匹配所有标签',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '开启后需要同时包含所有选中的标签',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  value: _filters.matchAllTags,
                  onChanged: (value) {
                    setState(() {
                      _filters = _filters.copyWith(matchAllTags: value);
                    });
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// 构建日期范围选择
  Widget _buildDateRangeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.date_range, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '日期范围',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildDateTile(
                title: '开始日期',
                subtitle: _filters.startDate?.toString().split(' ')[0] ?? '未选择',
                icon: Icons.calendar_today,
                onTap: () => _selectDate(isStartDate: true),
                hasValue: _filters.startDate != null,
              ),
              const Divider(height: 1),
              _buildDateTile(
                title: '结束日期',
                subtitle: _filters.endDate?.toString().split(' ')[0] ?? '未选择',
                icon: Icons.event,
                onTap: () => _selectDate(isStartDate: false),
                hasValue: _filters.endDate != null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建日期选择项
  Widget _buildDateTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasValue,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: hasValue
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: hasValue ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: hasValue
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建内容长度筛选
  Widget _buildContentLengthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.text_fields, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '内容长度',
              style: AppTextStyles.h4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最小字数',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final minLength = int.tryParse(value);
                          setState(() {
                            _filters = _filters.copyWith(
                              minContentLength: minLength,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '最大字数',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: Border.all(
                          color: AppColors.border.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: '无限制',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final maxLength = int.tryParse(value);
                          setState(() {
                            _filters = _filters.copyWith(
                              maxContentLength: maxLength,
                            );
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
