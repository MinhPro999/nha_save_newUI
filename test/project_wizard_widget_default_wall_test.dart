import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// FIX-CALC-001 Phase 12 — widget test: wizard chọn Sơn nội thất +
/// KHÔNG thêm Tường → hoàn tất thành công (Default Wall xử lý ở tầng
/// tính toán, wizard không chặn).
///
/// File riêng (không gộp vào project_wizard_widget_test.dart) vì harness
/// của project không hỗ trợ pump `ConstructionPlanApp` 2 lần trong cùng
/// 1 test process (lần 2 rootBundle.loadString của AppLocalizations treo
/// vô hạn) — mỗi file test chạy trong 1 process mới nên không đụng nhau.
void main() {
  testWidgets(
      'FIX-CALC-001: chọn Sơn nội thất + không thêm Tường → wizard hoàn '
      'tất thành công (không chặn)', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    HydratedBloc.storage = InMemoryStorage();

    await tester.pumpWidget(
      ConstructionPlanApp(
        materialLibraryStore: InMemoryMaterialLibraryStore(),
        projectStore: InMemoryProjectStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addProjectButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('projectNameField')),
      'Nhà không tường',
    );
    await tester.tap(find.byKey(const Key('projectLocationField')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('provinceSearchField')),
      'ho chi minh',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('province_ho_chi_minh_city')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('districtSearchField')),
      'thu duc',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('district_769')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('floor1LengthField')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('floor1WidthField')),
      '8',
    );
    await tester.enterText(
      find.byKey(const Key('floor1HeightField')),
      '3.3',
    );
    await tester.enterText(
      find.byKey(const Key('roofLengthField')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('roofWidthField')),
      '8',
    );
    await tester.enterText(
      find.byKey(const Key('roofHeightField')),
      '0.3',
    );
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Móng băng'));
    await tester.pump();
    await tester.tap(find.text('Bê tông cốt thép'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    // Chọn Sơn nội thất (library) — KHÔNG thêm bất kỳ WallSpec nào.
    await tester.ensureVisible(
      find.byKey(const Key('projectMaterial_catalog:interior_paint')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('projectMaterial_catalog:interior_paint')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addFoundationSegmentButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveProjectButton')));
    await tester.pumpAndSettle();

    expect(find.text('Nhà không tường'), findsOneWidget);
    expect(find.text('Đã tạo dự án mới.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
