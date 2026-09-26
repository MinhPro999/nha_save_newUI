import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/common/widgets/media/image_source_bottom_sheet.dart';
import 'package:flutter_core_project/common/widgets/sheets/app_bottom_sheet_header.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/core/data/vietnam_districts.dart';
import 'package:flutter_core_project/core/data/vietnam_provinces.dart';
import 'package:flutter_core_project/features/projects/data/project_cover_image_service.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_cubit.dart';
import 'package:flutter_core_project/features/projects/presentation/bloc/project_wizard_state.dart';
import 'package:flutter_core_project/features/projects/presentation/widgets/project_step_input_border.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:image_picker/image_picker.dart';

class ProjectBasicStep extends StatefulWidget {
  const ProjectBasicStep({super.key});

  @override
  State<ProjectBasicStep> createState() => _ProjectBasicStepState();
}

class _ProjectBasicStepState extends State<ProjectBasicStep> {
  final ImagePicker _imagePicker = ImagePicker();
  final ProjectCoverImageService _imageService =
      const ProjectCoverImageService();
  final TextEditingController _nameController = TextEditingController();
  bool _processingImage = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = context.read<ProjectWizardCubit>().state.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _chooseImage() async {
    final source = await showImageSourceBottomSheet(context);
    if (source == null || !mounted) return;

    setState(() => _processingImage = true);
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 2400,
        maxHeight: 2400,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (image == null) return;

      final savedPath = await _imageService.persistCompressed(image);
      if (!mounted) return;
      final cubit = context.read<ProjectWizardCubit>();
      final previousPath = cubit.state.imagePath;
      cubit.setImage(savedPath);
      if (!cubit.isEditing || previousPath != cubit.originalImagePath) {
        await _imageService.delete(previousPath);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('project_image_error'))),
        );
      }
    } finally {
      if (mounted) setState(() => _processingImage = false);
    }
  }

  Future<void> _removeImage(String imagePath) async {
    final cubit = context.read<ProjectWizardCubit>();
    cubit.setImage(null);
    if (!cubit.isEditing || imagePath != cubit.originalImagePath) {
      await _imageService.delete(imagePath);
    }
  }

  Future<void> _chooseProvince(ProjectWizardState state) async {
    final province = await showModalBottomSheet<VietnamProvince>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: _ProvincePickerSheet(
            selectedProvince: state.provinceName ?? '',
          ),
        ),
      ),
    );
    if (province == null || !mounted) return;

    final previousDistrictId =
        state.provinceId == province.id ? state.districtId : null;
    context.read<ProjectWizardCubit>().selectProvince(province);
    await _chooseDistrict(province, previousDistrictId);
  }

  Future<void> _chooseCurrentProvinceDistrict(ProjectWizardState state) async {
    VietnamProvince? province;
    for (final item in vietnamProvinces) {
      if (item.id == state.provinceId) {
        province = item;
        break;
      }
    }
    if (province == null) {
      await _chooseProvince(state);
      return;
    }
    await _chooseDistrict(province, state.districtId);
  }

  Future<void> _chooseDistrict(
    VietnamProvince province,
    String? selectedDistrictId,
  ) async {
    final districts = await VietnamDistrictCatalog.forProvince(province.id);
    if (!mounted) return;
    if (districts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('project_district_load_error'))),
      );
      return;
    }

    final district = await showModalBottomSheet<VietnamDistrict>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: _DistrictPickerSheet(
            province: province,
            districts: districts,
            selectedDistrictId: selectedDistrictId,
          ),
        ),
      ),
    );
    if (district != null && mounted) {
      context.read<ProjectWizardCubit>().selectDistrict(district);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectWizardCubit, ProjectWizardState>(
      builder: (context, state) {
        final cubit = context.read<ProjectWizardCubit>();
        final accent = AppColors.linearShapeFor(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _StepHeading(
              title: context.tr('project_basic_title'),
              description: context.tr('project_basic_description'),
            ),
            const SizedBox(height: 22),
            InkWell(
              key: const Key('projectImagePicker'),
              onTap: _processingImage ? null : _chooseImage,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 154,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.38),
                  ),
                ),
                child: state.imagePath == null
                    ? Center(
                        child: _processingImage
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    color: accent,
                                    size: 34,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    context.tr('project_choose_image'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(color: accent),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    context.tr('project_image_optional'),
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                      )
                    : Stack(
                        fit: StackFit.expand,
                        children: [
                          if (!kIsWeb)
                            Image.file(
                              File(state.imagePath!),
                              fit: BoxFit.cover,
                            ),
                          if (_processingImage)
                            const ColoredBox(
                              color: Color(0x66000000),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: IconButton.filledTonal(
                              tooltip: context.tr('delete'),
                              onPressed: _processingImage
                                  ? null
                                  : () => _removeImage(state.imagePath!),
                              icon: const Icon(Icons.delete_outline_rounded),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              key: const Key('projectNameField'),
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (value) => cubit.updateBasicInfo(name: value),
              decoration: InputDecoration(
                labelText: context.tr('project_name'),
                hintText: context.tr('project_name_hint'),
                prefixIcon: const Icon(Icons.home_work_outlined),
                errorText: state.showValidation && state.name.trim().isEmpty
                    ? context.tr('project_name_required')
                    : null,
                border: projectStepInputBorder,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('projectLocationField'),
              onTap: () => _chooseProvince(state),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                isEmpty: state.provinceName == null,
                decoration: InputDecoration(
                  labelText: context.tr('project_province_field'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  errorText: state.showValidation &&
                          (state.provinceName == null ||
                              state.provinceName!.trim().isEmpty)
                      ? context.tr('project_location_required')
                      : null,
                  border: projectStepInputBorder,
                ),
                child: Text(
                  state.provinceName ??
                      (state.provinceId == null && state.location.isNotEmpty
                          ? state.location
                          : context.tr('project_province_hint')),
                  style: state.provinceName == null && state.location.isEmpty
                      ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).hintColor,
                          )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              key: const Key('projectDistrictField'),
              onTap: () => _chooseCurrentProvinceDistrict(state),
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                isEmpty: state.districtName == null,
                decoration: InputDecoration(
                  labelText: context.tr('project_district_field'),
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  prefixIcon: const Icon(Icons.map_outlined),
                  suffixIcon: const Icon(Icons.keyboard_arrow_down_rounded),
                  errorText: state.showValidation &&
                          state.provinceId != null &&
                          state.districtId == null
                      ? context.tr('project_district_required')
                      : null,
                  border: projectStepInputBorder,
                ),
                child: Text(
                  state.districtName ?? context.tr('project_district_hint'),
                  style: state.districtName == null
                      ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Theme.of(context).hintColor,
                          )
                      : Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProvincePickerSheet extends StatefulWidget {
  const _ProvincePickerSheet({required this.selectedProvince});

  final String selectedProvince;

  @override
  State<_ProvincePickerSheet> createState() => _ProvincePickerSheetState();
}

class _ProvincePickerSheetState extends State<_ProvincePickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<VietnamProvince> _filteredProvinces = vietnamProvinces;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedItem());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSelectedItem() {
    if (!_scrollController.hasClients || widget.selectedProvince.isEmpty) {
      return;
    }
    final index = vietnamProvinces.indexWhere(
      (province) => province.name == widget.selectedProvince,
    );
    if (index < 0) return;
    final target = (index * 56.0 - 112).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  void _search(String query) {
    final normalizedQuery = _normalizeVietnamese(query.trim());
    setState(() {
      _filteredProvinces = normalizedQuery.isEmpty
          ? vietnamProvinces
          : vietnamProvinces
              .where(
                (province) => _normalizeVietnamese(province.name).contains(
                  normalizedQuery,
                ),
              )
              .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return SizedBox(
      height: height.clamp(480.0, 720.0),
      child: Column(
        children: [
          AppBottomSheetHeader(
            title: context.tr('project_select_province'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: SizedBox(
              height: 44,
              child: TextField(
                key: const Key('provinceSearchField'),
                controller: _searchController,
                autofocus: false,
                textInputAction: TextInputAction.search,
                onChanged: _search,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  hintText: context.tr('project_search_province'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('clear'),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.65),
                      width: 0.7,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredProvinces.isEmpty
                ? Center(child: Text(context.tr('project_province_not_found')))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _filteredProvinces.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 20,
                      endIndent: 20,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.72),
                    ),
                    itemBuilder: (context, index) {
                      final province = _filteredProvinces[index];
                      final selected = province.name == widget.selectedProvince;
                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          key: Key('province_${province.id}'),
                          selected: selected,
                          selectedTileColor: accent.withValues(alpha: 0.055),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          visualDensity: const VisualDensity(vertical: -1),
                          title: Text(
                            province.name,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                          ),
                          leading: Icon(
                            Icons.location_on_rounded,
                            size: 21,
                            color: selected
                                ? accent
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: accent,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, province),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DistrictPickerSheet extends StatefulWidget {
  const _DistrictPickerSheet({
    required this.province,
    required this.districts,
    required this.selectedDistrictId,
  });

  final VietnamProvince province;
  final List<VietnamDistrict> districts;
  final String? selectedDistrictId;

  @override
  State<_DistrictPickerSheet> createState() => _DistrictPickerSheetState();
}

class _DistrictPickerSheetState extends State<_DistrictPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<VietnamDistrict> _filteredDistricts;

  bool get _showsLegacyProvince =>
      widget.districts.map((item) => item.legacyProvinceName).toSet().length >
      1;

  @override
  void initState() {
    super.initState();
    _filteredDistricts = widget.districts;
    WidgetsBinding.instance.addPostFrameCallback((_) => _showSelectedItem());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showSelectedItem() {
    if (!_scrollController.hasClients || widget.selectedDistrictId == null) {
      return;
    }
    final index = widget.districts.indexWhere(
      (district) => district.id == widget.selectedDistrictId,
    );
    if (index < 0) return;
    final itemExtent = _showsLegacyProvince ? 68.0 : 56.0;
    final target = (index * itemExtent - 112).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );
    _scrollController.jumpTo(target);
  }

  void _search(String query) {
    final normalizedQuery = _normalizeVietnamese(query.trim());
    setState(() {
      _filteredDistricts = normalizedQuery.isEmpty
          ? widget.districts
          : widget.districts
              .where(
                (district) => _normalizeVietnamese(
                  '${district.name} ${district.legacyProvinceName}',
                ).contains(normalizedQuery),
              )
              .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.linearShapeFor(context);
    final height = MediaQuery.sizeOf(context).height * 0.82;
    return SizedBox(
      height: height.clamp(480.0, 720.0),
      child: Column(
        children: [
          AppBottomSheetHeader(
            title: context.tr('project_select_district'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: SizedBox(
              height: 44,
              child: TextField(
                key: const Key('districtSearchField'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: _search,
                textAlignVertical: TextAlignVertical.center,
                decoration: InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.55),
                  hintText: context.tr('project_search_district'),
                  prefixIcon: const Icon(Icons.search_rounded, size: 21),
                  prefixIconConstraints: const BoxConstraints(minWidth: 42),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: context.tr('clear'),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                          icon: const Icon(Icons.close_rounded, size: 19),
                        ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.65),
                      width: 0.7,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: accent,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: _filteredDistricts.isEmpty
                ? Center(child: Text(context.tr('project_district_not_found')))
                : ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 20),
                    itemCount: _filteredDistricts.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 0.5,
                      thickness: 0.5,
                      indent: 20,
                      endIndent: 20,
                      color: Theme.of(context)
                          .dividerColor
                          .withValues(alpha: 0.72),
                    ),
                    itemBuilder: (context, index) {
                      final district = _filteredDistricts[index];
                      final selected = district.id == widget.selectedDistrictId;
                      return Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          key: Key('district_${district.id}'),
                          selected: selected,
                          selectedTileColor: accent.withValues(alpha: 0.055),
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          visualDensity: const VisualDensity(vertical: -1),
                          title: Text(
                            district.name,
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: selected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                          ),
                          subtitle: _showsLegacyProvince
                              ? Text(
                                  district.legacyProvinceName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
                          leading: Icon(
                            Icons.location_on_rounded,
                            size: 21,
                            color: selected
                                ? accent
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                          trailing: selected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: accent,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, district),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

String _normalizeVietnamese(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp('[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp('[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp('[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp('[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp('[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp('[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
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
