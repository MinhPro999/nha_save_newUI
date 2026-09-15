import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_step_input_border.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class ProjectDetailsStep extends StatelessWidget {
  const ProjectDetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectWizardCubit, ProjectWizardState>(
      builder: (context, state) {
        final details = state.details;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              title: context.tr('project_details_title'),
              description: context.tr('project_details_description'),
            ),
            const SizedBox(height: 18),
            _SummaryStrip(state: state),
            const SizedBox(height: 22),
            _DetailSection(
              addButtonKey: const Key('addFoundationSegmentButton'),
              title: context.tr('project_foundation_segments'),
              description: context.tr('project_foundation_segments_hint'),
              icon: Icons.straighten_rounded,
              onAdd: () => _update(
                context,
                details,
                foundationSegments: [
                  ...details.foundationSegments,
                  const FoundationSegment(1),
                ],
              ),
              children: [
                for (var index = 0;
                    index < details.foundationSegments.length;
                    index++)
                  _SingleNumberEditor(
                    key: ValueKey('foundationSegment$index'),
                    title: '${context.tr('project_segment')} ${index + 1}',
                    fieldKey: Key('foundationSegment${index}LengthField'),
                    label: context.tr('project_length'),
                    suffix: 'm',
                    value: details.foundationSegments[index].length,
                    onChanged: (value) {
                      final items = [...details.foundationSegments]..[index] =
                          FoundationSegment(value);
                      _update(context, details, foundationSegments: items);
                    },
                    onRemove: () {
                      final items = [...details.foundationSegments]
                        ..removeAt(index);
                      _update(context, details, foundationSegments: items);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              addButtonKey: const Key('addWallButton'),
              title: context.tr('project_walls'),
              description: context.tr('project_walls_hint'),
              icon: Icons.view_module_outlined,
              onAdd: () => _update(
                context,
                details,
                walls: [
                  ...details.walls,
                  const WallSpec(
                    type: WallType.wall100,
                    plasterSides: 2,
                    length: 1,
                    height: 3.3,
                  ),
                ],
              ),
              children: [
                for (var index = 0; index < details.walls.length; index++)
                  _WallEditor(
                    key: ValueKey('wall$index'),
                    index: index,
                    value: details.walls[index],
                    onChanged: (value) {
                      final items = [...details.walls]..[index] = value;
                      _update(context, details, walls: items);
                    },
                    onRemove: () {
                      final items = [...details.walls]..removeAt(index);
                      _update(context, details, walls: items);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              addButtonKey: const Key('addOpeningButton'),
              title: context.tr('project_openings'),
              description: context.tr('project_openings_hint'),
              icon: Icons.door_front_door_outlined,
              onAdd: () => _update(
                context,
                details,
                openings: [
                  ...details.openings,
                  const OpeningSpec(
                    type: OpeningType.window,
                    width: 1.2,
                    height: 1.4,
                    quantity: 1,
                  ),
                ],
              ),
              children: [
                for (var index = 0; index < details.openings.length; index++)
                  _OpeningEditor(
                    key: ValueKey('opening$index'),
                    index: index,
                    value: details.openings[index],
                    onChanged: (value) {
                      final items = [...details.openings]..[index] = value;
                      _update(context, details, openings: items);
                    },
                    onRemove: () {
                      final items = [...details.openings]..removeAt(index);
                      _update(context, details, openings: items);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              addButtonKey: const Key('addBathroomButton'),
              title: context.tr('project_bathrooms'),
              description: context.tr('project_bathrooms_hint'),
              icon: Icons.bathtub_outlined,
              onAdd: () => _update(
                context,
                details,
                bathrooms: [
                  ...details.bathrooms,
                  const BathroomSpec(4),
                ],
              ),
              children: [
                for (var index = 0; index < details.bathrooms.length; index++)
                  _SingleNumberEditor(
                    key: ValueKey('bathroom$index'),
                    title: '${context.tr('project_bathroom')} ${index + 1}',
                    fieldKey: Key('bathroom${index}AreaField'),
                    label: context.tr('project_area'),
                    suffix: 'm²',
                    value: details.bathrooms[index].area,
                    onChanged: (value) {
                      final items = [...details.bathrooms]..[index] =
                          BathroomSpec(value);
                      _update(context, details, bathrooms: items);
                    },
                    onRemove: () {
                      final items = [...details.bathrooms]..removeAt(index);
                      _update(context, details, bathrooms: items);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            _DetailSection(
              addButtonKey: const Key('addStairButton'),
              title: context.tr('project_stairs'),
              description: context.tr('project_stairs_hint'),
              icon: Icons.stairs_outlined,
              onAdd: () => _update(
                context,
                details,
                stairs: [...details.stairs, const StairSpec(18)],
              ),
              children: [
                for (var index = 0; index < details.stairs.length; index++)
                  _SingleNumberEditor(
                    key: ValueKey('stair$index'),
                    title: '${context.tr('project_stair')} ${index + 1}',
                    fieldKey: Key('stair${index}StepsField'),
                    label: context.tr('project_steps'),
                    suffix: '',
                    integer: true,
                    value: details.stairs[index].steps.toDouble(),
                    onChanged: (value) {
                      final items = [...details.stairs]..[index] =
                          StairSpec(value.toInt());
                      _update(context, details, stairs: items);
                    },
                    onRemove: () {
                      final items = [...details.stairs]..removeAt(index);
                      _update(context, details, stairs: items);
                    },
                  ),
              ],
            ),
            if (state.showValidation && !state.isStepValid(4)) ...[
              const SizedBox(height: 16),
              _ValidationNotice(text: context.tr('project_details_invalid')),
            ],
          ],
        );
      },
    );
  }

  void _update(
    BuildContext context,
    ProjectDetails current, {
    List<FoundationSegment>? foundationSegments,
    List<WallSpec>? walls,
    List<OpeningSpec>? openings,
    List<BathroomSpec>? bathrooms,
    List<StairSpec>? stairs,
  }) {
    context.read<ProjectWizardCubit>().updateDetails(
          ProjectDetails(
            foundationSegments:
                foundationSegments ?? current.foundationSegments,
            walls: walls ?? current.walls,
            openings: openings ?? current.openings,
            bathrooms: bathrooms ?? current.bathrooms,
            stairs: stairs ?? current.stairs,
          ),
        );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.state});

  final ProjectWizardState state;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    final floorArea = state.floors.fold<double>(
      0,
      (total, floor) => total + floor.area,
    );
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              value: '${state.floors.length}',
              label: context.tr('project_floors_section'),
            ),
          ),
          Container(
              width: 1, height: 36, color: Theme.of(context).dividerColor),
          Expanded(
            child: _SummaryItem(
              value: '${floorArea.toStringAsFixed(1)} m²',
              label: context.tr('project_total_floor_area'),
            ),
          ),
          Container(
              width: 1, height: 36, color: Theme.of(context).dividerColor),
          Expanded(
            child: _SummaryItem(
              value: '${state.materials.length}',
              label: context.tr('project_materials_selected'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.addButtonKey,
    required this.title,
    required this.description,
    required this.icon,
    required this.onAdd,
    required this.children,
  });

  final Key addButtonKey;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onAdd;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                key: addButtonKey,
                tooltip: context.tr('library_add_short'),
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          if (children.isEmpty) ...[
            const SizedBox(height: 10),
            Text(
              context.tr('project_no_details_yet'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ] else ...[
            const SizedBox(height: 12),
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _WallEditor extends StatelessWidget {
  const _WallEditor({
    super.key,
    required this.index,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final WallSpec value;
  final ValueChanged<WallSpec> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return _Editor(
      title: '${context.tr('project_wall')} ${index + 1}',
      onRemove: onRemove,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<WallType>(
                  initialValue: value.type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('project_wall_type'),
                    border: projectStepInputBorder,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: WallType.wall100,
                      child: Text(context.tr('project_wall_100')),
                    ),
                    DropdownMenuItem(
                      value: WallType.wall200,
                      child: Text(context.tr('project_wall_200')),
                    ),
                  ],
                  onChanged: (type) {
                    if (type != null) onChanged(_copy(type: type));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: value.plasterSides,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.tr('project_plaster_sides'),
                    border: projectStepInputBorder,
                  ),
                  items: const [0, 1, 2]
                      .map(
                        (number) => DropdownMenuItem(
                          value: number,
                          child: Text('$number'),
                        ),
                      )
                      .toList(),
                  onChanged: (number) {
                    if (number != null) {
                      onChanged(_copy(plasterSides: number));
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NumberField(
                  fieldKey: Key('wall${index}LengthField'),
                  label: context.tr('project_length'),
                  suffix: 'm',
                  value: value.length,
                  onChanged: (number) => onChanged(_copy(length: number)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NumberField(
                  fieldKey: Key('wall${index}HeightField'),
                  label: context.tr('library_height'),
                  suffix: 'm',
                  value: value.height,
                  onChanged: (number) => onChanged(_copy(height: number)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${context.tr('project_area')}: ${value.area.toStringAsFixed(2)} m²',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  WallSpec _copy({
    WallType? type,
    int? plasterSides,
    double? length,
    double? height,
  }) {
    return WallSpec(
      type: type ?? value.type,
      plasterSides: plasterSides ?? value.plasterSides,
      length: length ?? value.length,
      height: height ?? value.height,
    );
  }
}

class _OpeningEditor extends StatelessWidget {
  const _OpeningEditor({
    super.key,
    required this.index,
    required this.value,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final OpeningSpec value;
  final ValueChanged<OpeningSpec> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    return _Editor(
      title: '${context.tr('project_opening')} ${index + 1}',
      onRemove: onRemove,
      child: Column(
        children: [
          DropdownButtonFormField<OpeningType>(
            initialValue: value.type,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: context.tr('project_opening_type'),
              border: projectStepInputBorder,
            ),
            items: [
              DropdownMenuItem(
                value: OpeningType.window,
                child: Text(context.tr('project_window')),
              ),
              DropdownMenuItem(
                value: OpeningType.door,
                child: Text(context.tr('project_door')),
              ),
              DropdownMenuItem(
                value: OpeningType.rollingDoor,
                child: Text(context.tr('project_rolling_door')),
              ),
            ],
            onChanged: (type) {
              if (type != null) onChanged(_copy(type: type));
            },
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 16) / 3;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: width,
                    child: _NumberField(
                      fieldKey: Key('opening${index}WidthField'),
                      label: context.tr('library_width'),
                      suffix: 'm',
                      value: value.width,
                      onChanged: (number) => onChanged(_copy(width: number)),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _NumberField(
                      fieldKey: Key('opening${index}HeightField'),
                      label: context.tr('library_height'),
                      suffix: 'm',
                      value: value.height,
                      onChanged: (number) => onChanged(_copy(height: number)),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _NumberField(
                      fieldKey: Key('opening${index}QuantityField'),
                      label: context.tr('project_quantity'),
                      suffix: '',
                      integer: true,
                      value: value.quantity.toDouble(),
                      onChanged: (number) =>
                          onChanged(_copy(quantity: number.toInt())),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 7),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${context.tr('project_area')}: ${value.area.toStringAsFixed(2)} m²',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: accent,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  OpeningSpec _copy({
    OpeningType? type,
    double? width,
    double? height,
    int? quantity,
  }) {
    return OpeningSpec(
      type: type ?? value.type,
      width: width ?? value.width,
      height: height ?? value.height,
      quantity: quantity ?? value.quantity,
    );
  }
}

class _SingleNumberEditor extends StatelessWidget {
  const _SingleNumberEditor({
    super.key,
    required this.title,
    required this.fieldKey,
    required this.label,
    required this.suffix,
    required this.value,
    required this.onChanged,
    required this.onRemove,
    this.integer = false,
  });

  final String title;
  final Key fieldKey;
  final String label;
  final String suffix;
  final double value;
  final ValueChanged<double> onChanged;
  final VoidCallback onRemove;
  final bool integer;

  @override
  Widget build(BuildContext context) {
    return _Editor(
      title: title,
      onRemove: onRemove,
      child: _NumberField(
        fieldKey: fieldKey,
        label: label,
        suffix: suffix,
        value: value,
        integer: integer,
        onChanged: onChanged,
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.title,
    required this.onRemove,
    required this.child,
  });

  final String title;
  final VoidCallback onRemove;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  tooltip: context.tr('delete'),
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.fieldKey,
    required this.label,
    required this.suffix,
    required this.value,
    required this.onChanged,
    this.integer = false,
  });

  final Key fieldKey;
  final String label;
  final String suffix;
  final double value;
  final ValueChanged<double> onChanged;
  final bool integer;

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
    return TextFormField(
      key: widget.fieldKey,
      controller: _controller,
      focusNode: _focusNode,
      keyboardType: TextInputType.numberWithOptions(decimal: !widget.integer),
      onChanged: (text) => widget.onChanged(_parse(text)),
      decoration: InputDecoration(
        labelText: widget.label,
        suffixText: widget.suffix.isEmpty ? null : widget.suffix,
        border: projectStepInputBorder,
      ),
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
