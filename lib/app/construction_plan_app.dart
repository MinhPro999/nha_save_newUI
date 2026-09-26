import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_theme.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_repository_impl.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/delete_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/get_material_library_items.dart';
import 'package:flutter_core_project/features/material_library/domain/usecases/save_material_library_item.dart';
import 'package:flutter_core_project/features/material_library/presentation/bloc/material_library_cubit.dart';
import 'package:flutter_core_project/features/projects/data/project_repository_impl.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/calculate_project.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/get_projects.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/save_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_cubit.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/locale_cubit.dart';
import 'package:flutter_core_project/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:flutter_core_project/presentation/pages/main/bloc/main_navigation_cubit.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_core_project/services/navigation_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class ConstructionPlanApp extends StatelessWidget {
  const ConstructionPlanApp({
    super.key,
    this.debugShowCheckedModeBanner = false,
    this.materialLibraryStore,
    this.projectStore,
  });

  final bool debugShowCheckedModeBanner;
  final MaterialLibraryStore? materialLibraryStore;
  final ProjectStore? projectStore;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
        BlocProvider(create: (_) => MainNavigationCubit()),
        BlocProvider(create: (_) => _createMaterialLibraryCubit()..load()),
        BlocProvider(create: (_) => _createProjectCubit()..load()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: AppConfig.appTitle,
                navigatorKey: NavigationService.navigatorKey,
                debugShowCheckedModeBanner: debugShowCheckedModeBanner,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                locale: locale,
                supportedLocales: const [Locale('vi'), Locale('en')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                builder: (context, child) => GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: child ?? const SizedBox.shrink(),
                ),
                home: const MainScreen(),
              );
            },
          );
        },
      ),
    );
  }

  MaterialLibraryCubit _createMaterialLibraryCubit() {
    final store = materialLibraryStore;
    if (store == null && sl.isRegistered<MaterialLibraryCubit>()) {
      return sl<MaterialLibraryCubit>();
    }

    final repository = MaterialLibraryRepositoryImpl(
      store ?? InMemoryMaterialLibraryStore(),
    );
    return MaterialLibraryCubit(
      getItems: GetMaterialLibraryItems(repository),
      saveItem: SaveMaterialLibraryItem(repository),
      deleteItem: DeleteMaterialLibraryItem(repository),
    );
  }

  ProjectCubit _createProjectCubit() {
    final store = projectStore;
    if (store == null && sl.isRegistered<ProjectCubit>()) {
      return sl<ProjectCubit>();
    }

    final repository = ProjectRepositoryImpl(store ?? InMemoryProjectStore());
    // Production calculation: LUÔN real engine (LegacyCalculationService),
    // KHÔNG dùng Mock — Mock chỉ cho test isolation.
    final calculateProject = sl.isRegistered<CalculateProject>()
        ? sl<CalculateProject>()
        : const CalculateProject(LegacyCalculationService());
    return ProjectCubit(
      getProjects: GetProjects(repository),
      saveProject: SaveProject(repository),
      calculateProject: calculateProject,
    );
  }
}
