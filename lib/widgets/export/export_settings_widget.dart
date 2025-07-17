import 'package:flutter/material.dart';
import '../../constants/app_constants.dart';

/// 导出设置组件
class ExportSettingsWidget extends StatelessWidget {
  final SortOrder sortOrder;
  final int pageSize;
  final bool includeCoverPage;
  final bool includeStatistics;
  final ValueChanged<SortOrder> onSortOrderChanged;
  final ValueChanged<int> onPageSizeChanged;
  final ValueChanged<bool> onIncludeCoverPageChanged;
  final ValueChanged<bool> onIncludeStatisticsChanged;

  const ExportSettingsWidget({
    super.key,
    required this.sortOrder,
    required this.pageSize,
    required this.includeCoverPage,
    required this.includeStatistics,
    required this.onSortOrderChanged,
    required this.onPageSizeChanged,
    required this.onIncludeCoverPageChanged,
    required this.onIncludeStatisticsChanged,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.settings,
                  color: Colors.purple,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '导出设置',
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
              // 排序设置
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '按日期排序',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<SortOrder>(
                        value: sortOrder,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF374151),
                        ),
                        items: [
                          DropdownMenuItem(
                            value: SortOrder.newest,
                            child: Text('最新优先'),
                          ),
                          DropdownMenuItem(
                            value: SortOrder.oldest,
                            child: Text('最早优先'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            onSortOrderChanged(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 分页设置
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '分页设置',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF374151),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD1D5DB)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: pageSize,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF374151),
                        ),
                        items: [
                          DropdownMenuItem(value: 0, child: Text('不分页')),
                          DropdownMenuItem(value: 20, child: Text('每页20条')),
                          DropdownMenuItem(value: 50, child: Text('每页50条')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            onPageSizeChanged(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 包含封面页
              _SettingOption(
                title: '包含封面页',
                isSelected: includeCoverPage,
                onChanged: onIncludeCoverPageChanged,
              ),
              const SizedBox(height: 12),
              // 包含统计信息
              _SettingOption(
                title: '包含统计信息',
                isSelected: includeStatistics,
                onChanged: onIncludeStatisticsChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _SettingOption({
    required this.title,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: Row(
        children: [
          _CustomCheckbox(isSelected: isSelected, onChanged: onChanged),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomCheckbox extends StatelessWidget {
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _CustomCheckbox({required this.isSelected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.blue : const Color(0xFFD1D5DB),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 12)
            : null,
      ),
    );
  }
}
