/// Age rules (mirrors nodejs_server/src/utils/age.js — the server enforces
/// the same rules, this is for instant feedback in the UI).
class AgePolicy {
  AgePolicy._();

  static const int minAge = 18;

  /// Latest year offered in the birthday picker.
  static const int maxPickerYear = 2018;

  /// How far back the picker goes.
  static int get minPickerYear => DateTime.now().year - 100;

  static const int birthdateChangeMonths = 6;

  static const String underageMessage = 'You must be 18 or older to use VoiChat';

  /// Full years on the exact birthday, as of today.
  static int ageOf(DateTime birthdate, [DateTime? today]) {
    final now = today ?? DateTime.now();
    var age = now.year - birthdate.year;
    final beforeBirthday = now.month < birthdate.month ||
        (now.month == birthdate.month && now.day < birthdate.day);
    if (beforeBirthday) age -= 1;
    return age;
  }

  static bool isAdult(DateTime birthdate) => ageOf(birthdate) >= minAge;

  static int daysInMonth(int year, int month) =>
      DateTime(year, month + 1, 0).day;

  /// When the birthdate may be changed again, or null if it can be now.
  static DateTime? nextBirthdateChange(DateTime? lastChangedAt) {
    if (lastChangedAt == null) return null;
    final last = lastChangedAt.toLocal();
    final month = last.month + birthdateChangeMonths;
    final year = last.year + (month - 1) ~/ 12;
    final m = (month - 1) % 12 + 1;
    final day = last.day.clamp(1, daysInMonth(year, m));
    final next = DateTime(year, m, day, last.hour, last.minute);
    return next.isAfter(DateTime.now()) ? next : null;
  }
}
