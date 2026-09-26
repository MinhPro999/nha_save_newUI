// Golden expected generator — ORACLE từ legacy authoritative source.
//
// Chạy (theo đúng thứ tự):
//   1. dart run tool/golden/sync_oracle.dart [legacyRepoPath]
//      — verify SHA e5fc8943 + copy 17 file legacy byte-exact vào
//        tool/golden/oracle_src/ (bắt buộc chạy TRƯỚC vì import phải tồn tại
//        lúc compile).
//   2. dart run tool/golden/generate_expected.dart
//      — với mỗi canonical case, chạy TRỰC TIẾP code legacy
//        (MaterialCalculator + FoundationStructureCalculator) để sinh
//        expected result, ghi test/golden/expected/<caseId>.json kèm
//        provenance (sourceSha).
//
// Expected value KHÔNG bao giờ đến từ implementation mới.
import 'dart:convert';
import 'dart:io';

import '../../test/golden/cases/golden_cases.dart';
import 'oracle_src/models/project/foundation_structure_model.dart';
import 'oracle_src/services/foundation_structure_calculator.dart';
import 'oracle_src/services/material_calculator.dart';

const expectedSha = 'e5fc8943daaab5953c75bd161061cd83a934b5fd';

SteelDiameter _diameter(num? value) {
  for (final d in SteelDiameter.values) {
    if (d.value == value) return d;
  }
  throw ArgumentError('Đường kính oracle không hợp lệ: $value');
}

FoundationBangAttribute _attribute(String? name) {
  switch (name) {
    case 'can_2_ben':
      return FoundationBangAttribute.can_2_ben;
    case 'lech_1_ben':
      return FoundationBangAttribute.lech_1_ben;
    case 'lech_2_ben':
      return FoundationBangAttribute.lech_2_ben;
    default:
      throw ArgumentError('Attribute oracle không hợp lệ: $name');
  }
}

FoundationStructureData _buildFoundationData(Map<String, dynamic> spec) {
  final FoundationTypeNew? type = switch (spec['foundationType']) {
    'bang' => FoundationTypeNew.bang,
    'be' => FoundationTypeNew.be,
    'coc' => FoundationTypeNew.coc,
    'coc_pile' => FoundationTypeNew.coc_pile,
    null => null,
    final other => throw ArgumentError('Foundation type không hợp lệ: $other'),
  };

  final columns = <ColumnInfo>[
    for (final c in (spec['columns'] as List? ?? const []))
      ColumnInfo(
        width: (c['width'] as num).toDouble(),
        thickness: (c['thickness'] as num).toDouble(),
        quantity: c['quantity'] as int,
        mainBarsCount: c['mainBarsCount'] as int,
        mainBarDiameter: _diameter(c['mainBarDiameter']),
      ),
  ];

  final diameter = _diameter(spec['mainBarDiameter']);

  return FoundationStructureData(
    foundationType: type,
    columns: columns,
    bangInfo: type == FoundationTypeNew.bang
        ? FoundationBangInfo(
            attribute: _attribute(spec['attribute']),
            mainBarDiameter: diameter,
          )
        : null,
    beInfo: type == FoundationTypeNew.be
        ? FoundationBeInfo(mainBarDiameter: diameter)
        : null,
    cocInfo: type == FoundationTypeNew.coc
        ? FoundationCocInfo(
            length: (spec['cocLength'] as num).toDouble(),
            width: (spec['cocWidth'] as num).toDouble(),
            height: (spec['cocHeight'] as num).toDouble(),
            mainBarDiameter: diameter,
          )
        : null,
    cocPileInfo: type == FoundationTypeNew.coc_pile
        ? FoundationCocPileInfo(
            pileCaps: [
              for (final cap in (spec['pileCaps'] as List? ?? const []))
                FoundationPileCapInfo(
                  length: (cap['length'] as num).toDouble(),
                  width: (cap['width'] as num).toDouble(),
                  height: (cap['height'] as num).toDouble(),
                ),
            ],
            mainBarDiameter: diameter,
          )
        : null,
  );
}

Future<void> main(List<String> args) async {
  final root =
      Directory(File.fromUri(Platform.script).parent.path).parent.parent;

  // ── 0. Verify oracle_src đã sync ────────────────────────────────────
  final oracleMaterial = File(
    '${root.path}/tool/golden/oracle_src/services/material_calculator.dart',
  );
  if (!oracleMaterial.existsSync()) {
    stderr.writeln(
      'Thiếu tool/golden/oracle_src — chạy dart run tool/golden/sync_oracle.dart trước.',
    );
    exitCode = 1;
    return;
  }

  // ── 1. Verify SHA (provenance) ──────────────────────────────────────
  final legacyPath =
      args.isNotEmpty ? args.first : '/Users/m.mac/app_dev/nha_save';
  final shaResult =
      await Process.run('git', ['-C', legacyPath, 'rev-parse', 'HEAD']);
  final sha =
      shaResult.exitCode == 0 ? (shaResult.stdout as String).trim() : 'unknown';
  if (sha != expectedSha) {
    stderr.writeln('SHA $sha KHÔNG khớp expected $expectedSha — TỪ CHỐI chạy.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Legacy SHA verified: $sha');

  // ── 2. Chạy oracle cho từng case ────────────────────────────────────
  final expectedDir = Directory('${root.path}/test/golden/expected');
  expectedDir.createSync(recursive: true);

  for (final c in goldenCases) {
    final materialResults =
        MaterialCalculator.calculateMaterialsFromDetailedParams(
      c.detailedParams,
      selectedMaterialIds: c.selectedMaterialIds,
      brickDimensions: c.brickDimensions,
      floors: c.floors,
    );

    Map<String, dynamic>? foundationMap;
    if (c.foundation != null) {
      final data = _buildFoundationData(c.foundation!);
      final result = FoundationStructureCalculator.calculate(
        foundationData: data,
        l1: c.l1,
        w1: c.w1,
        area1: c.area1,
        hTotal: c.hTotal,
      );
      foundationMap = result.toMap();
    }

    final payload = <String, dynamic>{
      'sourceSha': expectedSha,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'caseId': c.id,
      'material': materialResults,
      'foundation': foundationMap,
    };

    final outFile = File('${expectedDir.path}/${c.id}.json');
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(payload),
    );
  }

  stdout.writeln('Generated ${goldenCases.length} golden expected files.');
}
