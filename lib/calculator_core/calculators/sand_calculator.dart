import '../models/brick.dart';
import '../constants/construction_constants.dart';
import '../utils/calculation_utils.dart';
import 'brick_calculator.dart';

/// Calculator chuyên dụng cho tính toán cát xây
/// Tuân thủ thuật toán Hybrid tối ưu từ template
class SandCalculator {
  /// Tính khối lượng cát xây theo thuật toán Hybrid
  ///
  /// Hỗ trợ 3 phương pháp:
  /// 1. Từ thông số chi tiết step5 (walls) - ưu tiên cao nhất, sử dụng Hybrid
  /// 2. Theo loại tường (wallType) - ưu tiên trung bình
  /// 3. Theo thể tích (wallVolume) - phương pháp cũ
  static double calculateQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    // Phương pháp 1: Từ thông số chi tiết step5 - sử dụng Hybrid Algorithm
    if (parameters.containsKey('walls') && parameters['walls'] is Map) {
      return _calculateSandFromDetailedParameters(
        parameters,
        brickLength: brickLength,
        brickWidth: brickWidth,
        brickHeight: brickHeight,
      );
    }
    // Phương pháp 2: Theo loại tường
    else if (parameters.containsKey('wallType')) {
      return _calculateSandByWallType(
        parameters,
        brickLength: brickLength,
        brickWidth: brickWidth,
        brickHeight: brickHeight,
      );
    }
    // Phương pháp 3: Theo thể tích (phương pháp cũ)
    else {
      return _calculateSandByVolume(parameters);
    }
  }

  /// Tính lượng cát dựa trên thông số chi tiết từ step5_detailed_parameters.dart
  /// Áp dụng thuật toán Hybrid với ensemble learning
  static double _calculateSandFromDetailedParameters(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    final Map<String, dynamic> wallsData =
        parameters['walls'] as Map<String, dynamic>;

    // Chuẩn bị danh sách tường cho thuật toán Hybrid
    List<_Wall> walls = [];

    // Xử lý danh sách tường chi tiết
    if (wallsData.containsKey('walls')) {
      final List<dynamic> wallsList = wallsData['walls'] as List<dynamic>;
      for (final wall in wallsList) {
        final double length = CalculationUtils.toDouble(wall['length']);
        final double height = CalculationUtils.toDouble(wall['height']);
        final String wallThickness = wall['type'] ?? '10';
        final int plasterSides = wall['plasterSides'] ?? 2;

        if (length > 0 && height > 0) {
          final double thickness = wallThickness == "20" ? 0.20 : 0.10;
          walls.add(
            _Wall(
              thickness: thickness,
              length: length,
              height: height,
              plasterSides: plasterSides,
            ),
          );
        }
      }
    }
    // Tương thích với dữ liệu cũ
    else if (wallsData.containsKey('area')) {
      final double wallArea = CalculationUtils.toDouble(wallsData['area']);
      if (wallArea > 0) {
        // Giả định tường vuông với chiều cao 3m, trát 2 mặt
        final double length = wallArea / 3.0;
        walls.add(
          _Wall(thickness: 0.10, length: length, height: 3.0, plasterSides: 2),
        );
      }
    }

    if (walls.isEmpty) return 0.0;

    // Áp dụng thuật toán Hybrid Ensemble
    return _calculateSandHybridEnsemble(walls);
  }

  /// Thuật toán Hybrid Ensemble cho tính cát xây
  /// Kết hợp M1 (geometry-first) và M2 (coefficient-first)
  static double _calculateSandHybridEnsemble(List<_Wall> walls) {
    // M1: Geometry-first - tính theo thể tích vữa thực tế
    final double sandM1 = _calculateSandM1(walls);

    // M2: Coefficient-first - tính theo hệ số thực nghiệm
    final double sandM2 = _calculateSandM2(walls);

    // Ensemble: 25% M1 + 75% M2
    const double alpha = ConstructionConstants.hybridEnsembleAlpha;
    return alpha * sandM1 + (1.0 - alpha) * sandM2;
  }

  /// M1: Geometry-first - tính cát theo thể tích vữa thực tế
  static double _calculateSandM1(List<_Wall> walls) {
    double totalSandVolume = 0.0;

    for (final wall in walls) {
      // 1. Tính thể tích tường
      final double wallVolume = wall.volume;

      // 2. Tính thể tích vữa xây theo tỷ lệ Hybrid
      final double buildingMortarVolume =
          wallVolume * ConstructionConstants.hybridMortarRatioInWall;

      // 3. Tính thể tích vữa trát (nếu có)
      double plasterMortarVolume = 0.0;
      if (wall.plasterSides > 0) {
        plasterMortarVolume = wall.area *
            wall.plasterSides *
            ConstructionConstants.plasterThickness;
      }

      // 4. Tổng thể tích vữa
      final double totalMortarVolume =
          buildingMortarVolume + plasterMortarVolume;

      // 5. Tính cát với hệ số nở rời
      final double sandVolume = totalMortarVolume *
          ConstructionConstants.sandRatioInMortar *
          ConstructionConstants.hybridSandBulkingFactor;

      totalSandVolume += sandVolume;
    }

    return totalSandVolume;
  }

  /// M2: Coefficient-first - tính cát theo hệ số thực nghiệm
  static double _calculateSandM2(List<_Wall> walls) {
    double volume10 = 0.0, volume20 = 0.0;

    // Phân loại thể tích theo loại tường
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
    }

    // Tính cát theo hệ số thực nghiệm
    return volume10 * ConstructionConstants.hybridSandPerM3_10cm +
        volume20 * ConstructionConstants.hybridSandPerM3_20cm;
  }

  /// Tính lượng cát dựa trên loại tường (phương pháp truyền thống)
  static double _calculateSandByWallType(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    final WallType wallType = parameters['wallType'] as WallType;
    final double wallArea = parameters['wallArea'] ?? 0.0;

    String wallThickness;
    int plasterSides;

    switch (wallType) {
      case WallType.wall10cmNoPlaster:
        wallThickness = "10";
        plasterSides = 0;
        break;
      case WallType.wall10cm1Side:
        wallThickness = "10";
        plasterSides = 1;
        break;
      case WallType.wall10cm2Side:
        wallThickness = "10";
        plasterSides = 2;
        break;
      case WallType.wall20cmNoPlaster:
        wallThickness = "20";
        plasterSides = 0;
        break;
      case WallType.wall20cm1Side:
        wallThickness = "20";
        plasterSides = 1;
        break;
      case WallType.wall20cm2Side:
        wallThickness = "20";
        plasterSides = 2;
        break;
    }

    // Sử dụng công thức cải tiến
    return _calculateSandByWallSpecification(
      wallArea: wallArea,
      wallThickness: wallThickness,
      plasterSides: plasterSides,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );
  }

  /// Tính lượng cát theo công thức cải tiến
  /// Sử dụng công thức: Vữa xây = Thể tích tường - Thể tích gạch
  static double _calculateSandByWallSpecification({
    required double wallArea,
    required String wallThickness,
    required int plasterSides,
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    // Độ dày tường (m)
    final double wallThicknessM = wallThickness == "10" ? 0.10 : 0.20;

    // 1. Tính thể tích tường
    final double wallVolume = wallArea * wallThicknessM;

    // 2. Tính số lượng gạch cần thiết
    final double brickQuantity = BrickCalculator.calculateBrickQuantityForWall(
      wallArea: wallArea,
      wallThickness: wallThickness,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );

    // 3. Tính thể tích gạch
    final double brickVolume = brickLength * brickWidth * brickHeight;
    final double totalBrickVolume = brickQuantity * brickVolume;

    // 4. Tính thể tích vữa xây: Vₓ = Thể tích tường - Thể tích gạch
    final double buildingMortarVolume = wallVolume - totalBrickVolume;

    // 5. Tính thể tích vữa trát: Vₜ = A × M × d_trát (chỉ khi có trát)
    final double plasterMortarVolume = plasterSides > 0
        ? wallArea * plasterSides * ConstructionConstants.plasterThickness
        : 0.0;

    // 6. Tổng thể tích vữa: V = Vₓ + Vₜ
    final double totalMortarVolume = buildingMortarVolume + plasterMortarVolume;

    // 7. Lượng cát: Cát (m³) = V × 75%
    final double sandVolume =
        totalMortarVolume * ConstructionConstants.sandRatioInMortar;

    return sandVolume;
  }

  /// Tính lượng cát dựa trên thể tích (phương pháp cũ - giữ để tương thích)
  static double _calculateSandByVolume(Map<String, dynamic> parameters) {
    final double wallVolume = parameters['wallVolume'] ?? 0.0;
    // Tính lượng cát (0.02 m³ cát trên mỗi m³ tường)
    return wallVolume * 0.02;
  }
}

/// Calculator chuyên dụng cho tính toán cát trát
/// Tuân thủ tiêu chuẩn TCVN 9202:2012 và công thức từ request15.md
class PlasteringSandCalculator {
  /// Tính khối lượng cát trát
  ///
  /// Hỗ trợ 3 phương pháp:
  /// 1. Từ thông số chi tiết step5 (walls) - ưu tiên cao nhất
  /// 2. Theo loại tường (wallType) - ưu tiên trung bình
  /// 3. Theo diện tích (area) - phương pháp cũ
  static double calculateQuantity(Map<String, dynamic> parameters) {
    // Phương pháp 1: Từ thông số chi tiết step5
    if (parameters.containsKey('walls') && parameters['walls'] is Map) {
      return _calculatePlasteringSandFromDetailedParameters(parameters);
    }
    // Phương pháp 2: Theo loại tường
    else if (parameters.containsKey('wallType')) {
      return _calculatePlasteringSandByWallType(parameters);
    }
    // Phương pháp 3: Theo diện tích (phương pháp cũ)
    else {
      return _calculatePlasteringSandByArea(parameters);
    }
  }

  /// Tính lượng cát trát từ thông số chi tiết step5
  /// Áp dụng công thức chuẩn: Cát trát = A × M × d_trát × 0.75
  static double _calculatePlasteringSandFromDetailedParameters(
    Map<String, dynamic> parameters,
  ) {
    final Map<String, dynamic> wallsData =
        parameters['walls'] as Map<String, dynamic>;
    double totalPlasterSandVolume = 0.0;

    // Xử lý danh sách tường chi tiết
    if (wallsData.containsKey('walls')) {
      final List<dynamic> walls = wallsData['walls'] as List<dynamic>;

      for (final wall in walls) {
        final int plasterSides = wall['plasterSides'] ?? 2; // 1 hoặc 2
        final double length = CalculationUtils.toDouble(wall['length']);
        final double height = CalculationUtils.toDouble(wall['height']);

        // Tính diện tích tường
        final double wallArea = length * height;

        if (wallArea > 0 && plasterSides > 0) {
          // Áp dụng công thức chuẩn từ request15.md:
          // Cát trát = A × M × d_trát × 0.75
          final double plasterSandForThisWall = wallArea *
              plasterSides *
              ConstructionConstants.plasterThickness *
              ConstructionConstants.sandRatioInMortar;

          totalPlasterSandVolume += plasterSandForThisWall;
        }
      }
    }
    // Tương thích với dữ liệu cũ
    else if (wallsData.containsKey('area')) {
      final double wallArea = CalculationUtils.toDouble(wallsData['area']);

      if (wallArea > 0) {
        // Giả định trát 2 mặt
        const int plasterSides = 2;
        totalPlasterSandVolume = wallArea *
            plasterSides *
            ConstructionConstants.plasterThickness *
            ConstructionConstants.sandRatioInMortar;
      }
    }

    return totalPlasterSandVolume;
  }

  /// Tính lượng cát trát dựa trên diện tích (phương pháp cũ - cải tiến)
  /// Áp dụng công thức chuẩn thay vì hằng số cũ
  static double _calculatePlasteringSandByArea(
    Map<String, dynamic> parameters,
  ) {
    final double area = parameters['area'] ?? 0.0;

    // Áp dụng công thức chuẩn: Cát trát = A × d_trát × 0.75
    // (Giả định diện tích đã bao gồm số mặt trát)
    return area *
        ConstructionConstants.plasterThickness *
        ConstructionConstants.sandRatioInMortar;
  }

  /// Tính lượng cát trát dựa trên loại tường (cải tiến)
  /// Áp dụng công thức chuẩn từ request15.md
  static double _calculatePlasteringSandByWallType(
    Map<String, dynamic> parameters,
  ) {
    final WallType wallType = parameters['wallType'] as WallType;
    final double wallArea = parameters['wallArea'] ?? 0.0;

    int plasterSides;
    switch (wallType) {
      case WallType.wall10cmNoPlaster:
      case WallType.wall20cmNoPlaster:
        plasterSides = 0;
        break;
      case WallType.wall10cm1Side:
      case WallType.wall20cm1Side:
        plasterSides = 1;
        break;
      case WallType.wall10cm2Side:
      case WallType.wall20cm2Side:
        plasterSides = 2;
        break;
    }

    if (plasterSides == 0) return 0.0;

    // Áp dụng công thức chuẩn: Cát trát = A × M × d_trát × 0.75
    return wallArea *
        plasterSides *
        ConstructionConstants.plasterThickness *
        ConstructionConstants.sandRatioInMortar;
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
