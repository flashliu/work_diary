import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';

/// 文件分享服务类
/// 提供文件保存和分享功能
class FileShareService {
  // 单例模式
  static final FileShareService _instance = FileShareService._internal();
  factory FileShareService() => _instance;
  FileShareService._internal();

  /// 保存文件到设备
  ///
  /// [filePath] 文件路径
  /// [fileName] 自定义文件名（可选）
  Future<String> saveFileToDevice(String filePath, {String? fileName}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      // 获取下载目录
      final downloadsDir = await _getDownloadsDirectory();
      final finalFileName = fileName ?? _getFileNameFromPath(filePath);
      final savedPath = '${downloadsDir.path}/$finalFileName';

      // 复制文件到下载目录
      await file.copy(savedPath);

      return savedPath;
    } catch (e) {
      debugPrint('Save file error: $e');
      rethrow;
    }
  }

  /// 分享文件
  ///
  /// [filePath] 文件路径
  /// [subject] 分享主题
  /// [text] 分享文本
  Future<void> shareFile(
    String filePath, {
    String? subject,
    String? text,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('文件不存在');
      }

      // 使用 share_plus 进行跨平台分享
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        subject: subject ?? '工作日记导出文件',
        text: text ?? '这是我导出的工作日记文件，请查收。',
      );
    } catch (e) {
      debugPrint('Share file error: $e');
      rethrow;
    }
  }

  /// 分享多个文件
  ///
  /// [filePaths] 文件路径列表
  /// [subject] 分享主题
  /// [text] 分享文本
  Future<void> shareMultipleFiles(
    List<String> filePaths, {
    String? subject,
    String? text,
  }) async {
    try {
      final files = <XFile>[];
      for (final filePath in filePaths) {
        final file = File(filePath);
        if (await file.exists()) {
          files.add(XFile(filePath));
        }
      }

      if (files.isEmpty) {
        throw Exception('没有有效的文件可分享');
      }

      await Share.shareXFiles(
        files,
        subject: subject ?? '工作日记导出文件',
        text: text ?? '这是我导出的工作日记文件，请查收。',
      );
    } catch (e) {
      debugPrint('Share multiple files error: $e');
      rethrow;
    }
  }

  /// 分享文本内容
  ///
  /// [text] 文本内容
  /// [subject] 分享主题
  Future<void> shareText(String text, {String? subject}) async {
    try {
      await Share.share(text, subject: subject ?? '工作日记内容分享');
    } catch (e) {
      debugPrint('Share text error: $e');
      rethrow;
    }
  }

  /// 分享链接
  ///
  /// [url] 链接地址
  /// [subject] 分享主题
  Future<void> shareUrl(String url, {String? subject}) async {
    try {
      await Share.shareUri(Uri.parse(url));
    } catch (e) {
      debugPrint('Share URL error: $e');
      rethrow;
    }
  }

  /// 复制文件路径到剪贴板
  ///
  /// [filePath] 文件路径
  Future<void> copyPathToClipboard(String filePath) async {
    await Clipboard.setData(ClipboardData(text: filePath));
  }

  /// 打开文件所在目录
  ///
  /// [filePath] 文件路径
  Future<void> openFileDirectory(String filePath) async {
    try {
      final directory = Directory(File(filePath).parent.path);

      if (Platform.isAndroid) {
        // Android: 尝试打开文件管理器
        await _openDirectoryOnAndroid(directory.path);
      } else if (Platform.isIOS) {
        // iOS: 在Files应用中显示
        await _openDirectoryOnIOS(directory.path);
      }
    } catch (e) {
      debugPrint('Open directory error: $e');
      rethrow;
    }
  }

  /// 删除临时文件
  ///
  /// [filePath] 文件路径
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Delete file error: $e');
    }
  }

  /// 获取文件大小
  ///
  /// [filePath] 文件路径
  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  /// 格式化文件大小
  ///
  /// [bytes] 文件大小（字节）
  String formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '${bytes}B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)}KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }

  /// 获取下载目录
  Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      // Android: 尝试使用外部存储的Downloads目录
      final downloadsDir = Directory('/storage/emulated/0/Download');
      if (await downloadsDir.exists()) {
        return downloadsDir;
      }
    }

    // 备选方案：使用应用文档目录
    return await getApplicationDocumentsDirectory();
  }

  /// 从路径中提取文件名
  String _getFileNameFromPath(String filePath) {
    return File(filePath).path.split('/').last;
  }

  /// Android 平台打开目录
  Future<void> _openDirectoryOnAndroid(String dirPath) async {
    try {
      // 在Android上，尝试打开文件管理器到指定目录
      await OpenFile.open(dirPath);
    } catch (e) {
      debugPrint('Android打开目录失败: $e');
      // 如果直接打开目录失败，可以尝试通过Intent打开文件管理器
      throw Exception('无法打开目录：$e');
    }
  }

  /// iOS 平台打开目录
  Future<void> _openDirectoryOnIOS(String dirPath) async {
    try {
      // 在iOS上，由于沙盒限制，通常无法直接打开文件管理器到指定目录
      // 但可以尝试打开Files应用
      await OpenFile.open(dirPath);
    } catch (e) {
      debugPrint('iOS打开目录失败: $e');
      // iOS系统限制，提供友好的错误信息
      throw Exception('iOS系统限制，无法直接打开目录。文件已保存到应用文档目录中。');
    }
  }
}

/// 文件分享选项
class ShareOptions {
  final bool saveToDevice;
  final bool shareViaSystem;
  final bool copyPath;
  final bool openDirectory;
  final String? customSubject;
  final String? customText;

  const ShareOptions({
    this.saveToDevice = true,
    this.shareViaSystem = false,
    this.copyPath = false,
    this.openDirectory = false,
    this.customSubject,
    this.customText,
  });
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
