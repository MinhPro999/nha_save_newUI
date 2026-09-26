import 'package:intl/intl.dart';

/// Lớp tiện ích để định dạng số
class NumberFormatter {
  /// Định dạng số theo phần nghìn
  /// Ví dụ: 1000 -> 1,000
  static String format(double number) {
    final formatter = NumberFormat('#,###.##', 'vi_VN');
    return formatter.format(number);
  }

  /// Định dạng số tiền theo phần nghìn
  /// Ví dụ: 1000000 -> 1,000,000
  static String formatCurrency(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(amount);
  }

  /// Định dạng số tiền theo phần nghìn và thêm đơn vị tiền tệ
  /// Ví dụ: 1000000 -> 1,000,000 VNĐ
  static String formatCurrencyWithSymbol(double amount) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)} VNĐ';
  }
}
