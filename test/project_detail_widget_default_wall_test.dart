import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// FIX-CALC-001 Phase 12 — widget test: project có interior_paint +
/// `walls=[]` → mở ProjectDetailPage → KHÔNG còn banner exception thô,
/// hiển thị đầy đủ material lines (sơn nội thất > 0 theo Default Wall),
/// có banner minh bạch "Ước tính".
///
/// File riêng (không gộp vào project_detail_widget_test.dart) vì harness
/// của project không hỗ trợ pump `ConstructionPlanApp` 2 lần trong cùng
/// 1 test process (lần 2 rootBundle.loadString của AppLocalizations treo
/// vô hạn) — mỗi file test chạy trong 1 process mới nên không đụng nhau.
void main() {
  testWidgets(
      'FIX-CALC-001: interior_paint + walls trống → hiển thị đầy đủ kết quả '
      'Default Wall + banner "Ước tính", không có exception thô',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    HydratedBloc.storage = InMemoryStorage();

    final store = InMemoryProjectStore();
    await store.save(_paintProjectNoWalls());
    await tester.pumpWidget(
      ConstructionPlanApp(
        materialLibraryStore: InMemoryMaterialLibraryStore(),
        projectStore: store,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('projectCard_detail-project-no-walls')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('projectDetailPage')), findsOneWidget);

    // KHÔNG còn exception thô từ PaintCalculator.
    expect(
      find.text('Diện tích sơn nội thất phải lớn hơn 0'),
      findsNothing,
    );

    // Banner minh bạch "ước tính mặc định" xuất hiện.
    expect(
      find.textContaining('ước lượng diện tích sàn'),
      findsOneWidget,
    );

    // Dòng vật tư Sơn nội thất có số liệu > 0 theo Default Wall
    // (1 tầng 10×8×3.3 → 36×3.3×2×1.5 = 356.4 m²).
    expect(find.text('Sơn nội thất'), findsWidgets);
    expect(find.textContaining('356.4 m²'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

ConstructionProject _paintProjectNoWalls() {
  final now = DateTime(2026, 9, 1);
  return ConstructionProject(
    id: 'detail-project-no-walls',
    name: 'Nhà sơn ước tính',
    location: 'Hà Nội',
    createdAt: now,
    updatedAt: now,
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
        selectionKey: 'catalog:interior_paint',
        catalogCode: 'interior_paint',
        name: 'Sơn nội thất',
        unit: 'm2',
        unitPrice: 65000,
        type: ProjectMaterialType.material,
      ),
    ],
    details: const ProjectDetails(
      foundationSegments: [FoundationSegment(18)],
      // KHÔNG nhập tường → Default Wall Calculator (FIX-CALC-001).
    ),
  );
}
