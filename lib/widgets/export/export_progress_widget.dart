import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 导出进度组件
class ExportProgressWidget extends StatelessWidget {
  final ExportStatus status;
  final double progress;
  final String statusMessage;

  const ExportProgressWidget({
    super.key,
    required this.status,
    required this.progress,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (status == ExportStatus.idle) {
      return const SizedBox.shrink();
    }

    return Container(
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
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _getStatusColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: _buildStatusIcon(),
              ),
              const SizedBox(width: 12),
              Text(
                '导出进度',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getStatusText(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                  Text(
                    _getProgressText(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _getStatusColor(),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: MediaQuery.of(context).size.width * progress,
                  decoration: BoxDecoration(
                    color: _getStatusColor(),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              if (statusMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  statusMessage,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ExportStatus.idle:
        return Colors.grey;
      case ExportStatus.preparing:
        return Colors.orange;
      case ExportStatus.exporting:
        return Colors.blue;
      case ExportStatus.completed:
        return Colors.green;
      case ExportStatus.error:
        return Colors.red;
    }
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case ExportStatus.idle:
        return Icon(Icons.download, color: _getStatusColor(), size: 16);
      case ExportStatus.preparing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: _getStatusColor(),
            strokeWidth: 2,
          ),
        );
      case ExportStatus.exporting:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            color: _getStatusColor(),
            strokeWidth: 2,
          ),
        );
      case ExportStatus.completed:
        return Icon(Icons.check_circle, color: _getStatusColor(), size: 16);
      case ExportStatus.error:
        return Icon(Icons.error, color: _getStatusColor(), size: 16);
    }
  }

  String _getStatusText() {
    switch (status) {
      case ExportStatus.idle:
        return '准备导出';
      case ExportStatus.preparing:
        return '正在准备文件...';
      case ExportStatus.exporting:
        return '正在生成文件...';
      case ExportStatus.completed:
        return '导出完成';
      case ExportStatus.error:
        return '导出失败';
    }
  }

  String _getProgressText() {
    switch (status) {
      case ExportStatus.idle:
        return '0%';
      case ExportStatus.preparing:
        return '准备中';
      case ExportStatus.exporting:
        return '${(progress * 100).toInt()}%';
      case ExportStatus.completed:
        return '完成';
      case ExportStatus.error:
        return '错误';
    }
  }
}
