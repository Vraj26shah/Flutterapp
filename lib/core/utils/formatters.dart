import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

/// `12.5` → `$12.50`
String formatPrice(num value) => _currency.format(value);

/// `2026-04-30T09:41:02.053Z` → `30 Apr 2026`
String formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);
