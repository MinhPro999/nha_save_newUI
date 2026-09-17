import '../models/project/foundation_structure_model.dart';

/// Service tính toán móng và kết cấu theo request17.md
class FoundationStructureCalculator {
  // === Tham số - Bảng tra & Hệ số (cấu hình được) ===

  /// Cấp phối 1 m³ bê tông M300 (có thể chỉnh)
  static const double cementKgPerM3 = 430.0; // Xi măng (kg)
  static const double sandM3PerM3 = 0.45; // Cát (m³)
  static const double stoneM3PerM3 = 0.86; // Đá 1×2 (m³)
  static const double waterLPerM3 = 185.0; // Nước (lít)

  /// Thép - đơn trọng (kg/m) và tỷ trọng
  static const double rhoSteel = 7850.0; // kg/m³
  static const Map<int, double> steelUnitWeight = {
    10: 0.617,
    12: 0.888,
    14: 1.210,
    16: 1.580,
    18: 2.000,
    20: 2.470,
    22: 2.980,
  };

  /// Hệ số hao hụt
  static const double lossConcrete = 0.03; // 3%
  static const double lossSteel = 0.05; // 5%

  /// Hằng số khác
  static const double lNeo = 0.8; // Chiều dài neo (m)

  /// Tính toán tổng hợp móng và kết cấu
  static FoundationStructureResult calculate({
    required FoundationStructureData foundationData,
    required double l1, // Chiều dài tầng 1 từ step2
    required double w1, // Chiều rộng tầng 1 từ step2
    required double area1, // Diện tích tầng 1 từ step2
    required double hTotal, // Tổng chiều cao nhà từ step2
  }) {
    // 1. Tính toán cột
    final columnResult = _calculateColumns(foundationData.columns, hTotal);

    // 2. Tính toán móng theo loại
    final foundationResult = _calculateFoundation(
      foundationData,
      l1,
      w1,
      area1,
      foundationData.columns.fold<int>(0, (sum, col) => sum + col.quantity),
    );

    // 3. Hợp nhất kết quả
    return FoundationStructureResult(
      // Bê tông
      columnConcreteM3: columnResult.concreteM3,
      foundationConcreteM3: foundationResult.concreteM3,
      totalConcreteM3: columnResult.concreteM3 + foundationResult.concreteM3,

      // Vật liệu chi tiết từ cột
      columnCementKg: columnResult.cementKg,
      columnSandM3: columnResult.sandM3,
      columnStoneM3: columnResult.stoneM3,
      columnWaterL: columnResult.waterL,

      // Vật liệu chi tiết từ móng
      foundationCementKg: foundationResult.cementKg,
      foundationSandM3: foundationResult.sandM3,
      foundationStoneM3: foundationResult.stoneM3,
      foundationWaterL: foundationResult.waterL,

      // Tổng vật liệu
      totalCementKg: columnResult.cementKg + foundationResult.cementKg,
      totalSandM3: columnResult.sandM3 + foundationResult.sandM3,
      totalStoneM3: columnResult.stoneM3 + foundationResult.stoneM3,
      totalWaterL: columnResult.waterL + foundationResult.waterL,

      // Thép
      columnSteelKg: columnResult.steelKg,
      foundationSteelKg: foundationResult.steelKg,
      totalSteelKg: columnResult.steelKg + foundationResult.steelKg,

      // Quy đổi đơn vị
      cementBags50kg:
          ((columnResult.cementKg + foundationResult.cementKg) / 50).ceil(),
      cementTon: (columnResult.cementKg + foundationResult.cementKg) / 1000,
      steelTon: (columnResult.steelKg + foundationResult.steelKg) / 1000,
      waterM3: (columnResult.waterL + foundationResult.waterL) / 1000,
    );
  }

  /// Tính toán cột (chi tiết ra vật liệu)
  static _ColumnResult _calculateColumns(
    List<ColumnInfo> columns,
    double hTotal,
  ) {
    double totalConcreteM3 = 0.0;
    double totalSteelKg = 0.0;

    for (final column in columns) {
      // Thể tích bê tông cột
      final vColI = column.width * column.thickness * hTotal * column.quantity;
      totalConcreteM3 += vColI;

      // Thép chủ cột
      final lBar = hTotal + lNeo;
      final unitWeight = steelUnitWeight[column.mainBarDiameter.value] ?? 0.0;
      final wMainI = column.quantity * column.mainBarsCount * lBar * unitWeight;
      totalSteelKg += wMainI;
    }

    // Áp dụng hệ số hao hụt
    totalSteelKg *= (1 + lossSteel);

    // Quy đổi bê tông cột → vật liệu chi tiết
    final cementKg = totalConcreteM3 * cementKgPerM3;
    final sandM3 = totalConcreteM3 * sandM3PerM3;
    final stoneM3 = totalConcreteM3 * stoneM3PerM3;
    final waterL = totalConcreteM3 * waterLPerM3;

    return _ColumnResult(
      concreteM3: totalConcreteM3,
      cementKg: cementKg,
      sandM3: sandM3,
      stoneM3: stoneM3,
      waterL: waterL,
      steelKg: totalSteelKg,
    );
  }

  /// Tính toán móng theo loại (ra khối m³)
  static _FoundationResult _calculateFoundation(
    FoundationStructureData foundationData,
    double l1,
    double w1,
    double area1,
    int totalColumns,
  ) {
    if (foundationData.foundationType == null) {
      return _FoundationResult.empty();
    }

    switch (foundationData.foundationType!) {
      case FoundationTypeNew.bang:
        return _calculateFoundationBang(
          foundationData.bangInfo,
          l1,
          w1,
          totalColumns,
        );
      case FoundationTypeNew.be:
        return _calculateFoundationBe(
          foundationData.beInfo,
          l1,
          w1,
          area1,
          totalColumns,
        );
      case FoundationTypeNew.coc:
        return _calculateFoundationCoc(
          foundationData.cocInfo,
          l1,
          w1,
          totalColumns,
        );
      case FoundationTypeNew.coc_pile:
        return _calculateFoundationCocPile(
          foundationData.cocPileInfo,
          l1,
          w1,
          totalColumns,
        );
    }
  }

  /// Tính toán móng băng
  static _FoundationResult _calculateFoundationBang(
    FoundationBangInfo? bangInfo,
    double l1,
    double w1,
    int totalColumns,
  ) {
    if (bangInfo == null) return _FoundationResult.empty();

    final nDam = totalColumns ~/ 2;

    // Thể tích bê tông dầm móng (giả sử bw=0.3m, bh=0.5m)
    const bw = 0.3;
    const bh = 0.5;
    final lDocTotal = (nDam / 2).ceil() * l1;
    final lNgangTotal = (nDam / 2).floor() * w1;
    final vFootingM3 = (lDocTotal + lNgangTotal) * bw * bh;

    // Thép dầm móng (đơn giản hóa - chỉ tính thép chủ)
    const nMainBeam = 4; // Số thanh thép chủ mỗi dầm
    final unitWeight = steelUnitWeight[bangInfo.mainBarDiameter.value] ?? 0.0;
    final wSteelFooting =
        nMainBeam * (lDocTotal + lNgangTotal) * unitWeight * (1 + lossSteel);

    return _FoundationResult.fromConcrete(vFootingM3, wSteelFooting);
  }

  /// Tính toán móng bè
  static _FoundationResult _calculateFoundationBe(
    FoundationBeInfo? beInfo,
    double l1,
    double w1,
    double area1,
    int totalColumns,
  ) {
    if (beInfo == null) return _FoundationResult.empty();

    // Bê tông sàn móng
    final vSlabM3 = area1 * 0.1;

    // Bê tông dầm móng (nếu có)
    const bw = 0.3;
    const bh = 0.5;
    final lDocTotal = l1;
    final lNgangTotal = (totalColumns / 2) * w1;
    final vBeamM3 = (lDocTotal + lNgangTotal) * bw * bh;
    final vFootingM3 = vSlabM3 + vBeamM3;

    // Thép sàn móng (D10, 2 lớp, A200)
    const matDoThanh = 5.0; // thanh/m
    final wMesh1Layer =
        (area1 * matDoThanh + area1 * matDoThanh) *
        (steelUnitWeight[10] ?? 0.0);
    final wMesh2Layers = 2 * wMesh1Layer * (1 + lossSteel);

    // Thép dầm móng
    const nMainBeam = 4;
    final unitWeight = steelUnitWeight[beInfo.mainBarDiameter.value] ?? 0.0;
    final wBeamSteel =
        nMainBeam * (lDocTotal + lNgangTotal) * unitWeight * (1 + lossSteel);
    final wSteelFooting = wMesh2Layers + wBeamSteel;

    return _FoundationResult.fromConcrete(vFootingM3, wSteelFooting);
  }

  /// Tính toán móng cốc
  static _FoundationResult _calculateFoundationCoc(
    FoundationCocInfo? cocInfo,
    double l1,
    double w1,
    int totalColumns,
  ) {
    if (cocInfo == null) return _FoundationResult.empty();

    final nCups = totalColumns;

    // Bê tông cốc
    final vCupM3 = cocInfo.length * cocInfo.width * cocInfo.height * nCups;

    // Bê tông dầm móng
    final nDam = totalColumns ~/ 2;
    const bw = 0.3;
    const bh = 0.5;
    final lDocTotal = (nDam / 2).ceil() * l1;
    final lNgangTotal = (nDam / 2).floor() * w1;
    final vBeamM3 = (lDocTotal + lNgangTotal) * bw * bh;
    final vFootingM3 = vCupM3 + vBeamM3;

    // Thép lồng cốc và dầm móng
    const lNeoCup = 0.6;
    const nMainPerCup = 8;
    final lBarCup = cocInfo.height + lNeoCup;
    final unitWeightCup = steelUnitWeight[cocInfo.mainBarDiameter.value] ?? 0.0;
    final wCupMain = nCups * nMainPerCup * lBarCup * unitWeightCup;

    const nMainBeam = 4;
    final wBeamMain = nMainBeam * (lDocTotal + lNgangTotal) * unitWeightCup;
    final wSteelFooting = (wCupMain + wBeamMain) * (1 + lossSteel);

    return _FoundationResult.fromConcrete(vFootingM3, wSteelFooting);
  }

  /// Tính toán móng cọc
  static _FoundationResult _calculateFoundationCocPile(
    FoundationCocPileInfo? cocPileInfo,
    double l1,
    double w1,
    int totalColumns,
  ) {
    if (cocPileInfo == null || cocPileInfo.pileCaps.isEmpty) {
      return _FoundationResult.empty();
    }

    final nCap = totalColumns;

    // Bê tông đài (sử dụng đài đầu tiên làm mẫu)
    final firstCap = cocPileInfo.pileCaps.first;
    final vCapM3 = firstCap.length * firstCap.width * firstCap.height * nCap;

    // Bê tông dầm móng
    const bw = 0.3;
    const bh = 0.5;
    final lDocTotal = l1;
    final lNgangTotal = (totalColumns / 2) * w1;
    final vBeamM3 = (lDocTotal + lNgangTotal) * bw * bh;
    final vFootingM3 = vCapM3 + vBeamM3;

    // Thép đài và dầm móng
    final wCap =
        nCap *
        (firstCap.length * firstCap.width) *
        10 *
        (steelUnitWeight[16] ?? 0.0) *
        2 *
        (1 + lossSteel);

    const nMainBeam = 4;
    final unitWeight =
        steelUnitWeight[cocPileInfo.mainBarDiameter.value] ?? 0.0;
    final wBeamMain = nMainBeam * (lDocTotal + lNgangTotal) * unitWeight;
    final wSteelFooting = wCap + wBeamMain * (1 + lossSteel);

    return _FoundationResult.fromConcrete(vFootingM3, wSteelFooting);
  }
}

/// Kết quả tính toán cột
class _ColumnResult {
  final double concreteM3;
  final double cementKg;
  final double sandM3;
  final double stoneM3;
  final double waterL;
  final double steelKg;

  _ColumnResult({
    required this.concreteM3,
    required this.cementKg,
    required this.sandM3,
    required this.stoneM3,
    required this.waterL,
    required this.steelKg,
  });
}

/// Kết quả tính toán móng
class _FoundationResult {
  final double concreteM3;
  final double cementKg;
  final double sandM3;
  final double stoneM3;
  final double waterL;
  final double steelKg;

  _FoundationResult({
    required this.concreteM3,
    required this.cementKg,
    required this.sandM3,
    required this.stoneM3,
    required this.waterL,
    required this.steelKg,
  });

  factory _FoundationResult.empty() {
    return _FoundationResult(
      concreteM3: 0.0,
      cementKg: 0.0,
      sandM3: 0.0,
      stoneM3: 0.0,
      waterL: 0.0,
      steelKg: 0.0,
    );
  }

  factory _FoundationResult.fromConcrete(double concreteM3, double steelKg) {
    return _FoundationResult(
      concreteM3: concreteM3,
      cementKg: concreteM3 * FoundationStructureCalculator.cementKgPerM3,
      sandM3: concreteM3 * FoundationStructureCalculator.sandM3PerM3,
      stoneM3: concreteM3 * FoundationStructureCalculator.stoneM3PerM3,
      waterL: concreteM3 * FoundationStructureCalculator.waterLPerM3,
      steelKg: steelKg,
    );
  }
}

/// Kết quả tính toán tổng hợp móng và kết cấu
class FoundationStructureResult {
  // Bê tông
  final double columnConcreteM3;
  final double foundationConcreteM3;
  final double totalConcreteM3;

  // Vật liệu chi tiết từ cột
  final double columnCementKg;
  final double columnSandM3;
  final double columnStoneM3;
  final double columnWaterL;

  // Vật liệu chi tiết từ móng
  final double foundationCementKg;
  final double foundationSandM3;
  final double foundationStoneM3;
  final double foundationWaterL;

  // Tổng vật liệu
  final double totalCementKg;
  final double totalSandM3;
  final double totalStoneM3;
  final double totalWaterL;

  // Thép
  final double columnSteelKg;
  final double foundationSteelKg;
  final double totalSteelKg;

  // Quy đổi đơn vị
  final int cementBags50kg;
  final double cementTon;
  final double steelTon;
  final double waterM3;

  FoundationStructureResult({
    required this.columnConcreteM3,
    required this.foundationConcreteM3,
    required this.totalConcreteM3,
    required this.columnCementKg,
    required this.columnSandM3,
    required this.columnStoneM3,
    required this.columnWaterL,
    required this.foundationCementKg,
    required this.foundationSandM3,
    required this.foundationStoneM3,
    required this.foundationWaterL,
    required this.totalCementKg,
    required this.totalSandM3,
    required this.totalStoneM3,
    required this.totalWaterL,
    required this.columnSteelKg,
    required this.foundationSteelKg,
    required this.totalSteelKg,
    required this.cementBags50kg,
    required this.cementTon,
    required this.steelTon,
    required this.waterM3,
  });

  /// Chuyển đổi sang Map để lưu trữ
  Map<String, dynamic> toMap() {
    return {
      'columnConcreteM3': columnConcreteM3,
      'foundationConcreteM3': foundationConcreteM3,
      'totalConcreteM3': totalConcreteM3,
      'columnCementKg': columnCementKg,
      'columnSandM3': columnSandM3,
      'columnStoneM3': columnStoneM3,
      'columnWaterL': columnWaterL,
      'foundationCementKg': foundationCementKg,
      'foundationSandM3': foundationSandM3,
      'foundationStoneM3': foundationStoneM3,
      'foundationWaterL': foundationWaterL,
      'totalCementKg': totalCementKg,
      'totalSandM3': totalSandM3,
      'totalStoneM3': totalStoneM3,
      'totalWaterL': totalWaterL,
      'columnSteelKg': columnSteelKg,
      'foundationSteelKg': foundationSteelKg,
      'totalSteelKg': totalSteelKg,
      'cementBags50kg': cementBags50kg,
      'cementTon': cementTon,
      'steelTon': steelTon,
      'waterM3': waterM3,
    };
  }

  /// Tạo từ Map
  factory FoundationStructureResult.fromMap(Map<String, dynamic> map) {
    return FoundationStructureResult(
      columnConcreteM3: map['columnConcreteM3']?.toDouble() ?? 0.0,
      foundationConcreteM3: map['foundationConcreteM3']?.toDouble() ?? 0.0,
      totalConcreteM3: map['totalConcreteM3']?.toDouble() ?? 0.0,
      columnCementKg: map['columnCementKg']?.toDouble() ?? 0.0,
      columnSandM3: map['columnSandM3']?.toDouble() ?? 0.0,
      columnStoneM3: map['columnStoneM3']?.toDouble() ?? 0.0,
      columnWaterL: map['columnWaterL']?.toDouble() ?? 0.0,
      foundationCementKg: map['foundationCementKg']?.toDouble() ?? 0.0,
      foundationSandM3: map['foundationSandM3']?.toDouble() ?? 0.0,
      foundationStoneM3: map['foundationStoneM3']?.toDouble() ?? 0.0,
      foundationWaterL: map['foundationWaterL']?.toDouble() ?? 0.0,
      totalCementKg: map['totalCementKg']?.toDouble() ?? 0.0,
      totalSandM3: map['totalSandM3']?.toDouble() ?? 0.0,
      totalStoneM3: map['totalStoneM3']?.toDouble() ?? 0.0,
      totalWaterL: map['totalWaterL']?.toDouble() ?? 0.0,
      columnSteelKg: map['columnSteelKg']?.toDouble() ?? 0.0,
      foundationSteelKg: map['foundationSteelKg']?.toDouble() ?? 0.0,
      totalSteelKg: map['totalSteelKg']?.toDouble() ?? 0.0,
      cementBags50kg: map['cementBags50kg']?.toInt() ?? 0,
      cementTon: map['cementTon']?.toDouble() ?? 0.0,
      steelTon: map['steelTon']?.toDouble() ?? 0.0,
      waterM3: map['waterM3']?.toDouble() ?? 0.0,
    );
  }
}
