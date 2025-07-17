import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';

/// 个人中心页面
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<DiaryProvider, TagProvider>(
      builder: (context, diaryProvider, tagProvider, child) {
        return Column(
          children: [
            CustomAppBar(
              title: '个人中心',
              subtitle: '设置和数据管理',
              actions: [
                IconButton(
                  onPressed: () => _showSettingsDialog(context),
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: '设置',
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 用户信息卡片
                    _buildUserInfoCard(diaryProvider),

                    const SizedBox(height: 16),

                    // 数据统计卡片
                    _buildDataStatsCard(diaryProvider, tagProvider),

                    const SizedBox(height: 16),

                    // 功能设置
                    _buildFunctionSection(context),

                    const SizedBox(height: 16),

                    // 数据管理
                    _buildDataManagementSection(context),

                    const SizedBox(height: 16),

                    // 帮助与反馈
                    _buildHelpSection(context),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoCard(DiaryProvider diaryProvider) {
    final totalDays = diaryProvider.allEntries.isNotEmpty
        ? DateTime.now()
                  .difference(diaryProvider.allEntries.first.date)
                  .inDays +
              1
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
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
        children: [
          // 头像
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppConstants.primaryGradient,
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Icon(Icons.person, size: 40, color: Colors.white),
          ),

          const SizedBox(height: 16),

          // 用户名
          const Text(
            '工作记录者',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          // 使用天数
          Text(
            '已使用 $totalDays 天',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 20),

          // 成就标签
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildAchievementChip(
                icon: Icons.edit,
                label: '记录达人',
                color: AppColors.primary,
              ),
              if (diaryProvider.allEntries.length >= 50)
                _buildAchievementChip(
                  icon: Icons.star,
                  label: '坚持之星',
                  color: AppColors.warning,
                ),
              if (diaryProvider.allEntries.length >= 100)
                _buildAchievementChip(
                  icon: Icons.diamond,
                  label: '百篇达成',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataStatsCard(
    DiaryProvider diaryProvider,
    TagProvider tagProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            '数据统计',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.note,
                  label: '总日记',
                  value: diaryProvider.allEntries.length.toString(),
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.local_offer,
                  label: '标签数',
                  value: tagProvider.tags.length.toString(),
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.text_fields,
                  label: '总字数',
                  value: _getTotalWordCount(diaryProvider),
                  color: AppColors.warning,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.calendar_today,
                  label: '本月日记',
                  value: diaryProvider.thisMonthEntries.toString(),
                  color: AppColors.info,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildFunctionSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            '功能设置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.palette,
            title: '主题设置',
            subtitle: '自定义应用主题',
            onTap: () => _showThemeDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.notifications,
            title: '提醒设置',
            subtitle: '设置日记提醒',
            onTap: () => _showNotificationDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.security,
            title: '隐私设置',
            subtitle: '数据隐私保护',
            onTap: () => _showPrivacyDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            '数据管理',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.backup,
            title: '数据备份',
            subtitle: '备份所有日记数据',
            onTap: () => _showBackupDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.download,
            title: '数据导出',
            subtitle: '导出为PDF或Excel',
            onTap: () => _showExportDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.upload,
            title: '数据导入',
            subtitle: '从备份文件导入',
            onTap: () => _showImportDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.delete_forever,
            title: '清空数据',
            subtitle: '删除所有日记数据',
            onTap: () => _showClearDataDialog(context),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            '帮助与反馈',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            icon: Icons.help,
            title: '使用帮助',
            subtitle: '查看使用说明',
            onTap: () => _showHelpDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.feedback,
            title: '意见反馈',
            subtitle: '提交问题或建议',
            onTap: () => _showFeedbackDialog(context),
          ),
          _buildSettingItem(
            icon: Icons.info,
            title: '关于应用',
            subtitle: '版本信息和开发者',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (isDestructive ? AppColors.error : AppColors.primary)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppColors.error : AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }

  String _getTotalWordCount(DiaryProvider diaryProvider) {
    final totalWords = diaryProvider.allEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.content.length,
    );

    if (totalWords >= 10000) {
      return '${(totalWords / 10000).toStringAsFixed(1)}万';
    } else if (totalWords >= 1000) {
      return '${(totalWords / 1000).toStringAsFixed(1)}k';
    } else {
      return totalWords.toString();
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置'),
        content: const Text('设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('主题设置'),
        content: const Text('主题设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提醒设置'),
        content: const Text('提醒设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('隐私设置'),
        content: const Text('隐私设置功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showBackupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据备份'),
        content: const Text('数据备份功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据导出'),
        content: const Text('数据导出功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('数据导入'),
        content: const Text('数据导入功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空数据'),
        content: const Text('确定要清空所有数据吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('清空数据功能开发中...')));
            },
            child: const Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用帮助'),
        content: const Text('使用帮助功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('意见反馈'),
        content: const Text('意见反馈功能开发中...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConfig.appName,
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppConstants.primaryGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.note, color: Colors.white, size: 32),
      ),
      children: [
        const Text('一款简洁高效的工作日记应用'),
        const SizedBox(height: 16),
        const Text('功能特点：'),
        const Text('• 简洁的日记记录'),
        const Text('• 标签分类管理'),
        const Text('• 数据统计分析'),
        const Text('• 多种导出格式'),
      ],
    );
  }
}
