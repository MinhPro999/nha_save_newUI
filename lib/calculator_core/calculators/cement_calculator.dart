import '../constants/construction_constants.dart';
import '../utils/calculation_utils.dart';
import 'brick_calculator.dart';

/// Calculator chuyên dụng cho tính toán xi măng
/// Tuân thủ thuật toán Hybrid tối ưu từ template
class CementCalculator {
  /// Tính khối lượng xi măng theo thuật toán Hybrid cải tiến
  ///
  /// Hỗ trợ 2 phương pháp:
  /// 1. Từ thông số chi tiết step5 (walls) - ưu tiên, sử dụng Hybrid
  /// 2. Từ diện tích tường tổng (wallArea) - fallback
  static double calculateQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    // Validation đầu vào
    CalculationUtils.validateParameters(parameters, []);
    if (parameters.isEmpty) {
      throw ArgumentError('Tham số đầu vào không được rỗng');
    }

    double totalCementKg = 0.0;

    // Phương pháp 1: Tính theo thông số chi tiết từ wizard (ưu tiên)
    if (parameters.containsKey('walls') && parameters['walls'] is Map) {
      totalCementKg = _calculateCementFromDetailedParameters(
        parameters,
        brickLength: brickLength,
        brickWidth: brickWidth,
        brickHeight: brickHeight,
      );
    }
    // Phương pháp 2: Tính theo diện tích tường tổng (fallback)
    else if (parameters.containsKey('wallArea')) {
      totalCementKg = _calculateCementFromWallArea(
        parameters,
        brickLength: brickLength,
        brickWidth: brickWidth,
        brickHeight: brickHeight,
      );
    } else {
      throw ArgumentError('Thiếu thông số cần thiết: walls hoặc wallArea');
    }

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalCementKg);
  }

  /// Tính xi măng từ thông số chi tiết sử dụng Hybrid Algorithm
  static double _calculateCementFromDetailedParameters(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    final Map<String, dynamic> wallsData =
        parameters['walls'] as Map<String, dynamic>;
    double totalCementKg = 0.0;

    if (wallsData.containsKey('walls')) {
      final List<dynamic> walls = wallsData['walls'] as List<dynamic>;

      // Chuẩn bị danh sách tường cho thuật toán Hybrid
      List<_Wall> wallList = [];

      for (final wall in walls) {
        final double length = CalculationUtils.toDouble(wall['length']);
        final double height = CalculationUtils.toDouble(wall['height']);
        final int plasterSides = wall['plasterSides'] ?? 2;

        if (length > 0 && height > 0) {
          final String wallType = wall['type'] ?? '10';
          final double wallThickness = wallType == '20' ? 0.20 : 0.10; // m

          wallList.add(
            _Wall(
              thickness: wallThickness,
              length: length,
              height: height,
              plasterSides: plasterSides,
            ),
          );
        }
      }

      if (wallList.isNotEmpty) {
        // Áp dụng thuật toán Hybrid Ensemble
        totalCementKg = _calculateCementHybridEnsemble(wallList);
      }
    }

    return totalCementKg;
  }

  /// Thuật toán Hybrid Ensemble cho tính xi măng
  /// Kết hợp M1 (geometry-first) và M2 (coefficient-first)
  static double _calculateCementHybridEnsemble(List<_Wall> walls) {
    // M1: Geometry-first - tính theo thể tích vữa thực tế
    final double cementM1 = _calculateCementM1(walls);

    // M2: Coefficient-first - tính theo hệ số thực nghiệm
    final double cementM2 = _calculateCementM2(walls);

    // Ensemble: 25% M1 + 75% M2
    final double alpha = ConstructionConstants.hybridEnsembleAlpha;
    return alpha * cementM1 + (1.0 - alpha) * cementM2;
  }

  /// M1: Geometry-first - tính xi măng theo thể tích vữa thực tế
  static double _calculateCementM1(List<_Wall> walls) {
    double totalCementKg = 0.0;

    for (final wall in walls) {
      // 1. Tính thể tích tường
      final double wallVolume = wall.volume;

      // 2. Tính thể tích vữa xây theo tỷ lệ Hybrid
      final double buildingMortarVolume =
          wallVolume * ConstructionConstants.hybridMortarRatioInWall;

      // 3. Tính xi măng cho vữa xây
      final double buildingCement =
          buildingMortarVolume *
          ConstructionConstants.hybridCementRatioInMortar *
          ConstructionConstants.hybridCementDensity;

      // 4. Tính xi măng cho vữa trát (nếu có)
      double plasteringCement = 0.0;
      if (wall.plasterSides > 0) {
        final double plasterArea = wall.area * wall.plasterSides;
        plasteringCement =
            plasterArea *
            ConstructionConstants.cementForPlastering *
            (ConstructionConstants.plasterThickness / 0.01);
      }

      totalCementKg += buildingCement + plasteringCement;
    }

    return totalCementKg;
  }

  /// M2: Coefficient-first - tính xi măng theo hệ số thực nghiệm
  static double _calculateCementM2(List<_Wall> walls) {
    double volume10 = 0.0, volume20 = 0.0;
    double plasterArea = 0.0;

    // Phân loại thể tích và tính diện tích trát
    for (final wall in walls) {
      final double volume = wall.volume;

      if (CalculationUtils.isWall10cm(wall.thickness)) {
        volume10 += volume;
      } else if (CalculationUtils.isWall20cm(wall.thickness)) {
        volume20 += volume;
      } else {
        // Phân loại theo ngưỡng
        if (wall.thickness < ConstructionConstants.wallThicknessThreshold) {
          volume10 += volume;
        } else {
          volume20 += volume;
        }
      }

      // Tính diện tích trát
      if (wall.plasterSides > 0) {
        plasterArea += wall.area * wall.plasterSides;
      }
    }

    // Tính xi măng theo hệ số thực nghiệm (đã bao gồm cả xây và trát)
    final double cementFromVolume =
        volume10 * ConstructionConstants.hybridCementPerM3_10cm * 1000 +
        volume20 * ConstructionConstants.hybridCementPerM3_20cm * 1000;

    // Thêm xi măng cho trát (nếu chưa được tính trong hệ số)
    final double additionalPlasterCement =
        plasterArea *
        ConstructionConstants.cementForPlastering *
        (ConstructionConstants.plasterThickness / 0.01);

    return cementFromVolume + additionalPlasterCement;
  }

  /// Tính xi măng từ diện tích tường tổng (phương pháp fallback)
  static double _calculateCementFromWallArea(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    final double wallArea = CalculationUtils.toDouble(parameters['wallArea']);
    CalculationUtils.validateArea(wallArea);

    // Mặc định trát 2 mặt và tường 10cm nếu không có thông tin chi tiết
    final int defaultPlasterSides = 2;
    final double defaultWallThickness = 0.1; // 10cm

    // Tính xi măng cho vữa xây theo công thức mới
    final double buildingCement = _calculateCementForBuildingMortar(
      wallArea: wallArea,
      wallThickness: defaultWallThickness,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );

    // Tính xi măng cho vữa trát theo TCKTXD01
    final double plasteringCement =
        wallArea *
        ConstructionConstants.cementForPlastering *
        (ConstructionConstants.plasterThickness / 0.01) *
        defaultPlasterSides;

    return buildingCement + plasteringCement;
  }

  /// Tính xi măng cho vữa xây theo công thức mới
  /// Xi măng = Vữa xây × 250kg/m³
  /// Vữa xây = Thể tích tường - Thể tích gạch
  static double _calculateCementForBuildingMortar({
    required double wallArea,
    required double wallThickness,
    required double brickLength,
    required double brickWidth,
    required double brickHeight,
  }) {
    // 1. Tính thể tích tường
    final double wallVolume = wallArea * wallThickness;

    // 2. Tính số lượng gạch cần thiết
    final String wallThicknessStr = wallThickness == 0.20 ? "20" : "10";
    final double brickQuantity = BrickCalculator.calculateBrickQuantityForWall(
      wallArea: wallArea,
      wallThickness: wallThicknessStr,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );

    // 3. Tính thể tích gạch
    final double brickVolume = brickLength * brickWidth * brickHeight;
    final double totalBrickVolume = brickQuantity * brickVolume;

    // 4. Tính thể tích vữa xây: Vₓ = Thể tích tường - Thể tích gạch
    final double buildingMortarVolume = wallVolume - totalBrickVolume;

    // 5. Tính xi măng cho vữa xây: Xi măng = Vữa xây × 250kg/m³
    final double buildingCement =
        buildingMortarVolume * ConstructionConstants.cementForMortar;

    return buildingCement;
  }
}

/// Lớp đại diện cho một bức tường với thông tin trát (internal use)
class _Wall {
  final double thickness; // độ dày (m)
  final double length; // chiều dài (m)
  final double height; // chiều cao (m)
  final int plasterSides; // số mặt trát

  const _Wall({
    required this.thickness,
    required this.length,
    required this.height,
    required this.plasterSides,
  });

  /// Thể tích tường (m³)
  double get volume => thickness * length * height;

  /// Diện tích tường (m²)
  double get area => length * height;
}
