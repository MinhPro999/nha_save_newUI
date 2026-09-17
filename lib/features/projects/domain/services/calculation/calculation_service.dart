import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';

/// Application/domain boundary cho calculation.
///
/// UI/application layer chỉ phụ thuộc interface này:
/// - không biết `calculator_core`,
/// - không nhận raw legacy Map,
/// - mọi kết quả đi qua [ProjectCalculationResult].
///
/// Implementations:
/// - `MockCalculationService` (mock cho dev/test — giữ đến khi Gate 6 PASS),
/// - `LegacyCalculationService` (orchestration thật qua calculator_core).
abstract class CalculationService {
  ProjectCalculationResult calculate(ConstructionProject project);
}
