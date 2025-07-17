import 'package:intl/intl.dart';

/// 日期工具类
/// 提供日期格式化、日期计算等功能
class DateUtils {
  // 日期格式化器
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');
  static final DateFormat _monthFormat = DateFormat('yyyy-MM');
  static final DateFormat _yearFormat = DateFormat('yyyy');
  static final DateFormat _displayDateFormat = DateFormat('M月d日');
  static final DateFormat _displayDateTimeFormat = DateFormat('M月d日 HH:mm');
  static final DateFormat _displayMonthFormat = DateFormat('yyyy年M月');
  static final DateFormat _displayYearFormat = DateFormat('yyyy年');

  /// 格式化日期为字符串 (yyyy-MM-dd)
  static String formatDate(DateTime date) {
    return _dateFormat.format(date);
  }

  /// 格式化时间为字符串 (HH:mm)
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// 格式化日期时间为字符串 (yyyy-MM-dd HH:mm)
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  /// 格式化月份为字符串 (yyyy-MM)
  static String formatMonth(DateTime date) {
    return _monthFormat.format(date);
  }

  /// 格式化年份为字符串 (yyyy)
  static String formatYear(DateTime date) {
    return _yearFormat.format(date);
  }

  /// 格式化为显示用的日期 (M月d日)
  static String formatDisplayDate(DateTime date) {
    return _displayDateFormat.format(date);
  }

  /// 格式化为显示用的日期时间 (M月d日 HH:mm)
  static String formatDisplayDateTime(DateTime date) {
    return _displayDateTimeFormat.format(date);
  }

  /// 格式化为显示用的月份 (yyyy年M月)
  static String formatDisplayMonth(DateTime date) {
    return _displayMonthFormat.format(date);
  }

  /// 格式化为显示用的年份 (yyyy年)
  static String formatDisplayYear(DateTime date) {
    return _displayYearFormat.format(date);
  }

  /// 自定义格式化日期
  static String formatCustom(DateTime date, String pattern) {
    final formatter = DateFormat(pattern);
    return formatter.format(date);
  }

  /// 格式化星期几 (星期一)
  static String formatWeekday(DateTime date) {
    return _getWeekdayString(date);
  }

  /// 格式化星期几 (周一)
  static String formatShortWeekday(DateTime date) {
    return _getShortWeekdayString(date);
  }

  /// 格式化相对时间 (今天、昨天、N天前等)
  static String formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (isSameDay(date, now)) {
      return '今天';
    } else if (difference.inDays == 1) {
      return '昨天';
    } else if (difference.inDays == 2) {
      return '前天';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks周前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years年前';
    }
  }

  /// 格式化时间差 (如：2小时前、30分钟前)
  static String formatTimeDifference(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return formatDisplayDate(date);
    }
  }

  /// 解析日期字符串
  static DateTime? parseDate(String dateString) {
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// 解析日期时间字符串
  static DateTime? parseDateTime(String dateTimeString) {
    try {
      return _dateTimeFormat.parse(dateTimeString);
    } catch (e) {
      return null;
    }
  }

  /// 判断两个日期是否是同一天
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// 判断两个日期是否是同一周
  static bool isSameWeek(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2).inDays;
    return diff.abs() < 7 && date1.weekday >= date2.weekday;
  }

  /// 判断两个日期是否是同一月
  static bool isSameMonth(DateTime date1, DateTime date2) {
    return date1.year == date2.year && date1.month == date2.month;
  }

  /// 判断两个日期是否是同一年
  static bool isSameYear(DateTime date1, DateTime date2) {
    return date1.year == date2.year;
  }

  /// 判断是否是今天
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 判断是否是昨天
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// 判断是否是本周
  static bool isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));

    return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        date.isBefore(endOfWeek.add(const Duration(days: 1)));
  }

  /// 判断是否是本月
  static bool isThisMonth(DateTime date) {
    return isSameMonth(date, DateTime.now());
  }

  /// 判断是否是本年
  static bool isThisYear(DateTime date) {
    return isSameYear(date, DateTime.now());
  }

  /// 获取一周的开始日期 (周一)
  static DateTime getStartOfWeek(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  /// 获取一周的结束日期 (周日)
  static DateTime getEndOfWeek(DateTime date) {
    return getStartOfWeek(date).add(const Duration(days: 6));
  }

  /// 获取一月的开始日期
  static DateTime getStartOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// 获取一月的结束日期
  static DateTime getEndOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// 获取一年的开始日期
  static DateTime getStartOfYear(DateTime date) {
    return DateTime(date.year, 1, 1);
  }

  /// 获取一年的结束日期
  static DateTime getEndOfYear(DateTime date) {
    return DateTime(date.year, 12, 31);
  }

  /// 获取一天的开始时间 (00:00:00)
  static DateTime getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 获取一天的结束时间 (23:59:59)
  static DateTime getEndOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// 获取两个日期之间的天数
  static int getDaysBetween(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  /// 获取两个日期之间的工作日数量
  static int getWorkdaysBetween(DateTime start, DateTime end) {
    int count = 0;
    DateTime current = start;

    while (current.isBefore(end) || isSameDay(current, end)) {
      if (current.weekday < 6) {
        // 周一到周五
        count++;
      }
      current = current.add(const Duration(days: 1));
    }

    return count;
  }

  /// 获取指定月份的天数
  static int getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  /// 获取指定年份的天数
  static int getDaysInYear(int year) {
    return DateTime(year + 1, 1, 1).difference(DateTime(year, 1, 1)).inDays;
  }

  /// 判断是否是闰年
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// 获取指定日期所在月份的所有日期
  static List<DateTime> getMonthDates(DateTime date) {
    final start = getStartOfMonth(date);
    final end = getEndOfMonth(date);
    final dates = <DateTime>[];

    DateTime current = start;
    while (current.isBefore(end) || isSameDay(current, end)) {
      dates.add(current);
      current = current.add(const Duration(days: 1));
    }

    return dates;
  }

  /// 获取指定日期所在周的所有日期
  static List<DateTime> getWeekDates(DateTime date) {
    final start = getStartOfWeek(date);
    final dates = <DateTime>[];

    for (int i = 0; i < 7; i++) {
      dates.add(start.add(Duration(days: i)));
    }

    return dates;
  }

  /// 获取日期的农历信息 (简单实现，实际项目中可能需要更复杂的算法)
  static String getLunarDate(DateTime date) {
    // 这里只是一个简单的示例，实际实现需要农历转换算法
    return '农历信息';
  }

  /// 获取节气信息
  static String? getSolarTerm(DateTime date) {
    // 这里只是一个简单的示例，实际实现需要节气计算算法
    return null;
  }

  /// 获取节日信息
  static String? getHoliday(DateTime date) {
    final month = date.month;
    final day = date.day;

    switch (month) {
      case 1:
        if (day == 1) return '元旦';
        break;
      case 2:
        if (day == 14) return '情人节';
        break;
      case 3:
        if (day == 8) return '妇女节';
        if (day == 12) return '植树节';
        break;
      case 4:
        if (day == 1) return '愚人节';
        if (day == 5) return '清明节';
        break;
      case 5:
        if (day == 1) return '劳动节';
        if (day == 4) return '青年节';
        break;
      case 6:
        if (day == 1) return '儿童节';
        break;
      case 7:
        if (day == 1) return '建党节';
        break;
      case 8:
        if (day == 1) return '建军节';
        break;
      case 9:
        if (day == 10) return '教师节';
        break;
      case 10:
        if (day == 1) return '国庆节';
        break;
      case 11:
        if (day == 11) return '双十一';
        break;
      case 12:
        if (day == 25) return '圣诞节';
        break;
    }

    return null;
  }

  /// 获取时间段描述
  static String getTimeRange(DateTime start, DateTime end) {
    if (isSameDay(start, end)) {
      return '${formatDisplayDate(start)} ${formatTime(start)}-${formatTime(end)}';
    } else {
      return '${formatDisplayDateTime(start)} 至 ${formatDisplayDateTime(end)}';
    }
  }

  /// 获取日期的描述性信息
  static String getDateDescription(DateTime date) {
    final parts = <String>[];

    parts.add(formatDisplayDate(date));
    parts.add(formatWeekday(date));

    final holiday = getHoliday(date);
    if (holiday != null) {
      parts.add(holiday);
    }

    return parts.join(' ');
  }

  /// 获取中文星期几字符串
  static String _getWeekdayString(DateTime date) {
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    return weekdays[date.weekday % 7];
  }

  /// 获取中文短星期几字符串
  static String _getShortWeekdayString(DateTime date) {
    final weekdays = ['日', '一', '二', '三', '四', '五', '六'];
    return '周${weekdays[date.weekday % 7]}';
  }
}
