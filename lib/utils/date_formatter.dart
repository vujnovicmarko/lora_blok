class DateFormatter {
  static String format(String dateString) {
    try {
      final dt = DateTime.parse(dateString);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}   ${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return dateString;
    }
  }
}
