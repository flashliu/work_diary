import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/diary_card.dart';
import '../widgets/fab_button.dart';
import '../models/diary_entry.dart';
import '../constants/app_constants.dart';
import '../animations/common_animations.dart';
import '../animations/page_transitions.dart';
import '../animations/loading_animations.dart';
import 'add_diary_page.dart';
import 'diary_detail_page.dart';
import 'calendar_page.dart';
import 'statistics_page.dart';
import 'export_page.dart';
import 'search_page.dart';

/// 首页 - 日记列表展示
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadDiaryEntries();
      context.read<TagProvider>().loadTags();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [_HomeContent(), CalendarPage(), StatisticsPage()],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _currentIndex == 0
          ? FabButton(
              onPressed: () => _navigateToAddDiary(context),
              icon: Icons.add,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider, width: 0.5)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '日历',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: '统计'),
        ],
      ),
    );
  }

  void _navigateToAddDiary(BuildContext context) {
    Navigator.push(context, const AddDiaryPage().slideUpTransition());
  }
}

/// 首页内容组件
class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        return Column(
          children: [
            // 自定义AppBar
            CustomAppBar(
              title: AppConfig.appName,
              subtitle: '记录每一天的工作成长',
              actions: [
                IconButton(
                  onPressed: () => _showSearch(context),
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: '搜索',
                ),
                IconButton(
                  onPressed: () => _navigateToExportPage(context),
                  icon: const Icon(Icons.download, color: Colors.white),
                  tooltip: '导出',
                ),
              ],
            ),

            // 统计卡片
            _buildStatsCards(context, diaryProvider),

            // 筛选标签
            _buildFilterTabs(context, diaryProvider),

            // 日记列表
            Expanded(child: _buildDiaryList(context, diaryProvider)),
          ],
        );
      },
    );
  }

  Widget _buildStatsCards(BuildContext context, DiaryProvider diaryProvider) {
    final now = DateTime.now();
    final thisMonth = diaryProvider.diaryEntries.where((entry) {
      return entry.date.year == now.year && entry.date.month == now.month;
    }).length;
    final total = diaryProvider.diaryEntries.length;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.calendar_today,
              iconColor: AppColors.primary,
              title: '本月日记',
              value: thisMonth.toString(),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              icon: Icons.trending_up,
              iconColor: AppColors.success,
              title: '总计',
              value: total.toString(),
              backgroundColor: AppColors.success.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(BuildContext context, DiaryProvider diaryProvider) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Expanded(
              child: _buildFilterTab(
                context,
                '全部',
                diaryProvider.filterType == DiaryFilterType.all,
                () => diaryProvider.setFilterType(DiaryFilterType.all),
              ),
            ),
            Expanded(
              child: _buildFilterTab(
                context,
                '本周',
                diaryProvider.filterType == DiaryFilterType.thisWeek,
                () => diaryProvider.setFilterType(DiaryFilterType.thisWeek),
              ),
            ),
            Expanded(
              child: _buildFilterTab(
                context,
                '本月',
                diaryProvider.filterType == DiaryFilterType.thisMonth,
                () => diaryProvider.setFilterType(DiaryFilterType.thisMonth),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(
    BuildContext context,
    String label,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDiaryList(BuildContext context, DiaryProvider diaryProvider) {
    if (diaryProvider.isLoading) {
      return const Center(
        child: LoadingAnimation(type: LoadingType.dots, text: '加载中...'),
      );
    }

    if (diaryProvider.errorMessage != null) {
      return FadeInAnimation(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                diaryProvider.errorMessage!,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => diaryProvider.loadDiaryEntries(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }

    if (diaryProvider.diaryEntries.isEmpty) {
      return FadeInAnimation(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.note_add,
                size: 64,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              const Text(
                '还没有日记记录',
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              const Text(
                '点击右下角按钮开始记录',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => diaryProvider.loadDiaryEntries(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: diaryProvider.diaryEntries.length,
        itemBuilder: (context, index) {
          final diary = diaryProvider.diaryEntries[index];
          return ListItemAnimation(
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DiaryCard(
                diary: diary,
                onTap: () => _navigateToDiaryDetail(context, diary),
                onMorePressed: () => _showDiaryOptions(context, diary),
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToDiaryDetail(BuildContext context, DiaryEntry diary) {
    Navigator.push(context, DiaryDetailPage(diary: diary).slideTransition());
  }

  void _showDiaryOptions(BuildContext context, DiaryEntry diary) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('编辑'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddDiaryPage(diary: diary),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('分享'),
                onTap: () {
                  Navigator.pop(context);
                  _shareDiary(context, diary);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppColors.error),
                title: const Text(
                  '删除',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, diary);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, DiaryEntry diary) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除日记'),
          content: const Text('确定要删除这篇日记吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<DiaryProvider>().deleteDiaryEntry(diary.id!);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('日记已删除')));
              },
              child: const Text('删除', style: TextStyle(color: AppColors.error)),
            ),
          ],
        );
      },
    );
  }

  void _showSearch(BuildContext context) {
    Navigator.push(context, const SearchPage().fadeTransition());
  }

  void _navigateToExportPage(BuildContext context) {
    Navigator.push(context, const ExportPage().slideTransition());
  }

  void _shareDiary(BuildContext context, DiaryEntry diary) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('分享功能开发中...')));
  }
}

/// 日记搜索委托
class DiarySearchDelegate extends SearchDelegate<String> {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        onPressed: () {
          query = '';
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      onPressed: () {
        close(context, '');
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        diaryProvider.searchDiaries(query);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: diaryProvider.diaryEntries.length,
          itemBuilder: (context, index) {
            final diary = diaryProvider.diaryEntries[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: DiaryCard(
                diary: diary,
                onTap: () {
                  close(context, '');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiaryDetailPage(diary: diary),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(
        child: Text(
          '输入关键词搜索日记',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        diaryProvider.searchDiaries(query);
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: diaryProvider.diaryEntries.length,
          itemBuilder: (context, index) {
            final diary = diaryProvider.diaryEntries[index];
            return ListTile(
              title: Text(diary.title),
              subtitle: Text(
                diary.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                close(context, '');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DiaryDetailPage(diary: diary),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
