import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_result_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/mock_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/calculate_project.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCalculationService implements CalculationService {
  const _FakeCalculationService(this.result);

  final ProjectCalculationResult result;

  @override
  ProjectCalculationResult calculate(ConstructionProject project) => result;
}

void main() {
  ConstructionProject buildSampleProject() {
    return ConstructionProject(
      id: 'p-service',
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
          selectionKey: 'k-steel',
          catalogCode: 'steel',
          name: 'Sắt thép',
          unit: 'ton',
          unitPrice: 18000000,
          type: ProjectMaterialType.material,
        ),
        ProjectMaterial(
          selectionKey: 'k-concrete',
          catalogCode: 'concrete_sand',
          name: 'Cát bê tông',
          unit: 'm3',
          unitPrice: 450000,
          type: ProjectMaterialType.material,
        ),
      ],
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(12), FoundationSegment(8)],
      ),
    );
  }

  group('LegacyCalculationService — orchestration wiring', () {
    test('tính qua calculator_core và trả typed result (steel + concrete)',
        () async {
      const service = LegacyCalculationService();
      final result = service.calculate(buildSampleProject());

      // ── Material lines (join theo selection key, không theo display name)
      expect(result.materialLines, hasLength(2));
      final steel = result.materialLines.firstWhere(
        (line) => line.name == 'Sắt thép',
      );
      final concrete = result.materialLines.firstWhere(
        (line) => line.name == 'Cát bê tông',
      );

      // Thép: length 20m × quantity 10 × 0.888 kg/m → 177.6 kg → 0.1776 tấn
      // → legacy round 2 = 0.18.
      expect(steel.quantity, closeTo(0.18, 1e-9));
      expect(steel.unit, 'ton');
      expect(steel.cost, closeTo(18000000 * 0.18, 1e-9));

      // Bê tông móng: (12 + 8) × 0.3 × 0.5 = 3.0 m³.
      expect(concrete.quantity, closeTo(3.0, 1e-9));
      expect(concrete.cost, closeTo(450000 * 3.0, 1e-9));

      // Cost convention: total = Σ price × quantity, không round thêm.
      expect(result.totalCost, closeTo(18000000 * 0.18 + 450000 * 3.0, 1e-9));

      // ── Foundation section (typed, giữ nguyên giá trị legacy)
      final foundation = result.foundation;
      expect(foundation, isNotNull);
      // Cột: 0.22 × 0.3 × 3 × 4 = 0.792 m³; móng băng: 15 × 0.3 × 0.5 = 2.25 m³.
      expect(foundation!.totalConcreteM3, closeTo(0.792 + 2.25, 1e-9));
      expect(foundation.columnConcreteM3, closeTo(0.792, 1e-9));
      expect(foundation.foundationConcreteM3, closeTo(2.25, 1e-9));
      expect(foundation.totalSteelKg, greaterThan(0));
      expect(foundation.totalCementKg, greaterThan(0));
    });

    test('không có raw legacy Map lọt ra ngoài service', () async {
      const service = LegacyCalculationService();
      final result = service.calculate(buildSampleProject());
      expect(result, isA<ProjectCalculationResult>());
      // ignore: unnecessary_type_check
      expect(result.materialLines.every((l) => l is ProjectMaterialLine), true);
    });
  });

  group('LegacyResultMapper — join theo legacy selection key', () {
    test('quantities key "Thép" join đúng material name "Sắt thép"', () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{'Thép': 0.18},
      };
      const materials = [
        ProjectMaterial(
          selectionKey: 'k-steel',
          catalogCode: 'steel',
          name: 'Sắt thép',
          unit: 'ton',
          unitPrice: 18000000,
          type: ProjectMaterialType.material,
        ),
      ];

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        materials,
      );

      expect(result.materialLines, hasLength(1));
      expect(result.materialLines.first.name, 'Sắt thép');
      expect(result.materialLines.first.quantity, 0.18);
      expect(result.materialLines.first.cost, 18000000 * 0.18);
    });
  });

  group('MockCalculationService — vẫn tồn tại, stub thuần cho test isolation',
      () {
    test('trả kết quả rỗng (không tính toán, không placeholder engine)', () {
      const service = MockCalculationService();
      final result = service.calculate(buildSampleProject());
      expect(result, isA<ProjectCalculationResult>());
      expect(result.materialLines, isEmpty);
      expect(result.foundation, isNull);
      expect(result.totalCost, 0.0);
    });
  });

  group('CalculateProject — use case delegation', () {
    test('gọi CalculationService và trả đúng ProjectCalculationResult',
        () async {
      const expected = ProjectCalculationResult();
      final useCase = CalculateProject(
        const _FakeCalculationService(expected),
      );
      final result = await useCase(buildSampleProject());
      expect(identical(result, expected), true);
    });
  });

  group('GATE 7 — production flow', () {
    test(
        'ConstructionProject → CalculateProject → LegacyCalculationService '
        '→ typed result (non-zero, foundation, cost)', () async {
      final useCase = CalculateProject(
        const LegacyCalculationService(),
      );
      final result = await useCase(buildSampleProject());

      // Typed boundary — không raw Map.
      expect(result, isA<ProjectCalculationResult>());
      // Material quantity non-zero (thép + bê tông móng).
      expect(result.materialLines, isNotEmpty);
      expect(
        result.materialLines.any((line) => line.quantity > 0),
        isTrue,
      );
      // Foundation section có dữ liệu thật.
      expect(result.foundation, isNotNull);
      expect(result.foundation!.totalConcreteM3, greaterThan(0));
      // Cost convention: mọi line cost = unitPrice × quantity.
      for (final line in result.materialLines) {
        expect(line.cost, line.unitPrice * line.quantity);
      }
      expect(result.totalCost, greaterThan(0));
    });
  });
}
