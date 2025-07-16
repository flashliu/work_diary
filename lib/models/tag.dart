// 标签模型
class Tag {
  final int? id;
  final String name;
  final String color;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastUsedAt;

  Tag({
    this.id,
    required this.name,
    required this.color,
    this.usageCount = 0,
    required this.createdAt,
    this.lastUsedAt,
  });

  // 从 Map 创建 Tag
  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      usageCount: map['usage_count'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.parse(map['last_used_at'])
          : null,
    );
  }

  // 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'last_used_at': lastUsedAt?.toIso8601String(),
    };
  }

  // 创建副本
  Tag copyWith({
    int? id,
    String? name,
    String? color,
    int? usageCount,
    DateTime? createdAt,
    DateTime? lastUsedAt,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  @override
  String toString() {
    return 'Tag{id: $id, name: $name, color: $color, usageCount: $usageCount}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tag &&
        other.id == id &&
        other.name == name &&
        other.color == color;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ color.hashCode;
  }
}
