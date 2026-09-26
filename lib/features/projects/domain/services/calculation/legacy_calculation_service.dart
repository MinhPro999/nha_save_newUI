import 'package:flutter_core_project/calculator_core/services/foundation_structure_calculator.dart';
import 'package:flutter_core_project/calculator_core/services/material_calculator.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_input_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_result_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';

/// Real implementation của [CalculationService] — **chỉ orchestration**:
///
/// ```text
/// LegacyInputMapper → calculator_core → LegacyResultMapper
/// ```
///
/// KHÔNG chứa: công thức tính, constants calculation, rounding logic riêng,
/// business logic duplicate, material formula, pricing logic thứ hai.
/// Mọi giá trị quantity/rounding/units đến từ calculator_core nguyên vẹn.
///
/// Ghi chú:
/// - Cost convention: `ProjectMaterial.unitPrice × quantity` — không dùng
///   `legacyResult['costs']` (luôn rỗng trong legacy).
/// - `gypsumCeilingArea = 0.0` được mapper giữ cố định (FUNCTIONAL GAP:
///   new UI chưa có input thạch cao — không suy đoán diện tích).
/// - `StructureType` không được truyền vào legacy engine (Gate 4 decision).
class LegacyCalculationService implements CalculationService {
  const LegacyCalculationService();

  @override
  ProjectCalculationResult calculate(ConstructionProject project) {
    // ── Input mapping ──────────────────────────────────────────────────
    // FIX-CALC-001R: WallSpec non-empty + invalid → STRUCTURED ERROR,
    // KHÔNG fallback Default Wall (LegacyInputMapper ném typed exception).
    final LegacyMaterialInput materialInput;
    try {
      materialInput = LegacyInputMapper.mapMaterialInput(project);
    } on InvalidWallSpecException {
      return const ProjectCalculationResult(
        issues: [
          CalculationIssue(
            section: 'walls',
            code: 'invalid_wall_spec',
            severity: CalculationIssueSeverity.error,
          ),
        ],
      );
    }
    final foundationInput = LegacyInputMapper.mapFoundationInput(project);

    // ── calculator_core (legacy engine nguyên vẹn) ────────────────────
    final legacyMaterialResults =
        MaterialCalculator.calculateMaterialsFromDetailedParams(
      materialInput.detailedParams,
      selectedMaterialIds: materialInput.selectedMaterialIds,
      brickDimensions: materialInput.brickDimensions,
      floors: materialInput.floors,
    );

    // ── Foundation ─────────────────────────────────────────────────────
    // Lỗi validation (vd steel diameter invalid, theo policy Gate 4) được
    // truyền nguyên lên caller — không silent-fallback.
    final legacyFoundationResult = FoundationStructureCalculator.calculate(
      foundationData: foundationInput.foundationData,
      l1: foundationInput.l1,
      w1: foundationInput.w1,
      area1: foundationInput.area1,
      hTotal: foundationInput.hTotal,
    );

    // ── Result mapping ─────────────────────────────────────────────────
    final materialResult = LegacyResultMapper.mapMaterialResult(
      legacyMaterialResults,
      project.materials,
    );
    final foundation = LegacyResultMapper.mapFoundationResult(
      legacyFoundationResult,
    );
    return LegacyResultMapper.combine(materialResult, foundation);
  }
}
