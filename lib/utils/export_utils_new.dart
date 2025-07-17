import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/diary_entry.dart';
import '../constants/app_constants.dart';
import 'date_utils.dart';

/// 导出工具类
/// 提供Excel、Word、JSON等格式的导出工具函数
class ExportUtils {
  /// 生成文件名
  static String generateFileName({
    required String baseFileName,
    required String extension,
    DateTime? date,
  }) {
    final dateStr = date != null
        ? DateUtils.formatCustom(date, 'yyyy-MM-dd_HHmmss')
        : DateUtils.formatCustom(DateTime.now(), 'yyyy-MM-dd_HHmmss');

    return '${baseFileName}_$dateStr.$extension';
  }

  /// 获取导出目录
  static Future<Directory> getExportDirectory() async {
    if (Platform.isAndroid) {
      // Android: 尝试使用Downloads目录
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
    }

    // 备选方案：使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 分享文件
  static Future<void> shareFile(
    String filePath, {
    String? subject,
    String? text,
  }) async {
    await Share.shareXFiles(
      [XFile(filePath)],
      subject: subject ?? '工作日记导出',
      text: text ?? '分享我的工作日记',
    );
  }

  /// 转换日记条目为JSON Map
  static Map<String, dynamic> entryToJsonMap(DiaryEntry entry) {
    return {
      'id': entry.id,
      'title': entry.title,
      'content': entry.content,
      'date': entry.date.toIso8601String(),
      'tags': entry.tags,
      'notes': entry.notes,
      'createdAt': entry.createdAt.toIso8601String(),
      'updatedAt': entry.updatedAt.toIso8601String(),
    };
  }

  /// 导出为JSON格式
  static Future<String> exportToJson({
    required List<DiaryEntry> entries,
    required String fileName,
    Map<String, dynamic>? metadata,
  }) async {
    final directory = await getExportDirectory();
    final filePath = '${directory.path}/$fileName';

    final exportData = {
      'metadata': {
        'exportDate': DateTime.now().toIso8601String(),
        'totalEntries': entries.length,
        'version': '1.0',
        ...?metadata,
      },
      'entries': entries.map((entry) => entryToJsonMap(entry)).toList(),
    };

    final file = File(filePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportData),
      encoding: utf8,
    );

    return filePath;
  }

  /// 筛选日记条目
  static List<DiaryEntry> filterEntries(
    List<DiaryEntry> entries, {
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
    String? searchTerm,
  }) {
    return entries.where((entry) {
      // 日期筛选
      if (startDate != null && entry.date.isBefore(startDate)) {
        return false;
      }
      if (endDate != null && entry.date.isAfter(endDate)) {
        return false;
      }

      // 标签筛选
      if (tags != null && tags.isNotEmpty) {
        if (!tags.any((tag) => entry.tags.contains(tag))) {
          return false;
        }
      }

      // 搜索词筛选
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final searchLower = searchTerm.toLowerCase();
        if (!entry.title.toLowerCase().contains(searchLower) &&
            !entry.content.toLowerCase().contains(searchLower)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// 排序日记条目
  static List<DiaryEntry> sortEntries(
    List<DiaryEntry> entries,
    SortOrder sortOrder,
  ) {
    final sortedEntries = List<DiaryEntry>.from(entries);

    switch (sortOrder) {
      case SortOrder.newest:
        sortedEntries.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOrder.oldest:
        sortedEntries.sort((a, b) => a.date.compareTo(b.date));
        break;
    }

    return sortedEntries;
  }

  /// 获取文件大小（人类可读格式）
  static String getFileSize(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) return '0 B';

    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// 验证文件是否存在
  static bool fileExists(String filePath) {
    return File(filePath).existsSync();
  }

  /// 删除文件
  static Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
