import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../providers/diary_provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/diary_card.dart';
import '../models/diary_entry.dart';
import '../constants/app_constants.dart';
import '../animations/page_transitions.dart';
import 'diary_detail_page.dart';
import 'search_page.dart';

/// 日历页面
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  List<DiaryEntry> _selectedDayEntries = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSelectedDayEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, diaryProvider, child) {
        return Column(
          children: [
            CustomAppBar(
              title: '日历视图',
              subtitle: DateFormat('yyyy年MM月').format(_focusedDay),
              actions: [
                IconButton(
                  onPressed: () => _navigateToSearch(context),
                  icon: const Icon(Icons.search, color: Colors.white),
                  tooltip: '搜索',
                ),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  // 月份导航
                  _buildMonthNavigation(),

                  // 日历
                  _buildCalendar(diaryProvider),

                  // 选中日期的日记列表
                  Expanded(child: _buildDayDiaryList(diaryProvider)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMonthNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
          Text(
            DateFormat('yyyy年MM月').format(_focusedDay),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_right),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.surfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar(DiaryProvider diaryProvider) {
    return Container(
      color: Colors.white,
      child: TableCalendar<DiaryEntry>(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        eventLoader: (day) => _getEventsForDay(day, diaryProvider.allEntries),
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerVisible: false,
        locale: 'zh_CN',
        calendarStyle: CalendarStyle(
          outsideDaysVisible: false,
          weekendTextStyle: const TextStyle(color: AppColors.textSecondary),
          holidayTextStyle: const TextStyle(color: AppColors.error),
          selectedDecoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.5),
            shape: BoxShape.circle,
          ),
          markerDecoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          weekendStyle: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadSelectedDayEntries();
        },
        onPageChanged: (focusedDay) {
          setState(() {
            _focusedDay = focusedDay;
          });
        },
      ),
    );
  }

  Widget _buildDayDiaryList(DiaryProvider diaryProvider) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // 日期标题
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text(
                      _selectedDay.day.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('yyyy年MM月dd日').format(_selectedDay),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        _getWeekdayString(_selectedDay),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${_selectedDayEntries.length}篇日记',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // 日记列表
          Expanded(
            child: _selectedDayEntries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _selectedDayEntries.length,
                    itemBuilder: (context, index) {
                      final diary = _selectedDayEntries[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: DiaryCard(
                          diary: diary,
                          onTap: () => _navigateToDiaryDetail(context, diary),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '这一天还没有日记',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '选择其他日期查看日记',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  List<DiaryEntry> _getEventsForDay(DateTime day, List<DiaryEntry> entries) {
    return entries.where((entry) {
      return isSameDay(entry.date, day);
    }).toList();
  }

  void _loadSelectedDayEntries() {
    final diaryProvider = context.read<DiaryProvider>();
    setState(() {
      _selectedDayEntries = _getEventsForDay(
        _selectedDay,
        diaryProvider.allEntries,
      );
    });
  }

  void _navigateToDiaryDetail(BuildContext context, DiaryEntry diary) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => DiaryDetailPage(diary: diary)),
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.push(context, const SearchPage().fadeTransition());
  }

  String _getWeekdayString(DateTime date) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.weekday % 7];
  }
}
