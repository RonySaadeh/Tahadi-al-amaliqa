import 'package:intl/intl.dart';

/// Locale-aware formatting helpers. Pass the current [locale] (from
/// `Localizations.localeOf(context)`) so numbers/dates render with the
/// correct digits and month names for Arabic vs English.
class Formatters {
  const Formatters._();

  static String elo(num value, {String? locale}) {
    return NumberFormat.decimalPattern(locale).format(value.round());
  }

  static String signedElo(int delta, {String? locale}) {
    final formatted = NumberFormat.decimalPattern(locale).format(delta.abs());
    return delta >= 0 ? '+$formatted' : '-$formatted';
  }

  static String joinDate(DateTime date, {String? locale}) {
    return DateFormat.yMMMM(locale).format(date);
  }

  static String record(int wins, int losses) => '$wins-$losses';

  /// mm:ss countdown display for the duel timer.
  static String countdown(Duration remaining) {
    final seconds = remaining.inSeconds.clamp(0, 999);
    return seconds.toString();
  }
}
