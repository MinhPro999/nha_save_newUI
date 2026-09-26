import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/wall_dependency_helper.dart';
import 'package:flutter_test/flutter_test.dart';

/// FIX-CALC-001 Phase 12 — vai trò MỚI của rule "wall dependent":
/// không còn dùng để *chặn* wizard (Phase 3 đã chốt), mà dùng để
/// ProjectDetailPage (Phase 10) xác định *có cần hiển thị banner
/// "Ước tính" hay không*.
void main() {
  group('WallDependencyHelper — quyết định banner "Ước tính" (Phase 10)', () {
    const baseDetails = ProjectDetails(
      foundationSegments: [FoundationSegment(12)],
    );

    ConstructionProject projectWith({
      List<ProjectMaterial> materials = const [],
      ProjectDetails details = baseDetails,
    }) {
      return ConstructionProject(
        id: 'p-helper',
        name: 'Nhà mẫu',
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
          mainBarDiameter: 16,
        ),
        materials: materials,
        details: details,
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

    const steel = ProjectMaterial(
      selectionKey: 'k-steel',
      catalogCode: 'steel',
      name: 'Sắt thép',
      unit: 'ton',
      unitPrice: 18000000,
      type: ProjectMaterialType.material,
    );

    test(
        'walls rỗng + có vật liệu phụ thuộc tường → DÙNG Default Wall '
        '→ banner "Ước tính" phải hiển thị', () {
      expect(
        WallDependencyHelper.usesDefaultWallEstimate(
          projectWith(
            materials: const [interiorPaint],
            details: const ProjectDetails(
              foundationSegments: [FoundationSegment(12)],
            ),
          ),
        ),
        isTrue,
      );
    });

    test('có WallSpec hợp lệ → KHÔNG dùng Default Wall → không banner', () {
      expect(
        WallDependencyHelper.usesDefaultWallEstimate(
          projectWith(
            materials: const [interiorPaint],
            details: const ProjectDetails(
              foundationSegments: [FoundationSegment(12)],
              walls: [
                WallSpec(
                  type: WallType.wall200,
                  plasterSides: 2,
                  length: 26,
                  height: 3.2,
                ),
              ],
            ),
          ),
        ),
        isFalse,
      );
    });

    test('walls rỗng nhưng KHÔNG chọn vật liệu phụ thuộc tường → không banner',
        () {
      expect(
        WallDependencyHelper.usesDefaultWallEstimate(
          projectWith(materials: const [steel]),
        ),
        isFalse,
      );
    });

    test('WallSpec toàn bộ không hợp lệ → coi như trống → banner hiển thị', () {
      expect(
        WallDependencyHelper.usesDefaultWallEstimate(
          projectWith(
            materials: const [interiorPaint],
            details: const ProjectDetails(
              foundationSegments: [FoundationSegment(12)],
              walls: [
                WallSpec(
                  type: WallType.wall100,
                  plasterSides: 2,
                  length: 0,
                  height: 0,
                ),
              ],
            ),
          ),
        ),
        isTrue,
      );
    });

    test('set wall-dependent khớp đúng 5 mã trong FIX-CALC-001 mục 2', () {
      expect(
        WallDependencyHelper.wallDependentCatalogCodes,
        {'brick', 'cement', 'sand', 'plaster_sand', 'interior_paint'},
      );
    });
  });
}
