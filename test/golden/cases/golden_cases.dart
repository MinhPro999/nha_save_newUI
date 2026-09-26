import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'canonical_cases.dart';

/// Bộ golden cases — canonical input (new UI) + canonical legacy input cho
/// oracle @ e5fc8943. Không chứa expected value — expected được sinh bởi
/// `tool/golden/generate_expected.dart` chạy code legacy authoritative.
List<GoldenCase> buildGoldenCases() {
  final cases = <GoldenCase>[];

  // ── Nhóm A/B: WALLS ──────────────────────────────────────────────────
  for (final plaster in [0, 1, 2]) {
    final id = 'golden_wall_100_plaster_$plaster';
    final walls = [wallMap('10', plaster, wall100L, wall100H)];
    final wallsNew = [wallSpec(WallType.wall100, plaster, wall100L, wall100H)];
    cases.add(
      GoldenCase(
        id: id,
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('sand', 'Cát xây', 'm3', 300000),
            pmat('plaster_sand', 'Cát trát', 'm3', 320000),
          ],
          details: detailsFor(walls: wallsNew),
        ),
        detailedParams: canonicalParams(walls: walls),
        selectedMaterialIds: ['Gạch xây', 'Xi măng', 'Cát xây', 'Cát trát'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
  }
  for (final plaster in [0, 1, 2]) {
    final id = 'golden_wall_200_plaster_$plaster';
    final walls = [wallMap('20', plaster, wall200L, wall200H)];
    final wallsNew = [wallSpec(WallType.wall200, plaster, wall200L, wall200H)];
    cases.add(
      GoldenCase(
        id: id,
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('sand', 'Cát xây', 'm3', 300000),
            pmat('plaster_sand', 'Cát trát', 'm3', 320000),
          ],
          details: detailsFor(walls: wallsNew),
        ),
        detailedParams: canonicalParams(walls: walls),
        selectedMaterialIds: ['Gạch xây', 'Xi măng', 'Cát xây', 'Cát trát'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
  }
  {
    const id = 'golden_walls_mixed_100_200';
    final walls = [
      wallMap('10', 2, wall100L, wall100H),
      wallMap('20', 1, wall200L, wall200H),
    ];
    cases.add(
      GoldenCase(
        id: id,
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('sand', 'Cát xây', 'm3', 300000),
            pmat('plaster_sand', 'Cát trát', 'm3', 320000),
          ],
          details: detailsFor(
            walls: [
              wallSpec(WallType.wall100, 2, wall100L, wall100H),
              wallSpec(WallType.wall200, 1, wall200L, wall200H),
            ],
          ),
        ),
        detailedParams: canonicalParams(walls: walls),
        selectedMaterialIds: ['Gạch xây', 'Xi măng', 'Cát xây', 'Cát trát'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
  }

  // ── Nhóm C: OPENINGS ────────────────────────────────────────────────
  {
    final walls = [wallMap('10', 2, wall100L, wall100H)];
    final wallsNew = [wallSpec(WallType.wall100, 2, wall100L, wall100H)];
    cases.add(
      GoldenCase(
        id: 'golden_openings_windows',
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
            pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
          ],
          details: detailsFor(
            walls: wallsNew,
            openings: [openingWindowStd()],
          ),
        ),
        detailedParams: canonicalParams(walls: walls, windows: [windowStd]),
        selectedMaterialIds: ['Gạch xây', 'Sơn nội thất', 'Nhôm'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
    cases.add(
      GoldenCase(
        id: 'golden_openings_doors',
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
            pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
          ],
          details: detailsFor(
            walls: wallsNew,
            openings: [openingDoorStd()],
          ),
        ),
        detailedParams: canonicalParams(walls: walls, doors: [doorStd]),
        selectedMaterialIds: ['Gạch xây', 'Sơn nội thất', 'Nhôm'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
    cases.add(
      GoldenCase(
        id: 'golden_openings_rolling_doors',
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
            pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
          ],
          details: detailsFor(
            walls: wallsNew,
            openings: [openingRollingStd()],
          ),
        ),
        detailedParams:
            canonicalParams(walls: walls, rollingDoors: [rollingStd]),
        selectedMaterialIds: ['Gạch xây', 'Sơn nội thất', 'Nhôm'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
    final windowQty = openingMap(1.2, 1.4, 3);
    final doorQty = openingMap(0.9, 2.2, 2);
    final rollingQty = openingMap(3.0, 3.0, 2);
    cases.add(
      GoldenCase(
        id: 'golden_openings_mixed_all_quantity',
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
            pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
          ],
          details: detailsFor(
            walls: wallsNew,
            openings: [
              openingSpec(OpeningType.window, 1.2, 1.4, 3),
              openingSpec(OpeningType.door, 0.9, 2.2, 2),
              openingSpec(OpeningType.rollingDoor, 3, 3, 2),
            ],
          ),
        ),
        detailedParams: canonicalParams(
          walls: walls,
          windows: [windowQty],
          doors: [doorQty],
          rollingDoors: [rollingQty],
        ),
        selectedMaterialIds: ['Gạch xây', 'Sơn nội thất', 'Nhôm'],
        brickDimensions: brickDims,
        floors: floors1,
      ),
    );
    final mixedWalls = [
      wallMap('10', 2, wall100L, wall100H),
      wallMap('20', 2, wall200L, wall200H),
    ];
    cases.add(
      GoldenCase(
        id: 'golden_openings_mixed_walls_two_floors',
        project: buildProject(
          floors: floors2New,
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
            pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
          ],
          details: detailsFor(
            walls: [
              wallSpec(WallType.wall100, 2, wall100L, wall100H),
              wallSpec(WallType.wall200, 2, wall200L, wall200H),
            ],
            openings: [
              openingWindowStd(),
              openingDoorStd(),
              openingRollingStd(),
            ],
          ),
        ),
        detailedParams: canonicalParams(
          walls: mixedWalls,
          windows: [windowStd],
          doors: [doorStd],
          rollingDoors: [rollingStd],
        ),
        selectedMaterialIds: ['Gạch xây', 'Xi măng', 'Sơn nội thất', 'Nhôm'],
        brickDimensions: brickDims,
        floors: floors2,
      ),
    );
  }

  // ── Nhóm D: MATERIAL SELECTION (single material) ─────────────────────
  final wallForMaterial = [wallMap('10', 2, 4, 3.3)];
  final wallNewForMaterial = [wallSpec(WallType.wall100, 2, 4, 3.3)];
  const segs = foundationSegmentsStd;

  void addSingleMaterialCase({
    required String id,
    required ProjectMaterial material,
    required String legacyKey,
    List<Map<String, dynamic>>? walls,
    List<WallSpec>? wallsNew,
    List<double> foundationLengths = segs,
    List<Map<String, dynamic>> windows = const [],
    List<Map<String, dynamic>> doors = const [],
    List<Map<String, dynamic>> rollingDoors = const [],
    List<OpeningSpec> openings = const [],
    bool useFloors = true,
  }) {
    cases.add(
      GoldenCase(
        id: id,
        project: buildProject(
          materials: [material],
          details: detailsFor(
            foundationSegments: foundationLengths,
            walls: wallsNew ?? wallNewForMaterial,
            openings: openings,
          ),
        ),
        detailedParams: canonicalParams(
          walls: walls ?? wallForMaterial,
          foundationLengths: foundationLengths,
          windows: windows,
          doors: doors,
          rollingDoors: rollingDoors,
        ),
        selectedMaterialIds: [legacyKey],
        brickDimensions: brickDims,
        floors: useFloors ? floors1 : const [],
        // Production service LUÔN chạy foundation — canonical phải khớp
        // project default (strip, d16, không cột, 1 floor 10×5×3).
        foundation: foundationSpec(
          type: 'bang',
          attribute: 'can_2_ben',
          mainBarDiameter: 16,
        ),
        l1: 10,
        w1: 5,
        area1: 50,
        hTotal: 3,
        notes: 'single material $legacyKey',
      ),
    );
  }

  addSingleMaterialCase(
    id: 'golden_material_brick',
    material: pmat('brick', 'Gạch xây', 'piece', 1500),
    legacyKey: 'Gạch xây',
  );
  addSingleMaterialCase(
    id: 'golden_material_cement',
    material: pmat('cement', 'Xi măng', 'ton', 1800000),
    legacyKey: 'Xi măng',
  );
  addSingleMaterialCase(
    id: 'golden_material_sand',
    material: pmat('sand', 'Cát xây', 'm3', 300000),
    legacyKey: 'Cát xây',
  );
  addSingleMaterialCase(
    id: 'golden_material_plaster_sand',
    material: pmat('plaster_sand', 'Cát trát', 'm3', 320000),
    legacyKey: 'Cát trát',
  );
  addSingleMaterialCase(
    id: 'golden_material_interior_paint',
    material: pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
    legacyKey: 'Sơn nội thất',
    doors: [doorStd],
    openings: [openingDoorStd()],
  );
  addSingleMaterialCase(
    id: 'golden_material_steel',
    material: pmat('steel', 'Sắt thép', 'ton', 18000000),
    legacyKey: 'Thép',
  );
  addSingleMaterialCase(
    id: 'golden_material_stone',
    material: pmat('stone', 'Đá', 'm3', 350000),
    legacyKey: 'Đá',
  );
  addSingleMaterialCase(
    id: 'golden_material_concrete_sand',
    material: pmat('concrete_sand', 'Cát bê tông', 'm3', 450000),
    legacyKey: 'Bê tông',
  );
  addSingleMaterialCase(
    id: 'golden_material_aluminum_door',
    material: pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
    legacyKey: 'Nhôm',
    doors: [doorStd],
    openings: [openingDoorStd()],
  );
  addSingleMaterialCase(
    id: 'golden_material_gypsum',
    material: pmat('gypsum', 'Thạch cao', 'm2', 160000),
    legacyKey: 'Thạch cao',
  );
  addSingleMaterialCase(
    id: 'golden_material_labor',
    material: pmat('labor', 'Nhân công xây dựng', 'm2', 1350000,
        type: ProjectMaterialType.labor),
    legacyKey: 'Nhân công xây dựng',
  );
  addSingleMaterialCase(
    id: 'golden_material_plumbing_labor',
    material: pmat('plumbing_labor', 'Nhân công điện nước', 'm2', 120000,
        type: ProjectMaterialType.labor),
    legacyKey: 'Nhân công điện nước',
  );
  addSingleMaterialCase(
    id: 'golden_material_plumbing_material',
    material: pmat('plumbing_material', 'Vật tư điện nước', 'm2', 280000),
    legacyKey: 'Vật tư điện nước',
  );

  // ── Nhóm: MATERIALS KHÔNG CÓ AGGREGATED KEY ──────────────────────────
  {
    final noKeyNames = [
      pmat('tile', 'Gạch lát nền 60x60', 'm2', 150000),
      pmat('roof_tile', 'Ngói Tây', 'm2', 180000),
      pmat('metal_sheet', 'Tôn thường', 'm2', 120000),
      pmat('insulated_metal_sheet', 'Tôn xốp', 'm2', 220000),
      pmat('exterior_paint', 'Sơn ngoại thất', 'm2', 80000),
      pmat('composite_door', 'Cửa nhựa composite', 'set', 3500000),
    ];
    cases.add(
      GoldenCase(
        id: 'golden_materials_no_aggregated_key',
        project: buildProject(
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            ...noKeyNames,
          ],
          details: detailsFor(walls: wallNewForMaterial),
        ),
        detailedParams: canonicalParams(walls: wallForMaterial),
        // Fallback name cho code không có key — đúng policy mapper.
        selectedMaterialIds: [
          'Gạch xây',
          'Gạch lát nền 60x60',
          'Ngói Tây',
          'Tôn thường',
          'Tôn xốp',
          'Sơn ngoại thất',
          'Cửa nhựa composite',
        ],
        brickDimensions: brickDims,
        floors: floors1,
        notes: 'LEGACY AGGREGATED PATH LIMITATION: chỉ "Gạch xây" có quantity',
      ),
    );
  }

  // ── Nhóm: CUSTOM MATERIAL ────────────────────────────────────────────
  cases.add(
    GoldenCase(
      id: 'golden_custom_material_no_code',
      project: buildProject(
        materials: [
          customMat('Vật liệu tùy chỉnh', 'm2', 999999),
          pmat('brick', 'Gạch xây', 'piece', 1500),
        ],
        details: detailsFor(walls: wallNewForMaterial),
      ),
      detailedParams: canonicalParams(walls: wallForMaterial),
      selectedMaterialIds: ['Vật liệu tùy chỉnh', 'Gạch xây'],
      brickDimensions: brickDims,
      floors: floors1,
      notes: 'catalogCode null → fallback name (không khớp check legacy)',
    ),
  );

  // ── Nhóm: FOUNDATION ─────────────────────────────────────────────────
  final stdColumn = columnMap(0.22, 0.3, 4, 4, 16);
  final stdColumnNew = columnSpec(0.22, 0.3, 4, 4, 16);

  cases.add(
    GoldenCase(
      id: 'golden_foundation_bang_balanced_d16',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.strip,
          alignment: FoundationAlignment.balanced,
          mainBarDiameter: 16,
          columns: [stdColumnNew],
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'bang',
        attribute: 'can_2_ben',
        mainBarDiameter: 16,
        columns: [stdColumn],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );
  cases.add(
    GoldenCase(
      id: 'golden_foundation_bang_lech_1_ben_d18',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.strip,
          alignment: FoundationAlignment.offsetOneSide,
          mainBarDiameter: 18,
          columns: [columnSpec(0.22, 0.3, 4, 4, 18)],
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'bang',
        attribute: 'lech_1_ben',
        mainBarDiameter: 18,
        columns: [columnMap(0.22, 0.3, 4, 4, 18)],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );
  cases.add(
    GoldenCase(
      id: 'golden_foundation_bang_lech_2_ben_d20',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.strip,
          alignment: FoundationAlignment.offsetTwoSides,
          mainBarDiameter: 20,
          columns: [columnSpec(0.22, 0.3, 4, 4, 20)],
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'bang',
        attribute: 'lech_2_ben',
        mainBarDiameter: 20,
        columns: [columnMap(0.22, 0.3, 4, 4, 20)],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );

  // ── STEEL d14..d22 (foundation BE + cột tương ứng) ──────────────────
  for (final d in [14, 16, 18, 20, 22]) {
    cases.add(
      GoldenCase(
        id: 'golden_steel_d$d',
        project: buildProject(
          foundationStructure: foundationStructureSpec(
            type: FoundationType.raft,
            mainBarDiameter: d,
            columns: [columnSpec(0.25, 0.3, 6, 6, d)],
          ),
        ),
        detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
        selectedMaterialIds: const [],
        brickDimensions: brickDims,
        floors: floors1,
        foundation: foundationSpec(
          type: 'be',
          mainBarDiameter: d,
          columns: [columnMap(0.25, 0.3, 6, 6, d)],
        ),
        l1: 10,
        w1: 5,
        area1: 50,
        hTotal: 3,
      ),
    );
  }

  cases.add(
    GoldenCase(
      id: 'golden_foundation_coc_d22',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.isolated,
          mainBarDiameter: 22,
          columns: [columnSpec(0.25, 0.3, 3, 6, 22)],
          isolatedLength: 1.2,
          isolatedWidth: 1.2,
          isolatedHeight: 0.6,
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'coc',
        mainBarDiameter: 22,
        columns: [columnMap(0.25, 0.3, 3, 6, 22)],
        cocLength: 1.2,
        cocWidth: 1.2,
        cocHeight: 0.6,
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );
  cases.add(
    GoldenCase(
      id: 'golden_foundation_coc_pile_d16',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.pile,
          mainBarDiameter: 16,
          columns: [columnSpec(0.25, 0.3, 4, 6, 16)],
          pileCaps: [
            const PileCapSpec(length: 1.5, width: 1.5, height: 0.8),
            const PileCapSpec(length: 1.2, width: 1.2, height: 0.6),
          ],
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'coc_pile',
        mainBarDiameter: 16,
        columns: [columnMap(0.25, 0.3, 4, 6, 16)],
        pileCaps: [
          {'length': 1.5, 'width': 1.5, 'height': 0.8},
          {'length': 1.2, 'width': 1.2, 'height': 0.6},
        ],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );
  cases.add(
    GoldenCase(
      id: 'golden_foundation_two_floors_h_total',
      project: buildProject(
        floors: floors2New,
        foundationStructure: foundationStructureSpec(
          type: FoundationType.strip,
          alignment: FoundationAlignment.balanced,
          mainBarDiameter: 18,
          columns: [columnSpec(0.22, 0.3, 4, 4, 18)],
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors2,
      foundation: foundationSpec(
        type: 'bang',
        attribute: 'can_2_ben',
        mainBarDiameter: 18,
        columns: [columnMap(0.22, 0.3, 4, 4, 18)],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 5.8,
    ),
  );
  cases.add(
    GoldenCase(
      id: 'golden_foundation_no_columns',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.strip,
          alignment: FoundationAlignment.balanced,
          mainBarDiameter: 16,
          columns: const [],
        ),
      ),
      detailedParams: canonicalParams(walls: const []),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'bang',
        attribute: 'can_2_ben',
        mainBarDiameter: 16,
        columns: const [],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );
  cases.add(
    GoldenCase(
      id: 'golden_foundation_pile_no_caps',
      project: buildProject(
        foundationStructure: foundationStructureSpec(
          type: FoundationType.pile,
          mainBarDiameter: 16,
          columns: [columnSpec(0.25, 0.3, 4, 6, 16)],
          pileCaps: const [],
        ),
      ),
      detailedParams: canonicalParams(walls: const [], foundationColumns: 1),
      selectedMaterialIds: const [],
      brickDimensions: brickDims,
      floors: floors1,
      foundation: foundationSpec(
        type: 'coc_pile',
        mainBarDiameter: 16,
        columns: [columnMap(0.25, 0.3, 4, 6, 16)],
        pileCaps: const [],
      ),
      l1: 10,
      w1: 5,
      area1: 50,
      hTotal: 3,
    ),
  );

  // ── Nhóm: INTEGRATION ───────────────────────────────────────────────
  {
    final wallsA = [wallMap('10', 2, wall100L, wall100H)];
    cases.add(
      GoldenCase(
        id: 'golden_integration_case_a',
        project: buildProject(
          foundationStructure: foundationStructureSpec(
            type: FoundationType.strip,
            alignment: FoundationAlignment.balanced,
            mainBarDiameter: 16,
            columns: [stdColumnNew],
          ),
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('sand', 'Cát xây', 'm3', 300000),
            pmat('interior_paint', 'Sơn nội thất', 'm2', 65000),
          ],
          details: detailsFor(
            walls: [wallSpec(WallType.wall100, 2, wall100L, wall100H)],
            openings: [openingWindowStd(), openingDoorStd()],
          ),
        ),
        detailedParams: canonicalParams(
          walls: wallsA,
          foundationColumns: 1,
          windows: [windowStd],
          doors: [doorStd],
        ),
        selectedMaterialIds: ['Gạch xây', 'Xi măng', 'Cát xây', 'Sơn nội thất'],
        brickDimensions: brickDims,
        floors: floors1,
        foundation: foundationSpec(
          type: 'bang',
          attribute: 'can_2_ben',
          mainBarDiameter: 16,
          columns: [stdColumn],
        ),
        l1: 10,
        w1: 5,
        area1: 50,
        hTotal: 3,
      ),
    );
  }
  {
    final wallsB = [
      wallMap('10', 2, wall100L, wall100H),
      wallMap('20', 1, wall200L, wall200H),
    ];
    cases.add(
      GoldenCase(
        id: 'golden_integration_case_b',
        project: buildProject(
          floors: floors2New,
          foundationStructure: foundationStructureSpec(
            type: FoundationType.strip,
            alignment: FoundationAlignment.offsetOneSide,
            mainBarDiameter: 20,
            columns: [columnSpec(0.25, 0.3, 4, 6, 20)],
          ),
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('steel', 'Sắt thép', 'ton', 18000000),
          ],
          details: detailsFor(
            foundationSegments: segs,
            walls: [
              wallSpec(WallType.wall100, 2, wall100L, wall100H),
              wallSpec(WallType.wall200, 1, wall200L, wall200H),
            ],
            openings: [
              openingWindowStd(),
              openingRollingStd(),
            ],
          ),
        ),
        detailedParams: canonicalParams(
          walls: wallsB,
          foundationLengths: segs,
          foundationColumns: 1,
          windows: [windowStd],
          rollingDoors: [rollingStd],
        ),
        selectedMaterialIds: ['Gạch xây', 'Xi măng', 'Thép'],
        brickDimensions: brickDims,
        floors: floors2,
        foundation: foundationSpec(
          type: 'bang',
          attribute: 'lech_1_ben',
          mainBarDiameter: 20,
          columns: [columnMap(0.25, 0.3, 4, 6, 20)],
        ),
        l1: 10,
        w1: 5,
        area1: 50,
        hTotal: 5.8,
      ),
    );
  }
  {
    final wallsC = [wallMap('10', 2, wall100L, wall100H)];
    cases.add(
      GoldenCase(
        id: 'golden_integration_case_c',
        project: buildProject(
          foundationStructure: foundationStructureSpec(
            type: FoundationType.isolated,
            mainBarDiameter: 16,
            columns: [columnSpec(0.25, 0.3, 3, 6, 16)],
            isolatedLength: 1.2,
            isolatedWidth: 1.2,
            isolatedHeight: 0.6,
          ),
          materials: [
            pmat('brick', 'Gạch xây', 'piece', 1500),
            pmat('cement', 'Xi măng', 'ton', 1800000),
            pmat('steel', 'Sắt thép', 'ton', 18000000),
            pmat('aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000),
            pmat('labor', 'Nhân công xây dựng', 'm2', 1350000,
                type: ProjectMaterialType.labor),
          ],
          details: detailsFor(
            foundationSegments: segs,
            walls: [wallSpec(WallType.wall100, 2, wall100L, wall100H)],
            openings: [openingDoorStd()],
          ),
        ),
        detailedParams: canonicalParams(
          walls: wallsC,
          foundationColumns: 1,
          foundationLengths: segs,
          doors: [doorStd],
        ),
        selectedMaterialIds: [
          'Gạch xây',
          'Xi măng',
          'Thép',
          'Nhôm',
          'Nhân công xây dựng',
        ],
        brickDimensions: brickDims,
        floors: floors1,
        foundation: foundationSpec(
          type: 'coc',
          mainBarDiameter: 16,
          columns: [columnMap(0.25, 0.3, 3, 6, 16)],
          cocLength: 1.2,
          cocWidth: 1.2,
          cocHeight: 0.6,
        ),
        l1: 10,
        w1: 5,
        area1: 50,
        hTotal: 3,
      ),
    );
  }

  // ── BRICK DIMENSIONS ────────────────────────────────────────────────
  cases.add(
    GoldenCase(
      id: 'golden_brick_dimensions_runtime',
      project: buildProject(
        materials: [
          pmat('brick', 'Gạch xây', 'piece', 1500),
          pmat('cement', 'Xi măng', 'ton', 1800000),
        ],
        details: detailsFor(
          walls: [
            wallSpec(WallType.wall100, 2, 6, 3),
            wallSpec(WallType.wall200, 0, 4, 3),
          ],
        ),
      ),
      detailedParams: canonicalParams(
        walls: [
          wallMap('10', 2, 6, 3),
          wallMap('20', 0, 4, 3),
        ],
      ),
      selectedMaterialIds: ['Gạch xây', 'Xi măng'],
      brickDimensions: brickDims,
      floors: floors1,
      notes:
          'adapter phải truyền {0.2, 0.1, 0.05} (runtime legacy) — KHÔNG dùng fallback 0.22 của calculator',
    ),
  );

  return cases;
}

final goldenCases = buildGoldenCases();
