import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';

enum ProjectStatus { initial, loading, success, failure, saving }

/// Lifecycle của một lần calculation trong Cubit.
///
/// FIX-CALC-001R: sau khi calculation hoàn tất, [ProjectCubit] phải map
/// `ProjectCalculationResult.status` (success/partial/failure) 1-1 sang enum
/// này — KHÔNG có 2 source of truth mâu thuẫn (vd Cubit=success mà
/// Result=failure). `calculating` là trạng thái transient duy nhất.
enum ProjectCalculationStatus { idle, calculating, success, partial, failure }

class ProjectState extends Equatable {
  const ProjectState({
    this.status = ProjectStatus.initial,
    this.projects = const [],
    this.errorMessage,
    this.calculationStatus = ProjectCalculationStatus.idle,
    this.calculationResult,
    this.calculationProjectId,
    this.calculationError,
  });

  static const _unset = Object();

  final ProjectStatus status;
  final List<ConstructionProject> projects;
  final String? errorMessage;

  /// Kết quả calculation thật (LegacyCalculationService) cho project hiện tại.
  final ProjectCalculationStatus calculationStatus;
  final ProjectCalculationResult? calculationResult;

  /// Project mà [calculationResult] thuộc về — tránh hiển thị kết quả cũ
  /// cho project khác.
  final String? calculationProjectId;
  final String? calculationError;

  ProjectState copyWith({
    ProjectStatus? status,
    List<ConstructionProject>? projects,
    String? errorMessage,
    bool clearError = false,
    ProjectCalculationStatus? calculationStatus,
    Object? calculationResult = _unset,
    String? calculationProjectId,
    String? calculationError,
    bool clearCalculationError = false,
  }) {
    return ProjectState(
      status: status ?? this.status,
      projects: projects ?? this.projects,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      calculationStatus: calculationStatus ?? this.calculationStatus,
      calculationResult: identical(calculationResult, _unset)
          ? this.calculationResult
          : calculationResult as ProjectCalculationResult?,
      calculationProjectId: calculationProjectId ?? this.calculationProjectId,
      calculationError: clearCalculationError
          ? null
          : calculationError ?? this.calculationError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        projects,
        errorMessage,
        calculationStatus,
        calculationResult,
        calculationProjectId,
        calculationError,
      ];
}
