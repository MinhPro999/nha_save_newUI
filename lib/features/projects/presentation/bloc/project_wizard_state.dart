import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

class ProjectWizardState extends Equatable {
  const ProjectWizardState({
    this.currentStep = 0,
    this.name = '',
    this.location = '',
    this.provinceId,
    this.provinceName,
    this.districtId,
    this.districtName,
    this.imagePath,
    this.floors = const [
      BuildingFloor(number: 1, length: 0, width: 0, height: 0),
    ],
    this.roof = const RoofSpec(
      type: RoofType.flat,
      length: 0,
      width: 0,
      height: 0,
    ),
    this.foundationType,
    this.structureType,
    this.alignment,
    this.mainBarDiameter = 16,
    this.isolatedLength,
    this.isolatedWidth,
    this.isolatedHeight,
    this.columns = const [],
    this.pileCaps = const [],
    this.materials = const [],
    this.details = const ProjectDetails(),
    this.showValidation = false,
  });

  factory ProjectWizardState.fromProject(ConstructionProject project) {
    final foundation = project.foundationStructure;
    return ProjectWizardState(
      name: project.name,
      location: project.location,
      provinceId: project.provinceId,
      provinceName: project.provinceName,
      districtId: project.districtId,
      districtName: project.districtName,
      imagePath: project.imagePath,
      floors: project.floors,
      roof: project.roof,
      foundationType: foundation.foundationType,
      structureType: foundation.structureType,
      alignment: foundation.alignment,
      mainBarDiameter: foundation.mainBarDiameter,
      isolatedLength: foundation.isolatedLength,
      isolatedWidth: foundation.isolatedWidth,
      isolatedHeight: foundation.isolatedHeight,
      columns: foundation.columns,
      pileCaps: foundation.pileCaps,
      materials: project.materials,
      details: project.details,
    );
  }

  static const stepCount = 5;

  final int currentStep;
  final String name;
  final String location;
  final String? provinceId;
  final String? provinceName;
  final String? districtId;
  final String? districtName;
  final String? imagePath;
  final List<BuildingFloor> floors;
  final RoofSpec roof;
  final FoundationType? foundationType;
  final StructureType? structureType;
  final FoundationAlignment? alignment;
  final int mainBarDiameter;
  final double? isolatedLength;
  final double? isolatedWidth;
  final double? isolatedHeight;
  final List<ColumnSpec> columns;
  final List<PileCapSpec> pileCaps;
  final List<ProjectMaterial> materials;
  final ProjectDetails details;
  final bool showValidation;

  double get progress => (currentStep + 1) / stepCount;

  bool isStepValid(int step) {
    switch (step) {
      case 0:
        return name.trim().isNotEmpty &&
            location.trim().isNotEmpty &&
            (provinceId == null || districtId != null);
      case 1:
        return floors.isNotEmpty &&
            floors.every(
              (floor) =>
                  floor.length > 0 && floor.width > 0 && floor.height > 0,
            ) &&
            roof.length > 0 &&
            roof.width > 0 &&
            roof.height >= 0;
      case 2:
        if (foundationType == null ||
            structureType == null ||
            columns.isEmpty ||
            !columns.every(
              (column) =>
                  column.width > 0 &&
                  column.thickness > 0 &&
                  column.quantity > 0 &&
                  column.mainBarsCount > 0 &&
                  column.mainBarDiameter > 0,
            )) {
          return false;
        }
        switch (foundationType!) {
          case FoundationType.strip:
            return alignment != null;
          case FoundationType.raft:
            return mainBarDiameter > 0;
          case FoundationType.isolated:
            return (isolatedLength ?? 0) > 0 &&
                (isolatedWidth ?? 0) > 0 &&
                (isolatedHeight ?? 0) > 0;
          case FoundationType.pile:
            return pileCaps.isNotEmpty &&
                pileCaps.every(
                  (cap) => cap.length > 0 && cap.width > 0 && cap.height > 0,
                );
        }
      case 3:
        return materials.isNotEmpty;
      case 4:
        return details.isNotEmpty &&
            details.foundationSegments.every((item) => item.length > 0) &&
            // FIX-CALC-001 Phase 3 — KHÔNG bắt buộc walls.isNotEmpty.
            // Không nhập tường = hợp lệ: DefaultWallCalculator (tầng tính
            // toán, Phase 1/2) sẽ ước lượng từ kích thước tầng. `every(...)`
            // trên list rỗng trả true (vacuous truth) — đây là CHỦ ĐÍCH,
            // không phải bug. KHÔNG sửa thành `walls.isNotEmpty &&` —
            // chỉ reject khi người dùng ĐÃ THÊM dòng tường nhưng để
            // trống/sai số (length/height <= 0 trên item đã tồn tại).
            details.walls.every(
              (item) => item.length > 0 && item.height > 0,
            ) &&
            details.openings.every(
              (item) => item.width > 0 && item.height > 0 && item.quantity > 0,
            ) &&
            details.bathrooms.every((item) => item.area > 0) &&
            details.stairs.every((item) => item.steps > 0);
      default:
        return false;
    }
  }

  bool get canComplete =>
      List.generate(stepCount, isStepValid).every((isValid) => isValid);

  ProjectWizardState copyWith({
    int? currentStep,
    String? name,
    String? location,
    String? provinceId,
    String? provinceName,
    String? districtId,
    String? districtName,
    bool clearDistrict = false,
    String? imagePath,
    bool clearImage = false,
    List<BuildingFloor>? floors,
    RoofSpec? roof,
    FoundationType? foundationType,
    StructureType? structureType,
    FoundationAlignment? alignment,
    bool clearAlignment = false,
    int? mainBarDiameter,
    double? isolatedLength,
    double? isolatedWidth,
    double? isolatedHeight,
    bool clearIsolatedDimensions = false,
    List<ColumnSpec>? columns,
    List<PileCapSpec>? pileCaps,
    List<ProjectMaterial>? materials,
    ProjectDetails? details,
    bool? showValidation,
  }) {
    return ProjectWizardState(
      currentStep: currentStep ?? this.currentStep,
      name: name ?? this.name,
      location: location ?? this.location,
      provinceId: provinceId ?? this.provinceId,
      provinceName: provinceName ?? this.provinceName,
      districtId: clearDistrict ? null : districtId ?? this.districtId,
      districtName: clearDistrict ? null : districtName ?? this.districtName,
      imagePath: clearImage ? null : imagePath ?? this.imagePath,
      floors: floors ?? this.floors,
      roof: roof ?? this.roof,
      foundationType: foundationType ?? this.foundationType,
      structureType: structureType ?? this.structureType,
      alignment: clearAlignment ? null : alignment ?? this.alignment,
      mainBarDiameter: mainBarDiameter ?? this.mainBarDiameter,
      isolatedLength: clearIsolatedDimensions
          ? null
          : isolatedLength ?? this.isolatedLength,
      isolatedWidth:
          clearIsolatedDimensions ? null : isolatedWidth ?? this.isolatedWidth,
      isolatedHeight: clearIsolatedDimensions
          ? null
          : isolatedHeight ?? this.isolatedHeight,
      columns: columns ?? this.columns,
      pileCaps: pileCaps ?? this.pileCaps,
      materials: materials ?? this.materials,
      details: details ?? this.details,
      showValidation: showValidation ?? this.showValidation,
    );
  }

  @override
  List<Object?> get props => [
        currentStep,
        name,
        location,
        provinceId,
        provinceName,
        districtId,
        districtName,
        imagePath,
        floors,
        roof,
        foundationType,
        structureType,
        alignment,
        mainBarDiameter,
        isolatedLength,
        isolatedWidth,
        isolatedHeight,
        columns,
        pileCaps,
        materials,
        details,
        showValidation,
      ];
}
