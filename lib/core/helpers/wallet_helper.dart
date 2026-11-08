/// Central place to format any wallet/coin-style amount (wallet balance,
/// total earnings, net earnings, etc.) the exact same way everywhere in
/// the app: a plain whole number, no decimal point, no thousands
/// separator — e.g. "1234", never "1,234.00" or "1234.50".
///
/// The server stores these as SQL DECIMAL columns, so they arrive on the
/// client as strings like "1234.00" or "150.50". [format] strips all of
/// that down to the integer part the user actually sees.
class WalletHelper {
  WalletHelper._();

  static String format(dynamic value) {
    if (value == null) return '0';
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value.toString());
    if (parsed == null) return '0';
    return parsed.truncate().toString();
  }
}
