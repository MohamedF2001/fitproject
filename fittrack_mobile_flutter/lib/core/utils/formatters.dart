import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();
  static String date(DateTime? value) =>
      value == null ? '—' : DateFormat('dd MMM yyyy', 'fr').format(value);
  static String time(Duration value) =>
      '${value.inMinutes.toString().padLeft(2, '0')}:${(value.inSeconds % 60).toString().padLeft(2, '0')}';
}
