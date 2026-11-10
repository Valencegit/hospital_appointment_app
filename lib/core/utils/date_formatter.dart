import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);

  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('hh:mm a').format(dt);

  static String formatShortDate(DateTime dt) =>
      DateFormat('dd/MM/yyyy').format(dt);

  static String formatDayMonth(DateTime dt) =>
      DateFormat('EEE, dd MMM').format(dt);

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(dt);
  }
}
