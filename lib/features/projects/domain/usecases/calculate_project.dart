import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';

/// Use case orchestration cho calculation.
///
/// Chỉ nhận project input → gọi [CalculationService] → trả [ProjectCalculationResult].
/// KHÔNG chứa calculation formula, material formula, unit conversion riêng,
/// cost formula riêng hay logic duplicate của calculator_core.
class CalculateProject
    implements UseCase<ProjectCalculationResult, ConstructionProject> {
  const CalculateProject(this._calculationService);

  final CalculationService _calculationService;

  @override
  Future<ProjectCalculationResult> call(ConstructionProject project) async {
    return _calculationService.calculate(project);
  }
}
