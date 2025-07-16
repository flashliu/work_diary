import 'dart:io';
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/diary_entry.dart';
import '../models/tag.dart';
import 'date_utils.dart';

/// 导出工具类
/// 提供PDF、Excel、Word、JSON等格式的导出功能
class ExportUtils {
  /// 导出为PDF格式
  static Future<String> exportToPDF({
    required List<DiaryEntry> entries,
    required String title,
    bool includeTags = true,
    bool includeNotes = true,
    String? author,
  }) async {
    final pdf = pw.Document();

    // 添加封面页
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '导出时间: ${DateUtils.formatDisplayDateTime(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                if (author != null) ...[
                  pw.SizedBox(height: 10),
                  pw.Text(
                    '作者: $author',
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
                pw.SizedBox(height: 20),
                pw.Text(
                  '共 ${entries.length} 篇日记',
                  style: const pw.TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );

    // 添加目录页
    if (entries.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '目录',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Expanded(
                  child: pw.ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 8),
                        child: pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Text(
                                '${index + 1}. ${entry.title}',
                                style: const pw.TextStyle(fontSize: 12),
                              ),
                            ),
                            pw.Text(
                              DateUtils.formatDisplayDate(entry.date),
                              style: const pw.TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // 添加日记内容页
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 标题
                pw.Text(
                  entry.title,
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),

                // 日期和元信息
                pw.Row(
                  children: [
                    pw.Text(
                      '日期: ${DateUtils.formatDisplayDate(entry.date)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.SizedBox(width: 20),
                    pw.Text(
                      '创建时间: ${DateUtils.formatDisplayDateTime(entry.createdAt)}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),

                // 标签
                if (includeTags && entry.tags.isNotEmpty) ...[
                  pw.Text(
                    '标签: ${entry.tags.join(', ')}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.SizedBox(height: 10),
                ],

                pw.Divider(),
                pw.SizedBox(height: 10),

                // 内容
                pw.Expanded(
                  child: pw.Text(
                    entry.content,
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ),

                // 备注
                if (includeNotes &&
                    entry.notes != null &&
                    entry.notes!.isNotEmpty) ...[
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '备注:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    entry.notes!,
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],

                // 页脚
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      '第 ${i + 1} 页，共 ${entries.length} 页',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                    pw.Text(
                      '导出时间: ${DateUtils.formatDisplayDateTime(DateTime.now())}',
                      style: const pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    // 保存PDF文件
    final output = await getTemporaryDirectory();
    final fileName = '${title}_${DateUtils.formatDate(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// 导出为Excel格式 (CSV实现)
  static Future<String> exportToExcel({
    required List<DiaryEntry> entries,
    required String title,
    bool includeTags = true,
    bool includeNotes = true,
  }) async {
    final buffer = StringBuffer();

    // 添加表头
    final headers = ['序号', '标题', '日期', '内容'];
    if (includeTags) headers.add('标签');
    if (includeNotes) headers.add('备注');
    headers.addAll(['创建时间', '更新时间']);

    buffer.writeln(headers.map((h) => '"$h"').join(','));

    // 添加数据行
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final row = <String>[
        (i + 1).toString(),
        _escapeCsvField(entry.title),
        DateUtils.formatDisplayDate(entry.date),
        _escapeCsvField(entry.content),
      ];

      if (includeTags) {
        row.add(_escapeCsvField(entry.tags.join(', ')));
      }

      if (includeNotes) {
        row.add(_escapeCsvField(entry.notes ?? ''));
      }

      row.addAll([
        DateUtils.formatDisplayDateTime(entry.createdAt),
        DateUtils.formatDisplayDateTime(entry.updatedAt),
      ]);

      buffer.writeln(row.join(','));
    }

    // 保存文件
    final output = await getTemporaryDirectory();
    final fileName = '${title}_${DateUtils.formatDate(DateTime.now())}.csv';
    final file = File('${output.path}/$fileName');
    await file.writeAsString(buffer.toString(), encoding: utf8);

    return file.path;
  }

  /// 导出为JSON格式
  static Future<String> exportToJSON({
    required List<DiaryEntry> entries,
    required String title,
    bool includeTags = true,
    bool includeNotes = true,
  }) async {
    final data = {
      'title': title,
      'exportTime': DateTime.now().toIso8601String(),
      'totalEntries': entries.length,
      'entries': entries.map((entry) {
        final map = {
          'id': entry.id,
          'title': entry.title,
          'content': entry.content,
          'date': entry.date.toIso8601String(),
          'createdAt': entry.createdAt.toIso8601String(),
          'updatedAt': entry.updatedAt.toIso8601String(),
        };

        if (includeTags) {
          map['tags'] = entry.tags;
        }

        if (includeNotes && entry.notes != null) {
          map['notes'] = entry.notes;
        }

        return map;
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // 保存文件
    final output = await getTemporaryDirectory();
    final fileName = '${title}_${DateUtils.formatDate(DateTime.now())}.json';
    final file = File('${output.path}/$fileName');
    await file.writeAsString(jsonString, encoding: utf8);

    return file.path;
  }

  /// 导出为Word格式 (简单的RTF实现)
  static Future<String> exportToWord({
    required List<DiaryEntry> entries,
    required String title,
    bool includeTags = true,
    bool includeNotes = true,
  }) async {
    final buffer = StringBuffer();

    // RTF 头部
    buffer.writeln(r'{\rtf1\ansi\deff0 {\fonttbl {\f0 Times New Roman;}}');
    buffer.writeln(r'\f0\fs24');

    // 标题
    buffer.writeln(r'{\fs32\b ' + title + r'}');
    buffer.writeln(r'\par');
    buffer.writeln(r'导出时间: ' + DateUtils.formatDisplayDateTime(DateTime.now()));
    buffer.writeln(r'\par');
    buffer.writeln(r'共 ' + entries.length.toString() + r' 篇日记');
    buffer.writeln(r'\par\par');

    // 日记内容
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // 标题
      buffer.writeln(
        r'{\fs28\b ' + (i + 1).toString() + r'. ' + entry.title + r'}',
      );
      buffer.writeln(r'\par');

      // 日期
      buffer.writeln(r'日期: ' + DateUtils.formatDisplayDate(entry.date));
      buffer.writeln(r'\par');

      // 标签
      if (includeTags && entry.tags.isNotEmpty) {
        buffer.writeln(r'标签: ' + entry.tags.join(', '));
        buffer.writeln(r'\par');
      }

      buffer.writeln(r'\par');

      // 内容
      buffer.writeln(entry.content.replaceAll('\n', r'\par'));
      buffer.writeln(r'\par');

      // 备注
      if (includeNotes && entry.notes != null && entry.notes!.isNotEmpty) {
        buffer.writeln(r'{\i 备注: ' + entry.notes! + r'}');
        buffer.writeln(r'\par');
      }

      buffer.writeln(r'\par');
    }

    // RTF 尾部
    buffer.writeln(r'}');

    // 保存文件
    final output = await getTemporaryDirectory();
    final fileName = '${title}_${DateUtils.formatDate(DateTime.now())}.rtf';
    final file = File('${output.path}/$fileName');
    await file.writeAsString(buffer.toString(), encoding: utf8);

    return file.path;
  }

  /// 导出标签统计
  static Future<String> exportTagStatistics({
    required List<Tag> tags,
    required String title,
  }) async {
    final data = {
      'title': title,
      'exportTime': DateTime.now().toIso8601String(),
      'totalTags': tags.length,
      'tags': tags
          .map(
            (tag) => {
              'id': tag.id,
              'name': tag.name,
              'color': tag.color,
              'usageCount': tag.usageCount,
              'createdAt': tag.createdAt.toIso8601String(),
              'lastUsedAt': tag.lastUsedAt?.toIso8601String(),
            },
          )
          .toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    // 保存文件
    final output = await getTemporaryDirectory();
    final fileName = '${title}_${DateUtils.formatDate(DateTime.now())}.json';
    final file = File('${output.path}/$fileName');
    await file.writeAsString(jsonString, encoding: utf8);

    return file.path;
  }

  /// 批量导出 (按月份分组)
  static Future<List<String>> exportByMonth({
    required List<DiaryEntry> entries,
    required String baseTitle,
    required ExportFormat format,
    bool includeTags = true,
    bool includeNotes = true,
  }) async {
    final groupedEntries = <String, List<DiaryEntry>>{};

    // 按月份分组
    for (final entry in entries) {
      final monthKey = DateUtils.formatDisplayMonth(entry.date);
      groupedEntries.putIfAbsent(monthKey, () => []).add(entry);
    }

    final filePaths = <String>[];

    // 为每个月份导出文件
    for (final monthKey in groupedEntries.keys) {
      final monthEntries = groupedEntries[monthKey]!;
      final title = '$baseTitle - $monthKey';

      String filePath;
      switch (format) {
        case ExportFormat.pdf:
          filePath = await exportToPDF(
            entries: monthEntries,
            title: title,
            includeTags: includeTags,
            includeNotes: includeNotes,
          );
          break;
        case ExportFormat.excel:
          filePath = await exportToExcel(
            entries: monthEntries,
            title: title,
            includeTags: includeTags,
            includeNotes: includeNotes,
          );
          break;
        case ExportFormat.word:
          filePath = await exportToWord(
            entries: monthEntries,
            title: title,
            includeTags: includeTags,
            includeNotes: includeNotes,
          );
          break;
        case ExportFormat.json:
          filePath = await exportToJSON(
            entries: monthEntries,
            title: title,
            includeTags: includeTags,
            includeNotes: includeNotes,
          );
          break;
      }

      filePaths.add(filePath);
    }

    return filePaths;
  }

  /// 分享文件
  static Future<void> shareFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await Share.shareXFiles([XFile(filePath)]);
    }
  }

  /// 获取导出文件的预览文本
  static String getExportPreview(
    List<DiaryEntry> entries, {
    int maxLength = 200,
  }) {
    if (entries.isEmpty) return '暂无日记内容';

    final buffer = StringBuffer();

    for (int i = 0; i < entries.length && i < 3; i++) {
      final entry = entries[i];
      buffer.writeln('${i + 1}. ${entry.title}');
      buffer.writeln('   日期: ${DateUtils.formatDisplayDate(entry.date)}');

      if (entry.content.length > 50) {
        buffer.writeln('   内容: ${entry.content.substring(0, 50)}...');
      } else {
        buffer.writeln('   内容: ${entry.content}');
      }

      if (i < entries.length - 1 && i < 2) {
        buffer.writeln();
      }
    }

    if (entries.length > 3) {
      buffer.writeln('\n... 还有 ${entries.length - 3} 篇日记');
    }

    return buffer.toString();
  }

  /// 获取文件大小估算
  static String getEstimatedFileSize(
    List<DiaryEntry> entries,
    ExportFormat format,
  ) {
    int totalChars = 0;

    for (final entry in entries) {
      totalChars += entry.title.length;
      totalChars += entry.content.length;
      totalChars += entry.tags.join(', ').length;
      totalChars += entry.notes?.length ?? 0;
    }

    double estimatedSize;

    switch (format) {
      case ExportFormat.pdf:
        estimatedSize = totalChars * 2.5; // PDF通常比较大
        break;
      case ExportFormat.excel:
        estimatedSize = totalChars * 1.2;
        break;
      case ExportFormat.word:
        estimatedSize = totalChars * 1.5;
        break;
      case ExportFormat.json:
        estimatedSize = totalChars * 1.1;
        break;
    }

    if (estimatedSize < 1024) {
      return '${estimatedSize.toInt()} B';
    } else if (estimatedSize < 1024 * 1024) {
      return '${(estimatedSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(estimatedSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// 转义CSV字段
  static String _escapeCsvField(String field) {
    if (field.contains('"') || field.contains(',') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

/// 导出格式枚举
enum ExportFormat { pdf, excel, word, json }
