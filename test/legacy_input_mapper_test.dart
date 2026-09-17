import 'package:flutter_core_project/calculator_core/models/project/foundation_structure_model.dart';
import 'package:flutter_core_project/calculator_core/services/foundation_structure_calculator.dart';
import 'package:flutter_core_project/calculator_core/services/material_calculator.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_input_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_result_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LegacyInputMapper — enum maps (semantic, KHÔNG .index)', () {
    test('wall type', () {
      expect(LegacyInputMapper.mapWallType(WallType.wall100), '10');
      expect(LegacyInputMapper.mapWallType(WallType.wall200), '20');
    });

    test('foundation type', () {
      expect(
        LegacyInputMapper.mapFoundationType(FoundationType.strip),
        FoundationTypeNew.bang,
      );
      expect(
        LegacyInputMapper.mapFoundationType(FoundationType.raft),
        FoundationTypeNew.be,
      );
      expect(
        LegacyInputMapper.mapFoundationType(FoundationType.isolated),
        FoundationTypeNew.coc,
      );
      expect(
        LegacyInputMapper.mapFoundationType(FoundationType.pile),
        FoundationTypeNew.coc_pile,
      );
      expect(LegacyInputMapper.mapFoundationType(null), isNull);
    });

    test('alignment', () {
      expect(
        LegacyInputMapper.mapFoundationAlignment(
          FoundationAlignment.balanced,
        ),
        FoundationBangAttribute.can_2_ben,
      );
      expect(
        LegacyInputMapper.mapFoundationAlignment(
          FoundationAlignment.offsetOneSide,
        ),
        FoundationBangAttribute.lech_1_ben,
      );
      expect(
        LegacyInputMapper.mapFoundationAlignment(
          FoundationAlignment.offsetTwoSides,
        ),
        FoundationBangAttribute.lech_2_ben,
      );
      expect(
        LegacyInputMapper.mapFoundationAlignment(null),
        FoundationBangAttribute.can_2_ben,
      );
    });

    test('steel diameter by value, not index — policy invalid/error', () {
      expect(LegacyInputMapper.mapSteelDiameter(14), SteelDiameter.d14);
      expect(LegacyInputMapper.mapSteelDiameter(16), SteelDiameter.d16);
      expect(LegacyInputMapper.mapSteelDiameter(20), SteelDiameter.d20);
      expect(LegacyInputMapper.mapSteelDiameter(22), SteelDiameter.d22);
      // null/missing → default d16 (legacy UI default).
      expect(LegacyInputMapper.mapSteelDiameter(null), SteelDiameter.d16);
      // Giá trị KHÔNG hợp lệ → lỗi validation, KHÔNG silent-map về d16.
      expect(
        () => LegacyInputMapper.mapSteelDiameter(99),
        throwsArgumentError,
      );
      expect(
        () => LegacyInputMapper.mapSteelDiameter(0),
        throwsArgumentError,
      );
    });
  });

  group('LegacyInputMapper — material key boundary (catalogCode)', () {
    test('catalogCode steel → "Thép" (legacy check) dù name hiển thị khác', () {
      final project = ConstructionProject(
        id: 'p-steel',
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
          mainBarDiameter: 16,
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

      final input = LegacyInputMapper.mapMaterialInput(project);

      // Boundary: identity tính toán theo catalogCode, không theo name.
      expect(input.selectedMaterialIds, contains('Thép'));
      expect(input.selectedMaterialIds, isNot(contains('Sắt thép')));
      expect(input.selectedMaterialIds, contains('Bê tông'));
      expect(input.selectedMaterialIds, isNot(contains('Cát bê tông')));

      // Chạy legacy engine thật: quantity thép không bị mất.
      final results = MaterialCalculator.calculateMaterialsFromDetailedParams(
        input.detailedParams,
        selectedMaterialIds: input.selectedMaterialIds,
        brickDimensions: input.brickDimensions,
        floors: input.floors,
      );
      final quantities = results['quantities'] as Map<String, dynamic>;
      expect(quantities, contains('Thép'));
      expect(quantities['Thép'], isA<double>());
      expect(quantities['Thép'] as double, greaterThan(0));
      // 'Bê tông' = khối bê tông móng (m³) theo legacy
      // (_calculateFoundationMaterials).
      expect(quantities, contains('Bê tông'));
      expect(quantities['Bê tông'] as double, greaterThan(0));
    });

    test('catalogCode không có key → fallback name (hành vi legacy runtime)',
        () {
      expect(
        LegacyMaterialSelectionKeyMapper.selectionIdFor(
          catalogCode: 'tile',
          name: 'Gạch lát nền 60x60',
        ),
        'Gạch lát nền 60x60',
      );
      expect(
        LegacyMaterialSelectionKeyMapper.selectionIdFor(
          catalogCode: null,
          name: 'Vật liệu tùy chỉnh',
        ),
        'Vật liệu tùy chỉnh',
      );
    });

    test('catalogCode aluminum_door → "Nhôm" (legacy check cửa)', () {
      expect(
        LegacyMaterialSelectionKeyMapper.selectionIdFor(
          catalogCode: 'aluminum_door',
          name: 'Cửa nhôm Xingfa',
        ),
        'Nhôm',
      );
    });
  });

  group('LegacyInputMapper — material input contract', () {
    ConstructionProject buildProject() {
      return ConstructionProject(
        id: 'p1',
        name: 'Nhà mẫu',
        location: 'Hà Nội',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        floors: const [
          BuildingFloor(number: 1, length: 10, width: 5, height: 3),
          BuildingFloor(number: 2, length: 10, width: 5, height: 2.8),
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
            selectionKey: 'k1',
            name: 'Gạch xây',
            unit: 'piece',
            unitPrice: 1500,
            type: ProjectMaterialType.material,
            catalogCode: 'brick',
          ),
          ProjectMaterial(
            selectionKey: 'k2',
            name: 'Xi măng',
            unit: 'ton',
            unitPrice: 1800000,
            type: ProjectMaterialType.material,
            catalogCode: 'cement',
          ),
        ],
        details: const ProjectDetails(
          foundationSegments: [FoundationSegment(12), FoundationSegment(8)],
          walls: [
            WallSpec(
              type: WallType.wall100,
              plasterSides: 2,
              length: 4,
              height: 3.3,
            ),
            WallSpec(
              type: WallType.wall200,
              plasterSides: 1,
              length: 5,
              height: 3.3,
            ),
          ],
          openings: [
            OpeningSpec(
              type: OpeningType.window,
              width: 1.2,
              height: 1.4,
              quantity: 2,
            ),
            OpeningSpec(
              type: OpeningType.door,
              width: 0.9,
              height: 2.2,
              quantity: 1,
            ),
            OpeningSpec(
              type: OpeningType.rollingDoor,
              width: 3,
              height: 3,
              quantity: 1,
            ),
          ],
          bathrooms: [BathroomSpec(5), BathroomSpec(4)],
          stairs: [StairSpec(18)],
        ),
      );
    }

    test('detailedParams khớp legacy input contract', () {
      final input = LegacyInputMapper.mapMaterialInput(buildProject());
      final params = input.detailedParams;

      // Foundation
      expect(params['foundation']['lengths'], [12, 8]);
      expect(params['foundation']['columns'], 1);

      // Walls
      final walls = params['walls']['walls'] as List;
      expect(walls, hasLength(2));
      expect(walls[0]['type'], '10');
      expect(walls[0]['plasterSides'], 2);
      expect(walls[0]['area'], closeTo(4 * 3.3, 1e-9));
      expect(walls[1]['type'], '20');
      expect(walls[1]['plasterSides'], 1);
      expect(
        params['walls']['area'],
        closeTo(4 * 3.3 + 5 * 3.3, 1e-9),
      );

      // Doors
      final doors = params['doors'];
      expect(doors['windows'], hasLength(1));
      expect(doors['doors'], hasLength(1));
      expect(doors['rollingDoors'], hasLength(1));
      expect(doors['windows'][0]['area'], closeTo(1.2 * 1.4 * 2, 1e-9));
      expect(doors['windowArea'], closeTo(1.2 * 1.4 * 2, 1e-9));

      // Others
      final others = params['others'];
      expect(others['bathrooms'], hasLength(2));
      expect(others['bathroomCount'], 2);
      expect(others['stairs'][0]['steps'], 18);
      expect(others['stairsSteps'], 18);
      expect(others['gypsumCeilingArea'], 0.0);

      // selectedMaterialIds: catalogCode → legacy key ('brick'→'Gạch xây'...).
      expect(input.selectedMaterialIds, ['Gạch xây', 'Xi măng']);

      // brickDimensions default legacy runtime
      expect(input.brickDimensions, {
        'length': 0.2,
        'width': 0.1,
        'height': 0.05,
      });

      // Floors: mỗi floor map phải có 'area'
      expect(input.floors, hasLength(2));
      expect(input.floors[0]['area'], 50.0);
      expect(input.floors[1]['area'], 50.0);
    });

    test('foundation input khớp legacy derivation (floors.first + hTotal)', () {
      final input = LegacyInputMapper.mapFoundationInput(buildProject());
      expect(input.l1, 10);
      expect(input.w1, 5);
      expect(input.area1, 50);
      expect(input.hTotal, closeTo(5.8, 1e-9));

      final data = input.foundationData;
      expect(data.foundationType, FoundationTypeNew.bang);
      expect(data.columns, hasLength(1));
      expect(data.columns.first.mainBarDiameter, SteelDiameter.d16);
      expect(data.bangInfo?.attribute, FoundationBangAttribute.can_2_ben);
      expect(data.bangInfo?.mainBarDiameter, SteelDiameter.d16);
      // Không phải loại tương ứng → info null.
      expect(data.beInfo, isNull);
      expect(data.cocInfo, isNull);
      expect(data.cocPileInfo, isNull);
    });

    test('móng cọc không có đài → cocPileInfo null (legacy trả empty)', () {
      final project = buildProject();
      final pileProject = ConstructionProject(
        id: 'p2',
        name: project.name,
        location: project.location,
        createdAt: project.createdAt,
        updatedAt: project.updatedAt,
        floors: project.floors,
        roof: project.roof,
        foundationStructure: const FoundationStructureSpec(
          foundationType: FoundationType.pile,
          structureType: StructureType.reinforcedConcrete,
          mainBarDiameter: 20,
          pileCaps: [],
        ),
        materials: project.materials,
        details: project.details,
      );

      final input = LegacyInputMapper.mapFoundationInput(pileProject);
      expect(input.foundationData.foundationType, FoundationTypeNew.coc_pile);
      expect(input.foundationData.cocPileInfo, isNull);
    });
  });

  group('LegacyResultMapper — typed result boundary', () {
    test('quantity + cost theo convention legacy (không round cost)', () {
      final legacyResults = <String, dynamic>{
        'quantities': <String, dynamic>{
          'Gạch xây': 12800.0,
          'Xi măng': 5.4,
          'Đá': 15.0, // không có trong snapshot → bị bỏ qua như legacy UI
        },
        'costs': <String, dynamic>{},
        'intermediateResults': <String, dynamic>{},
      };
      const materials = [
        ProjectMaterial(
          selectionKey: 'k1',
          name: 'Gạch xây',
          unit: 'piece',
          unitPrice: 1500,
          type: ProjectMaterialType.material,
        ),
        ProjectMaterial(
          selectionKey: 'k2',
          name: 'Xi măng',
          unit: 'ton',
          unitPrice: 1800000,
          type: ProjectMaterialType.material,
        ),
      ];

      final result = LegacyResultMapper.mapMaterialResult(
        legacyResults,
        materials,
      );

      expect(result.materialLines, hasLength(2));
      expect(result.materialLines[0].name, 'Gạch xây');
      expect(result.materialLines[0].quantity, 12800.0);
      expect(result.materialLines[0].unit, 'piece');
      expect(result.materialLines[0].cost, 1500 * 12800);
      expect(result.materialLines[1].cost, 1800000 * 5.4);
      expect(result.totalCost, 1500 * 12800 + 1800000 * 5.4);
      expect(result.foundation, isNull);
    });

    test('foundation section chép giá trị 1-1 từ FoundationStructureResult',
        () {
      // Giá trị ví dụ — mapper chỉ copy, không tính lại.
      final legacyResult = FoundationStructureResult(
        columnConcreteM3: 1.5,
        foundationConcreteM3: 2.5,
        totalConcreteM3: 4.0,
        columnCementKg: 100,
        columnSandM3: 1,
        columnStoneM3: 2,
        columnWaterL: 3,
        foundationCementKg: 200,
        foundationSandM3: 4,
        foundationStoneM3: 5,
        foundationWaterL: 6,
        totalCementKg: 300,
        totalSandM3: 5,
        totalStoneM3: 7,
        totalWaterL: 9,
        columnSteelKg: 50,
        foundationSteelKg: 60,
        totalSteelKg: 110,
        cementBags50kg: 6,
        cementTon: 0.3,
        steelTon: 0.11,
        waterM3: 0.009,
      );

      final section = LegacyResultMapper.mapFoundationResult(legacyResult);
      expect(section.totalConcreteM3, 4.0);
      expect(section.totalSteelKg, 110);
      expect(section.cementBags50kg, 6);

      // Round-trip qua toMap/fromMap giữ nguyên giá trị (phục vụ Gate 8).
      final restored = FoundationStructureSection.fromMap(section.toMap());
      expect(restored, section);
    });
  });
}
