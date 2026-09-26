/// Các utility functions chung cho tính toán vật liệu xây dựng
class CalculationUtils {
  /// Chuyển đổi giá trị sang kiểu double
  /// Hỗ trợ chuyển đổi từ int, double, String sang double
  static double toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  /// Giới hạn giá trị trong khoảng [0.0, 1.0]
  /// Sử dụng trong thuật toán hybrid để đảm bảo tỷ lệ hợp lệ
  static double clamp01(double value) {
    if (value < 0.0) return 0.0;
    if (value > 1.0) return 1.0;
    return value;
  }

  /// Làm tròn số với số chữ số thập phân chỉ định
  static double roundToDecimal(double value, int decimals) {
    return double.parse(value.toStringAsFixed(decimals));
  }

  /// Tính tổng diện tích các tầng từ danh sách tầng
  /// [floors]: Danh sách các tầng
  static double calculateTotalFloorArea(List<dynamic> floors) {
    double totalArea = 0.0;
    for (final floor in floors) {
      totalArea += toDouble(floor['area']);
    }
    return totalArea;
  }

  /// Kiểm tra xem tường có phải là tường 10cm không
  /// [thickness]: Độ dày tường (m)
  static bool isWall10cm(double thickness) {
    return (thickness - 0.10).abs() < 1e-9;
  }

  /// Kiểm tra xem tường có phải là tường 20cm không
  /// [thickness]: Độ dày tường (m) - có thể là 0.20 hoặc 0.22
  static bool isWall20cm(double thickness) {
    return (thickness - 0.20).abs() < 1e-9 || (thickness - 0.22).abs() < 1e-9;
  }

  /// Phân loại tường dựa trên độ dày
  /// Trả về "10" cho tường mỏng, "20" cho tường dày
  /// [thickness]: Độ dày tường (m)
  /// [threshold]: Ngưỡng phân loại (mặc định 0.16m)
  static String classifyWallType(double thickness, [double threshold = 0.16]) {
    return thickness < threshold ? "10" : "20";
  }

  /// Tính thể tích tường từ kích thước
  /// [length]: Chiều dài (m)
  /// [width]: Chiều rộng/độ dày (m)  
  /// [height]: Chiều cao (m)
  static double calculateWallVolume(double length, double width, double height) {
    return length * width * height;
  }

  /// Tính diện tích tường từ kích thước
  /// [length]: Chiều dài (m)
  /// [height]: Chiều cao (m)
  static double calculateWallArea(double length, double height) {
    return length * height;
  }

  /// Tính thể tích viên gạch từ kích thước
  /// [length]: Chiều dài viên gạch (m)
  /// [width]: Chiều rộng viên gạch (m)
  /// [height]: Chiều cao viên gạch (m)
  static double calculateBrickVolume(double length, double width, double height) {
    return length * width * height;
  }

  /// Áp dụng hệ số hao hụt cho vật liệu
  /// [quantity]: Số lượng gốc
  /// [wastePercentage]: Tỷ lệ hao hụt (0.05 = 5%)
  static double applyWasteFactor(double quantity, double wastePercentage) {
    return quantity * (1.0 + wastePercentage);
  }

  /// Chuyển đổi từ kg sang tấn
  static double kgToTon(double kg) {
    return kg / 1000.0;
  }

  /// Chuyển đổi từ tấn sang kg
  static double tonToKg(double ton) {
    return ton * 1000.0;
  }

  /// Chuyển đổi từ bao xi măng sang kg
  /// [bags]: Số bao xi măng
  /// [bagWeight]: Khối lượng một bao (mặc định 50kg)
  static double bagsToKg(double bags, [double bagWeight = 50.0]) {
    return bags * bagWeight;
  }

  /// Chuyển đổi từ kg sang bao xi măng
  /// [kg]: Khối lượng xi măng (kg)
  /// [bagWeight]: Khối lượng một bao (mặc định 50kg)
  static double kgToBags(double kg, [double bagWeight = 50.0]) {
    return kg / bagWeight;
  }

  /// Tính sai số tương đối giữa dự đoán và thực tế
  /// Sử dụng trong đánh giá độ chính xác thuật toán
  static double relativeError(double predicted, double actual) {
    final denominator = actual.abs() < 1e-9 ? 1.0 : actual.abs();
    return (predicted - actual).abs() / denominator;
  }

  /// Validate tham số đầu vào
  /// Ném exception nếu tham số không hợp lệ
  static void validateParameters(Map<String, dynamic> parameters, List<String> requiredKeys) {
    if (parameters.isEmpty) {
      throw ArgumentError('Tham số đầu vào không được rỗng');
    }
    
    for (final key in requiredKeys) {
      if (!parameters.containsKey(key)) {
        throw ArgumentError('Thiếu tham số bắt buộc: $key');
      }
    }
  }

  /// Validate giá trị số không âm
  static void validateNonNegative(double value, String parameterName) {
    if (value < 0) {
      throw ArgumentError('$parameterName không thể âm: $value');
    }
  }

  /// Validate diện tích hợp lệ
  static void validateArea(double area) {
    validateNonNegative(area, 'Diện tích');
  }

  /// Validate thể tích hợp lệ
  static void validateVolume(double volume) {
    validateNonNegative(volume, 'Thể tích');
  }
}
