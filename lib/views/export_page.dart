import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/diary_provider.dart';
import '../providers/tag_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/export/index.dart';
import '../constants/app_constants.dart';
import '../models/diary_entry.dart';
import '../services/export_service.dart';

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
  bool _includeCreatedAt = false;
  bool _includeUpdatedAt = false;

  // 导出设置
  SortOrder _sortOrder = SortOrder.newest;
  int _pageSize = 0;
  bool _includeCoverPage = true;
  bool _includeStatistics = false;

  // 导出状态
  ExportStatus _exportStatus = ExportStatus.idle;
  double _exportProgress = 0.0;
  String _statusMessage = '';

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
                onPressed: _resetOptions,
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
                  FormatSelectionWidget(
                    selectedFormat: _selectedFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _selectedFormat = format;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 时间范围选择
                  DateRangeSelectionWidget(
                    selectedDateRange: _selectedDateRange,
                    startDate: _startDate,
                    endDate: _endDate,
                    onDateRangeChanged: (range) {
                      setState(() {
                        _selectedDateRange = range;
                      });
                    },
                    onStartDateChanged: (date) {
                      setState(() {
                        _startDate = date;
                      });
                    },
                    onEndDateChanged: (date) {
                      setState(() {
                        _endDate = date;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 导出内容选择
                  ContentOptionsWidget(
                    includeDate: _includeDate,
                    includeContent: _includeContent,
                    includeTags: _includeTags,
                    includeNotes: _includeNotes,
                    includeCreatedAt: _includeCreatedAt,
                    includeUpdatedAt: _includeUpdatedAt,
                    onIncludeDateChanged: (value) {
                      setState(() {
                        _includeDate = value;
                      });
                    },
                    onIncludeContentChanged: (value) {
                      setState(() {
                        _includeContent = value;
                      });
                    },
                    onIncludeTagsChanged: (value) {
                      setState(() {
                        _includeTags = value;
                      });
                    },
                    onIncludeNotesChanged: (value) {
                      setState(() {
                        _includeNotes = value;
                      });
                    },
                    onIncludeCreatedAtChanged: (value) {
                      setState(() {
                        _includeCreatedAt = value;
                      });
                    },
                    onIncludeUpdatedAtChanged: (value) {
                      setState(() {
                        _includeUpdatedAt = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 导出设置
                  ExportSettingsWidget(
                    sortOrder: _sortOrder,
                    pageSize: _pageSize,
                    includeCoverPage: _includeCoverPage,
                    includeStatistics: _includeStatistics,
                    onSortOrderChanged: (order) {
                      setState(() {
                        _sortOrder = order;
                      });
                    },
                    onPageSizeChanged: (size) {
                      setState(() {
                        _pageSize = size;
                      });
                    },
                    onIncludeCoverPageChanged: (value) {
                      setState(() {
                        _includeCoverPage = value;
                      });
                    },
                    onIncludeStatisticsChanged: (value) {
                      setState(() {
                        _includeStatistics = value;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // 导出进度 (条件显示)
                  ExportProgressWidget(
                    status: _exportStatus,
                    progress: _exportProgress,
                    statusMessage: _statusMessage,
                  ),

                  const SizedBox(height: 80), // 为底部按钮留出空间
                ],
              ),
            ),
          ),

          // 底部导出按钮
          _buildFloatingExportButton(),
        ],
      ),
    );
  }

  /// 重置选项
  void _resetOptions() {
    setState(() {
      _selectedFormat = ExportFormat.word;
      _selectedDateRange = DateRange.all;
      _startDate = null;
      _endDate = null;
      _includeDate = true;
      _includeContent = true;
      _includeTags = true;
      _includeNotes = true;
      _includeCreatedAt = false;
      _includeUpdatedAt = false;
      _sortOrder = SortOrder.newest;
      _pageSize = 0;
      _includeCoverPage = true;
      _includeStatistics = false;
    });
  }

  /// 构建浮动导出按钮
  Widget _buildFloatingExportButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Consumer<DiaryProvider>(
        builder: (context, diaryProvider, child) {
          final recordCount = _getFilteredDiaryEntries(diaryProvider).length;
          final estimatedSize = _calculateEstimatedSize(recordCount);
          final estimatedTime = _calculateEstimatedTime(recordCount);

          return ExportButtonWidget(
            isExporting:
                _exportStatus == ExportStatus.preparing ||
                _exportStatus == ExportStatus.exporting,
            recordCount: recordCount,
            estimatedSize: estimatedSize,
            estimatedTime: estimatedTime,
            onExport: () => _startExport(diaryProvider),
          );
        },
      ),
    );
  }

  /// 获取筛选后的日记列表
  List<DiaryEntry> _getFilteredDiaryEntries(DiaryProvider diaryProvider) {
    List<DiaryEntry> entries = diaryProvider.diaryEntries;

    // 按时间范围筛选
    switch (_selectedDateRange) {
      case DateRange.thisMonth:
        entries = diaryProvider.getEntriesThisMonth();
        break;
      case DateRange.lastMonth:
        entries = diaryProvider.getEntriesLastMonth();
        break;
      case DateRange.custom:
        if (_startDate != null && _endDate != null) {
          entries = entries.where((entry) {
            return entry.date.isAfter(
                  _startDate!.subtract(const Duration(days: 1)),
                ) &&
                entry.date.isBefore(_endDate!.add(const Duration(days: 1)));
          }).toList();
        }
        break;
      case DateRange.thisWeek:
        // 本周筛选：从本周一开始到今天
        final now = DateTime.now();
        final weekday = now.weekday; // 1 = Monday, 7 = Sunday
        final startOfWeek = now.subtract(Duration(days: weekday - 1));
        final startOfWeekDate = DateTime(
          startOfWeek.year,
          startOfWeek.month,
          startOfWeek.day,
        );
        final endOfWeekDate = DateTime(
          now.year,
          now.month,
          now.day,
          23,
          59,
          59,
        );

        entries = entries.where((entry) {
          return !entry.date.isBefore(startOfWeekDate) &&
              !entry.date.isAfter(endOfWeekDate);
        }).toList();
        break;
      case DateRange.lastWeek:
        // 上周筛选：上周一到上周日
        final now = DateTime.now();
        final weekday = now.weekday; // 1 = Monday, 7 = Sunday
        final startOfThisWeek = now.subtract(Duration(days: weekday - 1));
        final startOfLastWeek = startOfThisWeek.subtract(
          const Duration(days: 7),
        );
        final endOfLastWeek = startOfThisWeek.subtract(const Duration(days: 1));

        final startOfLastWeekDate = DateTime(
          startOfLastWeek.year,
          startOfLastWeek.month,
          startOfLastWeek.day,
        );
        final endOfLastWeekDate = DateTime(
          endOfLastWeek.year,
          endOfLastWeek.month,
          endOfLastWeek.day,
          23,
          59,
          59,
        );

        entries = entries.where((entry) {
          return !entry.date.isBefore(startOfLastWeekDate) &&
              !entry.date.isAfter(endOfLastWeekDate);
        }).toList();
        break;
      case DateRange.all:
        // 使用所有记录
        break;
    }

    // 排序
    switch (_sortOrder) {
      case SortOrder.newest:
        entries.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOrder.oldest:
        entries.sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    return entries;
  }

  /// 计算预估文件大小
  String _calculateEstimatedSize(int recordCount) {
    if (recordCount == 0) return '0KB';

    double sizeKB = recordCount * 15; // 每条记录约15KB

    if (sizeKB < 1024) {
      return '${sizeKB.toInt()}KB';
    } else if (sizeKB < 1024 * 1024) {
      return '${(sizeKB / 1024).toStringAsFixed(1)}MB';
    } else {
      return '${(sizeKB / (1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 计算预估时间
  String _calculateEstimatedTime(int recordCount) {
    if (recordCount == 0) return '0秒';

    int seconds = (recordCount / 50).ceil(); // 假设每秒处理50条记录

    if (seconds < 60) {
      return '$seconds秒';
    } else {
      int minutes = seconds ~/ 60;
      int remainingSeconds = seconds % 60;
      return remainingSeconds > 0
          ? '$minutes分$remainingSeconds秒'
          : '$minutes分钟';
    }
  }

  /// 开始导出
  Future<void> _startExport(DiaryProvider diaryProvider) async {
    try {
      setState(() {
        _exportStatus = ExportStatus.preparing;
        _exportProgress = 0.0;
        _statusMessage = '正在准备数据...';
      });

      final entries = _getFilteredDiaryEntries(diaryProvider);

      if (entries.isEmpty) {
        _showSnackBar('没有找到符合条件的日记记录', isError: true);
        setState(() {
          _exportStatus = ExportStatus.idle;
        });
        return;
      }

      // 模拟导出过程
      setState(() {
        _exportStatus = ExportStatus.exporting;
        _statusMessage = '正在生成文件...';
      });

      for (int i = 0; i <= 100; i += 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _exportProgress = i / 100;
        });
      }

      // 执行简单的导出逻辑
      await _performExport(entries);

      setState(() {
        _exportStatus = ExportStatus.completed;
        _statusMessage = '导出完成！文件已保存到下载文件夹';
      });

      _showSnackBar('导出成功！文件已保存');

      // 3秒后重置状态
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _exportStatus = ExportStatus.idle;
            _exportProgress = 0.0;
            _statusMessage = '';
          });
        }
      });
    } catch (e) {
      setState(() {
        _exportStatus = ExportStatus.error;
        _statusMessage = '导出失败: ${e.toString()}';
      });

      _showSnackBar('导出失败: ${e.toString()}', isError: true);

      // 5秒后重置状态
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            _exportStatus = ExportStatus.idle;
            _exportProgress = 0.0;
            _statusMessage = '';
          });
        }
      });
    }
  }

  /// 执行导出操作
  Future<void> _performExport(List<DiaryEntry> entries) async {
    try {
      final exportService = ExportService();

      final options = ExportOptions(
        includeDate: _includeDate,
        includeContent: _includeContent,
        includeTags: _includeTags,
        includeNotes: _includeNotes,
        includeCreatedAt: _includeCreatedAt,
        includeUpdatedAt: _includeUpdatedAt,
        includeCoverPage: _includeCoverPage,
        includeStatistics: _includeStatistics,
        sortOrder: _sortOrder,
        pageSize: _pageSize,
      );

      final filePath = await exportService.exportDiaries(
        entries: entries,
        format: _selectedFormat,
        options: options,
        onProgress: (progress, message) {
          if (mounted) {
            setState(() {
              _exportProgress = progress;
              _statusMessage = message;
            });
          }
        },
      );

      debugPrint('导出完成，文件路径：$filePath');
    } catch (e) {
      debugPrint('导出失败：$e');
      rethrow;
    }
  }

  /// 显示提示信息
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }
}
