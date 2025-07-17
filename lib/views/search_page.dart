import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/advanced_search_widget.dart';
import '../widgets/diary_card.dart';
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
        return DiaryCard(
          diary: diary,
          onTap: () => _navigateToDiaryDetail(diary),
          highlightKeyword: _currentFilters.keyword,
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
