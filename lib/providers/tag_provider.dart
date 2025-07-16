import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../services/tag_service.dart';

/// 标签状态管理类
/// 负责管理标签列表、标签选择状态等
class TagProvider extends ChangeNotifier {
  final TagService _tagService = TagService();

  // 标签列表
  List<Tag> _tags = [];

  // 选中的标签
  final List<Tag> _selectedTags = [];

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // 排序方式
  TagSort _sortBy = TagSort.nameAsc;

  // 预定义的标签颜色
  static const List<String> defaultColors = [
    '#FF6B6B', // 红色
    '#4ECDC4', // 青色
    '#45B7D1', // 蓝色
    '#96CEB4', // 绿色
    '#FFEAA7', // 黄色
    '#DDA0DD', // 紫色
    '#FFB347', // 橙色
    '#FF69B4', // 粉色
    '#87CEEB', // 天蓝色
    '#98FB98', // 浅绿色
    '#F0E68C', // 卡其色
    '#DEB887', // 棕色
  ];

  // Getters
  List<Tag> get tags => _tags;
  List<Tag> get selectedTags => _selectedTags;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  TagSort get sortBy => _sortBy;

  // 获取常用标签（按使用次数排序）
  List<Tag> get popularTags {
    final sorted = List<Tag>.from(_tags)
      ..sort((a, b) => b.usageCount.compareTo(a.usageCount));
    return sorted.take(10).toList();
  }

  // 获取最近使用的标签
  List<Tag> get recentTags {
    final recentTags = _tags.where((tag) => tag.lastUsedAt != null).toList()
      ..sort((a, b) => b.lastUsedAt!.compareTo(a.lastUsedAt!));
    return recentTags.take(10).toList();
  }

  // 获取标签统计
  Map<String, dynamic> get statistics {
    final totalTags = _tags.length;
    final usedTags = _tags.where((tag) => tag.usageCount > 0).length;
    final unusedTags = totalTags - usedTags;
    final averageUsage = totalTags > 0
        ? _tags.map((tag) => tag.usageCount).reduce((a, b) => a + b) / totalTags
        : 0.0;

    return {
      'total': totalTags,
      'used': usedTags,
      'unused': unusedTags,
      'averageUsage': averageUsage,
      'mostUsed': _tags.isNotEmpty
          ? _tags.reduce((a, b) => a.usageCount > b.usageCount ? a : b)
          : null,
    };
  }

  /// 加载所有标签
  Future<void> loadTags() async {
    _setLoading(true);
    _clearError();

    try {
      _tags = await _tagService.getAllTags();
      _applySorting();
    } catch (e) {
      _setError('加载标签失败: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// 创建新标签
  Future<Tag?> createTag(String name, {String? color}) async {
    _setLoading(true);
    _clearError();

    try {
      // 检查标签是否已存在
      if (_tags.any((tag) => tag.name.toLowerCase() == name.toLowerCase())) {
        _setError('标签已存在');
        return null;
      }

      final tag = Tag(
        name: name,
        color: color ?? _getNextAvailableColor(),
        createdAt: DateTime.now(),
      );

      final id = await _tagService.createTag(tag);
      final newTag = tag.copyWith(id: id);

      _tags.add(newTag);
      _applySorting();

      return newTag;
    } catch (e) {
      _setError('创建标签失败: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// 更新标签
  Future<bool> updateTag(Tag tag) async {
    _setLoading(true);
    _clearError();

    try {
      await _tagService.updateTag(tag);

      final index = _tags.indexWhere((t) => t.id == tag.id);
      if (index != -1) {
        _tags[index] = tag;
        _applySorting();
      }

      return true;
    } catch (e) {
      _setError('更新标签失败: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 删除标签
  Future<bool> deleteTag(int id) async {
    _setLoading(true);
    _clearError();

    try {
      await _tagService.deleteTag(id);

      _tags.removeWhere((tag) => tag.id == id);
      _selectedTags.removeWhere((tag) => tag.id == id);

      notifyListeners();
      return true;
    } catch (e) {
      _setError('删除标签失败: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// 选择标签
  void selectTag(Tag tag) {
    if (!_selectedTags.contains(tag)) {
      _selectedTags.add(tag);
      notifyListeners();
    }
  }

  /// 取消选择标签
  void unselectTag(Tag tag) {
    _selectedTags.remove(tag);
    notifyListeners();
  }

  /// 切换标签选择状态
  void toggleTagSelection(Tag tag) {
    if (_selectedTags.contains(tag)) {
      unselectTag(tag);
    } else {
      selectTag(tag);
    }
  }

  /// 选择多个标签
  void selectTags(List<Tag> tags) {
    for (final tag in tags) {
      if (!_selectedTags.contains(tag)) {
        _selectedTags.add(tag);
      }
    }
    notifyListeners();
  }

  /// 清除所有选择
  void clearSelection() {
    _selectedTags.clear();
    notifyListeners();
  }

  /// 设置排序方式
  void setSortBy(TagSort sort) {
    _sortBy = sort;
    _applySorting();
  }

  /// 搜索标签
  List<Tag> searchTags(String query) {
    if (query.isEmpty) return _tags;

    return _tags.where((tag) {
      return tag.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// 根据名称查找标签
  Tag? findTagByName(String name) {
    try {
      return _tags.firstWhere(
        (tag) => tag.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// 根据ID查找标签
  Tag? findTagById(int id) {
    try {
      return _tags.firstWhere((tag) => tag.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 获取标签颜色选项
  List<String> getColorOptions() {
    return defaultColors;
  }

  /// 获取下一个可用的颜色
  String _getNextAvailableColor() {
    final usedColors = _tags.map((tag) => tag.color).toSet();

    for (final color in defaultColors) {
      if (!usedColors.contains(color)) {
        return color;
      }
    }

    // 如果所有预定义颜色都被使用了，返回第一个颜色
    return defaultColors.first;
  }

  /// 应用排序
  void _applySorting() {
    _tags.sort((a, b) {
      switch (_sortBy) {
        case TagSort.nameAsc:
          return a.name.compareTo(b.name);
        case TagSort.nameDesc:
          return b.name.compareTo(a.name);
        case TagSort.usageAsc:
          return a.usageCount.compareTo(b.usageCount);
        case TagSort.usageDesc:
          return b.usageCount.compareTo(a.usageCount);
        case TagSort.createdAsc:
          return a.createdAt.compareTo(b.createdAt);
        case TagSort.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case TagSort.lastUsedAsc:
          final aLastUsed =
              a.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bLastUsed =
              b.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return aLastUsed.compareTo(bLastUsed);
        case TagSort.lastUsedDesc:
          final aLastUsed =
              a.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bLastUsed =
              b.lastUsedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bLastUsed.compareTo(aLastUsed);
      }
    });

    notifyListeners();
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
}

/// 标签排序方式枚举
enum TagSort {
  nameAsc,
  nameDesc,
  usageAsc,
  usageDesc,
  createdAsc,
  createdDesc,
  lastUsedAsc,
  lastUsedDesc,
}

/// 标签排序方式扩展
extension TagSortExtension on TagSort {
  String get displayName {
    switch (this) {
      case TagSort.nameAsc:
        return '名称升序';
      case TagSort.nameDesc:
        return '名称降序';
      case TagSort.usageAsc:
        return '使用次数升序';
      case TagSort.usageDesc:
        return '使用次数降序';
      case TagSort.createdAsc:
        return '创建时间升序';
      case TagSort.createdDesc:
        return '创建时间降序';
      case TagSort.lastUsedAsc:
        return '最后使用时间升序';
      case TagSort.lastUsedDesc:
        return '最后使用时间降序';
    }
  }

  IconData get icon {
    switch (this) {
      case TagSort.nameAsc:
      case TagSort.nameDesc:
        return Icons.sort_by_alpha;
      case TagSort.usageAsc:
      case TagSort.usageDesc:
        return Icons.bar_chart;
      case TagSort.createdAsc:
      case TagSort.createdDesc:
        return Icons.add_circle;
      case TagSort.lastUsedAsc:
      case TagSort.lastUsedDesc:
        return Icons.access_time;
    }
  }
}
