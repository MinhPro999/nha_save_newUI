import 'material_model.dart';

/// Loại tường
enum WallType {
  wall10cmNoPlaster, // Tường 10cm không chát
  wall10cm1Side, // Tường 10cm chát 1 mặt
  wall10cm2Side, // Tường 10cm chát 2 mặt
  wall20cmNoPlaster, // Tường 20cm không chát
  wall20cm1Side, // Tường 20cm chát 1 mặt
  wall20cm2Side, // Tường 20cm chát 2 mặt
}

/// Lớp vật liệu gạch xây
class Brick extends Material {
  /// Kích thước của viên gạch theo mét
  double brickLength;
  double brickWidth;
  double brickHeight;

  /// Hàm khởi tạo
  Brick({
    required super.pricePerUnit,
    this.brickLength = 0.2,
    this.brickWidth = 0.1,
    this.brickHeight = 0.05,
  }) : super(
          name: 'Gạch xây',
          type: MaterialType.brick,
          measurementUnit: MeasurementUnit.piece,
        );

  /// FIX-CALC-001 Phase 8 AUDIT: legacy model API đã chết — mọi công thức
  /// đi qua `MaterialCalculator.calculateBrickQuantity()`. Không có caller
  /// nào trong lib/. Giữ lại để tương thích legacy, KHÔNG dùng cho code mới.
  @Deprecated(
    'Tính toán đã chuyển sang MaterialCalculator.calculateBrickQuantity()',
  )
  @override
  double calculateQuantity(Map<String, dynamic> parameters) {
    // Logic tính toán đã được chuyển sang MaterialCalculator.calculateBrickQuantity()
    // Import MaterialCalculator và gọi phương thức tương ứng
    throw UnimplementedError(
      'Phương thức calculateQuantity đã được chuyển sang MaterialCalculator.calculateBrickQuantity(). '
      'Vui lòng sử dụng MaterialCalculator.calculateBrickQuantity(parameters, '
      'brickLength: $brickLength, brickWidth: $brickWidth, brickHeight: $brickHeight)',
    );
  }

  @override
  List<String> get requiredParameters => ['length', 'width', 'height'];

  @override
  String get unit => 'viên';

  @override
  Material copyWith({
    double? pricePerUnit,
    double? brickLength,
    double? brickWidth,
    double? brickHeight,
  }) {
    // Tạo bản sao với giá và kích thước mới hoặc giữ nguyên giá trị hiện tại
    return Brick(
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      brickLength: brickLength ?? this.brickLength,
      brickWidth: brickWidth ?? this.brickWidth,
      brickHeight: brickHeight ?? this.brickHeight,
    );
  }
}
