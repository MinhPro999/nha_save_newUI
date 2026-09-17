import '../utils/calculation_utils.dart';
import '../calculators/brick_calculator.dart';
import '../calculators/cement_calculator.dart';
import '../calculators/sand_calculator.dart';
import '../calculators/steel_calculator.dart';
import '../calculators/stone_calculator.dart';
import '../calculators/tile_calculator.dart';
import '../calculators/paint_calculator.dart';
import '../calculators/door_calculator.dart';
import '../calculators/custom_material_calculator.dart';

/// Lớp tính toán vật liệu xây dựng - Orchestrator
/// Delegate các phương thức tính toán cho calculator tương ứng
class MaterialCalculator {
  // ==================== PHƯƠNG THỨC TÍNH TOÁN CHO TỪNG LOẠI VẬT LIỆU ====================

  /// Tính số lượng gạch xây
  /// Delegate cho BrickCalculator
  static double calculateBrickQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.2,
    double brickWidth = 0.1,
    double brickHeight = 0.05,
  }) {
    return BrickCalculator.calculateQuantity(
      parameters,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );
  }

  /// Tính khối lượng cát xây
  /// Delegate cho SandCalculator
  static double calculateSandQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    return SandCalculator.calculateQuantity(
      parameters,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );
  }

  /// Tính khối lượng cát trát
  /// Delegate cho PlasteringSandCalculator
  static double calculatePlasteringSandQuantity(
    Map<String, dynamic> parameters,
  ) {
    return PlasteringSandCalculator.calculateQuantity(parameters);
  }

  /// Tính khối lượng xi măng
  /// Delegate cho CementCalculator
  static double calculateCementQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    return CementCalculator.calculateQuantity(
      parameters,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );
  }

  /// Tính khối lượng nước
  /// Delegate cho CustomMaterialCalculator
  static double calculateWaterQuantity(
    Map<String, dynamic> parameters, {
    double brickLength = 0.22,
    double brickWidth = 0.10,
    double brickHeight = 0.05,
  }) {
    return CustomMaterialCalculator.calculateWaterQuantity(
      parameters,
      brickLength: brickLength,
      brickWidth: brickWidth,
      brickHeight: brickHeight,
    );
  }

  /// Tính khối lượng thép
  /// Delegate cho SteelCalculator
  static double calculateSteelQuantity(Map<String, dynamic> parameters) {
    return SteelCalculator.calculateQuantity(parameters);
  }

  /// Tính khối lượng đá
  /// Delegate cho StoneCalculator
  static double calculateStoneQuantity(Map<String, dynamic> parameters) {
    return StoneCalculator.calculateQuantity(parameters);
  }

  /// Tính khối lượng cát bê tông
  /// Delegate cho CustomMaterialCalculator
  static double calculateConcreteSandQuantity(Map<String, dynamic> parameters) {
    return CustomMaterialCalculator.calculateConcreteSandQuantity(parameters);
  }

  /// Tính diện tích gạch ốp lát 60x60
  /// Delegate cho TileCalculator
  static double calculateTile6060Quantity(Map<String, dynamic> parameters) {
    return TileCalculator.calculateTile6060Quantity(parameters);
  }

  /// Tính diện tích ngói tây
  /// Delegate cho TileCalculator
  static double calculateRoofTileQuantity(Map<String, dynamic> parameters) {
    return TileCalculator.calculateRoofTileQuantity(parameters);
  }

  /// Tính diện tích tôn thường
  /// Delegate cho TileCalculator
  static double calculateMetalSheetQuantity(Map<String, dynamic> parameters) {
    return TileCalculator.calculateMetalSheetQuantity(parameters);
  }

  /// Tính diện tích tôn xốp
  /// Delegate cho TileCalculator
  static double calculateInsulatedMetalQuantity(
    Map<String, dynamic> parameters,
  ) {
    return TileCalculator.calculateInsulatedMetalQuantity(parameters);
  }

  /// Tính diện tích thạch cao
  /// Delegate cho CustomMaterialCalculator
  static double calculateGypsumQuantity(Map<String, dynamic> parameters) {
    return CustomMaterialCalculator.calculateGypsumQuantity(parameters);
  }

  /// Tính diện tích sơn ngoại thất
  /// Delegate cho PaintCalculator
  static double calculateExteriorPaintQuantity(
    Map<String, dynamic> parameters,
  ) {
    return PaintCalculator.calculateExteriorPaintQuantity(parameters);
  }

  /// Tính diện tích sơn nội thất
  /// Delegate cho PaintCalculator
  static double calculateInteriorPaintQuantity(
    Map<String, dynamic> parameters,
  ) {
    return PaintCalculator.calculateInteriorPaintQuantity(parameters);
  }

  /// Tính diện tích cửa nhôm Xingfa
  /// Delegate cho DoorCalculator
  static double calculateAluminumDoorQuantity(Map<String, dynamic> parameters) {
    return DoorCalculator.calculateAluminumDoorQuantity(parameters);
  }

  /// Tính số lượng cửa nhựa composite
  /// Delegate cho DoorCalculator
  static double calculateCompositeDoorQuantity(
    Map<String, dynamic> parameters,
  ) {
    return DoorCalculator.calculateCompositeDoorQuantity(parameters);
  }

  /// Tính diện tích nhân công xây dựng
  /// Delegate cho CustomMaterialCalculator
  static double calculateLaborQuantity(Map<String, dynamic> parameters) {
    return CustomMaterialCalculator.calculateLaborQuantity(parameters);
  }

  /// Tính diện tích nhân công điện nước
  /// Delegate cho CustomMaterialCalculator
  static double calculatePlumbingLaborQuantity(
    Map<String, dynamic> parameters,
  ) {
    return CustomMaterialCalculator.calculatePlumbingLaborQuantity(parameters);
  }

  /// Tính diện tích vật tư điện nước
  /// Delegate cho CustomMaterialCalculator
  static double calculatePlumbingMaterialQuantity(
    Map<String, dynamic> parameters,
  ) {
    return CustomMaterialCalculator.calculatePlumbingMaterialQuantity(
      parameters,
    );
  }

  /// Tính khối lượng vật liệu tùy chỉnh
  /// Delegate cho CustomMaterialCalculator
  static double calculateCustomMaterialQuantity(
    Map<String, dynamic> parameters,
    String measurementUnit,
  ) {
    return CustomMaterialCalculator.calculateQuantity(
      parameters,
      measurementUnit,
    );
  }

  // ==================== UTILITY METHODS ====================

  /// Tính tổng diện tích các tầng từ danh sách tầng
  /// [floors]: Danh sách các tầng
  static double calculateTotalFloorArea(List<dynamic> floors) {
    return CalculationUtils.calculateTotalFloorArea(floors);
  }

  // ==================== PHƯƠNG THỨC TÍNH TOÁN TỔNG HỢP ====================

  /// Tính toán vật liệu dựa trên thông số chi tiết
  ///
  /// [detailedParams]: Thông số chi tiết từ người dùng
  /// [selectedMaterialIds]: Danh sách ID vật liệu được chọn
  /// [brickDimensions]: Kích thước viên gạch (chiều dài, chiều rộng, chiều cao)
  /// [floors]: Danh sách các tầng từ dự án (để tính diện tích cho nhân công)
  static Map<String, dynamic> calculateMaterialsFromDetailedParams(
    Map<String, dynamic> detailedParams, {
    List<String>? selectedMaterialIds,
    Map<String, double>? brickDimensions,
    List<dynamic>? floors,
  }) {
    // Kết quả tính toán
    Map<String, Map<String, double>> intermediateResults = {};
    Map<String, double> quantities = {};
    Map<String, double> costs = {};

    // Thông số gạch mặc định (m) - có thể được ghi đè bởi thông số từ MaterialProvider
    double brickLength = brickDimensions?['length'] ?? 0.22;
    double brickWidth = brickDimensions?['width'] ?? 0.10;
    double brickHeight = brickDimensions?['height'] ?? 0.05;

    // Tính toán vật liệu cho tường
    if (detailedParams.containsKey('walls')) {
      _calculateWallMaterials(
        detailedParams,
        selectedMaterialIds,
        quantities,
        intermediateResults,
        brickLength,
        brickWidth,
        brickHeight,
      );
    }

    // Tính toán vật liệu cho móng
    if (detailedParams.containsKey('foundation')) {
      _calculateFoundationMaterials(
        detailedParams,
        selectedMaterialIds,
        quantities,
        intermediateResults,
      );
    }

    // Tính toán vật liệu cho cửa
    if (detailedParams.containsKey('doors')) {
      _calculateDoorMaterials(
        detailedParams,
        selectedMaterialIds,
        quantities,
        intermediateResults,
      );
    }

    // Tính toán vật liệu cho nhà vệ sinh và khác
    if (detailedParams.containsKey('others')) {
      _calculateOtherMaterials(
        detailedParams,
        selectedMaterialIds,
        quantities,
        intermediateResults,
        floors,
      );
    }

    return {
      'quantities': quantities,
      'costs': costs,
      'intermediateResults': intermediateResults,
    };
  }

  // ==================== HELPER METHODS ====================

  /// Tính toán vật liệu cho tường
  static void _calculateWallMaterials(
    Map<String, dynamic> detailedParams,
    List<String>? selectedMaterialIds,
    Map<String, double> quantities,
    Map<String, Map<String, double>> intermediateResults,
    double brickLength,
    double brickWidth,
    double brickHeight,
  ) {
    Map<String, dynamic> wallsData = detailedParams['walls'];

    if (wallsData.containsKey('walls')) {
      final List<dynamic> walls = wallsData['walls'] as List<dynamic>;

      // Tính gạch
      if (selectedMaterialIds?.contains('Gạch xây') ?? false) {
        final brickQuantity = calculateBrickQuantity(
          {'walls': wallsData},
          brickLength: brickLength,
          brickWidth: brickWidth,
          brickHeight: brickHeight,
        );
        quantities['Gạch xây'] = CalculationUtils.roundToDecimal(
          brickQuantity,
          2,
        );
      }

      // Tính xi măng
      if (selectedMaterialIds?.contains('Xi măng') ?? false) {
        final cementQuantity = calculateCementQuantity(
          {'walls': wallsData},
          brickLength: brickLength,
          brickWidth: brickWidth,
          brickHeight: brickHeight,
        );
        quantities['Xi măng'] = CalculationUtils.roundToDecimal(
          cementQuantity,
          2,
        );
      }

      // Tính cát xây
      if (selectedMaterialIds?.contains('Cát xây') ?? false) {
        final sandQuantity = calculateSandQuantity(
          {'walls': wallsData},
          brickLength: brickLength,
          brickWidth: brickWidth,
          brickHeight: brickHeight,
        );
        quantities['Cát xây'] = CalculationUtils.roundToDecimal(
          sandQuantity,
          2,
        );
      }

      // Tính cát trát
      if (selectedMaterialIds?.contains('Cát trát') ?? false) {
        double totalPlasterArea = 0.0;
        for (final wall in walls) {
          final double length = CalculationUtils.toDouble(wall['length']);
          final double height = CalculationUtils.toDouble(wall['height']);
          final int plasterSides = wall['plasterSides'] ?? 2;
          totalPlasterArea += length * height * plasterSides;
        }
        final plasterSandQuantity = calculatePlasteringSandQuantity({
          'area': totalPlasterArea,
        });
        quantities['Cát trát'] = CalculationUtils.roundToDecimal(
          plasterSandQuantity,
          2,
        );
      }

      // Tính nước
      if (selectedMaterialIds?.contains('Nước') ?? false) {
        final waterQuantity = calculateWaterQuantity(
          {'walls': wallsData},
          brickLength: brickLength,
          brickWidth: brickWidth,
          brickHeight: brickHeight,
        );
        quantities['Nước'] = CalculationUtils.roundToDecimal(waterQuantity, 2);
      }

      // Tính sơn nội thất
      if (selectedMaterialIds?.contains('Sơn nội thất') ?? false) {
        final interiorPaintQuantity = calculateInteriorPaintQuantity({
          'walls': wallsData,
          'doors':
              detailedParams['doors'], // Truyền thông tin cửa để trừ diện tích
        });
        quantities['Sơn nội thất'] = CalculationUtils.roundToDecimal(
          interiorPaintQuantity,
          2,
        );
      }
    }
  }

  /// Tính toán vật liệu cho móng
  static void _calculateFoundationMaterials(
    Map<String, dynamic> detailedParams,
    List<String>? selectedMaterialIds,
    Map<String, double> quantities,
    Map<String, Map<String, double>> intermediateResults,
  ) {
    Map<String, dynamic> foundation = detailedParams['foundation'];
    double totalFoundationLength = 0.0;

    if (foundation.containsKey('lengths')) {
      final List<dynamic> foundationLengths =
          foundation['lengths'] as List<dynamic>;
      for (final length in foundationLengths) {
        totalFoundationLength += CalculationUtils.toDouble(length);
      }
    } else if (foundation.containsKey('length')) {
      totalFoundationLength = CalculationUtils.toDouble(foundation['length']);
    }

    if (totalFoundationLength > 0) {
      // Giả định chiều rộng móng là 0.3m và chiều cao là 0.5m
      double foundationVolume = totalFoundationLength * 0.3 * 0.5;

      if (selectedMaterialIds?.contains('Bê tông') ?? false) {
        quantities['Bê tông'] = CalculationUtils.roundToDecimal(
          foundationVolume,
          2,
        );
      }

      if (selectedMaterialIds?.contains('Thép') ?? false) {
        final steelQuantity = calculateSteelQuantity({
          'length': totalFoundationLength,
          'quantity': 10, // Giả định 10 thanh thép
        });
        quantities['Thép'] = CalculationUtils.roundToDecimal(steelQuantity, 2);
      }

      if (selectedMaterialIds?.contains('Đá') ?? false) {
        final stoneQuantity = calculateStoneQuantity({
          'volume': foundationVolume * 0.7,
        });
        quantities['Đá'] = CalculationUtils.roundToDecimal(stoneQuantity, 2);
      }
    }
  }

  /// Tính toán vật liệu cho cửa
  static void _calculateDoorMaterials(
    Map<String, dynamic> detailedParams,
    List<String>? selectedMaterialIds,
    Map<String, double> quantities,
    Map<String, Map<String, double>> intermediateResults,
  ) {
    Map<String, dynamic> doors = detailedParams['doors'];

    // Tính tổng diện tích các loại cửa
    double totalDoorArea = 0.0;

    // Cửa sổ
    if (doors.containsKey('windows')) {
      final List<dynamic> windows = doors['windows'] as List<dynamic>;
      for (final window in windows) {
        final double width = CalculationUtils.toDouble(window['width']);
        final double height = CalculationUtils.toDouble(window['height']);
        final int quantity = window['quantity'] ?? 1;
        totalDoorArea += width * height * quantity;
      }
    }

    // Cửa đi
    if (doors.containsKey('doors')) {
      final List<dynamic> doorsList = doors['doors'] as List<dynamic>;
      for (final door in doorsList) {
        final double width = CalculationUtils.toDouble(door['width']);
        final double height = CalculationUtils.toDouble(door['height']);
        final int quantity = door['quantity'] ?? 1;
        totalDoorArea += width * height * quantity;
      }
    }

    // Cửa cuốn
    if (doors.containsKey('rollingDoors')) {
      final List<dynamic> rollingDoors = doors['rollingDoors'] as List<dynamic>;
      for (final rollingDoor in rollingDoors) {
        final double width = CalculationUtils.toDouble(rollingDoor['width']);
        final double height = CalculationUtils.toDouble(rollingDoor['height']);
        final int quantity = rollingDoor['quantity'] ?? 1;
        totalDoorArea += width * height * quantity;
      }
    }

    if (totalDoorArea > 0) {
      if (selectedMaterialIds?.contains('Nhôm') ?? false) {
        final aluminumQuantity = calculateAluminumDoorQuantity({
          'width': totalDoorArea,
          'height': 1.0,
        });
        quantities['Nhôm'] = CalculationUtils.roundToDecimal(
          aluminumQuantity * 3,
          2,
        ); // 3kg/m²
      }
    }
  }

  /// Tính toán vật liệu khác (nhà vệ sinh, nhân công, v.v.)
  static void _calculateOtherMaterials(
    Map<String, dynamic> detailedParams,
    List<String>? selectedMaterialIds,
    Map<String, double> quantities,
    Map<String, Map<String, double>> intermediateResults,
    List<dynamic>? floors,
  ) {
    Map<String, dynamic> others = detailedParams['others'];

    // Tính diện tích sàn tổng cho nhân công
    double totalFloorArea = 0.0;
    if (floors != null) {
      totalFloorArea = calculateTotalFloorArea(floors);
    }

    // Nhân công xây dựng
    if ((selectedMaterialIds?.contains('Nhân công xây dựng') ?? false) &&
        totalFloorArea > 0) {
      final laborQuantity = calculateLaborQuantity({'area': totalFloorArea});
      quantities['Nhân công xây dựng'] = CalculationUtils.roundToDecimal(
        laborQuantity,
        2,
      );
    }

    // Nhân công điện nước
    if ((selectedMaterialIds?.contains('Nhân công điện nước') ?? false) &&
        totalFloorArea > 0) {
      final plumbingLaborQuantity = calculatePlumbingLaborQuantity({
        'area': totalFloorArea,
      });
      quantities['Nhân công điện nước'] = CalculationUtils.roundToDecimal(
        plumbingLaborQuantity,
        2,
      );
    }

    // Vật tư điện nước
    if ((selectedMaterialIds?.contains('Vật tư điện nước') ?? false) &&
        totalFloorArea > 0) {
      final plumbingMaterialQuantity = calculatePlumbingMaterialQuantity({
        'area': totalFloorArea,
      });
      quantities['Vật tư điện nước'] = CalculationUtils.roundToDecimal(
        plumbingMaterialQuantity,
        2,
      );
    }

    // Thạch cao
    if ((selectedMaterialIds?.contains('Thạch cao') ?? false) &&
        others.containsKey('gypsumCeilingArea')) {
      final gypsumQuantity = calculateGypsumQuantity({
        'gypsumCeilingArea': others['gypsumCeilingArea'],
      });
      quantities['Thạch cao'] = CalculationUtils.roundToDecimal(
        gypsumQuantity,
        2,
      );
    }
  }
}
