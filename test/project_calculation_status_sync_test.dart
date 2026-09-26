import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/repositories/project_repository.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/calculate_project.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/get_projects.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/save_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// FIX-CALC-001R — P2: Cubit `calculationStatus` và
/// `ProjectCalculationResult.status` KHÔNG được mâu thuẫn.
///
/// R9/R10/R11: result success/partial/failure → Cubit success/partial/failure
/// (map 1-1, `calculating` chỉ là trạng thái transient trước khi hoàn tất).
class _StubRepository implements ProjectRepository {
  @override
  Future<List<ConstructionProject>> getProjects() async => const [];

  @override
  Future<void> saveProject(ConstructionProject project) async {}

  @override
  Future<void> deleteProject(String id) async {}
}

class _FixedCalculationService implements CalculationService {
  const _FixedCalculationService(this.result);

  final ProjectCalculationResult result;

  @override
  ProjectCalculationResult calculate(ConstructionProject project) => result;
}

class _ThrowingCalculationService implements CalculationService {
  const _ThrowingCalculationService();

  @override
  ProjectCalculationResult calculate(ConstructionProject project) {
    throw StateError('boom');
  }
}

void main() {
  ConstructionProject buildSampleProject() {
    return ConstructionProject(
      id: 'p-status-sync',
      name: 'Nhà mẫu',
      location: 'Hà Nội',
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
      floors: const [
        BuildingFloor(number: 1, length: 10, width: 5, height: 3),
      ],
      roof: const RoofSpec(
        type: RoofType.flat,
        length: 10,
        width: 5,
        height: 0,
      ),
      foundationStructure: const FoundationStructureSpec(
        foundationType: FoundationType.strip,
        structureType: StructureType.reinforcedConcrete,
        alignment: FoundationAlignment.balanced,
        mainBarDiameter: 16,
        columns: [
          ColumnSpec(
            width: 0.22,
            thickness: 0.3,
            quantity: 4,
            mainBarsCount: 4,
            mainBarDiameter: 16,
          ),
        ],
      ),
      materials: const [
        ProjectMaterial(
          selectionKey: 'k-brick',
          catalogCode: 'brick',
          name: 'Gạch xây',
          unit: 'piece',
          unitPrice: 1500,
          type: ProjectMaterialType.material,
        ),
      ],
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(12)],
      ),
    );
  }

  ProjectCubit buildCubit(CalculationService service) {
    return ProjectCubit(
      getProjects: GetProjects(_StubRepository()),
      saveProject: SaveProject(_StubRepository()),
      calculateProject: CalculateProject(service),
    );
  }

  const successResult = ProjectCalculationResult(
    materialLines: [
      ProjectMaterialLine(name: 'Gạch xây', quantity: 100),
    ],
  );

  const partialResult = ProjectCalculationResult(
    materialLines: [
      ProjectMaterialLine(name: 'Gạch xây', quantity: 100),
    ],
    issues: [
      CalculationIssue(
        section: 'materials',
        code: 'material_not_supported',
        severity: CalculationIssueSeverity.warning,
        materialCode: 'tile',
      ),
    ],
  );

  const failureResult = ProjectCalculationResult(
    issues: [
      CalculationIssue(
        section: 'walls',
        code: 'invalid_wall_spec',
        severity: CalculationIssueSeverity.error,
      ),
    ],
  );

  group('R9/R10/R11 — Cubit map 1-1 result.status', () {
    test('R9: result success → Cubit success, không mâu thuẫn', () async {
      final cubit = buildCubit(const _FixedCalculationService(successResult));
      addTearDown(cubit.close);

      final states = <ProjectCalculationStatus>[];
      cubit.stream.listen((state) => states.add(state.calculationStatus));

      await cubit.calculate(buildSampleProject());

      expect(cubit.state.calculationStatus, ProjectCalculationStatus.success);
      expect(cubit.state.calculationResult, successResult);
      // transient calculating xuất hiện TRƯỚC khi hoàn tất.
      expect(states, contains(ProjectCalculationStatus.calculating));
      // Completed state phản ánh đúng typed result.
      expect(cubit.state.calculationResult!.status, 'success');
    });

    test('R10: result partial → Cubit partial, không mâu thuẫn', () async {
      final cubit = buildCubit(const _FixedCalculationService(partialResult));
      addTearDown(cubit.close);

      await cubit.calculate(buildSampleProject());

      expect(cubit.state.calculationStatus, ProjectCalculationStatus.partial);
      expect(cubit.state.calculationResult, partialResult);
      expect(cubit.state.calculationResult!.status, 'partial');
    });

    test('R11: result failure → Cubit failure, không mâu thuẫn', () async {
      final cubit = buildCubit(const _FixedCalculationService(failureResult));
      addTearDown(cubit.close);

      await cubit.calculate(buildSampleProject());

      expect(cubit.state.calculationStatus, ProjectCalculationStatus.failure);
      expect(cubit.state.calculationResult, failureResult);
      expect(cubit.state.calculationResult!.status, 'failure');
      // Failure qua typed result KHÔNG dùng calculationError.
      expect(cubit.state.calculationError, isNull);
    });
  });

  group('exception tầng ngoài', () {
    test('exception → Cubit failure + calculationError, result null', () async {
      final cubit = buildCubit(const _ThrowingCalculationService());
      addTearDown(cubit.close);

      await cubit.calculate(buildSampleProject());

      expect(cubit.state.calculationStatus, ProjectCalculationStatus.failure);
      expect(cubit.state.calculationResult, isNull);
      expect(cubit.state.calculationError, isNotNull);
    });
  });
}
