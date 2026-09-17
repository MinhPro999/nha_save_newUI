import 'package:flutter_core_project/calculator_core/services/foundation_structure_calculator.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';

/// Output boundary: legacy calculation result → typed result.
///
/// - Không sửa giá trị quantity (đã được legacy round 2).
/// - Cost tính đúng convention legacy: `unitPrice × quantity`, không round.
/// - Join theo **legacy selection key** (`LegacyMaterialSelectionKeyMapper`),
///   KHÔNG theo display name — để các key khác tên hiển thị (`'Thép'` cho
///   `'Sắt thép'`, `'Bê tông'` cho `'Cát bê tông'`) không bị mất quantity.
///   Tên hiển thị trên dòng kết quả vẫn là `material.name`.
/// - `results['costs']` và `results['intermediateResults']` của legacy luôn rỗng
///   → không đưa vào typed result.
class LegacyResultMapper {
  LegacyResultMapper._();

  /// Kết quả từ `MaterialCalculator.calculateMaterialsFromDetailedParams`
  /// + price snapshot của project → [ProjectCalculationResult].
  static ProjectCalculationResult mapMaterialResult(
    Map<String, dynamic> legacyResults,
    List<ProjectMaterial> materials,
  ) {
    final rawQuantities = legacyResults['quantities'];
    final quantities = rawQuantities is Map
        ? rawQuantities.map((key, value) => MapEntry(
              key.toString(),
              (value as num?)?.toDouble() ?? 0.0,
            ))
        : <String, double>{};

    final lines = <ProjectMaterialLine>[];
    for (final material in materials) {
      final key = LegacyMaterialSelectionKeyMapper.selectionIdFor(
        catalogCode: material.catalogCode,
        name: material.name,
      );
      final quantity = quantities[key];
      if (quantity == null) continue; // legacy UI chỉ hiện material đã chọn.
      lines.add(
        ProjectMaterialLine(
          name: material.name,
          quantity: quantity,
          unit: material.unit,
          unitPrice: material.unitPrice,
        ),
      );
    }

    return ProjectCalculationResult(materialLines: lines);
  }

  /// `FoundationStructureResult` (core) → typed section — chép giá trị 1-1,
  /// giữ nguyên đơn vị (m³, kg, lít, bao, tấn), không tính lại.
  static FoundationStructureSection mapFoundationResult(
    FoundationStructureResult result,
  ) {
    return FoundationStructureSection(
      columnConcreteM3: result.columnConcreteM3,
      foundationConcreteM3: result.foundationConcreteM3,
      totalConcreteM3: result.totalConcreteM3,
      columnCementKg: result.columnCementKg,
      columnSandM3: result.columnSandM3,
      columnStoneM3: result.columnStoneM3,
      columnWaterL: result.columnWaterL,
      foundationCementKg: result.foundationCementKg,
      foundationSandM3: result.foundationSandM3,
      foundationStoneM3: result.foundationStoneM3,
      foundationWaterL: result.foundationWaterL,
      totalCementKg: result.totalCementKg,
      totalSandM3: result.totalSandM3,
      totalStoneM3: result.totalStoneM3,
      totalWaterL: result.totalWaterL,
      columnSteelKg: result.columnSteelKg,
      foundationSteelKg: result.foundationSteelKg,
      totalSteelKg: result.totalSteelKg,
      cementBags50kg: result.cementBags50kg,
      cementTon: result.cementTon,
      steelTon: result.steelTon,
      waterM3: result.waterM3,
    );
  }

  /// Gộp material + foundation thành một kết quả typed hoàn chỉnh.
  static ProjectCalculationResult combine(
    ProjectCalculationResult materialResult,
    FoundationStructureSection? foundation,
  ) {
    return ProjectCalculationResult(
      materialLines: materialResult.materialLines,
      foundation: foundation,
    );
  }
}
