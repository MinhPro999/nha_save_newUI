import 'package:flutter_core_project/calculator_core/models/project/foundation_structure_model.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/default_wall_calculator.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/wall_dependency_helper.dart';

/// Đầu vào đã map cho `MaterialCalculator.calculateMaterialsFromDetailedParams`.
class LegacyMaterialInput {
  const LegacyMaterialInput({
    required this.detailedParams,
    required this.selectedMaterialIds,
    required this.brickDimensions,
    required this.floors,
  });

  final Map<String, dynamic> detailedParams;
  final List<String> selectedMaterialIds;
  final Map<String, double> brickDimensions;
  final List<Map<String, dynamic>> floors;
}

/// Đầu vào đã map cho `FoundationStructureCalculator.calculate`.
class LegacyFoundationInput {
  const LegacyFoundationInput({
    required this.foundationData,
    required this.l1,
    required this.w1,
    required this.area1,
    required this.hTotal,
  });

  final FoundationStructureData foundationData;
  final double l1;
  final double w1;
  final double area1;
  final double hTotal;
}

/// Input boundary: new UI/domain models → legacy calculation input structures.
///
/// Mọi mapping đã xác minh source-level (PHASE2_MAPPING_SPEC.md). Không map enum
/// bằng `.index`; không sửa calculator_core.
class LegacyInputMapper {
  LegacyInputMapper._();

  /// Kích thước gạch hiệu quả của legacy app runtime:
  /// `MaterialProvider.getBrickDimensions()` trả về default của class `Brick`
  /// trong legacy (`lib/models/brick.dart`: 0.2 / 0.1 / 0.05) — khớp với
  /// default catalog của new UI. Adapter luôn truyền tường minh giá trị này
  /// (legacy chưa bao giờ để tham số null ở wizard flow).
  static const Map<String, double> defaultBrickDimensions = {
    'length': 0.2,
    'width': 0.1,
    'height': 0.05,
  };

  /// New UI project → input cho `MaterialCalculator.calculateMaterialsFromDetailedParams`.
  ///
  /// [brickDimensions]: override nếu có (vd lấy từ material library có kích
  /// thước viên); mặc định [defaultBrickDimensions].
  static LegacyMaterialInput mapMaterialInput(
    ConstructionProject project, {
    Map<String, double>? brickDimensions,
  }) {
    final details = project.details;

    // ── Walls: ưu tiên WallSpec thật, fallback Default Wall ──────────
    // FIX-CALC-001 Phase 2:
    // - Có >= 1 item hợp lệ (length>0 && height>0) → dùng ĐÚNG VÀ CHỈ các
    //   item hợp lệ đó, KHÔNG cộng thêm Default Wall (tránh double-count).
    // - Không có item hợp lệ nào VÀ có vật liệu phụ thuộc tường được chọn
    //   → Default Wall Calculator (Phase 1).
    //   Điều kiện "có vật liệu phụ thuộc tường" giữ nguyên canonical input
    //   của golden cases (foundation-only có selectedMaterialIds rỗng →
    //   walls vẫn là list rỗng như legacy) — kết quả golden KHÔNG đổi.
    final explicitWalls = details.walls
        .where((wall) => wall.length > 0 && wall.height > 0)
        .toList();

    final walls = explicitWalls.isNotEmpty
        ? explicitWalls
            .map((wall) => <String, dynamic>{
                  'type': mapWallType(wall.type),
                  'plasterSides': wall.plasterSides,
                  'length': wall.length,
                  'height': wall.height,
                  'area': wall.area,
                  // Lưu ý: KHÔNG thêm key mới vào entry explicit — golden
                  // test deep-compare detailedParams theo shape legacy.
                })
            .toList()
        : WallDependencyHelper.hasWallDependentMaterial(project)
            ? DefaultWallCalculator.buildDefaultWallEntries(
                floors: project.floors,
              )
            : <Map<String, dynamic>>[];
    final totalWallArea =
        walls.fold<double>(0, (sum, wall) => sum + (wall['area'] as double));

    final windows = <Map<String, dynamic>>[];
    final doors = <Map<String, dynamic>>[];
    final rollingDoors = <Map<String, dynamic>>[];
    for (final opening in details.openings) {
      final map = <String, dynamic>{
        'width': opening.width,
        'height': opening.height,
        'quantity': opening.quantity,
        'area': opening.area,
      };
      switch (opening.type) {
        case OpeningType.window:
          windows.add(map);
        case OpeningType.door:
          doors.add(map);
        case OpeningType.rollingDoor:
          rollingDoors.add(map);
      }
    }

    final bathrooms = details.bathrooms
        .map((bathroom) => <String, dynamic>{'area': bathroom.area})
        .toList();
    final stairs = details.stairs
        .map((stair) => <String, dynamic>{'steps': stair.steps})
        .toList();
    final stairsSteps =
        details.stairs.fold<int>(0, (sum, stair) => sum + stair.steps);

    final detailedParams = <String, dynamic>{
      'foundation': <String, dynamic>{
        'lengths': details.foundationSegments
            .map((segment) => segment.length)
            .toList(),
        'columns': project.foundationStructure.columns.length,
      },
      'walls': <String, dynamic>{
        'walls': walls,
        'area': totalWallArea,
      },
      'doors': <String, dynamic>{
        'windows': windows,
        'doors': doors,
        'rollingDoors': rollingDoors,
        'windowArea': windows.fold<double>(
          0,
          (sum, window) => sum + (window['area'] as double),
        ),
        'doorArea': doors.fold<double>(
          0,
          (sum, door) => sum + (door['area'] as double),
        ),
        'rollingDoorArea': rollingDoors.fold<double>(
          0,
          (sum, rollingDoor) => sum + (rollingDoor['area'] as double),
        ),
      },
      'others': <String, dynamic>{
        'bathrooms': bathrooms,
        // FUNCTIONAL GAP / NEEDS_REVIEW — new UI chưa có input diện tích trần
        // thạch cao → giữ nguyên default legacy 0.0; quantity 'Thạch cao' có
        // thể = 0 cho đến khi bổ sung UI field. (PHASE2_MAPPING_SPEC.md mục 7)
        'gypsumCeilingArea': 0.0,
        'stairs': stairs,
        'bathroomCount': bathrooms.length,
        'stairsSteps': stairsSteps,
      },
    };

    // Material selection: catalogCode → legacy selection key (boundary ổn định,
    // không dùng name làm identity calculation khi có catalogCode).
    // Ví dụ: catalogCode 'steel' → 'Thép' (legacy check) dù name hiển thị là
    // 'Sắt thép' — quantity thép không bị mất. Xem LegacyMaterialSelectionKeyMapper.
    final selectedMaterialIds = project.materials
        .map(
          (material) => LegacyMaterialSelectionKeyMapper.selectionIdFor(
            catalogCode: material.catalogCode,
            name: material.name,
          ),
        )
        .toList();

    // Legacy Floor.toMap() luôn kèm 'area' — calculateTotalFloorArea chỉ đọc 'area'.
    final floors = project.floors.map((floor) {
      return <String, dynamic>{
        'number': floor.number,
        'length': floor.length,
        'width': floor.width,
        'height': floor.height,
        'area': floor.area,
      };
    }).toList();

    return LegacyMaterialInput(
      detailedParams: detailedParams,
      selectedMaterialIds: selectedMaterialIds,
      brickDimensions: brickDimensions ?? defaultBrickDimensions,
      floors: floors,
    );
  }

  /// New UI project → input cho `FoundationStructureCalculator.calculate`.
  ///
  /// Lấy tầng đầu tiên (floors.first) như legacy step3 (`draftProject.floors.first`).
  static LegacyFoundationInput mapFoundationInput(ConstructionProject project) {
    final foundation = project.foundationStructure;
    if (project.floors.isEmpty) {
      // Mirror validation legacy step3: "Không tìm thấy thông tin tầng".
      throw ArgumentError(
        'Không tìm thấy thông tin tầng (floors rỗng) — legacy yêu cầu floors.first',
      );
    }
    final floor1 = project.floors.first;

    final foundationData = FoundationStructureData(
      foundationType: mapFoundationType(foundation.foundationType),
      columns: foundation.columns.map(mapColumnInfo).toList(),
      bangInfo: foundation.foundationType == FoundationType.strip
          ? FoundationBangInfo(
              attribute: mapFoundationAlignment(foundation.alignment),
              mainBarDiameter: mapSteelDiameter(foundation.mainBarDiameter),
            )
          : null,
      beInfo: foundation.foundationType == FoundationType.raft
          ? FoundationBeInfo(
              mainBarDiameter: mapSteelDiameter(foundation.mainBarDiameter),
            )
          : null,
      cocInfo: foundation.foundationType == FoundationType.isolated
          ? FoundationCocInfo(
              length: foundation.isolatedLength ?? 0.0,
              width: foundation.isolatedWidth ?? 0.0,
              height: foundation.isolatedHeight ?? 0.0,
              mainBarDiameter: mapSteelDiameter(foundation.mainBarDiameter),
            )
          : null,
      cocPileInfo: foundation.foundationType == FoundationType.pile &&
              foundation.pileCaps.isNotEmpty
          ? FoundationCocPileInfo(
              pileCaps: foundation.pileCaps.map(mapPileCapInfo).toList(),
              mainBarDiameter: mapSteelDiameter(foundation.mainBarDiameter),
            )
          : null,
    );

    return LegacyFoundationInput(
      foundationData: foundationData,
      l1: floor1.length,
      w1: floor1.width,
      area1: floor1.area,
      hTotal: project.floors.fold(0, (sum, floor) => sum + floor.height),
    );
  }

  // ============================== ENUM MAPS ==============================
  // Tất cả mapping đã xác minh semantic từ legacy UI labels — KHÔNG dùng .index.

  static FoundationTypeNew? mapFoundationType(FoundationType? type) {
    switch (type) {
      case FoundationType.strip:
        return FoundationTypeNew.bang;
      case FoundationType.raft:
        return FoundationTypeNew.be;
      case FoundationType.isolated:
        return FoundationTypeNew.coc;
      case FoundationType.pile:
        return FoundationTypeNew.coc_pile;
      case null:
        return null;
    }
  }

  static FoundationBangAttribute mapFoundationAlignment(
    FoundationAlignment? alignment,
  ) {
    switch (alignment) {
      case FoundationAlignment.balanced:
        return FoundationBangAttribute.can_2_ben;
      case FoundationAlignment.offsetOneSide:
        return FoundationBangAttribute.lech_1_ben;
      case FoundationAlignment.offsetTwoSides:
        return FoundationBangAttribute.lech_2_ben;
      case null:
        // Legacy UI default khi tạo bangInfo.
        return FoundationBangAttribute.can_2_ben;
    }
  }

  /// Map theo giá trị mm (enum `value`), KHÔNG theo `.index`.
  ///
  /// Policy (PHASE2_MAPPING_SPEC.md mục 3.3):
  /// - null/missing → `d16` (default legacy UI, evidence step3).
  /// - hợp lệ {14,16,18,20,22} → map theo value.
  /// - giá trị KHÔNG hợp lệ → ném [ArgumentError] — KHÔNG silent-map sang d16.
  static SteelDiameter mapSteelDiameter(int? millimeters) {
    if (millimeters == null) return SteelDiameter.d16;
    for (final diameter in SteelDiameter.values) {
      if (diameter.value == millimeters) return diameter;
    }
    throw ArgumentError(
      'Đường kính thép $millimeters mm không hợp lệ '
      '(hỗ trợ 14, 16, 18, 20, 22)',
    );
  }

  static String mapWallType(WallType type) {
    switch (type) {
      case WallType.wall100:
        return '10';
      case WallType.wall200:
        return '20';
    }
  }

  // ============================== STRUCT MAPS ==============================

  static ColumnInfo mapColumnInfo(ColumnSpec column) {
    return ColumnInfo(
      width: column.width,
      thickness: column.thickness,
      quantity: column.quantity,
      mainBarsCount: column.mainBarsCount,
      mainBarDiameter: mapSteelDiameter(column.mainBarDiameter),
    );
  }

  static FoundationPileCapInfo mapPileCapInfo(PileCapSpec pileCap) {
    return FoundationPileCapInfo(
      width: pileCap.width,
      length: pileCap.length,
      height: pileCap.height,
    );
  }
}
