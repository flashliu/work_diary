import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_constants.dart';
import '../../providers/diary_provider.dart';

/// 日期范围选择组件
class DateRangeSelectionWidget extends StatelessWidget {
  final DateRange selectedDateRange;
  final DateTime? startDate;
  final DateTime? endDate;
  final ValueChanged<DateRange> onDateRangeChanged;
  final ValueChanged<DateTime?> onStartDateChanged;
  final ValueChanged<DateTime?> onEndDateChanged;

  const DateRangeSelectionWidget({
    super.key,
    required this.selectedDateRange,
    required this.startDate,
    required this.endDate,
    required this.onDateRangeChanged,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_today,
                  color: Colors.blue,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '选择时间范围',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer<DiaryProvider>(
            builder: (context, diaryProvider, child) {
              final totalCount = diaryProvider.diaryEntries.length;
              final thisMonthCount = diaryProvider.getEntriesThisMonth().length;
              final lastMonthCount = diaryProvider.getEntriesLastMonth().length;

              return Column(
                children: [
                  _DateRangeOption(
                    dateRange: DateRange.all,
                    title: '全部时间',
                    count: totalCount,
                    isSelected: selectedDateRange == DateRange.all,
                    onSelected: () => onDateRangeChanged(DateRange.all),
                  ),
                  const SizedBox(height: 12),
                  _DateRangeOption(
                    dateRange: DateRange.thisMonth,
                    title: '本月',
                    count: thisMonthCount,
                    isSelected: selectedDateRange == DateRange.thisMonth,
                    onSelected: () => onDateRangeChanged(DateRange.thisMonth),
                  ),
                  const SizedBox(height: 12),
                  _DateRangeOption(
                    dateRange: DateRange.lastMonth,
                    title: '上月',
                    count: lastMonthCount,
                    isSelected: selectedDateRange == DateRange.lastMonth,
                    onSelected: () => onDateRangeChanged(DateRange.lastMonth),
                  ),
                  const SizedBox(height: 12),
                  _DateRangeOption(
                    dateRange: DateRange.custom,
                    title: '自定义范围',
                    count: null,
                    isSelected: selectedDateRange == DateRange.custom,
                    onSelected: () => onDateRangeChanged(DateRange.custom),
                  ),
                  if (selectedDateRange == DateRange.custom) ...[
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.only(left: 32),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '开始日期',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF374151),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _CustomDatePicker(
                                  date: startDate,
                                  onDateChanged: onStartDateChanged,
                                  hint: '选择开始日期',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '结束日期',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF374151),
                                      ),
                                ),
                                const SizedBox(height: 8),
                                _CustomDatePicker(
                                  date: endDate,
                                  onDateChanged: onEndDateChanged,
                                  hint: '选择结束日期',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DateRangeOption extends StatelessWidget {
  final DateRange dateRange;
  final String title;
  final int? count;
  final bool isSelected;
  final VoidCallback onSelected;

  const _DateRangeOption({
    required this.dateRange,
    required this.title,
    required this.count,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.blue : const Color(0xFFD1D5DB),
                width: 2,
              ),
            ),
            child: isSelected
                ? Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF374151)),
            ),
          ),
          if (count != null)
            Text(
              '($count 条记录)',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
            ),
        ],
      ),
    );
  }
}

class _CustomDatePicker extends StatelessWidget {
  final DateTime? date;
  final ValueChanged<DateTime?> onDateChanged;
  final String hint;

  const _CustomDatePicker({
    required this.date,
    required this.onDateChanged,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (selectedDate != null) {
          onDateChanged(selectedDate);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD1D5DB)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                date != null
                    ? '${date!.year}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}'
                    : hint,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: date != null
                      ? const Color(0xFF374151)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            const Icon(
              Icons.calendar_today,
              size: 16,
              color: Color(0xFF6B7280),
            ),
          ],
        ),
      ),
    );
  }
}
