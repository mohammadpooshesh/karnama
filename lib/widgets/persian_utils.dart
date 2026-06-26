class PersianUtils {
  static const Map<String, String> _enToFa = {
    '0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴',
    '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹',
  };

  static String toPersianNumber(String input) {
    return input.split('').map((c) => _enToFa[c] ?? c).join();
  }

  static String formatDuration(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String formatPersianDuration(int totalSeconds) {
    return toPersianNumber(formatDuration(totalSeconds));
  }

  static String formatPersianDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    final parts = isoDate.split('T')[0].split('-');
    if (parts.length != 3) return isoDate;
    return toPersianNumber('${parts[0]}/${parts[1]}/${parts[2]}');
  }

  static String toPersianDate(DateTime dt) {
    return toPersianNumber(
      '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}');
  }

  static String toPersianDateTime(DateTime dt) {
    return toPersianDate(dt) + ' ' +
        toPersianNumber(
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}');
  }
}
