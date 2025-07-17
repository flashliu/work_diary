import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 导出按钮组件
class ExportButtonWidget extends StatelessWidget {
  final bool isExporting;
  final int recordCount;
  final String estimatedSize;
  final String estimatedTime;
  final VoidCallback onExport;

  const ExportButtonWidget({
    super.key,
    required this.isExporting,
    required this.recordCount,
    required this.estimatedSize,
    required this.estimatedTime,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 导出按钮
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: isExporting ? null : onExport,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.zero,
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: isExporting
                    ? LinearGradient(
                        colors: [Colors.grey.shade400, Colors.grey.shade500],
                      )
                    : AppConstants.primaryGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: isExporting
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isExporting)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    else
                      const Icon(Icons.download, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      isExporting ? '正在导出...' : '开始导出 ($recordCount 条记录)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // 估算信息
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _InfoItem(icon: Icons.info_outline, text: '预计文件大小: $estimatedSize'),
            const SizedBox(width: 24),
            _InfoItem(icon: Icons.schedule, text: '预计用时: $estimatedTime'),
          ],
        ),
      ],
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF6B7280)),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
