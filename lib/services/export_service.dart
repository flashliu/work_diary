import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart';
import '../models/diary_entry.dart';
import '../constants/app_constants.dart';
import '../utils/date_utils.dart' as app_date_utils;

/// 导出服务类
/// 提供PDF、Excel等格式的导出功能
class ExportService {
  // 单例模式
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// 导出日记到文件
  ///
  /// [entries] 要导出的日记列表
  /// [format] 导出格式
  /// [options] 导出选项
  /// [onProgress] 进度回调
  Future<String> exportDiaries({
    required List<DiaryEntry> entries,
    required ExportFormat format,
    required ExportOptions options,
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      // 检查权限
      await _checkPermissions();

      // 获取保存目录
      final directory = await _getSaveDirectory();

      // 生成文件名
      final fileName = _generateFileName(format, options);
      final filePath = '${directory.path}/$fileName';

      // 根据格式执行相应的导出
      switch (format) {
        case ExportFormat.word:
          return await _exportToWord(entries, filePath, options, onProgress);
        case ExportFormat.excel:
          return await _exportToExcel(entries, filePath, options, onProgress);
      }
    } catch (e) {
      debugPrint('Export error: $e');
      rethrow;
    }
  }

  /// 检查存储权限
  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          throw Exception('需要存储权限才能保存文件');
        }
      }
    }
  }

  /// 获取保存目录
  Future<Directory> _getSaveDirectory() async {
    if (Platform.isAndroid) {
      // Android: 使用外部存储的Downloads目录
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
    }

    // iOS 或 Android 备选方案：使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 生成文件名
  String _generateFileName(ExportFormat format, ExportOptions options) {
    final now = DateTime.now();
    final dateStr = app_date_utils.DateUtils.formatCustom(now, 'yyyy-MM-dd');
    final timeStr = app_date_utils.DateUtils.formatCustom(now, 'HHmmss');

    String extension;
    switch (format) {
      case ExportFormat.word:
        extension = 'docx'; // 使用DOCX格式
        break;
      case ExportFormat.excel:
        extension = 'xlsx';
        break;
    }

    return '工作日记_${dateStr}_$timeStr.$extension';
  }

  /// 导出为Word文档
  Future<String> _exportToWord(
    List<DiaryEntry> entries,
    String filePath,
    ExportOptions options,
    Function(double, String)? onProgress,
  ) async {
    onProgress?.call(0.1, '正在准备Word文档...');

    // 生成HTML格式的内容，保存为.docx扩展名
    // 这样大多数文字处理程序都可以打开
    final htmlContent = _generateHtmlContent(entries, options);

    onProgress?.call(0.5, '正在生成文档内容...');

    // 将文件保存为.docx格式
    final file = File(filePath);
    await file.writeAsString(htmlContent, encoding: utf8);

    onProgress?.call(1.0, '导出完成');
    return file.path;
  }

  /// 导出为Excel表格
  Future<String> _exportToExcel(
    List<DiaryEntry> entries,
    String filePath,
    ExportOptions options,
    Function(double, String)? onProgress,
  ) async {
    onProgress?.call(0.1, '正在准备Excel表格...');

    // 创建Excel工作簿
    final excel = Excel.createExcel();
    final sheet = excel['日记数据'];

    // 删除默认工作表
    excel.delete('Sheet1');

    onProgress?.call(0.3, '正在生成表格结构...');

    // 添加表头
    final headers = <String>[];
    if (options.includeDate) headers.add('日期');
    headers.add('标题');
    if (options.includeContent) headers.add('内容');
    if (options.includeTags) headers.add('标签');
    if (options.includeNotes) headers.add('备注');
    if (options.includeCreatedAt) headers.add('创建时间');
    if (options.includeUpdatedAt) headers.add('更新时间');

    // 设置表头样式
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        backgroundColorHex: ExcelColor.blue,
        fontColorHex: ExcelColor.white,
        bold: true,
      );
    }

    onProgress?.call(0.5, '正在填充数据...');

    // 添加数据行
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      int columnIndex = 0;

      if (options.includeDate) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
        );
        cell.value = TextCellValue(
          app_date_utils.DateUtils.formatDate(entry.date),
        );
        columnIndex++;
      }

      // 标题
      final titleCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
      );
      titleCell.value = TextCellValue(entry.title);
      columnIndex++;

      if (options.includeContent) {
        final contentCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
        );
        contentCell.value = TextCellValue(entry.content);
        columnIndex++;
      }

      if (options.includeTags) {
        final tagsCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
        );
        tagsCell.value = TextCellValue(entry.tags.join(', '));
        columnIndex++;
      }

      if (options.includeNotes) {
        final notesCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
        );
        notesCell.value = TextCellValue(entry.notes ?? '');
        columnIndex++;
      }

      if (options.includeCreatedAt) {
        final createdCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
        );
        createdCell.value = TextCellValue(
          app_date_utils.DateUtils.formatDateTime(entry.createdAt),
        );
        columnIndex++;
      }

      if (options.includeUpdatedAt) {
        final updatedCell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: columnIndex, rowIndex: i + 1),
        );
        updatedCell.value = TextCellValue(
          app_date_utils.DateUtils.formatDateTime(entry.updatedAt),
        );
        columnIndex++;
      }

      // 更新进度
      onProgress?.call(
        0.5 + (0.3 * (i + 1) / entries.length),
        '正在处理第 ${i + 1} 条记录...',
      );
    }

    onProgress?.call(0.9, '正在保存文件...');

    // 保存文件
    final file = File(filePath);
    final bytes = excel.encode();
    if (bytes != null) {
      await file.writeAsBytes(bytes);
    }

    onProgress?.call(1.0, '导出完成');
    return file.path;
  }

  /// 生成HTML格式的内容（以.docx扩展名保存，便于Word打开）
  String _generateHtmlContent(List<DiaryEntry> entries, ExportOptions options) {
    final buffer = StringBuffer();

    // HTML头部
    buffer.writeln('<!DOCTYPE html>');
    buffer.writeln('<html>');
    buffer.writeln('<head>');
    buffer.writeln('<meta charset="UTF-8">');
    buffer.writeln('<title>工作日记导出</title>');
    buffer.writeln('<style>');
    buffer.writeln(
      'body { font-family: "Microsoft YaHei", Arial, sans-serif; margin: 40px; line-height: 1.6; }',
    );
    buffer.writeln(
      'h1 { color: #333; text-align: center; font-size: 24px; margin-bottom: 30px; }',
    );
    buffer.writeln(
      'h2 { color: #666; font-size: 18px; margin-top: 30px; margin-bottom: 10px; }',
    );
    buffer.writeln('p { margin: 8px 0; }');
    buffer.writeln(
      '.meta { color: #999; font-style: italic; font-size: 12px; }',
    );
    buffer.writeln('.content { margin: 15px 0; }');
    buffer.writeln('.tags { color: #666; font-style: italic; }');
    buffer.writeln('.notes { color: #666; font-style: italic; }');
    buffer.writeln(
      '.separator { border-bottom: 1px solid #ddd; margin: 20px 0; }',
    );
    buffer.writeln('.cover-info { text-align: center; margin-bottom: 30px; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');

    // 封面信息
    if (options.includeCoverPage) {
      buffer.writeln('<h1>工作日记导出</h1>');
      buffer.writeln('<div class="cover-info">');
      buffer.writeln(
        '<p>导出时间：${app_date_utils.DateUtils.formatDateTime(DateTime.now())}</p>',
      );
      buffer.writeln('<p>记录数量：${entries.length} 条</p>');
      buffer.writeln('</div>');
    }

    // 日记内容
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // 标题
      buffer.writeln('<h2>${_escapeHtml(entry.title)}</h2>');

      // 日期
      if (options.includeDate) {
        buffer.writeln(
          '<p class="meta">日期：${app_date_utils.DateUtils.formatDate(entry.date)}</p>',
        );
      }

      // 内容
      if (options.includeContent) {
        buffer.writeln('<div class="content">');
        final contentLines = entry.content.split('\n');
        for (final line in contentLines) {
          buffer.writeln('<p>${_escapeHtml(line)}</p>');
        }
        buffer.writeln('</div>');
      }

      // 标签
      if (options.includeTags && entry.tags.isNotEmpty) {
        buffer.writeln(
          '<p class="tags">标签：${_escapeHtml(entry.tags.join(', '))}</p>',
        );
      }

      // 备注
      if (options.includeNotes && entry.notes?.isNotEmpty == true) {
        buffer.writeln('<p class="notes">备注：${_escapeHtml(entry.notes!)}</p>');
      }

      // 时间信息
      if (options.includeCreatedAt) {
        buffer.writeln(
          '<p class="meta">创建时间：${app_date_utils.DateUtils.formatDateTime(entry.createdAt)}</p>',
        );
      }

      if (options.includeUpdatedAt) {
        buffer.writeln(
          '<p class="meta">更新时间：${app_date_utils.DateUtils.formatDateTime(entry.updatedAt)}</p>',
        );
      }

      // 分隔线
      if (i < entries.length - 1) {
        buffer.writeln('<div class="separator"></div>');
      }
    }

    // HTML结尾
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    return buffer.toString();
  }

  /// 转义HTML特殊字符
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

/// 导出选项类
class ExportOptions {
  final bool includeDate;
  final bool includeContent;
  final bool includeTags;
  final bool includeNotes;
  final bool includeCreatedAt;
  final bool includeUpdatedAt;
  final bool includeCoverPage;
  final bool includeStatistics;
  final SortOrder sortOrder;
  final int pageSize;

  const ExportOptions({
    this.includeDate = true,
    this.includeContent = true,
    this.includeTags = true,
    this.includeNotes = true,
    this.includeCreatedAt = false,
    this.includeUpdatedAt = false,
    this.includeCoverPage = true,
    this.includeStatistics = false,
    this.sortOrder = SortOrder.newest,
    this.pageSize = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'includeDate': includeDate,
      'includeContent': includeContent,
      'includeTags': includeTags,
      'includeNotes': includeNotes,
      'includeCreatedAt': includeCreatedAt,
      'includeUpdatedAt': includeUpdatedAt,
      'includeCoverPage': includeCoverPage,
      'includeStatistics': includeStatistics,
      'sortOrder': sortOrder.name,
      'pageSize': pageSize,
    };
  }
}

/// 文件操作结果
class FileOperationResult {
  final bool success;
  final String? filePath;
  final String? message;
  final Exception? error;

  const FileOperationResult({
    required this.success,
    this.filePath,
    this.message,
    this.error,
  });

  factory FileOperationResult.success({String? filePath, String? message}) {
    return FileOperationResult(
      success: true,
      filePath: filePath,
      message: message,
    );
  }

  factory FileOperationResult.failure({String? message, Exception? error}) {
    return FileOperationResult(success: false, message: message, error: error);
  }
}
