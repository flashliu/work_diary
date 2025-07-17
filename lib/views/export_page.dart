import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../models/diary_entry.dart';
import '../models/tag.dart';
import '../utils/export_utils.dart';

/// 导出页面
/// 提供多种导出格式和选项
class ExportPage extends StatefulWidget {
  const ExportPage({super.key});

  @override
  State<ExportPage> createState() => _ExportPageState();
}

class _ExportPageState extends State<ExportPage> {
  // 导出格式选择
  ExportFormat _selectedFormat = ExportFormat.word;

  // 时间范围选择
  DateRange _selectedDateRange = DateRange.all;
  DateTime? _startDate;
  DateTime? _endDate;

  // 内容选择
  bool _includeDate = true;
  bool _includeContent = true;
  bool _includeTags = true;
  bool _includeNotes = true;

  // 标签筛选
  final List<Tag> _selectedTags = [];

  // 导出状态
  bool _isExporting = false;
  double _exportProgress = 0.0;
  String _exportStatus = '';

  @override
  void initState() {
    super.initState();
    // 初始化数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DiaryProvider>().loadDiaryEntries();
      context.read<TagProvider>().loadTags();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          // 使用 CustomAppBar
          CustomAppBar(
            title: '导出日记',
            subtitle: '选择导出格式和内容',
            showBackButton: true,
            actions: [
              IconButton(
                onPressed: () {
                  // 重置选项
                  setState(() {
                    _selectedFormat = ExportFormat.word;
                    _selectedDateRange = DateRange.all;
                    _startDate = null;
                    _endDate = null;
                    _includeDate = true;
                    _includeContent = true;
                    _includeTags = true;
                    _includeNotes = true;
                    _selectedTags.clear();
                  });
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: '重置选项',
              ),
            ],
          ),

          // 主要内容
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 导出格式选择
                  _buildFormatSelection(),

                  const SizedBox(height: 16),

                  // 时间范围选择
                  _buildDateRangeSelection(),

                  const SizedBox(height: 16),

                  // 导出内容选择
                  _buildContentOptions(),

                  const SizedBox(height: 16),

                  // 导出设置
                  _buildExportSettings(),

                  const SizedBox(height: 16),

                  // 导出进度 (条件显示)
                  if (_isExporting) _buildExportProgress(),

                  const SizedBox(height: 80), // 为底部按钮留出空间
                ],
              ),
            ),
          ),

          // 底部导出按钮
          _buildExportButton(),
        ],
      ),
    );
  }

  /// 构建导出格式选择
  Widget _buildFormatSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '选择导出格式',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Word 格式
            Expanded(
              child: _buildFormatCard(
                format: ExportFormat.word,
                icon: Icons.article_outlined,
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFDBEAFE),
                title: 'Word 文档',
                subtitle: '导出为 .docx 格式',
                isRecommended: true,
              ),
            ),
            const SizedBox(width: 16),
            // Excel 格式
            Expanded(
              child: _buildFormatCard(
                format: ExportFormat.excel,
                icon: Icons.table_chart_outlined,
                iconColor: const Color(0xFF10B981),
                iconBgColor: const Color(0xFFD1FAE5),
                title: 'Excel 表格',
                subtitle: '导出为 .xlsx 格式',
                additionalInfo: '适合数据分析',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建格式卡片
  Widget _buildFormatCard({
    required ExportFormat format,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    bool isRecommended = false,
    String? additionalInfo,
  }) {
    final isSelected = _selectedFormat == format;

    return GestureDetector(
      onTap: () => setState(() => _selectedFormat = format),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部：图标和选择状态
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF3B82F6)
                          : const Color(0xFFD1D5DB),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 12)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 标题
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 4),
            // 副标题
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            // 推荐标签或额外信息
            if (isRecommended && isSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '推荐格式',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else if (additionalInfo != null)
              Text(
                additionalInfo,
                style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建时间范围选择
  Widget _buildDateRangeSelection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '选择时间范围',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 时间范围选项
          Consumer<DiaryProvider>(
            builder: (context, diaryProvider, child) {
              final allEntries = diaryProvider.allEntries;
              final thisMonthEntries = _getThisMonthEntries(allEntries);
              final lastMonthEntries = _getLastMonthEntries(allEntries);

              return Column(
                children: [
                  _buildDateRangeOption(
                    DateRange.all,
                    '全部时间',
                    '(${allEntries.length} 条记录)',
                  ),
                  _buildDateRangeOption(
                    DateRange.thisMonth,
                    '本月',
                    '(${thisMonthEntries.length} 条记录)',
                  ),
                  _buildDateRangeOption(
                    DateRange.lastMonth,
                    '上月',
                    '(${lastMonthEntries.length} 条记录)',
                  ),
                  _buildDateRangeOption(DateRange.custom, '自定义范围', ''),
                ],
              );
            },
          ),
          // 自定义日期范围输入
          if (_selectedDateRange == DateRange.custom) ...[
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.only(left: 32),
              child: Row(
                children: [
                  Expanded(
                    child: _buildDateInput(
                      label: '开始日期',
                      date: _startDate,
                      onDateSelected: (date) =>
                          setState(() => _startDate = date),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDateInput(
                      label: '结束日期',
                      date: _endDate,
                      onDateSelected: (date) => setState(() => _endDate = date),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 构建日期范围选项
  Widget _buildDateRangeOption(DateRange range, String title, String subtitle) {
    return InkWell(
      onTap: () => setState(() => _selectedDateRange = range),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: _selectedDateRange == range
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                border: Border.all(
                  color: _selectedDateRange == range
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: _selectedDateRange == range
                  ? const Icon(Icons.check, color: Colors.white, size: 10)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF374151),
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
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

  /// 构建日期输入框
  Widget _buildDateInput({
    required String label,
    required DateTime? date,
    required Function(DateTime) onDateSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectDate(onDateSelected),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date != null
                      ? '${date.year}/${date.month}/${date.day}'
                      : '年/月/日',
                  style: TextStyle(
                    fontSize: 14,
                    color: date != null
                        ? const Color(0xFF374151)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 构建内容选择
  Widget _buildContentOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.checklist,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '导出内容',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 内容选项
          Column(
            children: [
              _buildContentOption(
                value: _includeDate,
                title: '日期信息',
                onChanged: (value) => setState(() => _includeDate = value),
              ),
              _buildContentOption(
                value: _includeContent,
                title: '工作内容',
                onChanged: (value) => setState(() => _includeContent = value),
              ),
              _buildContentOption(
                value: _includeTags,
                title: '标签',
                onChanged: (value) => setState(() => _includeTags = value),
              ),
              _buildContentOption(
                value: _includeNotes,
                title: '备注',
                onChanged: (value) => setState(() => _includeNotes = value),
              ),
              _buildContentOption(
                value: false,
                title: '创建时间',
                onChanged: (value) => {},
              ),
              _buildContentOption(
                value: false,
                title: '修改时间',
                onChanged: (value) => {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建内容选项
  Widget _buildContentOption({
    required bool value,
    required String title,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF3B82F6) : Colors.transparent,
                border: Border.all(
                  color: value
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导出设置
  Widget _buildExportSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE9FE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '导出设置',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 设置选项
          Column(
            children: [
              _buildSettingOption(
                label: '按日期排序',
                value: '最新优先',
                options: ['最新优先', '最早优先'],
                onChanged: (value) => {},
              ),
              _buildSettingOption(
                label: '分页设置',
                value: '不分页',
                options: ['不分页', '每页20条', '每页50条'],
                onChanged: (value) => {},
              ),
              _buildSimpleContentOption(
                value: true,
                title: '包含封面页',
                onChanged: (value) => {},
              ),
              _buildSimpleContentOption(
                value: false,
                title: '包含统计信息',
                onChanged: (value) => {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建设置选项
  Widget _buildSettingOption({
    required String label,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButton<String>(
              value: value,
              underline: const SizedBox(),
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  onChanged(newValue);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建简单内容选项
  Widget _buildSimpleContentOption({
    required bool value,
    required String title,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF3B82F6) : Colors.transparent,
                border: Border.all(
                  color: value
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建导出进度
  Widget _buildExportProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.download,
                  color: Color(0xFF3B82F6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                '导出进度',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 进度信息
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _exportStatus,
                style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              ),
              const Text(
                '完成',
                style: TextStyle(fontSize: 14, color: Color(0xFF3B82F6)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 进度条
          LinearProgressIndicator(
            value: _exportProgress,
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          ),
          const SizedBox(height: 8),
          const Text(
            '文件已生成，即将开始下载',
            style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  /// 构建导出按钮
  Widget _buildExportButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Consumer<DiaryProvider>(
        builder: (context, diaryProvider, child) {
          final filteredEntries = _getFilteredEntries(diaryProvider.allEntries);
          final canExport = filteredEntries.isNotEmpty && !_isExporting;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 导出按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: canExport ? _startExport : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.download, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isExporting
                            ? '正在导出...'
                            : '开始导出 (${filteredEntries.length} 条记录)',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // 导出信息
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '预计文件大小: 2.3MB',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '预计用时: 5秒',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  /// 选择日期
  Future<void> _selectDate(Function(DateTime) onDateSelected) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      onDateSelected(picked);
    }
  }

  /// 获取本月记录
  List<DiaryEntry> _getThisMonthEntries(List<DiaryEntry> entries) {
    final now = DateTime.now();
    return entries.where((entry) {
      return entry.date.year == now.year && entry.date.month == now.month;
    }).toList();
  }

  /// 获取上月记录
  List<DiaryEntry> _getLastMonthEntries(List<DiaryEntry> entries) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1);
    return entries.where((entry) {
      return entry.date.year == lastMonth.year &&
          entry.date.month == lastMonth.month;
    }).toList();
  }

  /// 获取过滤后的记录
  List<DiaryEntry> _getFilteredEntries(List<DiaryEntry> entries) {
    List<DiaryEntry> filtered = entries;

    // 按时间范围过滤
    switch (_selectedDateRange) {
      case DateRange.thisMonth:
        filtered = _getThisMonthEntries(filtered);
        break;
      case DateRange.lastMonth:
        filtered = _getLastMonthEntries(filtered);
        break;
      case DateRange.custom:
        if (_startDate != null && _endDate != null) {
          filtered = filtered.where((entry) {
            return entry.date.isAfter(_startDate!) &&
                entry.date.isBefore(_endDate!);
          }).toList();
        }
        break;
      case DateRange.all:
        break;
    }

    // 按标签过滤
    if (_selectedTags.isNotEmpty) {
      filtered = filtered.where((entry) {
        return _selectedTags.any((tag) => entry.tags.contains(tag.name));
      }).toList();
    }

    return filtered;
  }

  /// 开始导出
  Future<void> _startExport() async {
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportStatus = '正在准备导出...';
    });

    try {
      final diaryProvider = context.read<DiaryProvider>();
      final entries = _getFilteredEntries(diaryProvider.allEntries);

      if (entries.isEmpty) {
        _showError('没有可导出的记录');
        return;
      }

      String filePath;

      // 模拟导出进度
      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 100));
        setState(() {
          _exportProgress = i / 100;
          _exportStatus = '正在处理数据... $i%';
        });
      }

      // 执行导出
      setState(() {
        _exportStatus = '正在生成文件...';
      });

      switch (_selectedFormat) {
        case ExportFormat.word:
          // Word 导出功能待实现
          _showError('Word 格式导出功能暂未实现');
          return;
        case ExportFormat.excel:
          filePath = await ExportUtils.exportToExcel(
            entries: entries,
            title: '工作日记导出',
            includeTags: _includeTags,
            includeNotes: _includeNotes,
          );
          break;
        case ExportFormat.pdf:
        case ExportFormat.json:
          _showError('此格式暂不支持');
          return;
      }

      setState(() {
        _exportStatus = '导出完成！';
      });

      // 显示成功对话框
      _showExportSuccess(filePath);
    } catch (e) {
      _showError('导出失败: $e');
    } finally {
      setState(() {
        _isExporting = false;
        _exportProgress = 0.0;
        _exportStatus = '';
      });
    }
  }

  /// 显示导出成功对话框
  void _showExportSuccess(String filePath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('文件已导出到:'),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(filePath, style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // 可以在这里添加分享文件的功能
            },
            child: const Text('分享'),
          ),
        ],
      ),
    );
  }

  /// 显示错误信息
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }
}

/// 导出格式枚举
enum ExportFormat { pdf, excel, word, json }

/// 时间范围枚举
enum DateRange { all, thisMonth, lastMonth, custom }
