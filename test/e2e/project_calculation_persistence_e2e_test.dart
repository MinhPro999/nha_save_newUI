import 'dart:io';

import 'package:flutter_core_project/features/projects/data/project_database.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/calculate_project.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path_util;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// GATE 8 — E2E calculation + SQLite persistence.
/// Dùng SQLite thật (sqflite_common_ffi) + DI thật (production binding
/// LegacyCalculationService) — KHÔNG mock CalculationService.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory temporaryDirectory;
  late String databasePath;
  late CalculateProject calculateProject;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDependencies();
    final service = sl<CalculationService>();
    expect(service, isA<LegacyCalculationService>(),
        reason: 'E2E bắt buộc production binding Legacy');
    calculateProject = sl<CalculateProject>();
  });

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'dutoan_e2e_',
    );
    databasePath = path_util.join(temporaryDirectory.path, 'e2e.db');
  });

  tearDown(() async {
    await databaseFactoryFfi.deleteDatabase(databasePath);
    await temporaryDirectory.delete(recursive: true);
  });

  Future<void> saveProject(ConstructionProject project) async {
    final database = ProjectDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    await database.save(project);
    await database.close();
  }

  /// Reload thật: mở database MỚI từ file (mô phỏng app reload).
  Future<List<ConstructionProject>> reloadProjects() async {
    final database = ProjectDatabase(
      factory: databaseFactoryFfi,
      databasePath: databasePath,
    );
    final projects = await database.getAll();
    await database.close();
    return projects;
  }

  // ── Semantic compare helpers ─────────────────────────────────────────

  void expectResultParity(
    ProjectCalculationResult actual,
    ProjectCalculationResult expected,
  ) {
    expect(actual.totalCost, expected.totalCost, reason: 'totalCost');
    final actualLines = [...actual.materialLines]
      ..sort((a, b) => a.name.compareTo(b.name));
    final expectedLines = [...expected.materialLines]
      ..sort((a, b) => a.name.compareTo(b.name));
    expect(actualLines.length, expectedLines.length, reason: 'line count');
    for (var index = 0; index < actualLines.length; index++) {
      final actual = actualLines[index];
      final expected = expectedLines[index];
      expect(actual.name, expected.name, reason: 'line name');
      expect(actual.quantity, expected.quantity,
          reason: 'quantity ${actual.name}');
      expect(actual.unit, expected.unit, reason: 'unit ${actual.name}');
      expect(actual.unitPrice, expected.unitPrice,
          reason: 'unitPrice ${actual.name}');
      expect(actual.cost, expected.cost, reason: 'cost ${actual.name}');
    }
    expect(
      actual.foundation?.toMap(),
      expected.foundation?.toMap(),
      reason: 'foundation section',
    );
  }

  void expectProjectParity(
    ConstructionProject actual,
    ConstructionProject expected,
  ) {
    expect(actual.id, expected.id);
    expect(actual.name, expected.name);
    expect(actual.location, expected.location);
    // Floors
    expect(actual.floors.length, expected.floors.length);
    for (var index = 0; index < actual.floors.length; index++) {
      expect(actual.floors[index].number, expected.floors[index].number);
      expect(actual.floors[index].length, expected.floors[index].length);
      expect(actual.floors[index].width, expected.floors[index].width);
      expect(actual.floors[index].height, expected.floors[index].height);
    }
    // Roof
    expect(actual.roof.type, expected.roof.type);
    expect(actual.roof.length, expected.roof.length);
    expect(actual.roof.width, expected.roof.width);
    expect(actual.roof.height, expected.roof.height);
    // Foundation (enum semantic + dims)
    final actualFoundation = actual.foundationStructure;
    final expectedFoundation = expected.foundationStructure;
    expect(actualFoundation.foundationType, expectedFoundation.foundationType);
    expect(actualFoundation.structureType, expectedFoundation.structureType);
    expect(actualFoundation.alignment, expectedFoundation.alignment);
    expect(
      actualFoundation.mainBarDiameter,
      expectedFoundation.mainBarDiameter,
    );
    expect(
      actualFoundation.isolatedLength,
      expectedFoundation.isolatedLength,
    );
    expect(actualFoundation.isolatedWidth, expectedFoundation.isolatedWidth);
    expect(
      actualFoundation.isolatedHeight,
      expectedFoundation.isolatedHeight,
    );
    expect(actualFoundation.columns.length, expectedFoundation.columns.length);
    for (var index = 0; index < actualFoundation.columns.length; index++) {
      expect(
        actualFoundation.columns[index].width,
        expectedFoundation.columns[index].width,
      );
      expect(
        actualFoundation.columns[index].thickness,
        expectedFoundation.columns[index].thickness,
      );
      expect(
        actualFoundation.columns[index].quantity,
        expectedFoundation.columns[index].quantity,
      );
      expect(
        actualFoundation.columns[index].mainBarsCount,
        expectedFoundation.columns[index].mainBarsCount,
      );
      expect(
        actualFoundation.columns[index].mainBarDiameter,
        expectedFoundation.columns[index].mainBarDiameter,
      );
    }
    expect(
        actualFoundation.pileCaps.length, expectedFoundation.pileCaps.length);
    for (var index = 0; index < actualFoundation.pileCaps.length; index++) {
      expect(
        actualFoundation.pileCaps[index].length,
        expectedFoundation.pileCaps[index].length,
      );
      expect(
        actualFoundation.pileCaps[index].width,
        expectedFoundation.pileCaps[index].width,
      );
      expect(
        actualFoundation.pileCaps[index].height,
        expectedFoundation.pileCaps[index].height,
      );
    }
    // Materials (price snapshot + catalogCode)
    expect(actual.materials.length, expected.materials.length);
    for (var index = 0; index < actual.materials.length; index++) {
      expect(
        actual.materials[index].selectionKey,
        expected.materials[index].selectionKey,
      );
      expect(
        actual.materials[index].catalogCode,
        expected.materials[index].catalogCode,
      );
      expect(actual.materials[index].name, expected.materials[index].name);
      expect(actual.materials[index].unit, expected.materials[index].unit);
      expect(
        actual.materials[index].unitPrice,
        expected.materials[index].unitPrice,
      );
      expect(actual.materials[index].type, expected.materials[index].type);
    }
    // Details
    expect(
      actual.details.foundationSegments.length,
      expected.details.foundationSegments.length,
    );
    for (var index = 0;
        index < actual.details.foundationSegments.length;
        index++) {
      expect(
        actual.details.foundationSegments[index].length,
        expected.details.foundationSegments[index].length,
      );
    }
    expect(actual.details.walls.length, expected.details.walls.length);
    for (var index = 0; index < actual.details.walls.length; index++) {
      expect(
        actual.details.walls[index].type,
        expected.details.walls[index].type,
      );
      expect(
        actual.details.walls[index].plasterSides,
        expected.details.walls[index].plasterSides,
      );
      expect(
        actual.details.walls[index].length,
        expected.details.walls[index].length,
      );
      expect(
        actual.details.walls[index].height,
        expected.details.walls[index].height,
      );
    }
    expect(actual.details.openings.length, expected.details.openings.length);
    for (var index = 0; index < actual.details.openings.length; index++) {
      expect(
        actual.details.openings[index].type,
        expected.details.openings[index].type,
      );
      expect(
        actual.details.openings[index].width,
        expected.details.openings[index].width,
      );
      expect(
        actual.details.openings[index].height,
        expected.details.openings[index].height,
      );
      expect(
        actual.details.openings[index].quantity,
        expected.details.openings[index].quantity,
      );
    }
    expect(actual.details.bathrooms.length, expected.details.bathrooms.length);
    for (var index = 0; index < actual.details.bathrooms.length; index++) {
      expect(
        actual.details.bathrooms[index].area,
        expected.details.bathrooms[index].area,
      );
    }
    expect(actual.details.stairs.length, expected.details.stairs.length);
    for (var index = 0; index < actual.details.stairs.length; index++) {
      expect(
        actual.details.stairs[index].steps,
        expected.details.stairs[index].steps,
      );
    }
  }

  // ── Fixtures ─────────────────────────────────────────────────────────

  ConstructionProject buildProject({
    String id = 'e2e-project',
    List<BuildingFloor> floors = const [
      BuildingFloor(number: 1, length: 10, width: 5, height: 3),
    ],
    FoundationStructureSpec? foundationStructure,
    List<ProjectMaterial> materials = const [
      ProjectMaterial(
        selectionKey: 'sel-brick',
        catalogCode: 'brick',
        name: 'Gạch xây',
        unit: 'piece',
        unitPrice: 1500,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'sel-cement',
        catalogCode: 'cement',
        name: 'Xi măng',
        unit: 'ton',
        unitPrice: 1800000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'sel-steel',
        catalogCode: 'steel',
        name: 'Sắt thép',
        unit: 'ton',
        unitPrice: 18000000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'sel-concrete-sand',
        catalogCode: 'concrete_sand',
        name: 'Cát bê tông',
        unit: 'm3',
        unitPrice: 450000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'sel-aluminum',
        catalogCode: 'aluminum_door',
        name: 'Cửa nhôm Xingfa',
        unit: 'm2',
        unitPrice: 1800000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'sel-gypsum',
        catalogCode: 'gypsum',
        name: 'Thạch cao',
        unit: 'm2',
        unitPrice: 160000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'sel-labor',
        catalogCode: 'labor',
        name: 'Nhân công xây dựng',
        unit: 'm2',
        unitPrice: 1350000,
        type: ProjectMaterialType.labor,
      ),
      ProjectMaterial(
        selectionKey: 'sel-tile',
        catalogCode: 'tile',
        name: 'Gạch lát nền 60x60',
        unit: 'm2',
        unitPrice: 150000,
        type: ProjectMaterialType.material,
      ),
    ],
    ProjectDetails details = const ProjectDetails(
      foundationSegments: [FoundationSegment(12), FoundationSegment(8)],
      walls: [
        WallSpec(
          type: WallType.wall100,
          plasterSides: 2,
          length: 4,
          height: 3.3,
        ),
      ],
      openings: [
        OpeningSpec(
            type: OpeningType.door, width: 0.9, height: 2.2, quantity: 1)
      ],
      bathrooms: [BathroomSpec(5)],
      stairs: [StairSpec(18)],
    ),
  }) {
    return ConstructionProject(
      id: id,
      name: 'Nhà E2E',
      location: 'Hà Nội',
      createdAt: DateTime.utc(2026, 9, 1, 8),
      updatedAt: DateTime.utc(2026, 9, 1, 9),
      floors: floors,
      roof: const RoofSpec(
        type: RoofType.flat,
        length: 10,
        width: 5,
        height: 0,
      ),
      foundationStructure: foundationStructure ??
          const FoundationStructureSpec(
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
      details: details,
    );
  }

  // ── Cases ────────────────────────────────────────────────────────────

  test('CASE A — create → calculate → save → reload → recalculate parity',
      () async {
    final project = buildProject();
    final before = await calculateProject(project);

    expect(before.materialLines, isNotEmpty);
    expect(before.totalCost, greaterThan(0));
    expect(before.foundation, isNotNull);
    expect(before.foundation!.totalConcreteM3, greaterThan(0));

    await saveProject(project);
    final reloaded = await reloadProjects();
    expect(reloaded, hasLength(1));

    final after = await calculateProject(reloaded.single);
    expectResultParity(after, before);
  });

  test('CASE B — multi floors + openings + foundation → save/reload parity',
      () async {
    final project = buildProject(
      floors: const [
        BuildingFloor(number: 1, length: 10, width: 5, height: 3.3),
        BuildingFloor(number: 2, length: 8, width: 6, height: 2.8),
      ],
      foundationStructure: const FoundationStructureSpec(
        foundationType: FoundationType.pile,
        structureType: StructureType.steelFrame,
        alignment: FoundationAlignment.offsetOneSide,
        mainBarDiameter: 20,
        columns: [
          ColumnSpec(
            width: 0.25,
            thickness: 0.3,
            quantity: 6,
            mainBarsCount: 6,
            mainBarDiameter: 20,
          ),
        ],
        pileCaps: [PileCapSpec(length: 1.5, width: 1.5, height: 0.8)],
      ),
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(15), FoundationSegment(10)],
        walls: [
          WallSpec(
            type: WallType.wall100,
            plasterSides: 1,
            length: 5,
            height: 3.2,
          ),
          WallSpec(
            type: WallType.wall200,
            plasterSides: 2,
            length: 6,
            height: 3.2,
          ),
        ],
        openings: [
          OpeningSpec(
              type: OpeningType.window, width: 1.2, height: 1.4, quantity: 2),
          OpeningSpec(
              type: OpeningType.rollingDoor, width: 3, height: 3, quantity: 1),
        ],
        bathrooms: [BathroomSpec(4), BathroomSpec(6)],
        stairs: [StairSpec(20)],
      ),
    );

    final before = await calculateProject(project);
    await saveProject(project);
    final reloaded = await reloadProjects();
    expectProjectParity(reloaded.single, project);
    final after = await calculateProject(reloaded.single);
    expectResultParity(after, before);
  });

  test('CASE C — modify input → recalculate → save → reload (no stale result)',
      () async {
    final project = buildProject();
    final before = await calculateProject(project);

    final modified = project.copyWith(
      details: ProjectDetails(
        foundationSegments: project.details.foundationSegments,
        walls: const [
          WallSpec(
            type: WallType.wall100,
            plasterSides: 2,
            length: 10,
            height: 3.3,
          ),
        ],
        openings: project.details.openings,
        bathrooms: project.details.bathrooms,
        stairs: project.details.stairs,
      ),
      updatedAt: DateTime.utc(2026, 9, 1, 10),
    );
    final afterModify = await calculateProject(modified);
    expect(afterModify.totalCost, isNot(before.totalCost),
        reason: 'input thay đổi phải ra kết quả mới');
    final brickBefore =
        before.materialLines.firstWhere((line) => line.name == 'Gạch xây');
    final brickAfter =
        afterModify.materialLines.firstWhere((line) => line.name == 'Gạch xây');
    expect(brickAfter.quantity, isNot(brickBefore.quantity));

    await saveProject(modified);
    final reloaded = await reloadProjects();
    expect(reloaded.single.details.walls.single.length, 10,
        reason: 'saved input phải là input đã sửa');
    final afterReload = await calculateProject(reloaded.single);
    expectResultParity(afterReload, afterModify);
  });

  test('PRICE SNAPSHOT — unitPrice giữ nguyên sau save/reload', () async {
    final project = buildProject();
    await saveProject(project);
    final reloaded = await reloadProjects();

    final steel = reloaded.single.materials
        .firstWhere((material) => material.catalogCode == 'steel');
    expect(steel.unitPrice, 18000000,
        reason: 'price snapshot KHÔNG đổi theo catalog');
    final result = await calculateProject(reloaded.single);
    final steelLine =
        result.materialLines.firstWhere((line) => line.name == 'Sắt thép');
    expect(steelLine.unitPrice, 18000000);
    expect(steelLine.cost, steelLine.unitPrice * steelLine.quantity);
  });

  for (final foundationCase in <String, FoundationStructureSpec>{
    'strip': const FoundationStructureSpec(
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
            mainBarDiameter: 16),
      ],
    ),
    'raft': const FoundationStructureSpec(
      foundationType: FoundationType.raft,
      structureType: StructureType.reinforcedConcrete,
      mainBarDiameter: 18,
      columns: [
        ColumnSpec(
            width: 0.25,
            thickness: 0.3,
            quantity: 4,
            mainBarsCount: 6,
            mainBarDiameter: 18),
      ],
    ),
    'isolated': const FoundationStructureSpec(
      foundationType: FoundationType.isolated,
      structureType: StructureType.reinforcedConcrete,
      mainBarDiameter: 22,
      columns: [
        ColumnSpec(
            width: 0.25,
            thickness: 0.3,
            quantity: 3,
            mainBarsCount: 6,
            mainBarDiameter: 22),
      ],
      isolatedLength: 1.2,
      isolatedWidth: 1.2,
      isolatedHeight: 0.6,
    ),
    'pile': const FoundationStructureSpec(
      foundationType: FoundationType.pile,
      structureType: StructureType.steelFrame,
      mainBarDiameter: 16,
      columns: [
        ColumnSpec(
            width: 0.25,
            thickness: 0.3,
            quantity: 4,
            mainBarsCount: 6,
            mainBarDiameter: 16),
      ],
      pileCaps: [PileCapSpec(length: 1.5, width: 1.5, height: 0.8)],
    ),
  }.entries) {
    test('FOUNDATION ${foundationCase.key} — save/reload/recalculate parity',
        () async {
      final project = buildProject(
        id: 'e2e-foundation-${foundationCase.key}',
        foundationStructure: foundationCase.value,
      );
      final before = await calculateProject(project);
      await saveProject(project);
      final reloaded = await reloadProjects();
      expectProjectParity(reloaded.single, project);
      final after = await calculateProject(reloaded.single);
      expectResultParity(after, before);
    });
  }

  test('SPECIAL MATERIALS — steel/concrete_sand/aluminum_door/gypsum/no-key',
      () async {
    final project = buildProject();
    final before = await calculateProject(project);
    final beforeLines = {
      for (final line in before.materialLines) line.name: line
    };

    // steel → key "Thép", display "Sắt thép"
    expect(beforeLines['Sắt thép']!.quantity, greaterThan(0));
    // concrete_sand → key "Bê tông"
    expect(beforeLines['Cát bê tông']!.quantity, greaterThan(0));
    // aluminum_door → key "Nhôm"
    expect(beforeLines['Cửa nhôm Xingfa']!.quantity, greaterThan(0));
    // gypsum → gypsumCeilingArea = 0.0
    expect(beforeLines['Thạch cao']!.quantity, 0.0);
    // tile — không có aggregated key → không sinh quantity → không có dòng.
    expect(beforeLines.containsKey('Gạch lát nền 60x60'), isFalse);

    await saveProject(project);
    final reloaded = await reloadProjects();
    final after = await calculateProject(reloaded.single);
    expectResultParity(after, before);
  });

  test('ENUM SEMANTICS — round-trip giữ enum đúng semantic', () async {
    const walls = [
      WallSpec(
        type: WallType.wall200,
        plasterSides: 1,
        length: 5,
        height: 3.2,
      ),
    ];
    final project = buildProject(
      floors: const [
        BuildingFloor(number: 1, length: 9, width: 4, height: 3),
      ],
      foundationStructure: const FoundationStructureSpec(
        foundationType: FoundationType.pile,
        structureType: StructureType.masonry,
        alignment: FoundationAlignment.offsetTwoSides,
        mainBarDiameter: 20,
        columns: [
          ColumnSpec(
              width: 0.2,
              thickness: 0.25,
              quantity: 2,
              mainBarsCount: 4,
              mainBarDiameter: 20),
        ],
        pileCaps: [PileCapSpec(length: 1.2, width: 1.2, height: 0.5)],
      ),
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(9)],
        walls: walls,
        openings: [
          OpeningSpec(
              type: OpeningType.rollingDoor,
              width: 2.5,
              height: 2.5,
              quantity: 1),
        ],
        bathrooms: [BathroomSpec(3)],
        stairs: [StairSpec(15)],
      ),
    );

    await saveProject(project);
    final reloaded = await reloadProjects();
    expectProjectParity(reloaded.single, project);

    final foundation = reloaded.single.foundationStructure;
    expect(foundation.foundationType, FoundationType.pile);
    expect(foundation.structureType, StructureType.masonry);
    expect(foundation.alignment, FoundationAlignment.offsetTwoSides);
    expect(reloaded.single.details.walls.single.type, WallType.wall200);
    expect(
      reloaded.single.details.openings.single.type,
      OpeningType.rollingDoor,
    );
  });

  test(
      'FIX-CALC-001 — interior_paint + bỏ qua Tường → Default Wall đúng '
      'số liệu, save/reload KHÔNG ghi dữ liệu ước lượng ngược vào DB',
      () async {
    final project = buildProject(
      id: 'e2e-default-wall',
      floors: const [
        BuildingFloor(number: 1, length: 10, width: 8, height: 3.3),
      ],
      materials: const [
        ProjectMaterial(
          selectionKey: 'sel-paint',
          catalogCode: 'interior_paint',
          name: 'Sơn nội thất',
          unit: 'm2',
          unitPrice: 65000,
          type: ProjectMaterialType.material,
        ),
      ],
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(12), FoundationSegment(8)],
        // KHÔNG nhập tường.
      ),
    );

    final before = await calculateProject(project);

    // Không throw, không issue — status success.
    expect(before.issues, isEmpty);
    expect(before.status, 'success');
    final paint =
        before.materialLines.firstWhere((line) => line.name == 'Sơn nội thất');
    // Default Wall: perimeter = 36 → 36 × 3.3 × 2 × 1.5 = 356.4 m².
    expect(paint.quantity, closeTo(356.4, 1e-9));
    expect(paint.cost, closeTo(65000 * 356.4, 1e-9));

    await saveProject(project);
    final reloaded = await reloadProjects();
    // Dữ liệu Default Wall KHÔNG ghi ngược DB — walls vẫn rỗng.
    expect(reloaded.single.details.walls, isEmpty);

    final after = await calculateProject(reloaded.single);
    expectResultParity(after, before);
  });
}
