import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_step_input_border.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class ProjectFloorsRoofStep extends StatelessWidget {
  const ProjectFloorsRoofStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectWizardCubit, ProjectWizardState>(
      builder: (context, state) {
        final cubit = context.read<ProjectWizardCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              title: context.tr('project_floors_title'),
              description: context.tr('project_floors_description'),
            ),
            const SizedBox(height: 22),
            _SectionHeader(
              title: context.tr('project_floors_section'),
              icon: Icons.layers_outlined,
              onAdd: cubit.addFloor,
            ),
            const SizedBox(height: 10),
            for (var index = 0; index < state.floors.length; index++) ...[
              _FloorEditor(
                key: ValueKey('floorEditor${state.floors[index].number}'),
                floor: state.floors[index],
                canRemove: state.floors.length > 1,
                onChanged: (floor) => cubit.updateFloor(index, floor),
                onRemove: () => cubit.removeFloor(index),
              ),
              if (index < state.floors.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 24),
            Text(
              context.tr('project_roof_section'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<RoofType>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: RoofType.flat,
                  icon: const Icon(Icons.horizontal_rule_rounded),
                  label: Text(context.tr('project_roof_flat')),
                ),
                ButtonSegment(
                  value: RoofType.metal,
                  icon: const Icon(Icons.roofing_outlined),
                  label: Text(context.tr('project_roof_metal')),
                ),
                ButtonSegment(
                  value: RoofType.tile,
                  icon: const Icon(Icons.other_houses_outlined),
                  label: Text(context.tr('project_roof_tile')),
                ),
              ],
              selected: {state.roof.type},
              onSelectionChanged: (selection) {
                cubit.updateRoof(
                  RoofSpec(
                    type: selection.first,
                    length: state.roof.length,
                    width: state.roof.width,
                    height: state.roof.height,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _DimensionFields(
              keyPrefix: 'roof',
              length: state.roof.length,
              width: state.roof.width,
              height: state.roof.height,
              onChanged: (length, width, height) {
                cubit.updateRoof(
                  RoofSpec(
                    type: state.roof.type,
                    length: length,
                    width: width,
                    height: height,
                  ),
                );
              },
            ),
            if (state.showValidation && !state.isStepValid(1)) ...[
              const SizedBox(height: 16),
              _ValidationNotice(text: context.tr('project_floors_invalid')),
            ],
          ],
        );
      },
    );
  }
}

class _FloorEditor extends StatelessWidget {
  const _FloorEditor({
    super.key,
    required this.floor,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final BuildingFloor floor;
  final bool canRemove;
  final ValueChanged<BuildingFloor> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${context.tr('project_floor')} ${floor.number}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                Text(
                  '${floor.area.toStringAsFixed(1)} m²',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accent,
                      ),
                ),
                if (canRemove) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: context.tr('delete'),
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _DimensionFields(
              keyPrefix: 'floor${floor.number}',
              length: floor.length,
              width: floor.width,
              height: floor.height,
              onChanged: (length, width, height) => onChanged(
                BuildingFloor(
                  number: floor.number,
                  length: length,
                  width: width,
                  height: height,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DimensionFields extends StatelessWidget {
  const _DimensionFields({
    required this.keyPrefix,
    required this.length,
    required this.width,
    required this.height,
    required this.onChanged,
  });

  final String keyPrefix;
  final double length;
  final double width;
  final double height;
  final void Function(double length, double width, double height) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fieldWidth = (constraints.maxWidth - 16) / 3;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _NumberField(
              fieldKey: Key('${keyPrefix}LengthField'),
              width: fieldWidth,
              label: context.tr('library_length'),
              value: length,
              onChanged: (value) => onChanged(value, width, height),
            ),
            _NumberField(
              fieldKey: Key('${keyPrefix}WidthField'),
              width: fieldWidth,
              label: context.tr('library_width'),
              value: width,
              onChanged: (value) => onChanged(length, value, height),
            ),
            _NumberField(
              fieldKey: Key('${keyPrefix}HeightField'),
              width: fieldWidth,
              label: context.tr('library_height'),
              value: height,
              onChanged: (value) => onChanged(length, width, value),
            ),
          ],
        );
      },
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
  });

  final Key fieldKey;
  final double width;
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  String _text(double value) => value == 0 ? '' : _format(value);

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
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (text) => widget.onChanged(_parse(text)),
        decoration: InputDecoration(
          labelText: widget.label,
          suffixText: 'm',
          border: projectStepInputBorder,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onAdd,
  });

  final String title;
  final IconData icon;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Row(
      children: [
        Icon(icon, color: accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        IconButton.filledTonal(
          key: const Key('addFloorButton'),
          tooltip: context.tr('library_add_short'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
        ),
      ],
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

double _parse(String value) {
  return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
}

String _format(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
