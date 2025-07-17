import 'package:flutter/material.dart';
import '../models/diary_entry.dart';
import '../services/diary_service.dart';

/// 日记筛选类型
enum DiaryFilterType { all, thisWeek, thisMonth }

/// 日记状态管理类
/// 负责管理日记列表、当前选中日记、筛选和搜索状态
class DiaryProvider extends ChangeNotifier {
  final DiaryService _diaryService = DiaryService();

  // 日记列表状态
  List<DiaryEntry> _diaryEntries = [];
  List<DiaryEntry> _filteredEntries = [];

  // 当前选中的日记
  DiaryEntry? _selectedEntry;

  // 筛选和搜索状态
  String _searchQuery = '';
  List<String> _selectedTags = [];
  DateTimeRange? _dateRange;
  DiaryFilterType _filterType = DiaryFilterType.all;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // 排序方式
  DiarySort _sortBy = DiarySort.dateDesc;

  // Getters
  List<DiaryEntry> get diaryEntries => _filteredEntries;
  List<DiaryEntry> get allEntries => _diaryEntries;
  DiaryEntry? get selectedEntry => _selectedEntry;
  String get searchQuery => _searchQuery;
  List<String> get selectedTags => _selectedTags;
  DateTimeRange? get dateRange => _dateRange;
  DiaryFilterType get filterType => _filterType;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DiarySort get sortBy => _sortBy;

  // 获取今天的日记
  DiaryEntry? get todayEntry {
    final today = DateTime.now();
    return _diaryEntries.firstWhere(
      (entry) => _isSameDay(entry.date, today),
      orElse: () => DiaryEntry(
        title: '',
        content: '',
        date: today,
        createdAt: today,
        updatedAt: today,
      ),
    );
  }

  // 获取统计信息
  int get totalEntries => _diaryEntries.length;

  int get thisMonthEntries {
    final now = DateTime.now();
    return _diaryEntries.where((entry) {
      return entry.date.year == now.year && entry.date.month == now.month;
    }).length;
  }

  int get thisWeekEntries {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return _diaryEntries.where((entry) {
      return entry.date.isAfter(
            startOfWeek.subtract(const Duration(days: 1)),
          ) &&
          entry.date.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).length;
  }

  /// 加载所有日记
  Future<void> loadDiaryEntries() async {
    _setLoading(true);
    _clearError();

    try {
      _diaryEntries = await _diaryService.getAllDiaries();
      _applyFilters();
    } catch (e) {
      _setError('加载日记失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 添加新日记
  Future<bool> addDiaryEntry(DiaryEntry entry) async {
    _setLoading(true);
    _clearError();

    try {
      final id = await _diaryService.createDiary(entry);
      final newEntry = entry.copyWith(id: id);
      _diaryEntries.add(newEntry);
      _applyFilters();
      return true;
    } catch (e) {
      _setError('添加日记失败: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新日记
  Future<bool> updateDiaryEntry(DiaryEntry entry) async {
    _setLoading(true);
    _clearError();

    try {
      await _diaryService.updateDiary(entry);
      final index = _diaryEntries.indexWhere((e) => e.id == entry.id);
      if (index != -1) {
        _diaryEntries[index] = entry;
        if (_selectedEntry?.id == entry.id) {
          _selectedEntry = entry;
        }
        _applyFilters();
      }
      return true;
    } catch (e) {
      _setError('更新日记失败: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除日记
  Future<bool> deleteDiaryEntry(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _diaryService.deleteDiary(id);
      _diaryEntries.removeWhere((entry) => entry.id == id);
      if (_selectedEntry?.id == id) {
        _selectedEntry = null;
      }
      _applyFilters();
      return true;
    } catch (e) {
      _setError('删除日记失败: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 选择日记
  void selectEntry(DiaryEntry? entry) {
    _selectedEntry = entry;
    notifyListeners();
  }

  /// 搜索日记
  void searchEntries(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// 按标签筛选
  void filterByTags(List<String> tags) {
    _selectedTags = tags;
    _applyFilters();
  }

  /// 按日期范围筛选
  void filterByDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
  }

  /// 设置排序方式
  void setSortBy(DiarySort sort) {
    _sortBy = sort;
    _applyFilters();
  }

  /// 清除所有筛选
  void clearFilters() {
    _searchQuery = '';
    _selectedTags.clear();
    _dateRange = null;
    _applyFilters();
  }

  /// 应用筛选和排序
  void _applyFilters() {
    _filteredEntries = List.from(_diaryEntries);

    // 应用时间筛选
    switch (_filterType) {
      case DiaryFilterType.thisWeek:
        final now = DateTime.now();
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        _filteredEntries = _filteredEntries.where((entry) {
          return entry.date.isAfter(
                startOfWeek.subtract(const Duration(days: 1)),
              ) &&
              entry.date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();
        break;
      case DiaryFilterType.thisMonth:
        final now = DateTime.now();
        _filteredEntries = _filteredEntries.where((entry) {
          return entry.date.year == now.year && entry.date.month == now.month;
        }).toList();
        break;
      case DiaryFilterType.all:
        break;
    }

    // 应用搜索
    if (_searchQuery.isNotEmpty) {
      _filteredEntries = _filteredEntries.where((entry) {
        return entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            entry.tags.any(
              (tag) => tag.toLowerCase().contains(_searchQuery.toLowerCase()),
            );
      }).toList();
    }

    // 应用标签筛选
    if (_selectedTags.isNotEmpty) {
      _filteredEntries = _filteredEntries.where((entry) {
        return _selectedTags.any((tag) => entry.tags.contains(tag));
      }).toList();
    }

    // 应用日期范围筛选
    if (_dateRange != null) {
      _filteredEntries = _filteredEntries.where((entry) {
        return entry.date.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1)),
            ) &&
            entry.date.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // 应用排序
    _filteredEntries.sort((a, b) {
      switch (_sortBy) {
        case DiarySort.dateAsc:
          return a.date.compareTo(b.date);
        case DiarySort.dateDesc:
          return b.date.compareTo(a.date);
        case DiarySort.titleAsc:
          return a.title.compareTo(b.title);
        case DiarySort.titleDesc:
          return b.title.compareTo(a.title);
        case DiarySort.updatedAsc:
          return a.updatedAt.compareTo(b.updatedAt);
        case DiarySort.updatedDesc:
          return b.updatedAt.compareTo(a.updatedAt);
      }
    });

    notifyListeners();
  }

  /// 获取指定日期的日记
  List<DiaryEntry> getEntriesByDate(DateTime date) {
    return _diaryEntries
        .where((entry) => _isSameDay(entry.date, date))
        .toList();
  }

  /// 获取指定月份的日记
  List<DiaryEntry> getEntriesByMonth(int year, int month) {
    return _diaryEntries.where((entry) {
      return entry.date.year == year && entry.date.month == month;
    }).toList();
  }

  /// 获取日记统计数据
  Map<String, int> getStatistics() {
    final now = DateTime.now();
    final thisMonth = getEntriesByMonth(now.year, now.month);
    final lastMonth = getEntriesByMonth(
      now.month == 1 ? now.year - 1 : now.year,
      now.month == 1 ? 12 : now.month - 1,
    );

    return {
      'total': _diaryEntries.length,
      'thisMonth': thisMonth.length,
      'lastMonth': lastMonth.length,
      'thisWeek': thisWeekEntries,
      'averagePerMonth': _diaryEntries.isNotEmpty
          ? (_diaryEntries.length / _getMonthsSinceFirst()).round()
          : 0,
    };
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  /// 清除错误信息
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// 判断两个日期是否是同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 获取自第一条日记以来的月份数
  int _getMonthsSinceFirst() {
    if (_diaryEntries.isEmpty) return 1;

    final firstEntry = _diaryEntries.reduce(
      (a, b) => a.date.isBefore(b.date) ? a : b,
    );
    final now = DateTime.now();

    int months =
        (now.year - firstEntry.date.year) * 12 +
        (now.month - firstEntry.date.month) +
        1;

    return months > 0 ? months : 1;
  }

  /// 设置筛选类型
  void setFilterType(DiaryFilterType filterType) {
    _filterType = filterType;
    _applyFilters();
    notifyListeners();
  }

  /// 搜索日记
  void searchDiaries(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }
}

/// 日记排序方式枚举
enum DiarySort {
  dateAsc,
  dateDesc,
  titleAsc,
  titleDesc,
  updatedAsc,
  updatedDesc,
}

/// 日记排序方式扩展
extension DiarySortExtension on DiarySort {
  String get displayName {
    switch (this) {
      case DiarySort.dateAsc:
        return '日期升序';
      case DiarySort.dateDesc:
        return '日期降序';
      case DiarySort.titleAsc:
        return '标题升序';
      case DiarySort.titleDesc:
        return '标题降序';
      case DiarySort.updatedAsc:
        return '更新时间升序';
      case DiarySort.updatedDesc:
        return '更新时间降序';
    }
  }

  IconData get icon {
    switch (this) {
      case DiarySort.dateAsc:
      case DiarySort.dateDesc:
        return Icons.date_range;
      case DiarySort.titleAsc:
      case DiarySort.titleDesc:
        return Icons.sort_by_alpha;
      case DiarySort.updatedAsc:
      case DiarySort.updatedDesc:
        return Icons.update;
    }
  }
}
