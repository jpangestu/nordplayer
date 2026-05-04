/// Formats a [DateTime] into a standard string representation (e.g., '01 Jan 2026').
String formatToStandard(DateTime date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  final day = date.day.toString().padLeft(2, '0');
  final month = months[date.month - 1];
  final year = date.year;

  return '$day $month $year';
}

extension DateTimeExtension on DateTime {
  /// Convert [DateTime] into a standard date string (e.g., '01 Jan 2026').
  String toStandardFormat() {
    return formatToStandard(this);
  }

  /// Converts [DateTime] into a relative time string (e.g., 'Just now', '3h ago', 'Yesterday').
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
    } else if (difference.inDays <= 6) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 7 && difference.inDays < 14) {
      return '1 week ago';
    } else if (difference.inDays >= 14 && difference.inDays < 21) {
      return '2 weeks ago';
    } else if (difference.inDays >= 21 && difference.inDays < 28) {
      return '3 weeks ago';
    } else if (difference.inDays == 28) {
      return '4 weeks ago';
    } else {
      return toStandardFormat();
    }
  }
}
