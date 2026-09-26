import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/core/configs/assets/app_images.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_calculation_service.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_cover_image.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  testWidgets('opens, edits and localizes a saved project detail',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    HydratedBloc.storage = InMemoryStorage();

    final store = InMemoryProjectStore();
    await store.save(_detailedProject());
    await tester.pumpWidget(
      ConstructionPlanApp(
        materialLibraryStore: InMemoryMaterialLibraryStore(),
        projectStore: store,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('projectCard_detail-project')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('projectDetailPage')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('projectDetailPage')),
        matching: find.byType(ProjectCoverImage),
      ),
      findsOneWidget,
    );
    final defaultCover = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const Key('projectDetailCover')),
        matching: find.byType(Image),
      ),
    );
    expect(defaultCover.image, isA<AssetImage>());
    expect(
      (defaultCover.image as AssetImage).assetName,
      AppImages.modernTownhouse,
    );
    expect(find.text('Tổng quan công trình'), findsOneWidget);
    // Tổng chi phí hiển thị phải là kết quả calculation THẬT
    // (LegacyCalculationService) — không phải placeholder cũ.
    final expectedTotal = const LegacyCalculationService()
        .calculate(_detailedProject())
        .totalCost;
    expect(find.text(_formatVnd(expectedTotal)), findsWidgets);
    expect(tester.takeException(), isNull);

    expect(find.text('Loại móng'), findsNWidgets(2));
    await tester.tap(find.text('Tổng quan công trình'));
    await tester.pumpAndSettle();
    expect(find.text('Loại móng'), findsOneWidget);
    await tester.tap(find.text('Tổng quan công trình'));
    await tester.pumpAndSettle();
    expect(find.text('Loại móng'), findsNWidgets(2));

    await tester.drag(
      find.byType(CustomScrollView),
      const Offset(0, -360),
    );
    await tester.pumpAndSettle();
    final collapsedTitleOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const Key('collapsedProjectTitle')),
        matching: find.byType(Opacity),
      ),
    );
    expect(collapsedTitleOpacity.opacity, greaterThan(0.9));

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa công trình'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.enterText(
      find.byKey(const Key('projectNameField')),
      'Nhà phố đã cập nhật',
    );
    await tester.tap(find.byKey(const Key('projectWizardStep4')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('saveProjectButton')));
    await tester.pumpAndSettle();
    expect(find.text('Nhà phố đã cập nhật'), findsWidgets);
    expect(find.text('Đã cập nhật thông tin công trình.'), findsOneWidget);

    final detailContext =
        tester.element(find.byKey(const Key('projectDetailPage')));
    detailContext.read<ThemeCubit>().updateTheme(ThemeMode.dark);
    detailContext.read<LocaleCubit>().changeLocale('en');
    await tester.pumpAndSettle();

    final localizedContext =
        tester.element(find.byKey(const Key('projectDetailPage')));
    expect(Theme.of(localizedContext).brightness, Brightness.dark);
    expect(find.text('Project overview'), findsOneWidget);
    expect(find.text('Cost distribution'), findsOneWidget);

    Navigator.of(localizedContext).pop();
    await tester.pumpAndSettle();
  });
}

/// Khớp định dạng hiển thị của `project_detail_page.dart` (`_formatCurrency`).
String _formatVnd(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} ₫';
}

ConstructionProject _detailedProject() {
  final now = DateTime(2026, 9, 1);
  return ConstructionProject(
    id: 'detail-project',
    name: 'Nhà phố An Phú',
    location: 'Thành phố Hồ Chí Minh',
    createdAt: now,
    updatedAt: now,
    floors: const [
      BuildingFloor(number: 1, length: 10, width: 8, height: 3.2),
    ],
    roof: const RoofSpec(
      type: RoofType.tile,
      length: 10,
      width: 8,
      height: 2,
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
        selectionKey: 'catalog:brick',
        catalogCode: 'brick',
        name: 'Gạch xây',
        unit: 'piece',
        unitPrice: 1500,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:cement',
        catalogCode: 'cement',
        name: 'Xi măng',
        unit: 'ton',
        unitPrice: 1800000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:steel',
        catalogCode: 'steel',
        name: 'Sắt thép',
        unit: 'ton',
        unitPrice: 18000000,
        type: ProjectMaterialType.material,
      ),
      ProjectMaterial(
        selectionKey: 'catalog:labor',
        catalogCode: 'labor',
        name: 'Nhân công xây dựng',
        unit: 'm2',
        unitPrice: 1350000,
        type: ProjectMaterialType.labor,
      ),
    ],
    details: const ProjectDetails(
      foundationSegments: [FoundationSegment(18)],
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
          width: 1.2,
          height: 2.2,
          quantity: 2,
        ),
      ],
      bathrooms: [BathroomSpec(5)],
      stairs: [StairSpec(21)],
    ),
  );
}
