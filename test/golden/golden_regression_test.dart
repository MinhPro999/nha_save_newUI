import 'dart:convert';
import 'dart:io';

import 'package:flutter_core_project/calculator_core/models/project/foundation_structure_model.dart';
import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_input_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/mock_calculation_service.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/project_calculation_result.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cases/golden_cases.dart';

const _sourceSha = 'e5fc8943daaab5953c75bd161061cd83a934b5fd';

Map<String, dynamic> _loadFixture(String id) {
  final file = File('test/golden/expected/$id.json');
  if (!file.existsSync()) {
    fail(
      'Thiếu fixture $id — chạy: dart run tool/golden/sync_oracle.dart && '
      'dart run tool/golden/generate_expected.dart',
    );
  }
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

bool _deepEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!_deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is num && b is num) return a == b;
  return a == b;
}

String _keyFor(ProjectMaterial material) {
  return LegacyMaterialSelectionKeyMapper.selectionIdFor(
    catalogCode: material.catalogCode,
    name: material.name,
  );
}

void main() {
  group('GATE 6 — GOLDEN REGRESSION (legacy oracle @ e5fc8943)', () {
    for (final c in goldenCases) {
      test(c.id, () {
        final fixture = _loadFixture(c.id);
        expect(fixture['sourceSha'], _sourceSha, reason: 'provenance SHA');
        expect(fixture['caseId'], c.id);

        final issues = <String>[];

        // ── 1. INPUT STAGE: mapper phải tạo đúng canonical legacy input ──
        final materialInput = LegacyInputMapper.mapMaterialInput(c.project);
        if (!_deepEquals(materialInput.detailedParams, c.detailedParams)) {
          issues.add(
            'STAGE: LegacyInputMapper.detailedParams\n'
            '  CANONICAL: ${jsonEncode(c.detailedParams)}\n'
            '  NEW: ${jsonEncode(materialInput.detailedParams)}',
          );
        }
        if (!_deepEquals(
            materialInput.selectedMaterialIds, c.selectedMaterialIds)) {
          issues.add(
            'STAGE: LegacyInputMapper.selectedMaterialIds\n'
            '  LEGACY: ${c.selectedMaterialIds}\n'
            '  NEW: ${materialInput.selectedMaterialIds}',
          );
        }
        if (!_deepEquals(materialInput.brickDimensions, c.brickDimensions)) {
          issues.add(
            'STAGE: LegacyInputMapper.brickDimensions\n'
            '  LEGACY: ${c.brickDimensions}\n'
            '  NEW: ${materialInput.brickDimensions}',
          );
        }
        if (!_deepEquals(materialInput.floors, c.floors)) {
          issues.add(
            'STAGE: LegacyInputMapper.floors\n'
            '  LEGACY: ${jsonEncode(c.floors)}\n'
            '  NEW: ${jsonEncode(materialInput.floors)}',
          );
        }

        // ── 2. NEW PATH ─────────────────────────────────────────────────
        const service = LegacyCalculationService();
        final result = service.calculate(c.project);

        // ── 3. MATERIAL COMPARE ─────────────────────────────────────────
        final expectedQuantities = ((fixture['material']
                        as Map<String, dynamic>)['quantities']
                    as Map<String, dynamic>?)
                ?.map(
                    (key, value) => MapEntry(key, (value as num).toDouble())) ??
            <String, double>{};

        // Actual: line theo key (join qua selection key) + display name.
        final actualByKey = <String, double>{};
        final lineByName = <String, ProjectMaterialLine>{
          for (final line in result.materialLines) line.name: line,
        };
        for (final material in c.project.materials) {
          final key = _keyFor(material);
          final line = lineByName[material.name];
          if (line == null) continue;
          if (actualByKey.containsKey(key)) {
            issues.add('STAGE: LegacyResultMapper — trùng key "$key"');
          }
          actualByKey[key] = line.quantity;
        }

        for (final entry in expectedQuantities.entries) {
          final actual = actualByKey[entry.key];
          if (actual == null) {
            issues.add(
              'FIELD: quantities["${entry.key}"]\n'
              '  LEGACY: ${entry.value}\n'
              '  NEW: (thiếu dòng)\n'
              '  STAGE: LegacyResultMapper',
            );
          } else if (actual != entry.value) {
            issues.add(
              'FIELD: quantities["${entry.key}"]\n'
              '  LEGACY: ${entry.value}\n'
              '  NEW: $actual\n'
              '  DELTA: ${actual - entry.value}\n'
              '  STAGE: LegacyResultMapper/calculator_core',
            );
          }
        }
        for (final entry in actualByKey.entries) {
          if (!expectedQuantities.containsKey(entry.key)) {
            issues.add(
              'FIELD: quantities["${entry.key}"]\n'
              '  LEGACY: (không có)\n'
              '  NEW: ${entry.value}\n'
              '  STAGE: LegacyResultMapper',
            );
          }
        }

        // ── 4. COST CONVENTION ──────────────────────────────────────────
        var expectedTotal = 0.0;
        for (final line in result.materialLines) {
          final lineCost = line.unitPrice * line.quantity;
          expectedTotal += lineCost;
          if (line.cost != lineCost) {
            issues.add(
              'FIELD: cost[${line.name}]\n'
              '  EXPECTED: unitPrice(${line.unitPrice}) × quantity(${line.quantity}) = $lineCost\n'
              '  NEW: ${line.cost}\n'
              '  STAGE: ProjectMaterialLine.cost',
            );
          }
        }
        if (result.totalCost != expectedTotal) {
          issues.add(
            'FIELD: totalCost\n'
            '  EXPECTED: $expectedTotal\n'
            '  NEW: ${result.totalCost}',
          );
        }

        // ── 5. FOUNDATION COMPARE ───────────────────────────────────────
        final expectedFoundation =
            fixture['foundation'] as Map<String, dynamic>?;
        final actualFoundation = result.foundation;
        if (expectedFoundation == null) {
          if (actualFoundation != null) {
            issues.add(
              'FIELD: foundation\n'
              '  LEGACY: null (không chạy foundation)\n'
              '  NEW: ${jsonEncode(actualFoundation.toMap())}\n'
              '  STAGE: LegacyCalculationService',
            );
          }
        } else {
          if (actualFoundation == null) {
            issues.add(
              'FIELD: foundation\n'
              '  LEGACY: ${jsonEncode(expectedFoundation)}\n'
              '  NEW: null\n'
              '  STAGE: LegacyCalculationService',
            );
          } else {
            final actualMap = actualFoundation.toMap();
            for (final entry in expectedFoundation.entries) {
              final actual = actualMap[entry.key];
              final expected = entry.value;
              final bool ok;
              if (actual is int) {
                ok = expected is num && expected.toInt() == actual;
              } else if (actual is double) {
                ok = expected is num && expected.toDouble() == actual;
              } else {
                ok = actual == expected;
              }
              if (!ok) {
                issues.add(
                  'FIELD: foundation.${entry.key}\n'
                  '  LEGACY: $expected\n'
                  '  NEW: $actual\n'
                  '  STAGE: LegacyCalculationService/calculator_core',
                );
              }
            }
            for (final entry in actualMap.entries) {
              if (!expectedFoundation.containsKey(entry.key)) {
                issues.add(
                  'FIELD: foundation.${entry.key}\n'
                  '  LEGACY: (không có)\n'
                  '  NEW: ${entry.value}',
                );
              }
            }
          }
        }

        if (issues.isNotEmpty) {
          fail('CASE: ${c.id}\n${issues.map((i) => '  • $i').join('\n')}');
        }
      });
    }
  });

  group('GATE 6 — STEEL DIAMETER POLICY', () {
    test('null/missing → d16 (legacy default)', () {
      expect(LegacyInputMapper.mapSteelDiameter(null), SteelDiameter.d16);
    });

    for (final invalid in [13, 15, 17, 19, 21, 23, 0]) {
      test('invalid $invalid mm → ArgumentError (KHÔNG silent-map)', () {
        expect(
          () => LegacyInputMapper.mapSteelDiameter(invalid),
          throwsArgumentError,
        );
      });
    }

    test('invalid diameter qua LegacyCalculationService → ArgumentError', () {
      final project = ConstructionProject(
        id: 'p-invalid',
        name: 'Nhà lỗi',
        location: 'Hà Nội',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        floors: const [
          BuildingFloor(number: 1, length: 10, width: 5, height: 3)
        ],
        roof: const RoofSpec(
            type: RoofType.flat, length: 10, width: 5, height: 0),
        foundationStructure: const FoundationStructureSpec(
          foundationType: FoundationType.strip,
          structureType: StructureType.reinforcedConcrete,
          mainBarDiameter: 13,
        ),
        materials: const [],
        details: const ProjectDetails(),
      );
      expect(
        () => const LegacyCalculationService().calculate(project),
        throwsArgumentError,
      );
    });

    test('floors rỗng → ArgumentError (mirror validation legacy step3)', () {
      final project = ConstructionProject(
        id: 'p-empty',
        name: 'Nhà trống',
        location: 'Hà Nội',
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
        floors: const [],
        roof: const RoofSpec(
            type: RoofType.flat, length: 10, width: 5, height: 0),
        foundationStructure: const FoundationStructureSpec(
          foundationType: FoundationType.strip,
          structureType: StructureType.reinforcedConcrete,
          mainBarDiameter: 16,
        ),
        materials: const [],
        details: const ProjectDetails(),
      );
      expect(
        () => const LegacyCalculationService().calculate(project),
        throwsArgumentError,
      );
    });
  });

  group('GATE 6 — BOUNDARY CHECKS', () {
    test(
        'steel/concrete_sand/aluminum_door quantity KHÔNG bị mất (join-by-key)',
        () {
      final steel = goldenCases.firstWhere(
        (c) => c.id == 'golden_material_steel',
      );
      final steelResult =
          const LegacyCalculationService().calculate(steel.project);
      expect(
        steelResult.materialLines.single.name,
        'Sắt thép',
        reason: 'display name giữ nguyên',
      );
      expect(steelResult.materialLines.single.quantity, greaterThan(0));

      final concrete = goldenCases.firstWhere(
        (c) => c.id == 'golden_material_concrete_sand',
      );
      final concreteResult =
          const LegacyCalculationService().calculate(concrete.project);
      expect(concreteResult.materialLines.single.name, 'Cát bê tông');
      expect(concreteResult.materialLines.single.quantity, greaterThan(0));

      final aluminum = goldenCases.firstWhere(
        (c) => c.id == 'golden_material_aluminum_door',
      );
      final aluminumResult =
          const LegacyCalculationService().calculate(aluminum.project);
      expect(aluminumResult.materialLines.single.name, 'Cửa nhôm Xingfa');
      expect(aluminumResult.materialLines.single.quantity, greaterThan(0));
    });

    test(
        'materials không có aggregated key → không sinh quantity (legacy parity)',
        () {
      final c = goldenCases.firstWhere(
        (c) => c.id == 'golden_materials_no_aggregated_key',
      );
      final result = const LegacyCalculationService().calculate(c.project);
      // Chỉ brick (có key) sinh quantity; 6 code không key → không dòng.
      expect(result.materialLines.map((l) => l.name), ['Gạch xây']);
    });

    test('custom material (catalogCode null) → fallback name, không quantity',
        () {
      final c = goldenCases.firstWhere(
        (c) => c.id == 'golden_custom_material_no_code',
      );
      final result = const LegacyCalculationService().calculate(c.project);
      expect(result.materialLines.map((l) => l.name), ['Gạch xây']);
    });

    test('gypsum zero-input → quantity 0.0 theo legacy oracle', () {
      final c = goldenCases.firstWhere(
        (c) => c.id == 'golden_material_gypsum',
      );
      final result = const LegacyCalculationService().calculate(c.project);
      final gypsum = result.materialLines.single;
      expect(gypsum.name, 'Thạch cao');
      expect(gypsum.quantity, 0.0);
      expect(gypsum.cost, 0.0);
    });

    test('brick dimensions runtime parity {0.2, 0.1, 0.05}', () {
      final c = goldenCases.firstWhere(
        (c) => c.id == 'golden_brick_dimensions_runtime',
      );
      final input = LegacyInputMapper.mapMaterialInput(c.project);
      expect(input.brickDimensions, {
        'length': 0.2,
        'width': 0.1,
        'height': 0.05,
      });
    });

    test(
        'mọi golden case: mapper KHÔNG map theo display name khi có catalogCode',
        () {
      for (final c in goldenCases) {
        final input = LegacyInputMapper.mapMaterialInput(c.project);
        expect(
          input.selectedMaterialIds,
          c.selectedMaterialIds,
          reason: 'case ${c.id}',
        );
      }
    });
  });

  group('GATE 7 — DI / MOCK STATUS', () {
    test('production binding là LegacyCalculationService; Mock giữ cho test',
        () async {
      SharedPreferences.setMockInitialValues({});
      await initializeDependencies();
      final sl = GetIt.instance;

      final binding = sl<CalculationService>();
      expect(binding, isA<LegacyCalculationService>());
      expect(binding, isNot(isA<MockCalculationService>()));

      // Mock vẫn tồn tại + inject được cho test/dev.
      expect(sl.isRegistered<MockCalculationService>(), isTrue);
      final mock = sl<MockCalculationService>();
      expect(mock, isA<MockCalculationService>());
      final sample = goldenCases.first;
      expect(mock.calculate(sample.project), isA<ProjectCalculationResult>());
    });
  });
}
