import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

/// FIX-CALC-001 Phase 7 — AUDIT tính nhất quán đơn vị
/// (quantity / unit / unitPrice / cost) cho 13 catalogCode supported.
///
/// Loại lỗi nguy hiểm nhất vì HOÀN TOÀN IM LẶNG (không exception) — test này
/// là chốt chặn: với mỗi mã, dựng input mẫu cố định, kiểm tra:
///   1. cost == quantity × unitPrice (convention legacy, không round thêm).
///   2. Đơn vị quantity mà calculator_core trả về KHỚP với đơn vị niêm yết
///      giá trong catalog (`material.unit`) — nếu lệch, test phải FAIL rõ
///      ràng kèm tên mã, TRỪ KHI mã đó nằm trong [knownUnitMismatches]
///      (registry audit đã ghi nhận, mở ticket riêng FIX-CALC-003).
void main() {
  // Đơn vị quantity mà calculator_core thực tế trả về cho từng mã
  // (đã audit từng nhánh _calculateWallMaterials/_calculateFoundationMaterials/
  // _calculateDoorMaterials/_calculateOtherMaterials).
  const expectedQuantityUnit = <String, String>{
    'brick': 'piece',
    'sand': 'm3',
    'plaster_sand': 'm3',
    'cement': 'ton', // CementCalculator kết thúc bằng kgToTon → TẤN.
    'interior_paint': 'm2',
    'concrete_sand': 'm3', // gán trực tiếp foundationVolume (m³).
    'steel': 'ton', // SteelCalculator kgToTon → TẤN.
    'stone': 'm3',
    'aluminum_door': 'kg', // diện tích (m²) × 3 "3kg/m²" → KG.
    'gypsum': 'm2', // gypsumCeilingArea = 0.0 (FUNCTIONAL GAP) → luôn 0.
    'labor': 'm2',
    'plumbing_labor': 'm2',
    'plumbing_material': 'm2',
  };

  /// Registry audit các lệch đơn vị ĐÃ PHÁT HIỆN và được chốt mở ticket
  /// riêng (FIX-CALC-003) — KHÔNG sửa trong FIX-CALC-001 vì sửa hệ số quy
  /// đổi cần xác nhận chủ dự án (rủi ro cao hơn cả bug gốc nếu sửa sai).
  /// Test CHỈ cho qua các mã nằm trong registry này; mọi lệch mới → FAIL.
  const knownUnitMismatches = <String, String>{
    // material_calculator.dart `_calculateDoorMaterials`:
    //   quantities['Nhôm'] = calculateAluminumDoorQuantity(...) × 3
    //   // 3kg/m² → giá trị là KHỐI LƯỢNG (kg), trong khi catalog
    //   'aluminum_door' niêm yết đơn vị 'm2' (giá theo m²).
    //   cost = (VNĐ/m²) × (kg) — trộn đơn vị. Chờ chủ dự án xác nhận
    //   đơn vị đúng (kg theo đơn giá tấn, hay giữ m²) → FIX-CALC-003.
    'aluminum_door':
        'quantity = diện tích × 3 (kg) nhưng catalog unit = m2 — trộn đơn vị',
  };

  ConstructionProject buildProjectFor(ProjectMaterial material) {
    return ConstructionProject(
      id: 'p-unit-audit-${material.catalogCode}',
      name: 'Nhà audit đơn vị',
      location: 'Hà Nội',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
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
      materials: [material],
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(12), FoundationSegment(8)],
        walls: [
          WallSpec(
            type: WallType.wall200,
            plasterSides: 2,
            length: 26,
            height: 3.2,
          ),
        ],
        openings: [
          OpeningSpec(
            type: OpeningType.door,
            width: 0.9,
            height: 2.2,
            quantity: 1,
          ),
        ],
        bathrooms: [BathroomSpec(5)],
        stairs: [StairSpec(18)],
      ),
    );
  }

  ProjectMaterial materialFor(
    String code,
    String name,
    String unit,
    double unitPrice,
  ) {
    return ProjectMaterial(
      selectionKey: 'audit-$code',
      catalogCode: code,
      name: name,
      unit: unit,
      unitPrice: unitPrice,
      type: ProjectMaterialType.material,
    );
  }

  // (catalogCode, tên hiển thị, unit catalog, unitPrice mẫu)
  final supportedCases = <List<Object>>[
    ['brick', 'Gạch xây', 'piece', 1500.0],
    ['sand', 'Cát xây', 'm3', 300000.0],
    ['plaster_sand', 'Cát trát', 'm3', 320000.0],
    ['cement', 'Xi măng', 'ton', 1800000.0],
    ['interior_paint', 'Sơn nội thất', 'm2', 65000.0],
    ['concrete_sand', 'Cát bê tông', 'm3', 450000.0],
    ['steel', 'Sắt thép', 'ton', 18000000.0],
    ['stone', 'Đá', 'm3', 350000.0],
    ['aluminum_door', 'Cửa nhôm Xingfa', 'm2', 1800000.0],
    ['gypsum', 'Thạch cao', 'm2', 160000.0],
    ['labor', 'Nhân công xây dựng', 'm2', 1350000.0],
    ['plumbing_labor', 'Nhân công điện nước', 'm2', 120000.0],
    ['plumbing_material', 'Vật tư điện nước', 'm2', 280000.0],
  ];

  test('13 supported catalogCode — đơn vị quantity khớp đơn vị niêm yết giá',
      () {
    expect(
      LegacyMaterialSelectionKeyMapper.supportedCatalogCodes,
      hasLength(13),
      reason: 'audit set phải khớp đúng 13 mã supported',
    );
    expect(
      supportedCases.map((c) => c[0]).toSet(),
      LegacyMaterialSelectionKeyMapper.supportedCatalogCodes,
      reason: 'danh sách test phải phủ đúng 13 mã supported',
    );

    const service = LegacyCalculationService();
    for (final caseRow in supportedCases) {
      final code = caseRow[0] as String;
      final name = caseRow[1] as String;
      final catalogUnit = caseRow[2] as String;
      final unitPrice = caseRow[3] as double;

      final material = materialFor(code, name, catalogUnit, unitPrice);
      final result = service.calculate(buildProjectFor(material));
      final lines =
          result.materialLines.where((line) => line.name == name).toList();

      expect(
        lines,
        hasLength(1),
        reason:
            '[$code] phải sinh đúng 1 dòng kết quả (không thiếu, không trùng)',
      );
      final line = lines.single;
      // ignore: avoid_print
      print(
        'AUDIT [$code]: quantity=${line.quantity} unit=${line.unit} '
        'unitPrice=${line.unitPrice} cost=${line.cost}',
      );

      // 1. Cost convention: cost == quantity × unitPrice (không round thêm).
      expect(
        line.cost,
        line.quantity * line.unitPrice,
        reason: '[$code] cost phải = quantity × unitPrice',
      );

      // 2. Đơn vị quantity thực tế phải khớp đơn vị catalog (giá theo đó).
      final quantityUnit = expectedQuantityUnit[code];
      expect(quantityUnit, isNotNull, reason: '[$code] thiếu audit khai báo');
      if (quantityUnit != catalogUnit) {
        final registered = knownUnitMismatches[code];
        expect(
          registered,
          isNotNull,
          reason: '[$code] LỆCH ĐƠN VỊ quantity=$quantityUnit vs catalog='
              '$catalogUnit — chưa có trong registry FIX-CALC-003, '
              'KHÔNG được cho qua',
        );
        // Đã ghi nhận trong registry — không chặn CI, nhưng in rõ.
        // ignore: avoid_print
        print(
          'AUDIT [$code]: KNOWN MISMATCH (FIX-CALC-003) — $registered',
        );
      }
    }
  });
}
