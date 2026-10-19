import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

/// `12.5` → `$12.50`
String formatPrice(num value) => _currency.format(value);

/// Price after applying a percentage discount, rounded to cents.
double discountedPrice(double price, double discountPercentage) =>
    (price * (1 - discountPercentage / 100) * 100).roundToDouble() / 100;

/// `2026-04-30T09:41:02.053Z` → `30 Apr 2026`
String formatDate(DateTime date) => DateFormat('d MMM yyyy').format(date);
