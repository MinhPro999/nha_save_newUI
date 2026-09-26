import '../utils/calculation_utils.dart';

/// Calculator chuyên dụng cho tính toán đá
class StoneCalculator {
  /// Tính khối lượng đá
  ///
  /// Dựa trên thể tích
  static double calculateQuantity(Map<String, dynamic> parameters) {
    final double volume = parameters['volume'] ?? 0.0;

    // Validation
    CalculationUtils.validateVolume(volume);

    // Tính lượng đá (1.0 m³ đá trên mỗi m³)
    return volume * 1.0;
  }

  /// Tính khối lượng đá cho bê tông
  /// [concreteVolume]: Thể tích bê tông (m³)
  /// [stoneRatio]: Tỷ lệ đá trong bê tông (mặc định 70%)
  static double calculateStoneForConcrete({
    required double concreteVolume,
    double stoneRatio = 0.7,
  }) {
    // Validation
    CalculationUtils.validateVolume(concreteVolume);
    CalculationUtils.validateNonNegative(stoneRatio, 'Tỷ lệ đá');

    if (stoneRatio > 1.0) {
      throw ArgumentError('Tỷ lệ đá không thể lớn hơn 100%: $stoneRatio');
    }

    // Tính lượng đá cần thiết
    return concreteVolume * stoneRatio;
  }

  /// Tính khối lượng đá cho móng
  /// [foundationLength]: Chiều dài móng (m)
  /// [foundationWidth]: Chiều rộng móng (m)
  /// [foundationHeight]: Chiều cao móng (m)
  /// [stoneRatio]: Tỷ lệ đá trong bê tông móng (mặc định 70%)
  static double calculateStoneForFoundation({
    required double foundationLength,
    required double foundationWidth,
    required double foundationHeight,
    double stoneRatio = 0.7,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(foundationLength, 'Chiều dài móng');
    CalculationUtils.validateNonNegative(foundationWidth, 'Chiều rộng móng');
    CalculationUtils.validateNonNegative(foundationHeight, 'Chiều cao móng');

    // Tính thể tích móng
    final double foundationVolume =
        foundationLength * foundationWidth * foundationHeight;

    // Tính lượng đá cho móng
    return calculateStoneForConcrete(
      concreteVolume: foundationVolume,
      stoneRatio: stoneRatio,
    );
  }

  /// Tính khối lượng đá cho sàn bê tông
  /// [slabArea]: Diện tích sàn (m²)
  /// [slabThickness]: Độ dày sàn (m)
  /// [stoneRatio]: Tỷ lệ đá trong bê tông sàn (mặc định 65%)
  static double calculateStoneForSlab({
    required double slabArea,
    required double slabThickness,
    double stoneRatio = 0.65,
  }) {
    // Validation
    CalculationUtils.validateArea(slabArea);
    CalculationUtils.validateNonNegative(slabThickness, 'Độ dày sàn');

    // Tính thể tích sàn
    final double slabVolume = slabArea * slabThickness;

    // Tính lượng đá cho sàn
    return calculateStoneForConcrete(
      concreteVolume: slabVolume,
      stoneRatio: stoneRatio,
    );
  }

  /// Tính khối lượng đá cho dầm
  /// [beamLength]: Chiều dài dầm (m)
  /// [beamWidth]: Chiều rộng dầm (m)
  /// [beamHeight]: Chiều cao dầm (m)
  /// [stoneRatio]: Tỷ lệ đá trong bê tông dầm (mặc định 68%)
  static double calculateStoneForBeam({
    required double beamLength,
    required double beamWidth,
    required double beamHeight,
    double stoneRatio = 0.68,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(beamLength, 'Chiều dài dầm');
    CalculationUtils.validateNonNegative(beamWidth, 'Chiều rộng dầm');
    CalculationUtils.validateNonNegative(beamHeight, 'Chiều cao dầm');

    // Tính thể tích dầm
    final double beamVolume = beamLength * beamWidth * beamHeight;

    // Tính lượng đá cho dầm
    return calculateStoneForConcrete(
      concreteVolume: beamVolume,
      stoneRatio: stoneRatio,
    );
  }

  /// Tính khối lượng đá cho cột
  /// [columnHeight]: Chiều cao cột (m)
  /// [columnWidth]: Chiều rộng cột (m)
  /// [columnDepth]: Chiều sâu cột (m)
  /// [stoneRatio]: Tỷ lệ đá trong bê tông cột (mặc định 68%)
  static double calculateStoneForColumn({
    required double columnHeight,
    required double columnWidth,
    required double columnDepth,
    double stoneRatio = 0.68,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(columnHeight, 'Chiều cao cột');
    CalculationUtils.validateNonNegative(columnWidth, 'Chiều rộng cột');
    CalculationUtils.validateNonNegative(columnDepth, 'Chiều sâu cột');

    // Tính thể tích cột
    final double columnVolume = columnHeight * columnWidth * columnDepth;

    // Tính lượng đá cho cột
    return calculateStoneForConcrete(
      concreteVolume: columnVolume,
      stoneRatio: stoneRatio,
    );
  }

  /// Tính khối lượng đá cho đường
  /// [roadLength]: Chiều dài đường (m)
  /// [roadWidth]: Chiều rộng đường (m)
  /// [roadThickness]: Độ dày lớp đá (m)
  /// [compactionFactor]: Hệ số đầm nén (mặc định 1.2)
  static double calculateStoneForRoad({
    required double roadLength,
    required double roadWidth,
    required double roadThickness,
    double compactionFactor = 1.2,
  }) {
    // Validation
    CalculationUtils.validateNonNegative(roadLength, 'Chiều dài đường');
    CalculationUtils.validateNonNegative(roadWidth, 'Chiều rộng đường');
    CalculationUtils.validateNonNegative(roadThickness, 'Độ dày lớp đá');
    CalculationUtils.validateNonNegative(compactionFactor, 'Hệ số đầm nén');

    // Tính thể tích đá cần thiết
    final double stoneVolume = roadLength * roadWidth * roadThickness;

    // Áp dụng hệ số đầm nén
    return stoneVolume * compactionFactor;
  }

  /// Tính tổng khối lượng đá cho toàn bộ công trình
  /// [foundationVolume]: Thể tích móng (m³)
  /// [beamVolume]: Thể tích dầm (m³)
  /// [columnVolume]: Thể tích cột (m³)
  /// [slabVolume]: Thể tích sàn (m³)
  static double calculateTotalStone({
    double foundationVolume = 0.0,
    double beamVolume = 0.0,
    double columnVolume = 0.0,
    double slabVolume = 0.0,
  }) {
    double totalStone = 0.0;

    // Đá cho móng (70% thể tích)
    if (foundationVolume > 0) {
      totalStone += foundationVolume * 0.7;
    }

    // Đá cho dầm (68% thể tích)
    if (beamVolume > 0) {
      totalStone += beamVolume * 0.68;
    }

    // Đá cho cột (68% thể tích)
    if (columnVolume > 0) {
      totalStone += columnVolume * 0.68;
    }

    // Đá cho sàn (65% thể tích)
    if (slabVolume > 0) {
      totalStone += slabVolume * 0.65;
    }

    return totalStone;
  }

  /// Tính khối lượng đá theo cấp phối
  /// [volume]: Thể tích cần đá (m³)
  /// [gradeType]: Loại cấp phối ('1', '2', '3')
  static double calculateStoneByGrade({
    required double volume,
    required String gradeType,
  }) {
    // Validation
    CalculationUtils.validateVolume(volume);

    // Hệ số theo cấp phối
    double gradeFactor;
    switch (gradeType) {
      case '1': // Cấp phối 1 (đá to)
        gradeFactor = 1.0;
        break;
      case '2': // Cấp phối 2 (đá vừa)
        gradeFactor = 1.1;
        break;
      case '3': // Cấp phối 3 (đá nhỏ)
        gradeFactor = 1.2;
        break;
      default:
        throw ArgumentError('Loại cấp phối không hợp lệ: $gradeType');
    }

    return volume * gradeFactor;
  }

  /// Tính khối lượng đá dăm theo kích cỡ
  /// [volume]: Thể tích cần đá (m³)
  /// [size]: Kích cỡ đá ('4x6', '1x2', '2x4')
  static double calculateCrushedStone({
    required double volume,
    required String size,
  }) {
    // Validation
    CalculationUtils.validateVolume(volume);

    // Hệ số theo kích cỡ đá dăm
    double sizeFactor;
    switch (size) {
      case '4x6': // Đá 4x6
        sizeFactor = 1.0;
        break;
      case '1x2': // Đá 1x2
        sizeFactor = 1.15;
        break;
      case '2x4': // Đá 2x4
        sizeFactor = 1.05;
        break;
      default:
        throw ArgumentError('Kích cỡ đá không hợp lệ: $size');
    }

    return volume * sizeFactor;
  }
}
