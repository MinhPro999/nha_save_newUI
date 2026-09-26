import 'package:flutter_core_project/core/data/vietnam_districts.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/core/data/vietnam_provinces.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProjectWizardCubit cubit;

  setUp(() => cubit = ProjectWizardCubit());
  tearDown(() => cubit.close());

  test('province catalog contains all current provincial-level units', () {
    expect(vietnamProvinces, hasLength(34));
    expect(
      vietnamProvinces.map((province) => province.id).toSet(),
      hasLength(34),
    );
    expect(
      vietnamProvinces.where((province) => province.isMunicipality),
      hasLength(6),
    );
  });

  test('district catalog maps legacy districts to current provinces', () async {
    final districts = await VietnamDistrictCatalog.forProvince(
      'ho_chi_minh_city',
    );

    expect(districts, isNotEmpty);
    expect(
      districts.any((district) => district.name == 'Thành phố Thủ Đức'),
      isTrue,
    );
    expect(
      districts.map((district) => district.legacyProvinceName).toSet(),
      containsAll([
        'Thành phố Hồ Chí Minh',
        'Tỉnh Bình Dương',
        'Tỉnh Bà Rịa - Vũng Tàu',
      ]),
    );
  });

  test('wizard enforces the five business validation steps', () {
    expect(cubit.next(), isFalse);
    expect(cubit.state.showValidation, isTrue);

    cubit.updateBasicInfo(name: 'Nhà phố mới', location: 'Đà Nẵng');
    expect(cubit.next(), isTrue);
    expect(cubit.state.currentStep, 1);

    cubit.updateFloor(
      0,
      const BuildingFloor(number: 1, length: 10, width: 5, height: 3.3),
    );
    cubit.updateRoof(
      const RoofSpec(type: RoofType.flat, length: 10, width: 5, height: 0.3),
    );
    expect(cubit.next(), isTrue);

    cubit.selectFoundationType(FoundationType.strip);
    cubit.selectStructureType(StructureType.reinforcedConcrete);
    expect(cubit.next(), isTrue);

    cubit.toggleMaterial(
      const ProjectMaterial(
        selectionKey: 'catalog:brick',
        catalogCode: 'brick',
        name: 'Gạch xây',
        unit: 'piece',
        unitPrice: 0,
        type: ProjectMaterialType.material,
      ),
    );
    expect(cubit.next(), isTrue);

    cubit.updateDetails(
      const ProjectDetails(foundationSegments: [FoundationSegment(20)]),
    );
    expect(cubit.state.canComplete, isTrue);

    final project = cubit.buildProject();
    expect(project.name, 'Nhà phố mới');
    expect(project.floors.single.area, 50);
    expect(project.materials.single.catalogCode, 'brick');
    expect(project.foundationStructure.columns, isNotEmpty);
  });

  test('edit wizard loads all project data and preserves project identity', () {
    final createdAt = DateTime(2026, 8, 1);
    final source = ConstructionProject(
      id: 'existing-project',
      name: 'Nhà phố hiện tại',
      location: 'Quận Ba Đình, Thành phố Hà Nội',
      provinceId: 'ha_noi',
      provinceName: 'Thành phố Hà Nội',
      districtId: '1',
      districtName: 'Quận Ba Đình',
      imagePath: '/tmp/project.jpg',
      createdAt: createdAt,
      updatedAt: createdAt,
      floors: const [
        BuildingFloor(number: 1, length: 12, width: 6, height: 3.4),
      ],
      roof: const RoofSpec(
        type: RoofType.tile,
        length: 12,
        width: 6,
        height: 2,
      ),
      foundationStructure: const FoundationStructureSpec(
        foundationType: FoundationType.strip,
        structureType: StructureType.reinforcedConcrete,
        alignment: FoundationAlignment.balanced,
        columns: [
          ColumnSpec(
            width: 0.2,
            thickness: 0.2,
            quantity: 8,
            mainBarsCount: 4,
            mainBarDiameter: 16,
          ),
        ],
      ),
      materials: const [
        ProjectMaterial(
          selectionKey: 'catalog:brick',
          name: 'Gạch xây',
          unit: 'piece',
          unitPrice: 1500,
          type: ProjectMaterialType.material,
        ),
      ],
      details: const ProjectDetails(
        foundationSegments: [FoundationSegment(24)],
      ),
    );
    final editingCubit = ProjectWizardCubit(initialProject: source);
    addTearDown(editingCubit.close);

    expect(editingCubit.isEditing, isTrue);
    expect(editingCubit.state.floors, source.floors);
    expect(editingCubit.state.materials, source.materials);
    expect(editingCubit.state.provinceId, source.provinceId);
    expect(editingCubit.state.districtId, source.districtId);
    expect(editingCubit.state.canComplete, isTrue);

    editingCubit.updateBasicInfo(name: 'Nhà phố đã sửa');
    final updated = editingCubit.buildProject();

    expect(updated.id, source.id);
    expect(updated.createdAt, source.createdAt);
    expect(updated.name, 'Nhà phố đã sửa');
    expect(updated.updatedAt.isAfter(source.updatedAt), isTrue);
  });

  group('FIX-CALC-001 Phase 3 — wizard không chặn khi walls trống', () {
    ProjectWizardCubit buildWizardAtStep4() {
      final wizardCubit = ProjectWizardCubit();
      addTearDown(wizardCubit.close);
      wizardCubit.updateBasicInfo(name: 'Nhà không tường', location: 'Hà Nội');
      expect(wizardCubit.next(), isTrue);
      wizardCubit.updateFloor(
        0,
        const BuildingFloor(number: 1, length: 10, width: 8, height: 3.3),
      );
      wizardCubit.updateRoof(
        const RoofSpec(type: RoofType.flat, length: 10, width: 8, height: 0.3),
      );
      expect(wizardCubit.next(), isTrue);
      wizardCubit.selectFoundationType(FoundationType.strip);
      wizardCubit.selectStructureType(StructureType.reinforcedConcrete);
      expect(wizardCubit.next(), isTrue);
      return wizardCubit;
    }

    test(
        'chọn interior_paint + không thêm wall nào + điền đủ mục khác '
        '→ next()/canComplete = true (Default Wall xử lý ở tầng tính toán)',
        () {
      final wizardCubit = buildWizardAtStep4();
      wizardCubit.toggleMaterial(
        const ProjectMaterial(
          selectionKey: 'catalog:interior_paint',
          catalogCode: 'interior_paint',
          name: 'Sơn nội thất',
          unit: 'm2',
          unitPrice: 65000,
          type: ProjectMaterialType.material,
        ),
      );
      expect(wizardCubit.next(), isTrue);
      expect(wizardCubit.state.currentStep, 4);

      wizardCubit.updateDetails(
        const ProjectDetails(
          foundationSegments: [FoundationSegment(20)],
        ),
      );
      expect(wizardCubit.state.isStepValid(4), isTrue);
      expect(wizardCubit.state.canComplete, isTrue);
      // buildProject không throw.
      final project = wizardCubit.buildProject();
      expect(project.details.walls, isEmpty);
      expect(
        project.materials.single.catalogCode,
        'interior_paint',
      );
    });

    test(
        'WallSpec đã thêm dòng nhưng sai số (length=0) → vẫn bị REJECT '
        '(lỗi nhập liệu thật, không che giấu bằng Default Wall)', () {
      final wizardCubit = buildWizardAtStep4();
      wizardCubit.toggleMaterial(
        const ProjectMaterial(
          selectionKey: 'catalog:interior_paint',
          catalogCode: 'interior_paint',
          name: 'Sơn nội thất',
          unit: 'm2',
          unitPrice: 65000,
          type: ProjectMaterialType.material,
        ),
      );
      expect(wizardCubit.next(), isTrue);

      wizardCubit.updateDetails(
        const ProjectDetails(
          foundationSegments: [FoundationSegment(20)],
          walls: [
            WallSpec(
              type: WallType.wall100,
              plasterSides: 2,
              length: 0,
              height: 3.0,
            ),
          ],
        ),
      );
      expect(wizardCubit.state.isStepValid(4), isFalse);
      expect(wizardCubit.state.canComplete, isFalse);
    });
  });
}
