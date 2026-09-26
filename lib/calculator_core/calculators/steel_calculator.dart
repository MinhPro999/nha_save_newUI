import '../constants/construction_constants.dart';
import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán thép
class SteelCalculator {
  /// Tính khối lượng thép
  ///
  /// Dựa trên chiều dài và số lượng thanh thép
  static double calculateQuantity(Map<String, dynamic> parameters) {
    final double length = parameters['length'] ?? 0.0;
    final int quantity = parameters['quantity'] ?? 0;

    // Validation
    CalculationUtils.validateNonNegative(length, 'Chiều dài thép');
    if (quantity < 0) {
      throw ArgumentError('Số lượng thép không thể âm: $quantity');
    }

    // Tính khối lượng thép (kg)
    final double totalWeight =
        length * quantity * ConstructionConstants.averageSteelWeight;

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính khối lượng thép theo đường kính cụ thể
  /// [diameter]: Đường kính thép (mm)
  /// [length]: Chiều dài thép (m)
  /// [quantity]: Số lượng thanh
  static double calculateQuantityByDiameter({
    required double diameter,
    required double length,
    required int quantity,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(diameter, 'Đường kính thép');
    CalculationUtils.validateNonNegative(length, 'Chiều dài thép');
    if (quantity < 0) {
      throw ArgumentError('Số lượng thép không thể âm: $quantity');
    }

    // Tính khối lượng riêng thép theo đường kính (kg/m)
    // Công thức: Khối lượng = π × (d/2)² × L × ρ
    // Với ρ = 7850 kg/m³ (khối lượng riêng thép)
    const double steelDensity = 7850.0; // kg/m³
    final double radius = diameter / 2000.0; // Chuyển từ mm sang m
    final double weightPerMeter = 3.14159 * radius * radius * steelDensity;

    // Tính tổng khối lượng
    final double totalWeight = weightPerMeter * length * quantity;

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính khối lượng thép cho móng
  /// Dựa trên thể tích bê tông và tỷ lệ thép
  /// [concreteVolume]: Thể tích bê tông (m³)
  /// [steelRatio]: Tỷ lệ thép (kg/m³), mặc định 80 kg/m³
  static double calculateSteelForFoundation({
    required double concreteVolume,
    double steelRatio = 80.0,
  }) {
    // Validation
    CalculationUtils.validateVolume(concreteVolume);
    CalculationUtils.validateNonNegative(steelRatio, 'Tỷ lệ thép');

    // Tính khối lượng thép (kg)
    final double totalWeight = concreteVolume * steelRatio;

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính khối lượng thép cho dầm
  /// [beamLength]: Chiều dài dầm (m)
  /// [beamWidth]: Chiều rộng dầm (m)
  /// [beamHeight]: Chiều cao dầm (m)
  /// [steelRatio]: Tỷ lệ thép (kg/m³), mặc định 120 kg/m³
  static double calculateSteelForBeam({
    required double beamLength,
    required double beamWidth,
    required double beamHeight,
    double steelRatio = 120.0,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(beamLength, 'Chiều dài dầm');
    CalculationUtils.validateNonNegative(beamWidth, 'Chiều rộng dầm');
    CalculationUtils.validateNonNegative(beamHeight, 'Chiều cao dầm');
    CalculationUtils.validateNonNegative(steelRatio, 'Tỷ lệ thép');

    // Tính thể tích dầm
    final double beamVolume = beamLength * beamWidth * beamHeight;

    // Tính khối lượng thép (kg)
    final double totalWeight = beamVolume * steelRatio;

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính khối lượng thép cho cột
  /// [columnHeight]: Chiều cao cột (m)
  /// [columnWidth]: Chiều rộng cột (m)
  /// [columnDepth]: Chiều sâu cột (m)
  /// [steelRatio]: Tỷ lệ thép (kg/m³), mặc định 150 kg/m³
  static double calculateSteelForColumn({
    required double columnHeight,
    required double columnWidth,
    required double columnDepth,
    double steelRatio = 150.0,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(columnHeight, 'Chiều cao cột');
    CalculationUtils.validateNonNegative(columnWidth, 'Chiều rộng cột');
    CalculationUtils.validateNonNegative(columnDepth, 'Chiều sâu cột');
    CalculationUtils.validateNonNegative(steelRatio, 'Tỷ lệ thép');

    // Tính thể tích cột
    final double columnVolume = columnHeight * columnWidth * columnDepth;

    // Tính khối lượng thép (kg)
    final double totalWeight = columnVolume * steelRatio;

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính khối lượng thép cho sàn
  /// [slabArea]: Diện tích sàn (m²)
  /// [slabThickness]: Độ dày sàn (m)
  /// [steelRatio]: Tỷ lệ thép (kg/m³), mặc định 100 kg/m³
  static double calculateSteelForSlab({
    required double slabArea,
    required double slabThickness,
    double steelRatio = 100.0,
  }) {
    // Validation
    CalculationUtils.validateArea(slabArea);
    CalculationUtils.validateNonNegative(slabThickness, 'Độ dày sàn');
    CalculationUtils.validateNonNegative(steelRatio, 'Tỷ lệ thép');

    // Tính thể tích sàn
    final double slabVolume = slabArea * slabThickness;

    // Tính khối lượng thép (kg)
    final double totalWeight = slabVolume * steelRatio;

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính tổng khối lượng thép cho toàn bộ công trình
  /// [foundationVolume]: Thể tích móng (m³)
  /// [beamVolume]: Thể tích dầm (m³)
  /// [columnVolume]: Thể tích cột (m³)
  /// [slabVolume]: Thể tích sàn (m³)
  static double calculateTotalSteel({
    double foundationVolume = 0.0,
    double beamVolume = 0.0,
    double columnVolume = 0.0,
    double slabVolume = 0.0,
  }) {
    double totalWeight = 0.0;

    // Thép móng (80 kg/m³)
    if (foundationVolume > 0) {
      totalWeight += foundationVolume * 80.0;
    }

    // Thép dầm (120 kg/m³)
    if (beamVolume > 0) {
      totalWeight += beamVolume * 120.0;
    }

    // Thép cột (150 kg/m³)
    if (columnVolume > 0) {
      totalWeight += columnVolume * 150.0;
    }

    // Thép sàn (100 kg/m³)
    if (slabVolume > 0) {
      totalWeight += slabVolume * 100.0;
    }

    // Chuyển đổi từ kg sang tấn
    return CalculationUtils.kgToTon(totalWeight);
  }

  /// Tính khối lượng thép theo bảng tra cứu đường kính
  /// Trả về khối lượng thép trên mét dài (kg/m)
  static double getSteelWeightPerMeter(double diameter) {
    // Bảng tra cứu khối lượng thép theo đường kính (kg/m)
    final Map<double, double> steelWeightTable = {
      6.0: 0.222, // Φ6
      8.0: 0.395, // Φ8
      10.0: 0.617, // Φ10
      12.0: 0.888, // Φ12
      14.0: 1.208, // Φ14
      16.0: 1.578, // Φ16
      18.0: 1.998, // Φ18
      20.0: 2.466, // Φ20
      22.0: 2.984, // Φ22
      25.0: 3.853, // Φ25
      28.0: 4.834, // Φ28
      32.0: 6.313, // Φ32
    };

    // Tìm khối lượng trong bảng tra cứu
    if (steelWeightTable.containsKey(diameter)) {
      return steelWeightTable[diameter]!;
    }

    // Nếu không có trong bảng, tính theo công thức
    const double steelDensity = 7850.0; // kg/m³
    final double radius = diameter / 2000.0; // Chuyển từ mm sang m
    return 3.14159 * radius * radius * steelDensity;
  }
}
