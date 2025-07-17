import 'package:flutter/material.dart';

/// 导出内容选项组件
class ContentOptionsWidget extends StatelessWidget {
  final bool includeDate;
  final bool includeContent;
  final bool includeTags;
  final bool includeNotes;
  final bool includeCreatedAt;
  final bool includeUpdatedAt;
  final ValueChanged<bool> onIncludeDateChanged;
  final ValueChanged<bool> onIncludeContentChanged;
  final ValueChanged<bool> onIncludeTagsChanged;
  final ValueChanged<bool> onIncludeNotesChanged;
  final ValueChanged<bool> onIncludeCreatedAtChanged;
  final ValueChanged<bool> onIncludeUpdatedAtChanged;

  const ContentOptionsWidget({
    super.key,
    required this.includeDate,
    required this.includeContent,
    required this.includeTags,
    required this.includeNotes,
    required this.includeCreatedAt,
    required this.includeUpdatedAt,
    required this.onIncludeDateChanged,
    required this.onIncludeContentChanged,
    required this.onIncludeTagsChanged,
    required this.onIncludeNotesChanged,
    required this.onIncludeCreatedAtChanged,
    required this.onIncludeUpdatedAtChanged,
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
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.checklist,
                  color: Colors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '导出内容',
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
              _ContentOption(
                title: '日期信息',
                isSelected: includeDate,
                onChanged: onIncludeDateChanged,
              ),
              const SizedBox(height: 12),
              _ContentOption(
                title: '工作内容',
                isSelected: includeContent,
                onChanged: onIncludeContentChanged,
              ),
              const SizedBox(height: 12),
              _ContentOption(
                title: '标签',
                isSelected: includeTags,
                onChanged: onIncludeTagsChanged,
              ),
              const SizedBox(height: 12),
              _ContentOption(
                title: '备注',
                isSelected: includeNotes,
                onChanged: onIncludeNotesChanged,
              ),
              const SizedBox(height: 12),
              _ContentOption(
                title: '创建时间',
                isSelected: includeCreatedAt,
                onChanged: onIncludeCreatedAtChanged,
              ),
              const SizedBox(height: 12),
              _ContentOption(
                title: '修改时间',
                isSelected: includeUpdatedAt,
                onChanged: onIncludeUpdatedAtChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentOption extends StatelessWidget {
  final String title;
  final bool isSelected;
  final ValueChanged<bool> onChanged;

  const _ContentOption({
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
