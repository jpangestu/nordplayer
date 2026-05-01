/// Standard Format: 01 Jan 2026
String formatToStandard(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year;

  return '$day $month $year';
}

extension DateTimeExtension on DateTime {
  String toStandardFormat() {
    return formatToStandard(this);
  }

  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays <= 7) {
      return '${difference.inDays} days ago';
    } else {
      return toStandardFormat();
    }
  }
}
