const koreanWeekdays = ['월', '화', '수', '목', '금', '토', '일'];

DateTime dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);
String dayKey(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
String formatDate(DateTime value) =>
    '${value.month}월 ${value.day}일 (${koreanWeekdays[value.weekday - 1]})';
String formatDateFull(DateTime value) => '${value.year}년 ${formatDate(value)}';
String formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
DateTime parseDate(String value) => DateTime.tryParse(value) ?? DateTime.now();
