import 'package:intl/intl.dart';

final _rupiahFormatter = NumberFormat.decimalPattern('id_ID');

String formatRupiah(num value) => 'Rp ${_rupiahFormatter.format(value)}';

String formatDateDMY(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String formatTimeHM(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

const monthNames = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agt', 'Sep', 'Okt', 'Nov', 'Des',
];
