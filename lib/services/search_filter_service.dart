import '../models/diary_entry.dart';

/// 搜索筛选服务类
/// 提供全文搜索、标签筛选、日期范围筛选等功能
class SearchFilterService {
  // 单例模式
  static final SearchFilterService _instance = SearchFilterService._internal();
  factory SearchFilterService() => _instance;
  SearchFilterService._internal();

  /// 全文搜索日记
  ///
  /// [entries] 要搜索的日记列表
  /// [keyword] 搜索关键词
  /// [searchInTitle] 是否在标题中搜索
  /// [searchInContent] 是否在内容中搜索
  /// [searchInTags] 是否在标签中搜索
  List<DiaryEntry> searchDiaries({
    required List<DiaryEntry> entries,
    required String keyword,
    bool searchInTitle = true,
    bool searchInContent = true,
    bool searchInTags = true,
  }) {
    if (keyword.trim().isEmpty) {
      return entries;
    }

    final searchKeyword = keyword.trim().toLowerCase();

    return entries.where((entry) {
      // 在标题中搜索
      if (searchInTitle && entry.title.toLowerCase().contains(searchKeyword)) {
        return true;
      }

      // 在内容中搜索
      if (searchInContent &&
          entry.content.toLowerCase().contains(searchKeyword)) {
        return true;
      }

      // 在标签中搜索
      if (searchInTags) {
        for (final tag in entry.tags) {
          if (tag.toLowerCase().contains(searchKeyword)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  /// 按标签筛选日记
  ///
  /// [entries] 要筛选的日记列表
  /// [selectedTags] 选中的标签列表
  /// [matchAll] 是否需要匹配所有标签（true=AND，false=OR）
  List<DiaryEntry> filterByTags({
    required List<DiaryEntry> entries,
    required List<String> selectedTags,
    bool matchAll = false,
  }) {
    if (selectedTags.isEmpty) {
      return entries;
    }

    return entries.where((entry) {
      if (matchAll) {
        // AND 模式：必须包含所有选中的标签
        return selectedTags.every((tag) => entry.tags.contains(tag));
      } else {
        // OR 模式：包含任意一个选中的标签
        return selectedTags.any((tag) => entry.tags.contains(tag));
      }
    }).toList();
  }

  /// 按日期范围筛选日记
  ///
  /// [entries] 要筛选的日记列表
  /// [startDate] 开始日期
  /// [endDate] 结束日期
  List<DiaryEntry> filterByDateRange({
    required List<DiaryEntry> entries,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    if (startDate == null && endDate == null) {
      return entries;
    }

    return entries.where((entry) {
      if (startDate != null && entry.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && entry.date.isAfter(endDate)) {
        return false;
      }
      return true;
    }).toList();
  }

  /// 高级筛选
  ///
  /// [entries] 要筛选的日记列表
  /// [filters] 筛选条件
  List<DiaryEntry> advancedFilter({
    required List<DiaryEntry> entries,
    required AdvancedFilterOptions filters,
  }) {
    var result = entries;

    // 关键词搜索
    if (filters.keyword?.isNotEmpty == true) {
      result = searchDiaries(
        entries: result,
        keyword: filters.keyword!,
        searchInTitle: filters.searchInTitle,
        searchInContent: filters.searchInContent,
        searchInTags: filters.searchInTags,
      );
    }

    // 标签筛选
    if (filters.selectedTags.isNotEmpty) {
      result = filterByTags(
        entries: result,
        selectedTags: filters.selectedTags,
        matchAll: filters.matchAllTags,
      );
    }

    // 日期范围筛选
    result = filterByDateRange(
      entries: result,
      startDate: filters.startDate,
      endDate: filters.endDate,
    );

    // 内容长度筛选
    if (filters.minContentLength != null || filters.maxContentLength != null) {
      result = result.where((entry) {
        final contentLength = entry.content.length;
        if (filters.minContentLength != null &&
            contentLength < filters.minContentLength!) {
          return false;
        }
        if (filters.maxContentLength != null &&
            contentLength > filters.maxContentLength!) {
          return false;
        }
        return true;
      }).toList();
    }

    // 标签数量筛选
    if (filters.minTagCount != null || filters.maxTagCount != null) {
      result = result.where((entry) {
        final tagCount = entry.tags.length;
        if (filters.minTagCount != null && tagCount < filters.minTagCount!) {
          return false;
        }
        if (filters.maxTagCount != null && tagCount > filters.maxTagCount!) {
          return false;
        }
        return true;
      }).toList();
    }

    return result;
  }

  /// 排序日记
  ///
  /// [entries] 要排序的日记列表
  /// [sortBy] 排序字段
  /// [ascending] 是否升序
  List<DiaryEntry> sortDiaries({
    required List<DiaryEntry> entries,
    required SortField sortBy,
    bool ascending = true,
  }) {
    final sortedEntries = List<DiaryEntry>.from(entries);

    switch (sortBy) {
      case SortField.date:
        sortedEntries.sort(
          (a, b) =>
              ascending ? a.date.compareTo(b.date) : b.date.compareTo(a.date),
        );
        break;
      case SortField.title:
        sortedEntries.sort(
          (a, b) => ascending
              ? a.title.compareTo(b.title)
              : b.title.compareTo(a.title),
        );
        break;
      case SortField.contentLength:
        sortedEntries.sort(
          (a, b) => ascending
              ? a.content.length.compareTo(b.content.length)
              : b.content.length.compareTo(a.content.length),
        );
        break;
      case SortField.tagCount:
        sortedEntries.sort(
          (a, b) => ascending
              ? a.tags.length.compareTo(b.tags.length)
              : b.tags.length.compareTo(a.tags.length),
        );
        break;
      case SortField.createdAt:
        sortedEntries.sort(
          (a, b) => ascending
              ? a.createdAt.compareTo(b.createdAt)
              : b.createdAt.compareTo(a.createdAt),
        );
        break;
      case SortField.updatedAt:
        sortedEntries.sort(
          (a, b) => ascending
              ? a.updatedAt.compareTo(b.updatedAt)
              : b.updatedAt.compareTo(a.updatedAt),
        );
        break;
    }

    return sortedEntries;
  }

  /// 获取搜索建议
  ///
  /// [entries] 日记列表
  /// [keyword] 当前输入的关键词
  /// [maxSuggestions] 最大建议数量
  List<String> getSearchSuggestions({
    required List<DiaryEntry> entries,
    required String keyword,
    int maxSuggestions = 10,
  }) {
    if (keyword.trim().isEmpty) {
      return [];
    }

    final suggestions = <String>[];
    final keywordLower = keyword.toLowerCase();

    // 从标题中提取建议
    for (final entry in entries) {
      final words = entry.title.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.toLowerCase().contains(keywordLower) &&
            word.length > keyword.length &&
            !suggestions.contains(word)) {
          suggestions.add(word);
        }
      }
    }

    // 从标签中提取建议
    final allTags = <String>{};
    for (final entry in entries) {
      allTags.addAll(entry.tags);
    }

    for (final tag in allTags) {
      if (tag.toLowerCase().contains(keywordLower) &&
          !suggestions.contains(tag)) {
        suggestions.add(tag);
      }
    }

    // 限制数量并排序
    suggestions.sort((a, b) => a.length.compareTo(b.length));
    return suggestions.take(maxSuggestions).toList();
  }

  /// 获取热门标签
  ///
  /// [entries] 日记列表
  /// [maxTags] 最大标签数量
  List<TagUsage> getPopularTags({
    required List<DiaryEntry> entries,
    int maxTags = 20,
  }) {
    final tagCounts = <String, int>{};

    // 统计标签使用次数
    for (final entry in entries) {
      for (final tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    // 转换为TagUsage列表并排序
    final tagUsages = tagCounts.entries
        .map(
          (entry) => TagUsage(
            tag: entry.key,
            count: entry.value,
            percentage: entry.value / entries.length,
          ),
        )
        .toList();

    tagUsages.sort((a, b) => b.count.compareTo(a.count));
    return tagUsages.take(maxTags).toList();
  }

  /// 获取搜索统计信息
  ///
  /// [originalEntries] 原始日记列表
  /// [filteredEntries] 筛选后的日记列表
  /// [filters] 筛选条件
  SearchStatistics getSearchStatistics({
    required List<DiaryEntry> originalEntries,
    required List<DiaryEntry> filteredEntries,
    required AdvancedFilterOptions filters,
  }) {
    return SearchStatistics(
      totalEntries: originalEntries.length,
      filteredEntries: filteredEntries.length,
      filterRatio: originalEntries.isEmpty
          ? 0.0
          : filteredEntries.length / originalEntries.length,
      hasActiveFilters: filters.hasActiveFilters,
    );
  }
}

/// 高级筛选选项
class AdvancedFilterOptions {
  final String? keyword;
  final bool searchInTitle;
  final bool searchInContent;
  final bool searchInTags;
  final List<String> selectedTags;
  final bool matchAllTags;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? minContentLength;
  final int? maxContentLength;
  final int? minTagCount;
  final int? maxTagCount;

  const AdvancedFilterOptions({
    this.keyword,
    this.searchInTitle = true,
    this.searchInContent = true,
    this.searchInTags = true,
    this.selectedTags = const [],
    this.matchAllTags = false,
    this.startDate,
    this.endDate,
    this.minContentLength,
    this.maxContentLength,
    this.minTagCount,
    this.maxTagCount,
  });

  /// 是否有激活的筛选条件
  bool get hasActiveFilters {
    return keyword?.isNotEmpty == true ||
        selectedTags.isNotEmpty ||
        startDate != null ||
        endDate != null ||
        minContentLength != null ||
        maxContentLength != null ||
        minTagCount != null ||
        maxTagCount != null;
  }

  /// 复制并修改选项
  AdvancedFilterOptions copyWith({
    String? keyword,
    bool? searchInTitle,
    bool? searchInContent,
    bool? searchInTags,
    List<String>? selectedTags,
    bool? matchAllTags,
    DateTime? startDate,
    DateTime? endDate,
    int? minContentLength,
    int? maxContentLength,
    int? minTagCount,
    int? maxTagCount,
  }) {
    return AdvancedFilterOptions(
      keyword: keyword ?? this.keyword,
      searchInTitle: searchInTitle ?? this.searchInTitle,
      searchInContent: searchInContent ?? this.searchInContent,
      searchInTags: searchInTags ?? this.searchInTags,
      selectedTags: selectedTags ?? this.selectedTags,
      matchAllTags: matchAllTags ?? this.matchAllTags,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minContentLength: minContentLength ?? this.minContentLength,
      maxContentLength: maxContentLength ?? this.maxContentLength,
      minTagCount: minTagCount ?? this.minTagCount,
      maxTagCount: maxTagCount ?? this.maxTagCount,
    );
  }
}

/// 排序字段枚举
enum SortField { date, title, contentLength, tagCount, createdAt, updatedAt }

/// 标签使用统计
class TagUsage {
  final String tag;
  final int count;
  final double percentage;

  const TagUsage({
    required this.tag,
    required this.count,
    required this.percentage,
  });
}

/// 搜索统计信息
class SearchStatistics {
  final int totalEntries;
  final int filteredEntries;
  final double filterRatio;
  final bool hasActiveFilters;

  const SearchStatistics({
    required this.totalEntries,
    required this.filteredEntries,
    required this.filterRatio,
    required this.hasActiveFilters,
  });
}
