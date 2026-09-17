import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/domain/usecases/usecase.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/calculate_project.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/get_projects.dart';
import 'package:flutter_core_project/features/projects/domain/usecases/save_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_state.dart';

class ProjectCubit extends Cubit<ProjectState> {
  ProjectCubit({
    required GetProjects getProjects,
    required SaveProject saveProject,
    required CalculateProject calculateProject,
  })  : _getProjects = getProjects,
        _saveProject = saveProject,
        _calculateProject = calculateProject,
        super(const ProjectState());

  final GetProjects _getProjects;
  final SaveProject _saveProject;
  final CalculateProject _calculateProject;

  /// Chạy calculation thật qua `CalculateProject → CalculationService
  /// → LegacyCalculationService`. KHÔNG fallback mock, KHÔNG nuốt lỗi —
  /// error được giữ trong state để UI hiển thị (theo pattern cubit hiện tại).
  Future<void> calculate(ConstructionProject project) async {
    emit(
      state.copyWith(
        calculationStatus: ProjectCalculationStatus.calculating,
        calculationProjectId: project.id,
        calculationResult: null,
        clearCalculationError: true,
      ),
    );
    try {
      final result = await _calculateProject(project);
      emit(
        state.copyWith(
          calculationStatus: ProjectCalculationStatus.success,
          calculationProjectId: project.id,
          calculationResult: result,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          calculationStatus: ProjectCalculationStatus.failure,
          calculationProjectId: project.id,
          calculationResult: null,
          calculationError: error.toString(),
        ),
      );
    }
  }

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      emit(state.copyWith(status: ProjectStatus.loading, clearError: true));
    }
    try {
      final projects = await _getProjects(const NoParams());
      emit(
        state.copyWith(
          status: ProjectStatus.success,
          projects: projects,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: ProjectStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> create(ConstructionProject project) async {
    await _persist(project);
  }

  Future<void> update(ConstructionProject project) async {
    await _persist(project);
  }

  Future<void> _persist(ConstructionProject project) async {
    emit(state.copyWith(status: ProjectStatus.saving, clearError: true));
    try {
      await _saveProject(project);
      await load(showLoading: false);
    } catch (error) {
      emit(
        state.copyWith(
          status: ProjectStatus.failure,
          errorMessage: error.toString(),
        ),
      );
      rethrow;
    }
  }
}
