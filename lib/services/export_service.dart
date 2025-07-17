import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart';
import '../models/diary_entry.dart';
import '../constants/app_constants.dart';
import '../utils/date_utils.dart' as app_date_utils;
import 'file_share_service.dart';

/// 导出服务类
/// 提供PDF、Excel等格式的导出功能
class ExportService {
  // 单例模式
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// 导出日记到文件并处理后续操作
  ///
  /// [entries] 要导出的日记列表
  /// [format] 导出格式
  /// [options] 导出选项
  /// [shareOptions] 分享选项
  /// [onProgress] 进度回调
  Future<FileOperationResult> exportAndShare({
    required List<DiaryEntry> entries,
    required ExportFormat format,
    required ExportOptions options,
    ShareOptions shareOptions = const ShareOptions(),
    Function(double progress, String message)? onProgress,
  }) async {
    try {
      // 执行导出
      final filePath = await exportDiaries(
        entries: entries,
        format: format,
        options: options,
        onProgress: onProgress,
      );

      final fileService = FileShareService();
      String? finalPath = filePath;

      // 保存到设备
      if (shareOptions.saveToDevice) {
        onProgress?.call(0.9, '正在保存文件...');
        finalPath = await fileService.saveFileToDevice(filePath);
      }

      // 执行其他操作
      if (shareOptions.shareViaSystem) {
        await fileService.shareFile(
          finalPath,
          subject: shareOptions.customSubject ?? '工作日记导出',
          text: shareOptions.customText ?? '分享我的工作日记',
        );
      }

      if (shareOptions.copyPath) {
        await fileService.copyPathToClipboard(finalPath);
      }

      if (shareOptions.openDirectory) {
        await fileService.openFileDirectory(finalPath);
      }

      onProgress?.call(1.0, '操作完成');

      return FileOperationResult.success(
        filePath: finalPath,
        message: '导出成功！文件已保存到：$finalPath',
      );
    } catch (e) {
      return FileOperationResult.failure(
        message: '导出失败：${e.toString()}',
        error: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

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
        case ExportFormat.json:
          return await _exportToJson(entries, filePath, options, onProgress);
        default:
          throw Exception('不支持的导出格式: $format');
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
        extension = 'rtf'; // 使用RTF格式，Word可以直接打开
        break;
      case ExportFormat.excel:
        extension = 'xlsx';
        break;
      case ExportFormat.json:
        extension = 'json';
        break;
      default:
        extension = 'txt';
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

    // 生成Rich Text Format (RTF) 格式，可以被Word正确读取
    final rtfContent = _generateRtfContent(entries, options);

    onProgress?.call(0.5, '正在生成文档内容...');

    // 将文件保存为.rtf格式，Word可以直接打开
    final file = File(filePath);
    await file.writeAsString(rtfContent, encoding: utf8);

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

  /// 生成RTF内容（Rich Text Format，Word可以直接打开）
  String _generateRtfContent(List<DiaryEntry> entries, ExportOptions options) {
    final buffer = StringBuffer();

    // RTF头部
    buffer.writeln(
      r'{\rtf1\ansi\deff0 {\fonttbl\f0\fswiss Helvetica;}\f0\fs24',
    );

    // 标题
    if (options.includeCoverPage) {
      buffer.writeln(r'\fs36\b 工作日记导出\b0\fs24\par');
      buffer.writeln(
        '导出时间：${app_date_utils.DateUtils.formatDateTime(DateTime.now())}\\par',
      );
      buffer.writeln('记录数量：${entries.length} 条\\par');
      buffer.writeln('\\par');
    }

    // 日记内容
    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      // 标题
      buffer.writeln('\\fs28\\b ${_escapeRtf(entry.title)}\\b0\\fs24\\par');

      // 日期
      if (options.includeDate) {
        buffer.writeln(
          '\\i 日期：${app_date_utils.DateUtils.formatDate(entry.date)}\\i0\\par',
        );
      }

      // 内容
      if (options.includeContent) {
        buffer.writeln('${_escapeRtf(entry.content)}\\par');
      }

      // 标签
      if (options.includeTags && entry.tags.isNotEmpty) {
        buffer.writeln('\\i 标签：${_escapeRtf(entry.tags.join(', '))}\\i0\\par');
      }

      // 备注
      if (options.includeNotes && entry.notes?.isNotEmpty == true) {
        buffer.writeln('\\i 备注：${_escapeRtf(entry.notes!)}\\i0\\par');
      }

      // 时间信息
      if (options.includeCreatedAt) {
        buffer.writeln(
          '\\fs20 创建时间：${app_date_utils.DateUtils.formatDateTime(entry.createdAt)}\\fs24\\par',
        );
      }

      if (options.includeUpdatedAt) {
        buffer.writeln(
          '\\fs20 更新时间：${app_date_utils.DateUtils.formatDateTime(entry.updatedAt)}\\fs24\\par',
        );
      }

      // 分隔线
      if (i < entries.length - 1) {
        buffer.writeln('\\par\\line\\par');
      }
    }

    // RTF结尾
    buffer.writeln('}');

    return buffer.toString();
  }

  /// 转义RTF特殊字符
  String _escapeRtf(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('{', '\\{')
        .replaceAll('}', '\\}')
        .replaceAll('\n', '\\par ');
  }

  /// 导出为JSON格式
  Future<String> _exportToJson(
    List<DiaryEntry> entries,
    String filePath,
    ExportOptions options,
    Function(double, String)? onProgress,
  ) async {
    onProgress?.call(0.1, '正在准备JSON数据...');

    final jsonData = {
      'exportTime': DateTime.now().toIso8601String(),
      'totalEntries': entries.length,
      'options': options.toJson(),
      'entries': entries.map((entry) => _entryToJson(entry, options)).toList(),
    };

    onProgress?.call(0.5, '正在生成JSON文件...');

    final file = File(filePath);
    await file.writeAsString(_formatJson(jsonData));

    onProgress?.call(1.0, '导出完成');
    return file.path;
  }

  /// 将日记条目转换为JSON
  Map<String, dynamic> _entryToJson(DiaryEntry entry, ExportOptions options) {
    final json = <String, dynamic>{};

    if (options.includeDate) {
      json['date'] = entry.date.toIso8601String();
    }

    json['title'] = entry.title;

    if (options.includeContent) {
      json['content'] = entry.content;
    }

    if (options.includeTags) {
      json['tags'] = entry.tags;
    }

    if (options.includeCreatedAt) {
      json['createdAt'] = entry.createdAt.toIso8601String();
    }

    if (options.includeUpdatedAt) {
      json['updatedAt'] = entry.updatedAt.toIso8601String();
    }

    return json;
  }

  /// 格式化JSON
  String _formatJson(Map<String, dynamic> data) {
    // 简单的JSON格式化
    return data
        .toString()
        .replaceAll(', ', ',\n  ')
        .replaceAll('{', '{\n  ')
        .replaceAll('}', '\n}');
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
