import '../models/brick.dart';
import '../constants/construction_constants.dart';
import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán gạch xây
/// Tuân thủ thuật toán Hybrid tối ưu từ template
class BrickCalculator {
  /// Tính số lượng gạch xây theo thuật toán Hybrid
  ///
  /// Hỗ trợ 3 phương pháp:
  /// 1. Từ thông số chi tiết step5 (walls) - ưu tiên cao nhất, sử dụng Hybrid
  /// 2. Theo loại tường (wallType) - ưu tiên trung bình, sử dụng hệ số cố định
  /// 3. Theo kích thước (length, width, height) - phương pháp cũ
  static double calculateQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.2,
    double brickWidth = 0.1,
    double brickHeight = 0.05,
  }) {
    // Phương pháp 1: Từ thông số chi tiết step5 - sử dụng Hybrid Algorithm
    if (parameters.containsKey('walls') && parameters['walls'] is Map) {
      return _calculateBrickFromDetailedParameters(
        parameters,
        brickLength: brickLength,
        brickWidth: brickWidth,
        brickHeight: brickHeight,
      );
    }
    // Phương pháp 2: Theo loại tường - sử dụng hệ số cố định
    else if (parameters.containsKey('wallType')) {
      return _calculateBrickByWallType(
        parameters,
        brickLength,
        brickWidth,
        brickHeight,
      );
    }
    // Phương pháp 3: Theo kích thước - phương pháp cũ
    else {
      return _calculateBrickByDimensions(
        parameters,
        brickLength,
        brickWidth,
        brickHeight,
      );
    }
  }

  /// Tính số lượng gạch từ thông số chi tiết sử dụng Hybrid Algorithm
  /// Áp dụng ensemble learning: 25% M1 + 75% M2
  static double _calculateBrickFromDetailedParameters(
    Map<String, dynamic> parameters, {
    double brickLength = 0.2,
    double brickWidth = 0.1,
    double brickHeight = 0.05,
  }) {
    final Map<String, dynamic> wallsData =
        parameters['walls'] as Map<String, dynamic>;

    // Chuẩn bị danh sách tường cho thuật toán Hybrid
    List<_Wall> walls = [];

    if (wallsData.containsKey('walls')) {
      final List<dynamic> wallsList = wallsData['walls'] as List<dynamic>;
      for (final wall in wallsList) {
        final double length = CalculationUtils.toDouble(wall['length']);
        final double height = CalculationUtils.toDouble(wall['height']);
        final String wallType = wall['type'] ?? '10';

        if (length > 0 && height > 0) {
          // Chuyển đổi loại tường thành độ dày
          final double thickness = wallType == '20' ? 0.20 : 0.10;
          walls
              .add(_Wall(thickness: thickness, length: length, height: height));
        }
      }
    }
    // Tương thích với dữ liệu cũ
    else if (wallsData.containsKey('area')) {
      final double wallArea = CalculationUtils.toDouble(wallsData['area']);
      if (wallArea > 0) {
        // Giả định tường vuông với chiều cao 3m
        final double length = wallArea / 3.0;
        // Giả định 70% tường 10cm, 30% tường 20cm
        walls.add(_Wall(thickness: 0.10, length: length * 0.7, height: 3.0));
        walls.add(_Wall(thickness: 0.20, length: length * 0.3, height: 3.0));
      }
    }

    if (walls.isEmpty) return 0.0;

    // Áp dụng thuật toán Hybrid Ensemble
    return _calculateBrickHybridEnsemble(walls);
  }

  /// Thuật toán Hybrid Ensemble cho tính gạch
  /// Kết hợp M1 (geometry-first) và M2 (coefficient-first)
  static double _calculateBrickHybridEnsemble(List<_Wall> walls) {
    // M1: Geometry-first - sử dụng hệ số cố định theo diện tích
    final double brickM1 = _calculateBrickM1(walls);

    // M2: Coefficient-first - sử dụng hệ số theo thể tích
    final double brickM2 = _calculateBrickM2(walls);

    // Ensemble: 25% M1 + 75% M2
    final double alpha = ConstructionConstants.hybridEnsembleAlpha;
    return alpha * brickM1 + (1.0 - alpha) * brickM2;
  }

  /// M1: Geometry-first - tính gạch theo hệ số diện tích cố định
  static double _calculateBrickM1(List<_Wall> walls) {
    double area10 = 0.0, area20 = 0.0;

    // Phân loại diện tích theo loại tường
    for (final wall in walls) {
      final double area = wall.area;
      if (CalculationUtils.isWall10cm(wall.thickness)) {
        area10 += area;
      } else if (CalculationUtils.isWall20cm(wall.thickness)) {
        area20 += area;
      } else {
        // Phân loại theo ngưỡng
        if (wall.thickness < ConstructionConstants.wallThicknessThreshold) {
          area10 += area;
        } else {
          area20 += area;
        }
      }
    }

    // Tính số viên gạch theo hệ số cố định
    final double bricksFromArea =
        area10 * ConstructionConstants.hybridBricksPerM2_10cm +
            area20 * ConstructionConstants.hybridBricksPerM2_20cm;

    // Áp dụng hao hụt và khấu trừ cửa
    final double wasteMultiplier = 1.0 + ConstructionConstants.hybridBrickWaste;
    final double openingMultiplier = CalculationUtils.clamp01(
        1.0 - ConstructionConstants.hybridOpeningsDeduction);

    return bricksFromArea * wasteMultiplier * openingMultiplier;
  }

  /// M2: Coefficient-first - tính gạch theo hệ số thể tích
  static double _calculateBrickM2(List<_Wall> walls) {
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

    // Tính số viên gạch theo hệ số thể tích
    return volume10 * ConstructionConstants.hybridBrickPerM3_10cm +
        volume20 * ConstructionConstants.hybridBrickPerM3_20cm;
  }

  /// Tính số lượng gạch dựa trên loại tường (phương pháp truyền thống)
  static double _calculateBrickByWallType(
    Map<String, dynamic> parameters,
    double brickLength,
    double brickWidth,
    double brickHeight,
  ) {
    final WallType wallType = parameters['wallType'] as WallType;
    final double length = parameters['length'] ?? 0.0;
    final double height = parameters['height'] ?? 0.0;
    final double wallArea = length * height;

    // Số lượng gạch trên mỗi m² tường (hệ số truyền thống)
    double bricksPerSquareMeter;
    switch (wallType) {
      case WallType.wall10cmNoPlaster:
      case WallType.wall10cm1Side:
      case WallType.wall10cm2Side:
        bricksPerSquareMeter = 65; // Tường 10cm
        break;
      case WallType.wall20cmNoPlaster:
      case WallType.wall20cm1Side:
      case WallType.wall20cm2Side:
        bricksPerSquareMeter = 130; // Tường 20cm
        break;
    }

    // Tính số lượng gạch cần thiết (thêm 3% cho hao hụt)
    return wallArea * bricksPerSquareMeter * 1.03;
  }

  /// Tính số lượng gạch dựa trên kích thước (phương pháp cũ)
  static double _calculateBrickByDimensions(
    Map<String, dynamic> parameters,
    double brickLength,
    double brickWidth,
    double brickHeight,
  ) {
    final double length = parameters['length'] ?? 0.0;
    final double width = parameters['width'] ?? 0.0;
    final double height = parameters['height'] ?? 0.0;

    // Tính thể tích tường và viên gạch
    final double wallVolume = length * width * height;
    final double brickVolume = brickLength * brickWidth * brickHeight;

    if (brickVolume <= 0) return 0.0;

    // Tính số lượng gạch cần thiết (thêm 5% cho hao hụt)
    return (wallVolume / brickVolume) * 1.05;
  }

  /// Tính số lượng gạch cho một bức tường cụ thể (utility method)
  /// Sử dụng trong các calculator khác
  static double calculateBrickQuantityForWall({
    required double wallArea,
    required String wallThickness,
    required double brickLength,
    required double brickWidth,
    required double brickHeight,
  }) {
    // Số lượng gạch trên mỗi m² tường
    double bricksPerSquareMeter;
    if (wallThickness == "10") {
      bricksPerSquareMeter = 65; // Tường 10cm
    } else {
      bricksPerSquareMeter = 130; // Tường 20cm
    }

    // Tính số lượng gạch cần thiết (thêm 3% cho hao hụt)
    return wallArea * bricksPerSquareMeter * 1.03;
  }
}

/// Lớp đại diện cho một bức tường (internal use)
class _Wall {
  final double thickness; // độ dày (m)
  final double length; // chiều dài (m)
  final double height; // chiều cao (m)

  const _Wall({
    required this.thickness,
    required this.length,
    required this.height,
  });

  /// Thể tích tường (m³)
  double get volume => thickness * length * height;

  /// Diện tích tường (m²)
  double get area => length * height;
}
