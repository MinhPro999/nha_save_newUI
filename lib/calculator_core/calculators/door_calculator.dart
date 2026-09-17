import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán cửa
class DoorCalculator {
  /// Tính diện tích cửa nhôm Xingfa
  ///
  /// Dựa trên chiều rộng và chiều cao
  static double calculateAluminumDoorQuantity(Map<String, dynamic> parameters) {
    final double width = parameters['width'] ?? 0.0;
    final double height = parameters['height'] ?? 0.0;

    // Validation
    CalculationUtils.validateNonNegative(width, 'Chiều rộng cửa');
    CalculationUtils.validateNonNegative(height, 'Chiều cao cửa');

    return width * height;
  }

  /// Tính số lượng cửa nhựa composite
  ///
  /// Dựa trên số lượng bộ cửa
  static double calculateCompositeDoorQuantity(
    Map<String, dynamic> parameters,
  ) {
    final int quantity = parameters['quantity'] ?? 0;

    // Validation
    if (quantity < 0) {
      throw ArgumentError('Số lượng cửa không thể âm: $quantity');
    }

    return quantity.toDouble();
  }

  /// Tính diện tích cửa sổ nhôm
  /// [width]: Chiều rộng cửa sổ (m)
  /// [height]: Chiều cao cửa sổ (m)
  /// [quantity]: Số lượng cửa sổ
  static double calculateAluminumWindowArea({
    required double width,
    required double height,
    required int quantity,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(width, 'Chiều rộng cửa sổ');
    CalculationUtils.validateNonNegative(height, 'Chiều cao cửa sổ');
    if (quantity < 0) {
      throw ArgumentError('Số lượng cửa sổ không thể âm: $quantity');
    }

    return width * height * quantity;
  }

  /// Tính diện tích cửa đi
  /// [width]: Chiều rộng cửa đi (m)
  /// [height]: Chiều cao cửa đi (m)
  /// [quantity]: Số lượng cửa đi
  static double calculateDoorArea({
    required double width,
    required double height,
    required int quantity,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(width, 'Chiều rộng cửa đi');
    CalculationUtils.validateNonNegative(height, 'Chiều cao cửa đi');
    if (quantity < 0) {
      throw ArgumentError('Số lượng cửa đi không thể âm: $quantity');
    }

    return width * height * quantity;
  }

  /// Tính diện tích cửa cuốn
  /// [width]: Chiều rộng cửa cuốn (m)
  /// [height]: Chiều cao cửa cuốn (m)
  /// [quantity]: Số lượng cửa cuốn
  static double calculateRollingDoorArea({
    required double width,
    required double height,
    required int quantity,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(width, 'Chiều rộng cửa cuốn');
    CalculationUtils.validateNonNegative(height, 'Chiều cao cửa cuốn');
    if (quantity < 0) {
      throw ArgumentError('Số lượng cửa cuốn không thể âm: $quantity');
    }

    return width * height * quantity;
  }

  /// Tính khối lượng nhôm cho cửa nhôm
  /// [doorArea]: Diện tích cửa (m²)
  /// [aluminumDensity]: Khối lượng nhôm trên m² (kg/m²), mặc định 5 kg/m²
  static double calculateAluminumWeight({
    required double doorArea,
    double aluminumDensity = 5.0,
  }) {
    // Validation
    CalculationUtils.validateArea(doorArea);
    CalculationUtils.validateNonNegative(
      aluminumDensity,
      'Khối lượng riêng nhôm',
    );

    return doorArea * aluminumDensity;
  }

  /// Tính diện tích kính cho cửa
  /// [doorArea]: Diện tích cửa (m²)
  /// [glassRatio]: Tỷ lệ kính trong cửa (mặc định 70%)
  static double calculateGlassArea({
    required double doorArea,
    double glassRatio = 0.7,
  }) {
    // Validation
    CalculationUtils.validateArea(doorArea);
    CalculationUtils.validateNonNegative(glassRatio, 'Tỷ lệ kính');

    if (glassRatio > 1.0) {
      throw ArgumentError('Tỷ lệ kính không thể lớn hơn 100%: $glassRatio');
    }

    return doorArea * glassRatio;
  }

  /// Tính khối lượng gỗ cho cửa gỗ
  /// [doorArea]: Diện tích cửa (m²)
  /// [doorThickness]: Độ dày cửa (m), mặc định 0.04m
  /// [woodDensity]: Khối lượng riêng gỗ (kg/m³), mặc định 600 kg/m³
  static double calculateWoodVolume({
    required double doorArea,
    double doorThickness = 0.04,
    double woodDensity = 600.0,
  }) {
    // Validation
    CalculationUtils.validateArea(doorArea);
    CalculationUtils.validateNonNegative(doorThickness, 'Độ dày cửa');
    CalculationUtils.validateNonNegative(woodDensity, 'Khối lượng riêng gỗ');

    // Tính thể tích gỗ
    final double woodVolume = doorArea * doorThickness;

    return woodVolume;
  }

  /// Tính khối lượng thép cho cửa cuốn
  /// [rollingDoorArea]: Diện tích cửa cuốn (m²)
  /// [steelDensity]: Khối lượng thép trên m² (kg/m²), mặc định 10 kg/m²
  static double calculateSteelWeight({
    required double rollingDoorArea,
    double steelDensity = 10.0,
  }) {
    // Validation
    CalculationUtils.validateArea(rollingDoorArea);
    CalculationUtils.validateNonNegative(steelDensity, 'Khối lượng riêng thép');

    return rollingDoorArea * steelDensity;
  }

  /// Tính tổng vật liệu cho tất cả các loại cửa
  /// [windows]: Danh sách cửa sổ
  /// [doors]: Danh sách cửa đi
  /// [rollingDoors]: Danh sách cửa cuốn
  static Map<String, double> calculateAllDoorMaterials({
    List<Map<String, dynamic>>? windows,
    List<Map<String, dynamic>>? doors,
    List<Map<String, dynamic>>? rollingDoors,
  }) {
    Map<String, double> materials = {
      'aluminum': 0.0,
      'glass': 0.0,
      'wood': 0.0,
      'steel': 0.0,
    };

    // Tính vật liệu cho cửa sổ
    if (windows != null) {
      for (final window in windows) {
        final double width = CalculationUtils.toDouble(window['width']);
        final double height = CalculationUtils.toDouble(window['height']);
        final int quantity = window['quantity'] ?? 1;

        final double windowArea = calculateAluminumWindowArea(
          width: width,
          height: height,
          quantity: quantity,
        );

        materials['aluminum'] =
            (materials['aluminum'] ?? 0) +
            calculateAluminumWeight(doorArea: windowArea, aluminumDensity: 3.0);
        materials['glass'] =
            (materials['glass'] ?? 0) +
            calculateGlassArea(doorArea: windowArea, glassRatio: 0.8);
      }
    }

    // Tính vật liệu cho cửa đi
    if (doors != null) {
      for (final door in doors) {
        final double width = CalculationUtils.toDouble(door['width']);
        final double height = CalculationUtils.toDouble(door['height']);
        final int quantity = door['quantity'] ?? 1;
        final String material = door['material'] ?? 'aluminum';

        final double doorArea = calculateDoorArea(
          width: width,
          height: height,
          quantity: quantity,
        );

        if (material.toLowerCase() == 'aluminum') {
          materials['aluminum'] =
              (materials['aluminum'] ?? 0) +
              calculateAluminumWeight(doorArea: doorArea);
          materials['glass'] =
              (materials['glass'] ?? 0) +
              calculateGlassArea(doorArea: doorArea, glassRatio: 0.5);
        } else if (material.toLowerCase() == 'wood') {
          materials['wood'] =
              (materials['wood'] ?? 0) +
              calculateWoodVolume(doorArea: doorArea);
        }
      }
    }

    // Tính vật liệu cho cửa cuốn
    if (rollingDoors != null) {
      for (final rollingDoor in rollingDoors) {
        final double width = CalculationUtils.toDouble(rollingDoor['width']);
        final double height = CalculationUtils.toDouble(rollingDoor['height']);
        final int quantity = rollingDoor['quantity'] ?? 1;

        final double rollingDoorArea = calculateRollingDoorArea(
          width: width,
          height: height,
          quantity: quantity,
        );

        materials['steel'] =
            (materials['steel'] ?? 0) +
            calculateSteelWeight(rollingDoorArea: rollingDoorArea);
      }
    }

    return materials;
  }

  /// Tính chi phí lắp đặt cửa
  /// [doorArea]: Diện tích cửa (m²)
  /// [doorType]: Loại cửa ('aluminum', 'wood', 'composite', 'rolling')
  /// [installationRate]: Đơn giá lắp đặt (VND/m²)
  static double calculateInstallationCost({
    required double doorArea,
    required String doorType,
    double installationRate = 200000.0, // VND/m²
  }) {
    // Validation
    CalculationUtils.validateArea(doorArea);
    CalculationUtils.validateNonNegative(installationRate, 'Đơn giá lắp đặt');

    // Hệ số điều chỉnh theo loại cửa
    double typeFactor;
    switch (doorType.toLowerCase()) {
      case 'aluminum':
        typeFactor = 1.0;
        break;
      case 'wood':
        typeFactor = 1.2;
        break;
      case 'composite':
        typeFactor = 0.8;
        break;
      case 'rolling':
        typeFactor = 1.5;
        break;
      default:
        typeFactor = 1.0;
    }

    return doorArea * installationRate * typeFactor;
  }

  /// Tính tổng chi phí cửa (vật liệu + lắp đặt)
  /// [materialCost]: Chi phí vật liệu (VND)
  /// [installationCost]: Chi phí lắp đặt (VND)
  /// [profitMargin]: Tỷ lệ lợi nhuận (mặc định 15%)
  static double calculateTotalDoorCost({
    required double materialCost,
    required double installationCost,
    double profitMargin = 0.15,
  }) {
    final double subtotal = materialCost + installationCost;
    return subtotal * (1.0 + profitMargin);
  }
}
