import 'package:equatable/equatable.dart';

/// Dòng kết quả vật liệu — typed boundary, thay cho raw legacy Map ra UI.
///
/// - [quantity]: lấy nguyên từ legacy core (đã round 2 chữ số bởi legacy).
/// - [cost]: `unitPrice * quantity`, KHÔNG round thêm (đúng convention legacy —
///   xem PHASE2_MAPPING_SPEC.md mục 4.3).
class ProjectMaterialLine extends Equatable {
  const ProjectMaterialLine({
    required this.name,
    required this.quantity,
    this.unit,
    this.unitPrice = 0.0,
  });

  /// Tên vật liệu (đúng tên tiếng Việt của legacy core).
  final String name;

  /// Số lượng đã được legacy round.
  final double quantity;

  /// Đơn vị từ price snapshot của project (vd: piece, m2, m3, ton, set).
  final String? unit;

  /// Giá snapshot tại thời điểm tính (từ ProjectMaterial.unitPrice).
  final double unitPrice;

  /// Thành tiền = unitPrice × quantity (không round).
  double get cost => unitPrice * quantity;

  @override
  List<Object?> get props => [name, quantity, unit, unitPrice];
}

/// Mirror typed 1-1 của `FoundationStructureResult` (legacy core).
///
/// Giữ nguyên giá trị và đơn vị (m³, kg, lít, bao, tấn) — mapper chỉ chép giá
/// trị, KHÔNG tính lại. Key toMap/fromMap giữ nguyên tên legacy để Gate 8
/// persist không mất dữ liệu.
class FoundationStructureSection extends Equatable {
  const FoundationStructureSection({
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

  // Bê tông (m³)
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

  // Thép (kg)
  final double columnSteelKg;
  final double foundationSteelKg;
  final double totalSteelKg;

  // Quy đổi đơn vị
  final int cementBags50kg;
  final double cementTon;
  final double steelTon;
  final double waterM3;

  /// Key giữ nguyên tên legacy `FoundationStructureResult.toMap()`.
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

  factory FoundationStructureSection.fromMap(Map<String, dynamic> map) {
    return FoundationStructureSection(
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

  @override
  List<Object?> get props => [
        columnConcreteM3,
        foundationConcreteM3,
        totalConcreteM3,
        columnCementKg,
        columnSandM3,
        columnStoneM3,
        columnWaterL,
        foundationCementKg,
        foundationSandM3,
        foundationStoneM3,
        foundationWaterL,
        totalCementKg,
        totalSandM3,
        totalStoneM3,
        totalWaterL,
        columnSteelKg,
        foundationSteelKg,
        totalSteelKg,
        cementBags50kg,
        cementTon,
        steelTon,
        waterM3,
      ];
}

/// Kết quả tính toán typed cho project — boundary giữa calculation và UI.
///
/// UI không được dùng raw legacy Map; mọi thứ đi qua class này.
class ProjectCalculationResult extends Equatable {
  const ProjectCalculationResult({
    this.materialLines = const [],
    this.foundation,
  });

  final List<ProjectMaterialLine> materialLines;
  final FoundationStructureSection? foundation;

  /// Tổng cost = Σ line.cost (legacy convention: không round).
  double get totalCost => materialLines.fold(0, (sum, line) => sum + line.cost);

  @override
  List<Object?> get props => [materialLines, foundation];
}
