import 'package:flutter_core_project/calculator_core/services/material_calculator.dart';
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
      const useCase = CalculateProject(
        _FakeCalculationService(expected),
      );
      final result = await useCase(buildSampleProject());
      expect(identical(result, expected), true);
    });
  });

  group('GATE 7 — production flow', () {
    test(
        'ConstructionProject → CalculateProject → LegacyCalculationService '
        '→ typed result (non-zero, foundation, cost)', () async {
      const useCase = CalculateProject(
        LegacyCalculationService(),
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

  group('FIX-CALC-001 — regression: walls trống + vật liệu phụ thuộc tường',
      () {
    ConstructionProject buildProject({
      required List<ProjectMaterial> materials,
      List<WallSpec> walls = const [],
      List<double> foundationSegments = const [12],
    }) {
      return ConstructionProject(
        id: 'p-fix-calc-001',
        name: 'Nhà sơn nội thất',
        location: 'Hà Nội',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        floors: const [
          BuildingFloor(number: 1, length: 10, width: 8, height: 3.3),
        ],
        roof: const RoofSpec(
          type: RoofType.flat,
          length: 10,
          width: 8,
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
        materials: materials,
        details: ProjectDetails(
          foundationSegments:
              foundationSegments.map(FoundationSegment.new).toList(),
          walls: walls,
        ),
      );
    }

    const interiorPaint = ProjectMaterial(
      selectionKey: 'k-paint',
      catalogCode: 'interior_paint',
      name: 'Sơn nội thất',
      unit: 'm2',
      unitPrice: 65000,
      type: ProjectMaterialType.material,
    );

    test(
        'REG-001: interior_paint + walls=[] + floors đủ → KHÔNG throw, '
        'quantity > 0 khớp công thức Default Wall (Σ[2×(L+W)×H×2×1.5])',
        () async {
      const service = LegacyCalculationService();

      // Trước fix: PaintCalculator throw
      // 'Diện tích sơn nội thất phải lớn hơn 0' và sập toàn bộ calculation.
      final result = service.calculate(
        buildProject(materials: const [interiorPaint]),
      );

      final paint = result.materialLines.firstWhere(
        (line) => line.name == 'Sơn nội thất',
      );
      // 1 tầng L=10 W=8 H=3.3 → perimeter = 36
      // Default Wall: (36×3.3×2) + (18×3.3×2) = 356.4 m² (= 36×3.3×2×1.5).
      expect(paint.quantity, closeTo(356.4, 1e-9));
      expect(paint.cost, closeTo(65000 * 356.4, 1e-9));
      expect(result.issues, isEmpty);
      expect(result.status, 'success');
    });

    test('REG-002: WallSpec hợp lệ được ƯU TIÊN — không cộng dồn Default Wall',
        () async {
      const service = LegacyCalculationService();
      final result = service.calculate(
        buildProject(
          materials: const [interiorPaint],
          walls: const [
            WallSpec(
              type: WallType.wall100,
              plasterSides: 2,
              length: 4,
              height: 3.3,
            ),
          ],
        ),
      );

      final paint = result.materialLines.firstWhere(
        (line) => line.name == 'Sơn nội thất',
      );
      // Dùng ĐÚNG số liệu WallSpec: 4 × 3.3 × 2 = 26.4 m².
      // Không phải 356.4 + 26.4 (chứng minh không double-count).
      expect(paint.quantity, closeTo(26.4, 1e-9));
    });

    test(
        'REG-003 (FIX-CALC-001R): WallSpec đã thêm dòng nhưng chưa nhập số '
        '(length=0, height=0) → invalid input → error, KHÔNG fallback '
        'Default Wall', () async {
      const service = LegacyCalculationService();
      final result = service.calculate(
        buildProject(
          materials: const [interiorPaint],
          walls: const [
            WallSpec(
              type: WallType.wall100,
              plasterSides: 2,
              length: 0,
              height: 0,
            ),
          ],
        ),
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'invalid_wall_spec');
      expect(result.issues.single.section, 'walls');
      expect(result.issues.single.severity, CalculationIssueSeverity.error);
      expect(result.status, 'failure');
    });

    test(
        'REG-R3 (FIX-CALC-001R): walls = [valid, invalid(length=0)] → '
        'error invalid_wall_spec, KHÔNG fallback Default Wall, KHÔNG tự bỏ '
        'item', () async {
      const service = LegacyCalculationService();
      final result = service.calculate(
        buildProject(
          materials: const [interiorPaint],
          walls: const [
            WallSpec(
              type: WallType.wall100,
              plasterSides: 2,
              length: 4,
              height: 3.3,
            ),
            WallSpec(
              type: WallType.wall200,
              plasterSides: 1,
              length: 0,
              height: 3,
            ),
          ],
        ),
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'invalid_wall_spec');
      expect(result.issues.single.section, 'walls');
      expect(result.issues.single.severity, CalculationIssueSeverity.error);
      expect(result.status, 'failure');
    });

    test(
        'REG-R4 (FIX-CALC-001R): walls = [invalid(length=0, height=3)] → '
        'error, KHÔNG Default Wall', () async {
      const service = LegacyCalculationService();
      final result = service.calculate(
        buildProject(
          materials: const [interiorPaint],
          walls: const [
            WallSpec(
              type: WallType.wall100,
              plasterSides: 2,
              length: 0,
              height: 3,
            ),
          ],
        ),
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'invalid_wall_spec');
      expect(result.status, 'failure');
    });

    test(
        'REG-R5 (FIX-CALC-001R): walls = [invalid(length=5, height=0)] → '
        'error, KHÔNG Default Wall', () async {
      const service = LegacyCalculationService();
      final result = service.calculate(
        buildProject(
          materials: const [interiorPaint],
          walls: const [
            WallSpec(
              type: WallType.wall200,
              plasterSides: 2,
              length: 5,
              height: 0,
            ),
          ],
        ),
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'invalid_wall_spec');
      expect(result.status, 'failure');
    });

    test(
        'REG-004: không chọn Sơn nội thất + không WallSpec → '
        'không tính interior paint, không throw', () async {
      const steel = ProjectMaterial(
        selectionKey: 'k-steel',
        catalogCode: 'steel',
        name: 'Sắt thép',
        unit: 'ton',
        unitPrice: 18000000,
        type: ProjectMaterialType.material,
      );
      const service = LegacyCalculationService();
      final result = service.calculate(
        buildProject(
          materials: const [steel],
          walls: const [],
          foundationSegments: const [12, 8],
        ),
      );

      expect(
        result.materialLines.where((line) => line.name == 'Sơn nội thất'),
        isEmpty,
      );
      // Thép vẫn tính được bình thường.
      final steelLine = result.materialLines.firstWhere(
        (line) => line.name == 'Sắt thép',
      );
      expect(steelLine.quantity, closeTo(0.18, 1e-9));
    });
  });

  group('FIX-CALC-001 Phase 5 — cô lập lỗi theo nhóm (orchestration)', () {
    test(
        'nhóm khác lỗi KHÔNG làm mất brick/cement hợp lệ; '
        'issues chỉ chứa đúng nhóm lỗi', () {
      final detailedParams = <String, dynamic>{
        'walls': <String, dynamic>{
          'walls': <dynamic>[
            <String, dynamic>{
              'type': '10',
              'plasterSides': 2,
              'length': 4,
              'height': 3.3,
              'area': 4 * 3.3,
            },
          ],
          'area': 4 * 3.3,
        },
        'foundation': <String, dynamic>{
          'lengths': <double>[12, 8],
          'columns': 0,
        },
        'doors': <String, dynamic>{
          'windows': <dynamic>[],
          'doors': <dynamic>[],
          'rollingDoors': <dynamic>[],
          'windowArea': 0.0,
          'doorArea': 0.0,
          'rollingDoorArea': 0.0,
        },
        // Nhóm 'others' cố tình làm lỗi: gypsumCeilingArea âm → throw.
        'others': <String, dynamic>{
          'bathrooms': <dynamic>[],
          'gypsumCeilingArea': -1.0,
          'stairs': <dynamic>[],
          'bathroomCount': 0,
          'stairsSteps': 0,
        },
      };
      const selectedMaterialIds = [
        'Gạch xây',
        'Xi măng',
        'Thạch cao',
      ];

      final legacyResults =
          MaterialCalculator.calculateMaterialsFromDetailedParams(
        detailedParams,
        selectedMaterialIds: selectedMaterialIds,
      );

      // Brick/cement vẫn có quantity (nhóm walls không bị sập).
      final quantities = legacyResults['quantities'] as Map<String, dynamic>;
      expect(quantities, contains('Gạch xây'));
      expect(quantities['Gạch xây'] as double, greaterThan(0));
      expect(quantities, contains('Xi măng'));
      expect(quantities['Xi măng'] as double, greaterThan(0));

      // Lỗi được ghi đúng nhóm 'others' — không nuốt, không sập cả hàm.
      final errors = legacyResults['errors'] as Map<String, dynamic>;
      expect(errors, hasLength(1));
      expect(errors, contains('others'));

      const materials = [
        ProjectMaterial(
          selectionKey: 'k-brick',
          catalogCode: 'brick',
          name: 'Gạch xây',
          unit: 'piece',
          unitPrice: 1500,
          type: ProjectMaterialType.material,
        ),
        ProjectMaterial(
          selectionKey: 'k-cement',
          catalogCode: 'cement',
          name: 'Xi măng',
          unit: 'ton',
          unitPrice: 1800000,
          type: ProjectMaterialType.material,
        ),
        ProjectMaterial(
          selectionKey: 'k-gypsum',
          catalogCode: 'gypsum',
          name: 'Thạch cao',
          unit: 'm2',
          unitPrice: 160000,
          type: ProjectMaterialType.material,
        ),
      ];

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        materials,
      );

      expect(result.materialLines, hasLength(2));
      expect(result.issues, hasLength(1));
      final issue = result.issues.single;
      expect(issue.section, 'others');
      expect(issue.code, 'unknown_calculation_error');
      expect(issue.severity, CalculationIssueSeverity.error);
      expect(result.status, 'partial');
    });

    test(
        'lỗi nhóm walls (project cũ lưu trạng thái lỗi) → code ổn định '
        'walls_calculation_failed', () {
      final detailedParams = <String, dynamic>{
        'walls': <String, dynamic>{
          'walls': <dynamic>[],
          'area': 0.0,
        },
        'foundation': <String, dynamic>{
          'lengths': <double>[],
          'columns': 0,
        },
        'doors': <String, dynamic>{
          'windows': <dynamic>[],
          'doors': <dynamic>[],
          'rollingDoors': <dynamic>[],
          'windowArea': 0.0,
          'doorArea': 0.0,
          'rollingDoorArea': 0.0,
        },
        'others': <String, dynamic>{
          'bathrooms': <dynamic>[],
          'gypsumCeilingArea': 0.0,
          'stairs': <dynamic>[],
          'bathroomCount': 0,
          'stairsSteps': 0,
        },
      };

      final legacyResults =
          MaterialCalculator.calculateMaterialsFromDetailedParams(
        detailedParams,
        selectedMaterialIds: const ['Sơn nội thất'],
      );
      expect(
        (legacyResults['errors'] as Map<String, dynamic>),
        contains('walls'),
      );

      const materials = [
        ProjectMaterial(
          selectionKey: 'k-paint',
          catalogCode: 'interior_paint',
          name: 'Sơn nội thất',
          unit: 'm2',
          unitPrice: 65000,
          type: ProjectMaterialType.material,
        ),
      ];
      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        materials,
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'walls_calculation_failed');
      expect(result.issues.single.section, 'walls');
      expect(result.status, 'failure');
    });
  });

  group('FIX-CALC-001 Phase 6 — material unsupported minh bạch', () {
    test('6 catalogCode unsupported → warning issue thay vì biến mất im lặng',
        () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{'Gạch xây': 100.0},
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
        'errors': <String, dynamic>{},
      };
      const materials = [
        ProjectMaterial(
          selectionKey: 'k-brick',
          catalogCode: 'brick',
          name: 'Gạch xây',
          unit: 'piece',
          unitPrice: 1500,
          type: ProjectMaterialType.material,
        ),
        ProjectMaterial(
          selectionKey: 'k-tile',
          catalogCode: 'tile',
          name: 'Gạch lát nền 60x60',
          unit: 'm2',
          unitPrice: 150000,
          type: ProjectMaterialType.material,
        ),
        ProjectMaterial(
          selectionKey: 'k-composite',
          catalogCode: 'composite_door',
          name: 'Cửa nhựa composite',
          unit: 'set',
          unitPrice: 3500000,
          type: ProjectMaterialType.material,
        ),
      ];

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        materials,
      );

      // Material supported vẫn hiển thị bình thường.
      expect(result.materialLines, hasLength(1));
      expect(result.materialLines.single.name, 'Gạch xây');
      // 2 material unsupported → 2 warning, không phải error.
      expect(result.issues, hasLength(2));
      for (final issue in result.issues) {
        expect(issue.code, 'material_not_supported');
        expect(issue.severity, CalculationIssueSeverity.warning);
        expect(issue.section, 'materials');
      }
      expect(
        result.issues.map((issue) => issue.materialCode).toSet(),
        {'tile', 'composite_door'},
      );
      // Warning không chặn kết quả các vật tư khác.
      expect(result.hasWarnings, isTrue);
      expect(result.hasErrors, isFalse);
      expect(result.status, 'partial');
    });
  });

  group('FIX-CALC-001R — quantity null KHÔNG silent drop', () {
    const tile = ProjectMaterial(
      selectionKey: 'k-tile',
      catalogCode: 'tile',
      name: 'Gạch lát nền 60x60',
      unit: 'm2',
      unitPrice: 150000,
      type: ProjectMaterialType.material,
    );
    const futureMaterial = ProjectMaterial(
      selectionKey: 'k-future',
      catalogCode: 'future_material',
      name: 'Vật liệu tương lai',
      unit: 'm2',
      unitPrice: 999000,
      type: ProjectMaterialType.material,
    );
    const brick = ProjectMaterial(
      selectionKey: 'k-brick',
      catalogCode: 'brick',
      name: 'Gạch xây',
      unit: 'piece',
      unitPrice: 1500,
      type: ProjectMaterialType.material,
    );

    test(
        'REG-R6: known unsupported (tile) → warning material_not_supported, '
        'không phải error', () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{},
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
        'errors': <String, dynamic>{},
      };

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        const [tile],
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'material_not_supported');
      expect(result.issues.single.severity, CalculationIssueSeverity.warning);
      expect(result.issues.single.materialCode, 'tile');
      expect(result.hasErrors, isFalse);
      expect(result.hasWarnings, isTrue);
      expect(result.status, 'failure');
    });

    test(
        'REG-R7: unknown catalog (future_material) quantity null → error '
        'material_calculation_missing, materialCode = catalogCode', () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{},
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
        'errors': <String, dynamic>{},
      };

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        const [futureMaterial],
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'material_calculation_missing');
      expect(result.issues.single.severity, CalculationIssueSeverity.error);
      expect(result.issues.single.materialCode, 'future_material');
      expect(result.hasErrors, isTrue);
      expect(result.status, 'failure');
    });

    test(
        'REG-R8: mixed brick(success) + tile(warning) + future_material'
        '(error) → brick line vẫn tồn tại, các issue độc lập, không crash', () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{'Gạch xây': 100.0},
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
        'errors': <String, dynamic>{},
      };

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        const [brick, tile, futureMaterial],
      );

      expect(result.materialLines, hasLength(1));
      expect(result.materialLines.single.name, 'Gạch xây');
      expect(result.materialLines.single.quantity, 100.0);

      final codes = result.issues.map((issue) => issue.code).toSet();
      expect(codes, {'material_not_supported', 'material_calculation_missing'});
      expect(result.hasWarnings, isTrue);
      expect(result.hasErrors, isTrue);
      // brick thành công + có issue → partial (không thành failure).
      expect(result.status, 'partial');
    });

    test(
        'custom material (catalogCode null) quantity null → error '
        'material_calculation_missing, materialCode null', () {
      const custom = ProjectMaterial(
        selectionKey: 'k-custom',
        catalogCode: null,
        name: 'Vật liệu tùy chỉnh',
        unit: 'm2',
        unitPrice: 50000,
        type: ProjectMaterialType.material,
      );
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{},
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
        'errors': <String, dynamic>{},
      };

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        const [custom],
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'material_calculation_missing');
      expect(result.issues.single.severity, CalculationIssueSeverity.error);
      expect(result.issues.single.materialCode, isNull);
    });

    test(
        'section error đã báo nguyên nhân → KHÔNG double-report '
        'material_calculation_missing cho từng material', () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{},
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
        'errors': <String, dynamic>{
          'walls': Exception('Diện tích sơn nội thất phải lớn hơn 0'),
        },
      };
      const paint = ProjectMaterial(
        selectionKey: 'k-paint',
        catalogCode: 'interior_paint',
        name: 'Sơn nội thất',
        unit: 'm2',
        unitPrice: 65000,
        type: ProjectMaterialType.material,
      );

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        const [paint],
      );

      expect(result.materialLines, isEmpty);
      expect(result.issues, hasLength(1));
      expect(result.issues.single.code, 'walls_calculation_failed');
      expect(result.status, 'failure');
    });
  });

  group('FIX-CALC-001 Phase 12 — cost convention', () {
    test('quantity=10, unitPrice=65_000 → cost=650_000', () {
      const line = ProjectMaterialLine(
        name: 'Sơn nội thất',
        quantity: 10,
        unit: 'm2',
        unitPrice: 65000,
      );
      expect(line.cost, 650000);
    });

    test('totalCost = Σ line.cost', () {
      const result = ProjectCalculationResult(
        materialLines: [
          ProjectMaterialLine(
            name: 'A',
            quantity: 10,
            unitPrice: 65000,
          ),
          ProjectMaterialLine(
            name: 'B',
            quantity: 2,
            unitPrice: 1800000,
          ),
        ],
      );
      expect(result.totalCost, 650000 + 3600000);
      expect(result.status, 'success');
    });

    test('CalculationIssue props + severity', () {
      const issue = CalculationIssue(
        section: 'walls',
        code: 'walls_calculation_failed',
        severity: CalculationIssueSeverity.error,
      );
      expect(issue.section, 'walls');
      expect(issue.code, 'walls_calculation_failed');
      expect(issue.severity, CalculationIssueSeverity.error);
      expect(issue.materialCode, isNull);
      expect(
        issue,
        const CalculationIssue(
          section: 'walls',
          code: 'walls_calculation_failed',
          severity: CalculationIssueSeverity.error,
        ),
      );
    });
  });
}
