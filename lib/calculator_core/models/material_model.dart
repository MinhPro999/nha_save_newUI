// Không cần import foundation
import '../utils/number_formatter.dart';

/// Loại vật liệu
enum MaterialType {
  brick, // Gạch xây
  sand, // Cát
  cement, // Xi măng
  steel, // Sắt thép
  stone, // Đá
  tile, // Gạch ốp lát
  roofTile, // Ngói tây
  metalSheet, // Tôn thường
  insulatedMetal, // Tôn xốp
  gypsum, // Thạch cao
  exteriorPaint, // Sơn ngoại thất
  interiorPaint, // Sơn nội thất
  aluminumDoor, // Cửa nhôm Xingfa
  compositeDoor, // Cửa nhựa composite
  labor, // Nhân công xây dựng
  plumbingLabor, // Nhân công điện nước
  plumbingMaterial, // Vật tư điện nước
  concreteSand, // Cát bê tông
  custom, // Vật liệu tùy chỉnh
}

/// Đơn vị đo lường
enum MeasurementUnit {
  piece, // Viên
  cubicMeter, // m³
  squareMeter, // m²
  meter, // m
  kilogram, // kg
  ton, // tấn
  set, // bộ
  package, // gói
  custom, // Tùy chỉnh
}

/// Lớp trừu tượng đại diện cho vật liệu xây dựng
abstract class Material {
  /// Tên của vật liệu
  final String name;

  /// Giá mỗi đơn vị của vật liệu (ví dụ: VNĐ/viên, VNĐ/m³)
  double pricePerUnit;

  /// Loại vật liệu
  final MaterialType type;

  /// Đơn vị đo lường
  final MeasurementUnit measurementUnit;

  /// Hàm khởi tạo
  Material({
    required this.name,
    required this.pricePerUnit,
    required this.type,
    required this.measurementUnit,
  });

  /// Phương thức trừu tượng để tính toán số lượng vật liệu cần thiết
  /// dựa trên các thông số được cung cấp
  double calculateQuantity(Map<String, dynamic> parameters);

  /// Tính tổng chi phí dựa trên số lượng và giá mỗi đơn vị
  double calculateCost(Map<String, dynamic> parameters) {
    return calculateQuantity(parameters) * pricePerUnit;
  }

  /// Lấy số lượng đã định dạng
  String getFormattedQuantity(Map<String, dynamic> parameters) {
    return NumberFormatter.format(calculateQuantity(parameters));
  }

  /// Lấy chi phí đã định dạng
  String getFormattedCost(Map<String, dynamic> parameters) {
    return NumberFormatter.formatCurrency(calculateCost(parameters));
  }

  /// Lấy các thông số cần thiết cho vật liệu này
  List<String> get requiredParameters;

  /// Lấy đơn vị đo lường cho vật liệu này
  String get unit;

  /// Tạo một bản sao của vật liệu này với giá mới
  Material copyWith({double? pricePerUnit});
}
