import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_state.dart';
import 'package:flutter_core_project/features/projects/presentation/pages/project_wizard_page.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_cover_image.dart';
import 'package:flutter_core_project/services/localization_service.dart';

enum _ProjectAction { calculate, exportPdf, share }

class ProjectDetailPage extends StatelessWidget {
  const ProjectDetailPage({
    super.key,
    required this.projectId,
    this.initialProject,
    this.allowEditing = true,
  });

  final String projectId;
  final ConstructionProject? initialProject;
  final bool allowEditing;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectCubit, ProjectState>(
      builder: (context, state) {
        ConstructionProject? project = initialProject;
        for (final item in state.projects) {
          if (item.id == projectId) {
            project = item;
            break;
          }
        }

        if (project == null) {
          return Scaffold(
            appBar: AppBar(title: Text(context.tr('project_detail_title'))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  context.tr('project_detail_not_found'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // Chỉ dùng kết quả calculation của CHÍNH project này (tránh stale).
        final calculationResult = state.calculationProjectId == project.id
            ? state.calculationResult
            : null;

        return _ProjectDetailView(
          key: const Key('projectDetailPage'),
          project: project,
          isSaving: state.status == ProjectStatus.saving,
          allowEditing: allowEditing,
          calculationStatus: calculationResult == null &&
                  state.calculationProjectId == project.id
              ? state.calculationStatus
              : ProjectCalculationStatus.idle,
          calculationResult: calculationResult,
          calculationError: state.calculationProjectId == project.id
              ? state.calculationError
              : null,
        );
      },
    );
  }
}

class _ProjectDetailView extends StatefulWidget {
  const _ProjectDetailView({
    super.key,
    required this.project,
    required this.isSaving,
    required this.allowEditing,
    required this.calculationStatus,
    required this.calculationResult,
    required this.calculationError,
  });

  final ConstructionProject project;
  final bool isSaving;
  final bool allowEditing;
  final ProjectCalculationStatus calculationStatus;
  final ProjectCalculationResult? calculationResult;
  final String? calculationError;

  @override
  State<_ProjectDetailView> createState() => _ProjectDetailViewState();
}

class _ProjectDetailViewState extends State<_ProjectDetailView> {
  bool _calculateTriggered = false;

  ConstructionProject get project => widget.project;
  bool get isSaving => widget.isSaving;
  bool get allowEditing => widget.allowEditing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _calculateTriggered) return;
      _calculateTriggered = true;
      _triggerCalculation();
    });
  }

  @override
  void didUpdateWidget(covariant _ProjectDetailView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Project được làm mới (vd sau khi edit/save) → tính lại để không stale.
    if (oldWidget.project != widget.project) {
      _calculateTriggered = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _calculateTriggered) return;
        _calculateTriggered = true;
        _triggerCalculation();
      });
    }
  }

  void _triggerCalculation() {
    context.read<ProjectCubit>().calculate(widget.project);
  }

  @override
  Widget build(BuildContext context) {
    final calculationResult = widget.calculationResult;
    final lines =
        calculationResult?.materialLines ?? const <ProjectMaterialLine>[];
    final totalCost = calculationResult?.totalCost ?? 0.0;
    final isCalculating =
        widget.calculationStatus == ProjectCalculationStatus.calculating;
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          if (isSaving || isCalculating)
            const SliverToBoxAdapter(
              child: LinearProgressIndicator(minHeight: 2),
            ),
          if (widget.calculationStatus == ProjectCalculationStatus.failure)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                child: _CalculationErrorBanner(
                  error: widget.calculationError ?? '?',
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    20,
                    18,
                    72 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _UpdatedLabel(project: project),
                      const SizedBox(height: 18),
                      _ProjectMetrics(
                        project: project,
                        totalCost: totalCost,
                      ),
                      const SizedBox(height: 30),
                      _TechnicalOverview(project: project),
                      const SizedBox(height: 30),
                      _FloorsAndRoof(project: project),
                      const SizedBox(height: 30),
                      _FoundationAndStructure(project: project),
                      const SizedBox(height: 30),
                      _DetailedParameters(project: project),
                      const SizedBox(height: 30),
                      _CostDistribution(lines: lines, total: totalCost),
                      const SizedBox(height: 30),
                      _MaterialList(lines: lines, total: totalCost),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: 290,
      backgroundColor: accent,
      foregroundColor: Colors.white,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leadingWidth: 64,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: _HeroAction(
          tooltip: context.tr('project_back'),
          icon: Icons.arrow_back_rounded,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      actions: [
        if (allowEditing) ...[
          _HeroAction(
            tooltip: context.tr('edit'),
            icon: Icons.edit_outlined,
            onPressed: () => _editProject(context),
          ),
          const SizedBox(width: 8),
        ],
        _MoreActions(onSelected: (action) => _handleAction(context, action)),
        const SizedBox(width: 12),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        centerTitle: true,
        titlePadding: const EdgeInsetsDirectional.only(
          start: 112,
          end: 112,
          bottom: 17,
        ),
        title: _CollapsedProjectTitle(projectName: project.name),
        background: Stack(
          fit: StackFit.expand,
          children: [
            ProjectCoverImage(
              key: const Key('projectDetailCover'),
              imagePath: project.imagePath,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x26000000), Color(0xD9000000)],
                  stops: [0.25, 1],
                ),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 24,
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        context.tr(
                          allowEditing
                              ? 'project_saved_status'
                              : 'project_status',
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      project.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            project.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProject(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProjectWizardPage(initialProject: project),
      ),
    );
    if (updated == true && context.mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(context.tr('project_updated'))),
        );
    }
  }

  void _handleAction(BuildContext context, _ProjectAction action) {
    switch (action) {
      case _ProjectAction.calculate:
        // Tính lại bằng calculation thật (CalculationService → Legacy).
        context.read<ProjectCubit>().calculate(project);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(context.tr('project_estimate_updated'))),
          );
        return;
      case _ProjectAction.exportPdf:
      case _ProjectAction.share:
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.tr('coming_soon'))));
        return;
    }
  }
}

class _CollapsedProjectTitle extends StatelessWidget {
  const _CollapsedProjectTitle({required this.projectName});

  final String projectName;

  @override
  Widget build(BuildContext context) {
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final extent = settings?.currentExtent ?? 0;
    final minExtent = settings?.minExtent ?? 0;
    final maxExtent = settings?.maxExtent ?? 1;
    final progress =
        (1 - (extent - minExtent) / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Opacity(
      opacity: Curves.easeIn.transform(progress),
      child: Text(
        projectName,
        key: const Key('collapsedProjectTitle'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 42,
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.46),
            foregroundColor: Colors.white,
          ),
          icon: Icon(icon, size: 21),
        ),
      ),
    );
  }
}

class _MoreActions extends StatelessWidget {
  const _MoreActions({required this.onSelected});

  final ValueChanged<_ProjectAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 42,
        child: PopupMenuButton<_ProjectAction>(
          tooltip: context.tr('more_actions'),
          onSelected: onSelected,
          color: Theme.of(context).colorScheme.surface,
          position: PopupMenuPosition.under,
          iconColor: Colors.white,
          icon: const Icon(Icons.more_vert_rounded, size: 21),
          style: IconButton.styleFrom(
            backgroundColor: Colors.black.withValues(alpha: 0.46),
          ),
          itemBuilder: (context) => [
            _menuItem(
              context,
              _ProjectAction.calculate,
              Icons.refresh_rounded,
              'project_recalculate',
            ),
            _menuItem(
              context,
              _ProjectAction.exportPdf,
              Icons.picture_as_pdf_outlined,
              'project_export_pdf',
            ),
            _menuItem(
              context,
              _ProjectAction.share,
              Icons.ios_share_rounded,
              'project_share',
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<_ProjectAction> _menuItem(
    BuildContext context,
    _ProjectAction value,
    IconData icon,
    String labelKey,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 12),
          Text(context.tr(labelKey)),
        ],
      ),
    );
  }
}

class _UpdatedLabel extends StatelessWidget {
  const _UpdatedLabel({required this.project});

  final ConstructionProject project;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.history_rounded,
          size: 17,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            '${context.tr('project_last_updated')} ${_formatDate(project.updatedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _ProjectMetrics extends StatelessWidget {
  const _ProjectMetrics({required this.project, required this.totalCost});

  final ConstructionProject project;
  final double totalCost;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    final metrics = [
      _MetricData(
        icon: Icons.layers_outlined,
        label: context.tr('project_total_floor_area'),
        value: '${_formatDecimal(project.totalFloorArea)} m²',
        color: accent,
      ),
      _MetricData(
        icon: Icons.apartment_rounded,
        label: context.tr('project_floor_count'),
        value: '${project.floors.length}',
        color: const Color(0xFF2F80ED),
      ),
      _MetricData(
        icon: Icons.roofing_outlined,
        label: context.tr('project_roof_area'),
        value: '${_formatDecimal(project.roof.area)} m²',
        color: const Color(0xFFE58A19),
      ),
      _MetricData(
        icon: Icons.payments_outlined,
        label: context.tr('project_estimated_cost'),
        value: _formatCompactCurrency(totalCost),
        color: const Color(0xFF249A68),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final metric in metrics)
              SizedBox(width: width, child: _MetricTile(data: metric)),
          ],
        );
      },
    );
  }
}

class _MetricData {
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.data});

  final _MetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 106,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: _detailPanelShadows(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 22, color: data.color),
          const Spacer(),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _TechnicalOverview extends StatelessWidget {
  const _TechnicalOverview({required this.project});

  final ConstructionProject project;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: context.tr('project_overview'),
      icon: Icons.domain_outlined,
      child: _InfoPanel(
        rows: [
          _InfoData(
            context.tr('project_location'),
            project.location,
            Icons.location_on_outlined,
          ),
          _InfoData(
            context.tr('project_foundation_type'),
            _foundationName(
                context, project.foundationStructure.foundationType),
            Icons.foundation_outlined,
          ),
          _InfoData(
            context.tr('project_structure_type'),
            _structureName(context, project.foundationStructure.structureType),
            Icons.account_tree_outlined,
          ),
          _InfoData(
            context.tr('project_roof_section'),
            _roofName(context, project.roof.type),
            Icons.roofing_outlined,
          ),
          _InfoData(
            context.tr('project_material_count'),
            '${project.materials.length}',
            Icons.inventory_2_outlined,
          ),
        ],
      ),
    );
  }
}

class _FloorsAndRoof extends StatelessWidget {
  const _FloorsAndRoof({required this.project});

  final ConstructionProject project;

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoData>[
      for (final floor in project.floors)
        _InfoData(
          '${context.tr('project_floor')} ${floor.number}',
          '${_formatDimensions(floor.length, floor.width, floor.height)}  •  ${_formatDecimal(floor.area)} m²',
          Icons.layers_outlined,
        ),
      _InfoData(
        _roofName(context, project.roof.type),
        '${_formatDimensions(project.roof.length, project.roof.width, project.roof.height)}  •  ${_formatDecimal(project.roof.area)} m²',
        Icons.roofing_outlined,
      ),
    ];
    return _DetailSection(
      title: context.tr('project_floors_and_roof'),
      icon: Icons.apartment_outlined,
      child: _InfoPanel(rows: rows),
    );
  }
}

class _FoundationAndStructure extends StatelessWidget {
  const _FoundationAndStructure({required this.project});

  final ConstructionProject project;

  @override
  Widget build(BuildContext context) {
    final foundation = project.foundationStructure;
    final rows = <_InfoData>[
      _InfoData(
        context.tr('project_foundation_type'),
        _foundationName(context, foundation.foundationType),
        Icons.foundation_outlined,
      ),
      _InfoData(
        context.tr('project_structure_type'),
        _structureName(context, foundation.structureType),
        Icons.account_tree_outlined,
      ),
      _InfoData(
        context.tr('project_main_steel'),
        'D${foundation.mainBarDiameter} mm',
        Icons.circle_outlined,
      ),
      if (foundation.foundationType == FoundationType.strip &&
          foundation.alignment != null)
        _InfoData(
          context.tr('project_foundation_alignment'),
          _alignmentName(context, foundation.alignment!),
          Icons.align_horizontal_center_rounded,
        ),
      if (foundation.foundationType == FoundationType.isolated &&
          foundation.isolatedLength != null &&
          foundation.isolatedWidth != null &&
          foundation.isolatedHeight != null)
        _InfoData(
          context.tr('project_isolated_dimensions'),
          _formatDimensions(
            foundation.isolatedLength!,
            foundation.isolatedWidth!,
            foundation.isolatedHeight!,
          ),
          Icons.crop_square_rounded,
        ),
      for (var index = 0; index < foundation.columns.length; index++)
        _InfoData(
          '${context.tr('project_column')} ${index + 1}',
          _columnDescription(context, foundation.columns[index]),
          Icons.view_column_outlined,
        ),
      for (var index = 0;
          foundation.foundationType == FoundationType.pile &&
              index < foundation.pileCaps.length;
          index++)
        _InfoData(
          '${context.tr('project_pile_cap')} ${index + 1}',
          _formatDimensions(
            foundation.pileCaps[index].length,
            foundation.pileCaps[index].width,
            foundation.pileCaps[index].height,
          ),
          Icons.grid_view_rounded,
        ),
    ];
    return _DetailSection(
      title: context.tr('project_foundation_structure_detail'),
      icon: Icons.foundation_rounded,
      child: _InfoPanel(rows: rows),
    );
  }
}

class _DetailedParameters extends StatelessWidget {
  const _DetailedParameters({required this.project});

  final ConstructionProject project;

  @override
  Widget build(BuildContext context) {
    final details = project.details;
    final rows = <_InfoData>[
      for (var index = 0; index < details.foundationSegments.length; index++)
        _InfoData(
          '${context.tr('project_segment')} ${index + 1}',
          '${_formatDecimal(details.foundationSegments[index].length)} m',
          Icons.horizontal_rule_rounded,
        ),
      for (var index = 0; index < details.walls.length; index++)
        _InfoData(
          '${context.tr('project_wall')} ${index + 1}',
          _wallDescription(context, details.walls[index]),
          Icons.view_stream_outlined,
        ),
      for (var index = 0; index < details.openings.length; index++)
        _InfoData(
          '${_openingName(context, details.openings[index].type)} ${index + 1}',
          _openingDescription(context, details.openings[index]),
          Icons.door_front_door_outlined,
        ),
      for (var index = 0; index < details.bathrooms.length; index++)
        _InfoData(
          '${context.tr('project_bathroom')} ${index + 1}',
          '${_formatDecimal(details.bathrooms[index].area)} m²',
          Icons.bathtub_outlined,
        ),
      for (var index = 0; index < details.stairs.length; index++)
        _InfoData(
          '${context.tr('project_stair')} ${index + 1}',
          '${details.stairs[index].steps} ${context.tr('project_steps').toLowerCase()}',
          Icons.stairs_outlined,
        ),
    ];
    return _DetailSection(
      title: context.tr('project_detailed_parameters'),
      icon: Icons.straighten_outlined,
      child: rows.isEmpty
          ? _EmptyPanel(text: context.tr('project_detail_no_parameters'))
          : _InfoPanel(rows: rows),
    );
  }
}

class _DetailSection extends StatefulWidget {
  const _DetailSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  State<_DetailSection> createState() => _DetailSectionState();
}

class _DetailSectionState extends State<_DetailSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          expanded: _expanded,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(widget.icon, color: accent, size: 22),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _InfoData {
  const _InfoData(this.label, this.value, this.icon);

  final String label;
  final String value;
  final IconData icon;
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.rows});

  final List<_InfoData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: _detailPanelShadows(context),
      ),
      child: Column(
        children: [
          for (var index = 0; index < rows.length; index++) ...[
            _InfoRow(data: rows[index]),
            if (index != rows.length - 1)
              Divider(
                  height: 1, indent: 52, color: Theme.of(context).dividerColor),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoData data;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(data.icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 4,
            child:
                Text(data.label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              data.value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: _detailPanelShadows(context),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _CostDistribution extends StatelessWidget {
  const _CostDistribution({required this.lines, required this.total});

  final List<ProjectMaterialLine> lines;
  final double total;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    final colors = [
      accent,
      const Color(0xFF2F80ED),
      const Color(0xFFE58A19),
      const Color(0xFFE55C4A),
      const Color(0xFF7A62C9),
      const Color(0xFF249A68),
    ];
    // Chỉ sắp xếp trình bày — KHÔNG tính lại cost.
    final priced = [...lines.where((line) => line.cost > 0)]
      ..sort((a, b) => b.cost.compareTo(a.cost));
    return _DetailSection(
      title: context.tr('project_cost_distribution'),
      icon: Icons.donut_large_outlined,
      child: priced.isEmpty
          ? _EmptyPanel(text: context.tr('project_no_cost_data'))
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: _detailPanelShadows(context),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final chartSize =
                          constraints.maxWidth < 390 ? 142.0 : 164.0;
                      return Row(
                        children: [
                          SizedBox.square(
                            dimension: chartSize,
                            child: _CostDonut(
                              lines: priced,
                              total: total,
                              colors: colors,
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('project_total_estimate'),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _formatCurrency(total),
                                  key: const Key('projectTotalEstimate'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        color: accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '${priced.length} ${context.tr('project_cost_categories').toLowerCase()}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  for (var index = 0; index < priced.length; index++) ...[
                    _CostLegendRow(
                      line: priced[index],
                      total: total,
                      color: colors[index % colors.length],
                    ),
                    if (index < priced.length - 1) const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 18),
                  Divider(height: 1, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 14),
                  Text(
                    context.tr('project_estimate_note'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CostDonut extends StatelessWidget {
  const _CostDonut({
    required this.lines,
    required this.total,
    required this.colors,
  });

  final List<ProjectMaterialLine> lines;
  final double total;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: _CostDonutPainter(
            values: [for (final line in lines) line.cost],
            total: total,
            colors: colors,
            trackColor: Theme.of(context).dividerColor.withValues(alpha: 0.55),
          ),
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 19,
                  color: accent,
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _formatCompactCurrency(total),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CostDonutPainter extends CustomPainter {
  const _CostDonutPainter({
    required this.values,
    required this.total,
    required this.colors,
    required this.trackColor,
  });

  final List<double> values;
  final double total;
  final List<Color> colors;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 18.0;
    const gap = 0.035;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final bounds = Rect.fromCircle(center: center, radius: radius);
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    var startAngle = -math.pi / 2;
    for (var index = 0; index < values.length; index++) {
      final sweep = total <= 0 ? 0.0 : values[index] / total * math.pi * 2;
      if (sweep <= gap) continue;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = colors[index % colors.length];
      canvas.drawArc(bounds, startAngle + gap / 2, sweep - gap, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _CostDonutPainter oldDelegate) {
    return total != oldDelegate.total ||
        trackColor != oldDelegate.trackColor ||
        !listEquals(values, oldDelegate.values) ||
        !listEquals(colors, oldDelegate.colors);
  }
}

class _CostLegendRow extends StatelessWidget {
  const _CostLegendRow({
    required this.line,
    required this.total,
    required this.color,
  });

  final ProjectMaterialLine line;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (line.cost / total).clamp(0.0, 1.0);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 34,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                line.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatCurrency(line.cost),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          constraints: const BoxConstraints(minWidth: 54),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            '${(ratio * 100).toStringAsFixed(1)}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

class _MaterialList extends StatelessWidget {
  const _MaterialList({required this.lines, required this.total});

  final List<ProjectMaterialLine> lines;
  final double total;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return _DetailSection(
      title: context.tr('project_material_labor_list'),
      icon: Icons.inventory_2_outlined,
      child: lines.isEmpty
          ? _EmptyPanel(text: context.tr('project_no_materials'))
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: _detailPanelShadows(context),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < lines.length; index++) ...[
                    _MaterialRow(line: lines[index]),
                    if (index != lines.length - 1)
                      Divider(
                        height: 1,
                        indent: 58,
                        color: Theme.of(context).dividerColor,
                      ),
                  ],
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(7),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('project_total'),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Flexible(
                          child: Text(
                            _formatCurrency(total),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.line});

  final ProjectMaterialLine line;

  @override
  Widget build(BuildContext context) {
    final unit = _localizedUnit(context, line.unit ?? '');
    final hasPrice = line.unitPrice > 0;
    final accent = AppColors.linearShapeFor(context);
    final materialColor = hasPrice ? accent : const Color(0xFFE58A19);
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: materialColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 19,
              color: materialColor,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDecimal(line.quantity)} $unit  •  ${hasPrice ? '${_formatCurrency(line.unitPrice)} / $unit' : context.tr('project_price_not_set')}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 132),
            child: Text(
              hasPrice ? _formatCurrency(line.cost) : '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: hasPrice ? null : Theme.of(context).disabledColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CalculationErrorBanner extends StatelessWidget {
  const _CalculationErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE55C4A).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFE55C4A).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFE55C4A)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              error,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

List<BoxShadow> _detailPanelShadows(BuildContext context) {
  final theme = Theme.of(context);
  final isDark = theme.brightness == Brightness.dark;
  return [
    BoxShadow(
      color: theme.colorScheme.shadow.withValues(
        alpha: isDark ? 0.28 : 0.08,
      ),
      blurRadius: isDark ? 12 : 16,
      offset: const Offset(0, 5),
    ),
  ];
}

String _foundationName(BuildContext context, FoundationType type) {
  switch (type) {
    case FoundationType.strip:
      return context.tr('project_foundation_strip');
    case FoundationType.raft:
      return context.tr('project_foundation_raft');
    case FoundationType.isolated:
      return context.tr('project_foundation_isolated');
    case FoundationType.pile:
      return context.tr('project_foundation_pile');
  }
}

String _structureName(BuildContext context, StructureType type) {
  switch (type) {
    case StructureType.reinforcedConcrete:
      return context.tr('project_structure_concrete');
    case StructureType.steelFrame:
      return context.tr('project_structure_steel');
    case StructureType.masonry:
      return context.tr('project_structure_masonry');
    case StructureType.timber:
      return context.tr('project_structure_timber');
  }
}

String _roofName(BuildContext context, RoofType type) {
  switch (type) {
    case RoofType.flat:
      return context.tr('project_roof_flat');
    case RoofType.metal:
      return context.tr('project_roof_metal');
    case RoofType.tile:
      return context.tr('project_roof_tile');
  }
}

String _alignmentName(BuildContext context, FoundationAlignment alignment) {
  switch (alignment) {
    case FoundationAlignment.balanced:
      return context.tr('project_alignment_balanced');
    case FoundationAlignment.offsetOneSide:
      return context.tr('project_alignment_one_side');
    case FoundationAlignment.offsetTwoSides:
      return context.tr('project_alignment_two_sides');
  }
}

String _openingName(BuildContext context, OpeningType type) {
  switch (type) {
    case OpeningType.window:
      return context.tr('project_window');
    case OpeningType.door:
      return context.tr('project_door');
    case OpeningType.rollingDoor:
      return context.tr('project_rolling_door');
  }
}

String _wallDescription(BuildContext context, WallSpec wall) {
  final type = wall.type == WallType.wall100
      ? context.tr('project_wall_100')
      : context.tr('project_wall_200');
  return '$type  •  ${_formatDecimal(wall.area)} m²  •  ${wall.plasterSides} ${context.tr('project_plaster_sides').toLowerCase()}';
}

String _openingDescription(BuildContext context, OpeningSpec opening) {
  return '${_formatDecimal(opening.width)} × ${_formatDecimal(opening.height)} m  •  ${opening.quantity} ${context.tr('project_quantity').toLowerCase()}  •  ${_formatDecimal(opening.area)} m²';
}

String _columnDescription(BuildContext context, ColumnSpec column) {
  return '${_formatDecimal(column.width)} × ${_formatDecimal(column.thickness)} m  •  ${column.quantity} ${context.tr('project_quantity').toLowerCase()}  •  ${column.mainBarsCount}D${column.mainBarDiameter}';
}

String _localizedUnit(BuildContext context, String unit) {
  switch (unit.toLowerCase().trim()) {
    case 'piece':
      return context.tr('unit_piece');
    case 'm3':
    case 'm³':
      return 'm³';
    case 'm2':
    case 'm²':
      return 'm²';
    case 'meter':
    case 'm':
      return 'm';
    case 'kilogram':
    case 'kg':
      return 'kg';
    case 'ton':
      return context.tr('unit_ton');
    case 'set':
      return context.tr('unit_set');
    case 'package':
      return context.tr('unit_package');
    default:
      return unit;
  }
}

String _formatDimensions(double length, double width, double height) {
  return '${_formatDecimal(length)} × ${_formatDecimal(width)} × ${_formatDecimal(height)} m';
}

String _formatDate(DateTime value) {
  String twoDigits(int number) => number.toString().padLeft(2, '0');
  return '${twoDigits(value.day)}/${twoDigits(value.month)}/${value.year}';
}

String _formatDecimal(double value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

String _formatCurrency(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} ₫';
}

String _formatCompactCurrency(double value) {
  if (value >= 1000000000) {
    return '${_formatDecimal(value / 1000000000)}B ₫';
  }
  if (value >= 1000000) return '${_formatDecimal(value / 1000000)}M ₫';
  return _formatCurrency(value);
}
