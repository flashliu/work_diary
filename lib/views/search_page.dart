import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/advanced_search_widget.dart';
import '../constants/app_constants.dart';
import '../models/diary_entry.dart';
import '../services/search_filter_service.dart';
import 'diary_detail_page.dart';

/// 搜索页面
/// 提供高级搜索和筛选功能
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<DiaryEntry> _searchResults = [];
  AdvancedFilterOptions _currentFilters = const AdvancedFilterOptions();
  bool _showAdvancedSearch = true;

  @override
  void initState() {
    super.initState();
    // 初始化时显示所有日记
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final diaryProvider = context.read<DiaryProvider>();
      setState(() {
        _searchResults = diaryProvider.diaryEntries;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // 自定义 AppBar
          CustomAppBar(
            title: '搜索日记',
            subtitle: '找到你想要的内容',
            showBackButton: true,
            actions: [
              IconButton(
                onPressed: _toggleAdvancedSearch,
                icon: Icon(
                  _showAdvancedSearch ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white,
                ),
                tooltip: _showAdvancedSearch ? '收起筛选' : '展开筛选',
              ),
            ],
          ),

          // 主要内容
          Expanded(
            child: Consumer2<DiaryProvider, TagProvider>(
              builder: (context, diaryProvider, tagProvider, child) {
                return Column(
                  children: [
                    // 高级搜索组件
                    if (_showAdvancedSearch)
                      Container(
                        margin: const EdgeInsets.all(AppSpacing.md),
                        child: AdvancedSearchWidget(
                          entries: diaryProvider.diaryEntries,
                          availableTags: tagProvider.tags
                              .map((tag) => tag.name)
                              .toList(),
                          initialFilters: _currentFilters,
                          onResultsChanged: (results) {
                            // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在构建完成后更新状态
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _searchResults = results;
                                });
                              }
                            });
                          },
                          onFiltersChanged: (filters) {
                            // 使用 WidgetsBinding.instance.addPostFrameCallback 确保在构建完成后更新状态
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() {
                                  _currentFilters = filters;
                                });
                              }
                            });
                          },
                        ),
                      ),

                    // 搜索结果列表
                    Expanded(child: _buildSearchResults()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建搜索结果列表
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final diary = _searchResults[index];
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: HighlightDiaryCard(
            diary: diary,
            onTap: () => _navigateToDiaryDetail(diary),
            highlightKeyword: _currentFilters.keyword,
          ),
        );
      },
    );
  }

  /// 构建空状态
  Widget _buildEmptyState() {
    final hasActiveFilters = _currentFilters.hasActiveFilters;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasActiveFilters ? Icons.search_off : Icons.search,
              size: 80,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              hasActiveFilters ? '未找到匹配的结果' : '开始搜索日记',
              style: AppTextStyles.h3.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              hasActiveFilters ? '尝试修改搜索条件或清除筛选器' : '输入关键词或使用筛选条件来搜索日记',
              style: AppTextStyles.bodySecondary,
              textAlign: TextAlign.center,
            ),
            if (hasActiveFilters) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: _clearFilters,
                child: const Text('清除筛选条件'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 切换高级搜索显示状态
  void _toggleAdvancedSearch() {
    setState(() {
      _showAdvancedSearch = !_showAdvancedSearch;
    });
  }

  /// 清除筛选条件
  void _clearFilters() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentFilters = const AdvancedFilterOptions();
          _searchResults = context.read<DiaryProvider>().diaryEntries;
        });
      }
    });
  }

  /// 导航到日记详情页面
  void _navigateToDiaryDetail(DiaryEntry diary) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiaryDetailPage(diary: diary)),
    );
  }
}

/// 增强的日记卡片，支持关键词高亮
class HighlightDiaryCard extends StatelessWidget {
  final DiaryEntry diary;
  final String? highlightKeyword;
  final VoidCallback? onTap;

  const HighlightDiaryCard({
    super.key,
    required this.diary,
    this.highlightKeyword,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 日期和操作按钮
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGradient.colors.first.withValues(
                        alpha: 0.1,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      _formatDate(diary.date),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: AppColors.textTertiary),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // 标题（支持高亮）
              _buildHighlightText(
                diary.title,
                style: AppTextStyles.h4,
                maxLines: 2,
              ),

              const SizedBox(height: AppSpacing.sm),

              // 内容预览（支持高亮）
              _buildHighlightText(
                diary.content,
                style: AppTextStyles.bodySecondary,
                maxLines: 3,
              ),

              if (diary.tags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                // 标签列表
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: diary.tags.map((tag) {
                    final isHighlighted =
                        highlightKeyword?.isNotEmpty == true &&
                        tag.toLowerCase().contains(
                          highlightKeyword!.toLowerCase(),
                        );

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: isHighlighted
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        border: isHighlighted
                            ? Border.all(color: AppColors.primary, width: 1)
                            : null,
                      ),
                      child: Text(
                        tag,
                        style: AppTextStyles.caption.copyWith(
                          color: isHighlighted
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: isHighlighted
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 构建支持高亮的文本
  Widget _buildHighlightText(
    String text, {
    required TextStyle style,
    int? maxLines,
  }) {
    if (highlightKeyword?.isEmpty != false) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final keyword = highlightKeyword!.toLowerCase();
    final textLower = text.toLowerCase();

    if (!textLower.contains(keyword)) {
      return Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
      );
    }

    final spans = <TextSpan>[];
    int start = 0;

    while (true) {
      final index = textLower.indexOf(keyword, start);
      if (index == -1) {
        // 添加剩余的文本
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      // 添加关键词前的文本
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }

      // 添加高亮的关键词
      spans.add(
        TextSpan(
          text: text.substring(index, index + keyword.length),
          style: style.copyWith(
            backgroundColor: AppColors.primary.withValues(alpha: 0.3),
            fontWeight: FontWeight.bold,
          ),
        ),
      );

      start = index + keyword.length;
    }

    return RichText(
      text: TextSpan(style: style, children: spans),
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return '今天';
    } else if (difference == 1) {
      return '昨天';
    } else if (difference < 7) {
      return '$difference天前';
    } else {
      return '${date.month}月${date.day}日';
    }
  }
}
