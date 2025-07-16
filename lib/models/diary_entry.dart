// 日记实体模型
class DiaryEntry {
  final int? id;
  final String title;
  final String content;
  final DateTime date;
  final List<String> tags;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  DiaryEntry({
    this.id,
    required this.title,
    required this.content,
    required this.date,
    this.tags = const [],
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // 从 Map 创建 DiaryEntry
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    return DiaryEntry(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      date: DateTime.parse(map['date']),
      tags: map['tags'] != null
          ? List<String>.from(map['tags'].split(','))
          : [],
      notes: map['notes'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date.toIso8601String(),
      'tags': tags.join(','),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // 创建副本
  DiaryEntry copyWith({
    int? id,
    String? title,
    String? content,
    DateTime? date,
    List<String>? tags,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'DiaryEntry{id: $id, title: $title, date: $date, tags: $tags}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry &&
        other.id == id &&
        other.title == title &&
        other.content == content &&
        other.date == date;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ content.hashCode ^ date.hashCode;
  }

  // 获取内容预览
  String get contentPreview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // 获取标签字符串
  String get tagsString {
    return tags.join(', ');
  }

  // 检查是否包含关键词
  bool containsKeyword(String keyword) {
    final lowerKeyword = keyword.toLowerCase();
    return title.toLowerCase().contains(lowerKeyword) ||
        content.toLowerCase().contains(lowerKeyword) ||
        tags.any((tag) => tag.toLowerCase().contains(lowerKeyword));
  }

  // 检查是否包含标签
  bool containsTag(String tag) {
    return tags.contains(tag);
  }

  // 检查是否在指定日期范围内
  bool isInDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate != null && date.isBefore(startDate)) return false;
    if (endDate != null && date.isAfter(endDate)) return false;
    return true;
  }
}
