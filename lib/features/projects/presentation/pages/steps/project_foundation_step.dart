import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_step_input_border.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class ProjectFoundationStep extends StatelessWidget {
  const ProjectFoundationStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectWizardCubit, ProjectWizardState>(
      builder: (context, state) {
        final cubit = context.read<ProjectWizardCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              title: context.tr('project_foundation_title'),
              description: context.tr('project_foundation_description'),
            ),
            const SizedBox(height: 22),
            _SectionTitle(
              title: context.tr('project_foundation_type'),
              icon: Icons.foundation_outlined,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_foundation_strip'),
                      icon: Icons.view_stream_outlined,
                      selected: state.foundationType == FoundationType.strip,
                      onPressed: () =>
                          cubit.selectFoundationType(FoundationType.strip),
                    ),
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_foundation_raft'),
                      icon: Icons.grid_on_rounded,
                      selected: state.foundationType == FoundationType.raft,
                      onPressed: () =>
                          cubit.selectFoundationType(FoundationType.raft),
                    ),
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_foundation_isolated'),
                      icon: Icons.crop_square_rounded,
                      selected: state.foundationType == FoundationType.isolated,
                      onPressed: () =>
                          cubit.selectFoundationType(FoundationType.isolated),
                    ),
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_foundation_pile'),
                      icon: Icons.view_column_outlined,
                      selected: state.foundationType == FoundationType.pile,
                      onPressed: () =>
                          cubit.selectFoundationType(FoundationType.pile),
                    ),
                  ],
                );
              },
            ),
            if (state.foundationType != null) ...[
              const SizedBox(height: 18),
              _FoundationOptions(state: state),
            ],
            const SizedBox(height: 24),
            _SectionTitle(
              title: context.tr('project_structure_type'),
              icon: Icons.account_tree_outlined,
            ),
            const SizedBox(height: 10),
            LayoutBuilder(
              builder: (context, constraints) {
                final tileWidth = (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_structure_concrete'),
                      icon: Icons.apartment_rounded,
                      selected: state.structureType ==
                          StructureType.reinforcedConcrete,
                      onPressed: () => cubit.selectStructureType(
                        StructureType.reinforcedConcrete,
                      ),
                    ),
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_structure_steel'),
                      icon: Icons.tag_rounded,
                      selected: state.structureType == StructureType.steelFrame,
                      onPressed: () => cubit.selectStructureType(
                        StructureType.steelFrame,
                      ),
                    ),
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_structure_masonry'),
                      icon: Icons.view_module_outlined,
                      selected: state.structureType == StructureType.masonry,
                      onPressed: () =>
                          cubit.selectStructureType(StructureType.masonry),
                    ),
                    _SelectionTile(
                      width: tileWidth,
                      label: context.tr('project_structure_timber'),
                      icon: Icons.park_outlined,
                      selected: state.structureType == StructureType.timber,
                      onPressed: () =>
                          cubit.selectStructureType(StructureType.timber),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: context.tr('project_columns'),
              onAdd: cubit.addColumn,
            ),
            const SizedBox(height: 10),
            if (state.columns.isEmpty)
              _EmptyHint(text: context.tr('project_columns_empty')),
            for (var index = 0; index < state.columns.length; index++) ...[
              _ColumnEditor(
                key: ValueKey('column$index'),
                index: index,
                column: state.columns[index],
                canRemove: state.columns.length > 1,
                onChanged: (value) => cubit.updateColumn(index, value),
                onRemove: () => cubit.removeColumn(index),
              ),
              if (index < state.columns.length - 1) const SizedBox(height: 10),
            ],
            if (state.showValidation && !state.isStepValid(2)) ...[
              const SizedBox(height: 16),
              _ValidationNotice(
                text: context.tr('project_foundation_invalid'),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _FoundationOptions extends StatelessWidget {
  const _FoundationOptions({required this.state});

  final ProjectWizardState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProjectWizardCubit>();
    switch (state.foundationType!) {
      case FoundationType.strip:
        return DropdownButtonFormField<FoundationAlignment>(
          key: const Key('foundationAlignmentField'),
          initialValue: state.alignment,
          decoration: InputDecoration(
            labelText: context.tr('project_foundation_alignment'),
            border: projectStepInputBorder,
          ),
          items: [
            DropdownMenuItem(
              value: FoundationAlignment.balanced,
              child: Text(context.tr('project_alignment_balanced')),
            ),
            DropdownMenuItem(
              value: FoundationAlignment.offsetOneSide,
              child: Text(context.tr('project_alignment_one_side')),
            ),
            DropdownMenuItem(
              value: FoundationAlignment.offsetTwoSides,
              child: Text(context.tr('project_alignment_two_sides')),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              cubit.updateFoundationOptions(alignment: value);
            }
          },
        );
      case FoundationType.raft:
        return _SteelDiameterField(value: state.mainBarDiameter);
      case FoundationType.isolated:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('project_isolated_dimensions'),
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = (constraints.maxWidth - 16) / 3;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _NumberField(
                      fieldKey: const Key('isolatedLengthField'),
                      width: fieldWidth,
                      label: context.tr('library_length'),
                      value: state.isolatedLength ?? 0,
                      onChanged: (value) => cubit.updateFoundationOptions(
                        isolatedLength: value,
                      ),
                    ),
                    _NumberField(
                      fieldKey: const Key('isolatedWidthField'),
                      width: fieldWidth,
                      label: context.tr('library_width'),
                      value: state.isolatedWidth ?? 0,
                      onChanged: (value) => cubit.updateFoundationOptions(
                        isolatedWidth: value,
                      ),
                    ),
                    _NumberField(
                      fieldKey: const Key('isolatedHeightField'),
                      width: fieldWidth,
                      label: context.tr('library_height'),
                      value: state.isolatedHeight ?? 0,
                      onChanged: (value) => cubit.updateFoundationOptions(
                        isolatedHeight: value,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _SteelDiameterField(value: state.mainBarDiameter),
          ],
        );
      case FoundationType.pile:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: context.tr('project_pile_caps'),
              onAdd: cubit.addPileCap,
            ),
            const SizedBox(height: 8),
            for (var index = 0; index < state.pileCaps.length; index++) ...[
              _PileCapEditor(
                key: ValueKey('pileCap$index'),
                index: index,
                value: state.pileCaps[index],
                canRemove: state.pileCaps.length > 1,
                onChanged: (value) => cubit.updatePileCap(index, value),
                onRemove: () => cubit.removePileCap(index),
              ),
              if (index < state.pileCaps.length - 1) const SizedBox(height: 8),
            ],
            const SizedBox(height: 12),
            _SteelDiameterField(value: state.mainBarDiameter),
          ],
        );
    }
  }
}

class _SteelDiameterField extends StatelessWidget {
  const _SteelDiameterField({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      key: const Key('foundationSteelDiameterField'),
      initialValue: value,
      decoration: InputDecoration(
        labelText: context.tr('project_main_steel'),
        border: projectStepInputBorder,
      ),
      items: const [14, 16, 18, 20, 22]
          .map(
            (diameter) => DropdownMenuItem(
              value: diameter,
              child: Text('D$diameter'),
            ),
          )
          .toList(),
      onChanged: (diameter) {
        if (diameter != null) {
          context
              .read<ProjectWizardCubit>()
              .updateFoundationOptions(mainBarDiameter: diameter);
        }
      },
    );
  }
}

class _ColumnEditor extends StatelessWidget {
  const _ColumnEditor({
    super.key,
    required this.index,
    required this.column,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final ColumnSpec column;
  final bool canRemove;
  final ValueChanged<ColumnSpec> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorSurface(
      title: '${context.tr('project_column')} ${index + 1}',
      canRemove: canRemove,
      onRemove: onRemove,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 10,
            children: [
              _NumberField(
                fieldKey: Key('column${index}WidthField'),
                width: fieldWidth,
                label: context.tr('library_width'),
                value: column.width,
                onChanged: (value) => onChanged(_copyColumn(width: value)),
              ),
              _NumberField(
                fieldKey: Key('column${index}ThicknessField'),
                width: fieldWidth,
                label: context.tr('project_thickness'),
                value: column.thickness,
                onChanged: (value) => onChanged(_copyColumn(thickness: value)),
              ),
              _NumberField(
                fieldKey: Key('column${index}QuantityField'),
                width: fieldWidth,
                label: context.tr('project_quantity'),
                value: column.quantity.toDouble(),
                integer: true,
                suffix: '',
                onChanged: (value) =>
                    onChanged(_copyColumn(quantity: value.toInt())),
              ),
              _NumberField(
                fieldKey: Key('column${index}BarsField'),
                width: fieldWidth,
                label: context.tr('project_main_bars_count'),
                value: column.mainBarsCount.toDouble(),
                integer: true,
                suffix: '',
                onChanged: (value) =>
                    onChanged(_copyColumn(mainBarsCount: value.toInt())),
              ),
              SizedBox(
                width: constraints.maxWidth,
                child: DropdownButtonFormField<int>(
                  initialValue: column.mainBarDiameter,
                  decoration: InputDecoration(
                    labelText: context.tr('project_main_steel'),
                    border: projectStepInputBorder,
                  ),
                  items: const [14, 16, 18, 20, 22]
                      .map(
                        (diameter) => DropdownMenuItem(
                          value: diameter,
                          child: Text('D$diameter'),
                        ),
                      )
                      .toList(),
                  onChanged: (diameter) {
                    if (diameter != null) {
                      onChanged(_copyColumn(mainBarDiameter: diameter));
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  ColumnSpec _copyColumn({
    double? width,
    double? thickness,
    int? quantity,
    int? mainBarsCount,
    int? mainBarDiameter,
  }) {
    return ColumnSpec(
      width: width ?? column.width,
      thickness: thickness ?? column.thickness,
      quantity: quantity ?? column.quantity,
      mainBarsCount: mainBarsCount ?? column.mainBarsCount,
      mainBarDiameter: mainBarDiameter ?? column.mainBarDiameter,
    );
  }
}

class _PileCapEditor extends StatelessWidget {
  const _PileCapEditor({
    super.key,
    required this.index,
    required this.value,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final PileCapSpec value;
  final bool canRemove;
  final ValueChanged<PileCapSpec> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return _EditorSurface(
      title: '${context.tr('project_pile_cap')} ${index + 1}',
      canRemove: canRemove,
      onRemove: onRemove,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fieldWidth = (constraints.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _NumberField(
                fieldKey: Key('pile${index}LengthField'),
                width: fieldWidth,
                label: context.tr('library_length'),
                value: value.length,
                onChanged: (number) => onChanged(
                  PileCapSpec(
                    length: number,
                    width: value.width,
                    height: value.height,
                  ),
                ),
              ),
              _NumberField(
                fieldKey: Key('pile${index}WidthField'),
                width: fieldWidth,
                label: context.tr('library_width'),
                value: value.width,
                onChanged: (number) => onChanged(
                  PileCapSpec(
                    length: value.length,
                    width: number,
                    height: value.height,
                  ),
                ),
              ),
              _NumberField(
                fieldKey: Key('pile${index}HeightField'),
                width: fieldWidth,
                label: context.tr('library_height'),
                value: value.height,
                onChanged: (number) => onChanged(
                  PileCapSpec(
                    length: value.length,
                    width: value.width,
                    height: number,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  const _SelectionTile({
    required this.width,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onPressed,
  });

  final double width;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return SizedBox(
      width: width,
      height: 58,
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.10)
            : Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? accent : Theme.of(context).dividerColor,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(icon, color: selected ? accent : null),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: selected ? accent : null,
                          fontWeight: selected ? FontWeight.w700 : null,
                        ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: accent,
                    size: 19,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorSurface extends StatelessWidget {
  const _EditorSurface({
    required this.title,
    required this.canRemove,
    required this.onRemove,
    required this.child,
  });

  final String title;
  final bool canRemove;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              if (canRemove)
                IconButton(
                  tooltip: context.tr('delete'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.fieldKey,
    required this.width,
    required this.label,
    required this.value,
    required this.onChanged,
    this.integer = false,
    this.suffix = 'm',
  });

  final Key fieldKey;
  final double width;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final bool integer;
  final String suffix;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String _text(double value) =>
      widget.integer ? value.toInt().toString() : _format(value);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _text(widget.value));
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(_NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Chỉ đồng bộ giá trị bên ngoài khi ô không đang được nhập, tránh việc
    // rebuild sau mỗi ký tự làm reset text (VD: gõ "3." bị xóa dấu chấm).
    if (!_focusNode.hasFocus && widget.value != oldWidget.value) {
      final next = _text(widget.value);
      if (_controller.text != next) {
        _controller.text = next;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextFormField(
        key: widget.fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.numberWithOptions(decimal: !widget.integer),
        onChanged: (text) => widget.onChanged(_parse(text)),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: widget.suffix.isEmpty ? null : widget.suffix,
          border: projectStepInputBorder,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onAdd});

  final String title;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton.filledTonal(
          tooltip: context.tr('library_add_short'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Row(
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ValidationNotice extends StatelessWidget {
  const _ValidationNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}

class _StepHeading extends StatelessWidget {
  const _StepHeading({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 7),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

double _parse(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

String _format(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();
