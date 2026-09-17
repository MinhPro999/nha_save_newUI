import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

/// Canonical golden case: một case có ĐỦ hai phía:
/// - [project]: input new UI (chạy qua LegacyInputMapper → calculator_core → LegacyResultMapper).
/// - canonical legacy input ([detailedParams], [selectedMaterialIds],
///   [brickDimensions], [floors], [foundation]): input CHÍNH XÁC cho legacy
///   authoritative source (được author theo contract đã xác minh ở Gate 4,
///   PHASE2_MAPPING_SPEC.md). Oracle generator dùng các field này chạy trực
///   tiếp code legacy @ e5fc8943 để sinh expected value.
class GoldenCase {
  GoldenCase({
    required this.id,
    required this.project,
    required this.detailedParams,
    required this.selectedMaterialIds,
    required this.brickDimensions,
    required this.floors,
    Map<String, dynamic>? foundation,
    double? l1,
    double? w1,
    double? area1,
    double? hTotal,
    this.notes,
  })  : foundation = foundation ?? _defaultFoundationSpec(floors),
        l1 = l1 ?? _floorField(floors, 'length', 0),
        w1 = w1 ?? _floorField(floors, 'width', 0),
        area1 = area1 ?? _floorArea(floors),
        hTotal = hTotal ?? _sumHeights(floors);

  final String id;
  final ConstructionProject project;
  final Map<String, dynamic> detailedParams;
  final List<String> selectedMaterialIds;
  final Map<String, double> brickDimensions;
  final List<Map<String, dynamic>> floors;

  /// Canonical foundation spec cho oracle (legacy side).
  /// Mặc định (khi case không chỉ định): strip d16 không cột — khớp
  /// `buildProject` default, vì production service LUÔN chạy foundation.
  final Map<String, dynamic>? foundation;

  /// l1/w1/area1/hTotal theo contract legacy (floors.first + Σ heights).
  final double l1;
  final double w1;
  final double area1;
  final double hTotal;

  final String? notes;
}

/// Project default (buildProject): strip + can_2_ben + d16, không cột.
/// Trả null khi floors rỗng (service sẽ throw — case không chạy foundation).
Map<String, dynamic>? _defaultFoundationSpec(
    List<Map<String, dynamic>> floors) {
  if (floors.isEmpty) return null;
  return <String, dynamic>{
    'foundationType': 'bang',
    'attribute': 'can_2_ben',
    'mainBarDiameter': 16,
    'columns': const [],
    'cocLength': 1.2,
    'cocWidth': 1.2,
    'cocHeight': 0.6,
    'pileCaps': const [],
  };
}

double _floorField(
    List<Map<String, dynamic>> floors, String key, double fallback) {
  if (floors.isEmpty) return fallback;
  return (floors.first[key] as num?)?.toDouble() ?? fallback;
}

double _floorArea(List<Map<String, dynamic>> floors) {
  if (floors.isEmpty) return 0;
  final length = (floors.first['length'] as num?)?.toDouble() ?? 0;
  final width = (floors.first['width'] as num?)?.toDouble() ?? 0;
  return length * width;
}

double _sumHeights(List<Map<String, dynamic>> floors) {
  return floors.fold<double>(
    0,
    (sum, floor) => sum + ((floor['height'] as num?)?.toDouble() ?? 0),
  );
}

// ═══════════════════════ HELPERS (fixtures) ═══════════════════════

const brickDims = <String, double>{'length': 0.2, 'width': 0.1, 'height': 0.05};

ProjectMaterial pmat(
  String code,
  String name,
  String unit,
  double unitPrice, {
  ProjectMaterialType type = ProjectMaterialType.material,
}) {
  return ProjectMaterial(
    selectionKey: 'sel-$code',
    catalogCode: code,
    name: name,
    unit: unit,
    unitPrice: unitPrice,
    type: type,
  );
}

ProjectMaterial customMat(String name, String unit, double unitPrice) {
  return ProjectMaterial(
    selectionKey: 'sel-custom-$name',
    catalogCode: null,
    name: name,
    unit: unit,
    unitPrice: unitPrice,
    type: ProjectMaterialType.material,
  );
}

WallSpec wallSpec(
    WallType type, int plasterSides, double length, double height) {
  return WallSpec(
    type: type,
    plasterSides: plasterSides,
    length: length,
    height: height,
  );
}

Map<String, dynamic> wallMap(
  String type,
  int plasterSides,
  double length,
  double height,
) {
  return <String, dynamic>{
    'type': type,
    'plasterSides': plasterSides,
    'length': length,
    'height': height,
    'area': length * height,
  };
}

Map<String, dynamic> openingMap(
  double width,
  double height,
  int quantity,
) {
  return <String, dynamic>{
    'width': width,
    'height': height,
    'quantity': quantity,
    'area': width * height * quantity,
  };
}

Map<String, dynamic> floorMap(
    int number, double length, double width, double height) {
  return <String, dynamic>{
    'number': number,
    'length': length,
    'width': width,
    'height': height,
    'area': length * width,
  };
}

BuildingFloor buildingFloor(
    int number, double length, double width, double height) {
  return BuildingFloor(
      number: number, length: length, width: width, height: height);
}

Map<String, dynamic> canonicalParams({
  required List<Map<String, dynamic>> walls,
  List<double> foundationLengths = const [],
  int foundationColumns = 0,
  List<Map<String, dynamic>> windows = const [],
  List<Map<String, dynamic>> doors = const [],
  List<Map<String, dynamic>> rollingDoors = const [],
  List<Map<String, dynamic>> bathrooms = const [],
  List<Map<String, dynamic>> stairs = const [],
  double gypsumCeilingArea = 0.0,
}) {
  final wallArea =
      walls.fold<double>(0, (sum, w) => sum + (w['area'] as double));
  final windowArea =
      windows.fold<double>(0, (sum, w) => sum + (w['area'] as double));
  final doorArea =
      doors.fold<double>(0, (sum, d) => sum + (d['area'] as double));
  final rollingDoorArea =
      rollingDoors.fold<double>(0, (sum, d) => sum + (d['area'] as double));
  final stairsSteps =
      stairs.fold<int>(0, (sum, s) => sum + (s['steps'] as int));
  return <String, dynamic>{
    'foundation': <String, dynamic>{
      'lengths': foundationLengths,
      'columns': foundationColumns,
    },
    'walls': <String, dynamic>{'walls': walls, 'area': wallArea},
    'doors': <String, dynamic>{
      'windows': windows,
      'doors': doors,
      'rollingDoors': rollingDoors,
      'windowArea': windowArea,
      'doorArea': doorArea,
      'rollingDoorArea': rollingDoorArea,
    },
    'others': <String, dynamic>{
      'bathrooms': bathrooms,
      'gypsumCeilingArea': gypsumCeilingArea,
      'stairs': stairs,
      'bathroomCount': bathrooms.length,
      'stairsSteps': stairsSteps,
    },
  };
}

ProjectDetails detailsFor({
  List<double> foundationSegments = const [],
  List<WallSpec> walls = const [],
  List<OpeningSpec> openings = const [],
  List<BathroomSpec> bathrooms = const [],
  List<StairSpec> stairs = const [],
}) {
  return ProjectDetails(
    foundationSegments: foundationSegments.map(FoundationSegment.new).toList(),
    walls: walls,
    openings: openings,
    bathrooms: bathrooms,
    stairs: stairs,
  );
}

OpeningSpec openingSpec(
  OpeningType type,
  double width,
  double height,
  int quantity,
) {
  return OpeningSpec(
      type: type, width: width, height: height, quantity: quantity);
}

ConstructionProject buildProject({
  List<ProjectMaterial> materials = const [],
  List<BuildingFloor> floors = const [
    BuildingFloor(number: 1, length: 10, width: 5, height: 3)
  ],
  FoundationStructureSpec foundationStructure = const FoundationStructureSpec(
    foundationType: FoundationType.strip,
    structureType: StructureType.reinforcedConcrete,
    mainBarDiameter: 16,
  ),
  ProjectDetails details = const ProjectDetails(),
}) {
  return ConstructionProject(
    id: 'golden',
    name: 'Nhà golden',
    location: 'Hà Nội',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    floors: floors,
    roof: const RoofSpec(type: RoofType.flat, length: 10, width: 5, height: 0),
    foundationStructure: foundationStructure,
    materials: materials,
    details: details,
  );
}

Map<String, dynamic> foundationSpec({
  required String type,
  String attribute = 'can_2_ben',
  int mainBarDiameter = 16,
  List<Map<String, dynamic>> columns = const [],
  double cocLength = 1.2,
  double cocWidth = 1.2,
  double cocHeight = 0.6,
  List<Map<String, dynamic>> pileCaps = const [],
}) {
  return <String, dynamic>{
    'foundationType': type,
    'attribute': attribute,
    'mainBarDiameter': mainBarDiameter,
    'columns': columns,
    'cocLength': cocLength,
    'cocWidth': cocWidth,
    'cocHeight': cocHeight,
    'pileCaps': pileCaps,
  };
}

Map<String, dynamic> columnMap(
  double width,
  double thickness,
  int quantity,
  int mainBarsCount,
  int mainBarDiameter,
) {
  return <String, dynamic>{
    'width': width,
    'thickness': thickness,
    'quantity': quantity,
    'mainBarsCount': mainBarsCount,
    'mainBarDiameter': mainBarDiameter,
  };
}

ColumnSpec columnSpec(
  double width,
  double thickness,
  int quantity,
  int mainBarsCount,
  int mainBarDiameter,
) {
  return ColumnSpec(
    width: width,
    thickness: thickness,
    quantity: quantity,
    mainBarsCount: mainBarsCount,
    mainBarDiameter: mainBarDiameter,
  );
}

FoundationStructureSpec foundationStructureSpec({
  required FoundationType type,
  FoundationAlignment? alignment,
  int mainBarDiameter = 16,
  List<ColumnSpec> columns = const [],
  double? isolatedLength,
  double? isolatedWidth,
  double? isolatedHeight,
  List<PileCapSpec> pileCaps = const [],
}) {
  return FoundationStructureSpec(
    foundationType: type,
    structureType: StructureType.reinforcedConcrete,
    alignment: alignment,
    mainBarDiameter: mainBarDiameter,
    columns: columns,
    isolatedLength: isolatedLength,
    isolatedWidth: isolatedWidth,
    isolatedHeight: isolatedHeight,
    pileCaps: pileCaps,
  );
}

// ═══════════════════════ FIXTURES CHUNG ═══════════════════════

// Tường chuẩn: wall100 4×3.3 (area 13.2); wall200 5×3.3 (area 16.5).
const wall100L = 4.0;
const wall100H = 3.3;
const wall200L = 5.0;
const wall200H = 3.3;

// Móng chuẩn: 2 đoạn 12 + 8 = 20 m.
const foundationSegmentsStd = <double>[12, 8];

// Openings chuẩn: window 1.2×1.4×2; door 0.9×2.2×1; rolling 3×3×1.
// Dùng openingMap để area được TÍNH y hệt mapper (tránh lệch floating point).
final windowStd = openingMap(1.2, 1.4, 2);
final doorStd = openingMap(0.9, 2.2, 1);
final rollingStd = openingMap(3.0, 3.0, 1);

OpeningSpec openingWindowStd() => openingSpec(OpeningType.window, 1.2, 1.4, 2);
OpeningSpec openingDoorStd() => openingSpec(OpeningType.door, 0.9, 2.2, 1);
OpeningSpec openingRollingStd() =>
    openingSpec(OpeningType.rollingDoor, 3, 3, 1);

const floors1 = <Map<String, dynamic>>[
  {'number': 1, 'length': 10, 'width': 5, 'height': 3, 'area': 50},
];
const floors1New = [BuildingFloor(number: 1, length: 10, width: 5, height: 3)];
const floors2 = <Map<String, dynamic>>[
  {'number': 1, 'length': 10, 'width': 5, 'height': 3, 'area': 50},
  {'number': 2, 'length': 8, 'width': 6, 'height': 2.8, 'area': 48},
];
const floors2New = [
  BuildingFloor(number: 1, length: 10, width: 5, height: 3),
  BuildingFloor(number: 2, length: 8, width: 6, height: 2.8),
];
