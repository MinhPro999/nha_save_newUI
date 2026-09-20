import 'dart:math' as math;
import '../constants/construction_constants.dart';
import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán gạch ốp lát và ngói
class TileCalculator {
  /// Tính diện tích gạch ốp lát 60x60
  ///
  /// Dựa trên diện tích bề mặt
  static double calculateTile6060Quantity(Map<String, dynamic> parameters) {
    final double surfaceArea = parameters['surfaceArea'] ?? 0.0;

    // Validation
    CalculationUtils.validateArea(surfaceArea);

    // Tính số lượng gạch cần thiết (thêm 10% cho hao hụt và cắt)
    return (surfaceArea / ConstructionConstants.standardTileArea) * 1.1;
  }

  /// Tính diện tích ngói tây
  ///
  /// Dựa trên diện tích mái
  static double calculateRoofTileQuantity(Map<String, dynamic> parameters) {
    final double area = parameters['area'] ?? 0.0;

    // Validation
    CalculationUtils.validateArea(area);

    // Diện tích mái ngói bằng diện tích đã nhập
    return area;
  }

  /// Tính diện tích tôn thường
  ///
  /// Dựa trên diện tích mái (thêm 5% cho phần chồng mí và hao hụt)
  static double calculateMetalSheetQuantity(Map<String, dynamic> parameters) {
    final double area = parameters['area'] ?? 0.0;

    // Validation
    CalculationUtils.validateArea(area);

    return area * 1.05;
  }

  /// Tính diện tích tôn xốp
  ///
  /// Dựa trên diện tích mái (thêm 5% cho phần chồng mí và hao hụt)
  static double calculateInsulatedMetalQuantity(
    Map<String, dynamic> parameters,
  ) {
    final double area = parameters['area'] ?? 0.0;

    // Validation
    CalculationUtils.validateArea(area);

    return area * 1.05;
  }

  /// Tính số lượng gạch ốp lát theo kích thước tùy chỉnh
  /// [surfaceArea]: Diện tích cần ốp lát (m²)
  /// [tileLength]: Chiều dài viên gạch (m)
  /// [tileWidth]: Chiều rộng viên gạch (m)
  /// [wasteFactor]: Hệ số hao hụt (mặc định 10%)
  static double calculateCustomTileQuantity({
    required double surfaceArea,
    required double tileLength,
    required double tileWidth,
    double wasteFactor = 0.1,
  }) {
    // Validation
    CalculationUtils.validateArea(surfaceArea);
    CalculationUtils.validateNonNegative(tileLength, 'Chiều dài gạch');
    CalculationUtils.validateNonNegative(tileWidth, 'Chiều rộng gạch');
    CalculationUtils.validateNonNegative(wasteFactor, 'Hệ số hao hụt');

    if (tileLength <= 0 || tileWidth <= 0) {
      throw ArgumentError('Kích thước gạch phải lớn hơn 0');
    }

    // Tính diện tích một viên gạch
    final double tileArea = tileLength * tileWidth;

    // Tính số lượng gạch cần thiết
    final double tilesNeeded = surfaceArea / tileArea;

    // Áp dụng hệ số hao hụt
    return CalculationUtils.applyWasteFactor(tilesNeeded, wasteFactor);
  }

  /// Tính số lượng gạch men cho nhà vệ sinh
  /// [bathroomArea]: Diện tích nhà vệ sinh (m²)
  /// [wallHeight]: Chiều cao tường (m), mặc định 2.5m
  /// [tileSize]: Kích thước gạch (m), mặc định 0.3x0.3m
  /// [wasteFactor]: Hệ số hao hụt (mặc định 15%)
  static double calculateBathroomTileQuantity({
    required double bathroomArea,
    double wallHeight = 2.5,
    double tileSize = 0.3,
    double wasteFactor = 0.15,
  }) {
    // Validation
    CalculationUtils.validateArea(bathroomArea);
    CalculationUtils.validateNonNegative(wallHeight, 'Chiều cao tường');
    CalculationUtils.validateNonNegative(tileSize, 'Kích thước gạch');

    // Ước tính chu vi nhà vệ sinh (giả định hình vuông)
    final double perimeter = 4 * math.sqrt(bathroomArea);

    // Tính diện tích tường cần ốp gạch
    final double wallArea = perimeter * wallHeight;

    // Tính diện tích sàn cần lát gạch
    final double floorArea = bathroomArea;

    // Tổng diện tích cần gạch
    final double totalArea = wallArea + floorArea;

    // Tính số lượng gạch
    return calculateCustomTileQuantity(
      surfaceArea: totalArea,
      tileLength: tileSize,
      tileWidth: tileSize,
      wasteFactor: wasteFactor,
    );
  }

  /// Tính số lượng ngói theo loại
  /// [roofArea]: Diện tích mái (m²)
  /// [tileType]: Loại ngói ('clay', 'concrete', 'metal')
  /// [roofSlope]: Độ dốc mái (độ), mặc định 30 độ
  static double calculateRoofTileByType({
    required double roofArea,
    required String tileType,
    double roofSlope = 30.0,
  }) {
    // Validation
    CalculationUtils.validateArea(roofArea);
    CalculationUtils.validateNonNegative(roofSlope, 'Độ dốc mái');

    // Hệ số điều chỉnh theo độ dốc mái
    double slopeFactor = 1.0;
    if (roofSlope > 45) {
      slopeFactor = 1.2;
    } else if (roofSlope > 30) {
      slopeFactor = 1.1;
    }

    // Hệ số theo loại ngói
    double tileFactor;
    switch (tileType.toLowerCase()) {
      case 'clay': // Ngói đất nung
        tileFactor = 1.0;
        break;
      case 'concrete': // Ngói bê tông
        tileFactor = 0.9;
        break;
      case 'metal': // Ngói kim loại
        tileFactor = 1.05;
        break;
      default:
        throw ArgumentError('Loại ngói không hợp lệ: $tileType');
    }

    return roofArea * slopeFactor * tileFactor;
  }

  /// Tính khối lượng keo dán gạch
  /// [tileArea]: Diện tích gạch (m²)
  /// [adhesiveThickness]: Độ dày lớp keo (mm), mặc định 3mm
  /// [adhesiveDensity]: Khối lượng riêng keo (kg/m³), mặc định 1200 kg/m³
  static double calculateTileAdhesive({
    required double tileArea,
    double adhesiveThickness = 3.0,
    double adhesiveDensity = 1200.0,
  }) {
    // Validation
    CalculationUtils.validateArea(tileArea);
    CalculationUtils.validateNonNegative(adhesiveThickness, 'Độ dày keo');
    CalculationUtils.validateNonNegative(
      adhesiveDensity,
      'Khối lượng riêng keo',
    );

    // Chuyển độ dày từ mm sang m
    final double thicknessM = adhesiveThickness / 1000.0;

    // Tính thể tích keo
    final double adhesiveVolume = tileArea * thicknessM;

    // Tính khối lượng keo (kg)
    final double adhesiveWeight = adhesiveVolume * adhesiveDensity;

    // Chuyển sang tấn
    return CalculationUtils.kgToTon(adhesiveWeight);
  }

  /// Tính khối lượng vữa chà ron
  /// [tileArea]: Diện tích gạch (m²)
  /// [jointWidth]: Độ rộng mạch (mm), mặc định 2mm
  /// [jointDepth]: Độ sâu mạch (mm), mặc định 3mm
  /// [groutDensity]: Khối lượng riêng vữa chà ron (kg/m³), mặc định 1800 kg/m³
  static double calculateGrout({
    required double tileArea,
    double jointWidth = 2.0,
    double jointDepth = 3.0,
    double groutDensity = 1800.0,
  }) {
    // Validation
    CalculationUtils.validateArea(tileArea);
    CalculationUtils.validateNonNegative(jointWidth, 'Độ rộng mạch');
    CalculationUtils.validateNonNegative(jointDepth, 'Độ sâu mạch');
    CalculationUtils.validateNonNegative(groutDensity, 'Khối lượng riêng vữa');

    // Ước tính tỷ lệ mạch chà ron (khoảng 5% diện tích)
    const double jointRatio = 0.05;

    // Chuyển độ sâu từ mm sang m
    final double depthM = jointDepth / 1000.0;

    // Tính thể tích vữa chà ron
    final double groutVolume = tileArea * jointRatio * depthM;

    // Tính khối lượng vữa (kg)
    final double groutWeight = groutVolume * groutDensity;

    // Chuyển sang tấn
    return CalculationUtils.kgToTon(groutWeight);
  }

  /// Tính tổng chi phí vật liệu ốp lát
  /// [tileQuantity]: Số lượng gạch
  /// [tilePrice]: Giá gạch (VND/viên hoặc VND/m²)
  /// [adhesiveQuantity]: Khối lượng keo dán (tấn)
  /// [adhesivePrice]: Giá keo dán (VND/tấn)
  /// [groutQuantity]: Khối lượng vữa chà ron (tấn)
  /// [groutPrice]: Giá vữa chà ron (VND/tấn)
  static double calculateTotalTileCost({
    required double tileQuantity,
    required double tilePrice,
    required double adhesiveQuantity,
    required double adhesivePrice,
    required double groutQuantity,
    required double groutPrice,
  }) {
    final double tileCost = tileQuantity * tilePrice;
    final double adhesiveCost = adhesiveQuantity * adhesivePrice;
    final double groutCost = groutQuantity * groutPrice;

    return tileCost + adhesiveCost + groutCost;
  }
}
