import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';

/// Mock/dev implementation của [CalculationService] — **stub thuần**.
///
/// KHÔNG tính toán, KHÔNG placeholder engine, KHÔNG công thức. Trả kết quả
/// rỗng để test isolation. Production path luôn đi qua
/// [LegacyCalculationService]; Mock chỉ dùng khi test muốn override.
class MockCalculationService implements CalculationService {
  const MockCalculationService();

  @override
  ProjectCalculationResult calculate(ConstructionProject project) {
    return const ProjectCalculationResult();
  }
}
