import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';

/// 导出结果页面
/// 显示导出完成的文件信息和操作选项
class ExportResultPage extends StatelessWidget {
  final String filePath;
  final ExportFormat format;
  final int recordCount;

  const ExportResultPage({
    super.key,
    required this.filePath,
    required this.format,
    required this.recordCount,
  });

  @override
  Widget build(BuildContext context) {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    final fileSize = _getFileSize(file);
    final createdTime = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Column(
        children: [
          CustomAppBar(
            title: '导出完成',
            subtitle: '文件已成功生成',
            showBackButton: true,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 成功提示卡片
                  _buildSuccessCard(context),

                  const SizedBox(height: 16),

                  // 文件信息卡片
                  _buildFileInfoCard(context, fileName, fileSize, createdTime),

                  const SizedBox(height: 16),

                  // 操作按钮
                  _buildActionButtons(context),

                  const SizedBox(height: 24),

                  // 帮助信息
                  _buildHelpCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建成功提示卡片
  Widget _buildSuccessCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: const Icon(
              Icons.check_circle,
              size: 32,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '导出成功！',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '已成功导出 $recordCount 条日记记录',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建文件信息卡片
  Widget _buildFileInfoCard(
    BuildContext context,
    String fileName,
    String fileSize,
    DateTime createdTime,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '文件信息',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoRow(Icons.description, '文件名', fileName),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.folder, '格式', _getFormatDisplayName(format)),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.storage, '大小', fileSize),
          const SizedBox(height: 12),
          _buildInfoRow(
            Icons.access_time,
            '创建时间',
            _formatDateTime(createdTime),
          ),
          const SizedBox(height: 16),

          // 文件路径
          const Text(
            '文件路径',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    filePath,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _copyPathToClipboard(context),
                  child: const Icon(
                    Icons.copy,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // 主要操作按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _openFile(context),
            icon: const Icon(Icons.open_in_new),
            label: const Text('打开文件'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 次要操作按钮
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openFileLocation(context),
                icon: const Icon(Icons.folder_open),
                label: const Text('打开位置'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _copyPathToClipboard(context),
                icon: const Icon(Icons.copy),
                label: const Text('复制路径'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建帮助卡片
  Widget _buildHelpCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.info),
              const SizedBox(width: 8),
              const Text(
                '使用提示',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 文件已保存到手机的下载文件夹中\n'
            '• 您可以使用任何支持 ${_getFormatDisplayName(format)} 格式的应用打开\n'
            '• 建议将文件备份到云存储或其他设备',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// 获取格式显示名称
  String _getFormatDisplayName(ExportFormat format) {
    switch (format) {
      case ExportFormat.word:
        return 'Word';
      case ExportFormat.excel:
        return 'Excel';
    }
  }

  String _getFileSize(File file) {
    try {
      final bytes = file.lengthSync();
      if (bytes < 1024) {
        return '$bytes B';
      } else if (bytes < 1024 * 1024) {
        return '${(bytes / 1024).toStringAsFixed(1)} KB';
      } else {
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return '未知';
    }
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}年${dateTime.month}月${dateTime.day}日 '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 打开文件
  void _openFile(BuildContext context) async {
    try {
      final result = await OpenFile.open(filePath);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          _showSnackBar(context, '无法打开文件：${result.message}', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, '打开文件失败：$e', isError: true);
      }
    }
  }

  /// 打开文件位置（Android）
  void _openFileLocation(BuildContext context) async {
    try {
      final directory = File(filePath).parent;
      final result = await OpenFile.open(directory.path);
      if (result.type != ResultType.done) {
        if (context.mounted) {
          _showSnackBar(context, '无法打开文件夹：${result.message}', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, '打开文件夹失败：$e', isError: true);
      }
    }
  }

  /// 复制路径到剪贴板
  void _copyPathToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: filePath));
    _showSnackBar(context, '文件路径已复制到剪贴板');
  }

  /// 显示提示信息
  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: Duration(seconds: isError ? 5 : 3),
      ),
    );
  }
}
