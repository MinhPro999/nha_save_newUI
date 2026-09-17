// Sync oracle sources: verify legacy SHA + copy byte-exact 17 file calculation
// legacy vào tool/golden/oracle_src/ (giữ layout tương đối). KHÔNG sửa legacy repo.
//
// Chạy: dart run tool/golden/sync_oracle.dart [legacyRepoPath]
import 'dart:io';

const expectedSha = 'e5fc8943daaab5953c75bd161061cd83a934b5fd';

const legacyFileMap = <String, String>{
  'lib/services/material_calculator.dart':
      'oracle_src/services/material_calculator.dart',
  'lib/services/foundation_structure_calculator.dart':
      'oracle_src/services/foundation_structure_calculator.dart',
  'lib/services/constants/construction_constants.dart':
      'oracle_src/services/constants/construction_constants.dart',
  'lib/services/utils/calculation_utils.dart':
      'oracle_src/services/utils/calculation_utils.dart',
  'lib/utils/number_formatter.dart': 'oracle_src/utils/number_formatter.dart',
  'lib/models/brick.dart': 'oracle_src/models/brick.dart',
  'lib/models/material_model.dart': 'oracle_src/models/material_model.dart',
  'lib/models/project/foundation_structure_model.dart':
      'oracle_src/models/project/foundation_structure_model.dart',
  'lib/services/calculators/brick_calculator.dart':
      'oracle_src/services/calculators/brick_calculator.dart',
  'lib/services/calculators/cement_calculator.dart':
      'oracle_src/services/calculators/cement_calculator.dart',
  'lib/services/calculators/custom_material_calculator.dart':
      'oracle_src/services/calculators/custom_material_calculator.dart',
  'lib/services/calculators/door_calculator.dart':
      'oracle_src/services/calculators/door_calculator.dart',
  'lib/services/calculators/paint_calculator.dart':
      'oracle_src/services/calculators/paint_calculator.dart',
  'lib/services/calculators/sand_calculator.dart':
      'oracle_src/services/calculators/sand_calculator.dart',
  'lib/services/calculators/steel_calculator.dart':
      'oracle_src/services/calculators/steel_calculator.dart',
  'lib/services/calculators/stone_calculator.dart':
      'oracle_src/services/calculators/stone_calculator.dart',
  'lib/services/calculators/tile_calculator.dart':
      'oracle_src/services/calculators/tile_calculator.dart',
};

Future<void> main(List<String> args) async {
  final root =
      Directory(File.fromUri(Platform.script).parent.path).parent.parent;
  final legacyPath =
      args.isNotEmpty ? args.first : '/Users/m.mac/app_dev/nha_save';

  final shaResult = await Process.run(
    'git',
    ['-C', legacyPath, 'rev-parse', 'HEAD'],
  );
  if (shaResult.exitCode != 0) {
    stderr.writeln('Không đọc được git SHA từ $legacyPath');
    exitCode = 1;
    return;
  }
  final sha = (shaResult.stdout as String).trim();
  if (sha != expectedSha) {
    stderr.writeln('SHA $sha KHÔNG khớp expected $expectedSha — TỪ CHỐI sync.');
    exitCode = 1;
    return;
  }
  stdout.writeln('Legacy SHA verified: $sha');

  final oracleDir = Directory('${root.path}/tool/golden/oracle_src');
  if (oracleDir.existsSync()) {
    oracleDir.deleteSync(recursive: true);
  }
  for (final entry in legacyFileMap.entries) {
    final source = File('$legacyPath/${entry.key}');
    final target = File('${root.path}/tool/golden/${entry.value}');
    target.parent.createSync(recursive: true);
    target.writeAsBytesSync(source.readAsBytesSync());
  }
  stdout.writeln(
    'Copied ${legacyFileMap.length} legacy files -> tool/golden/oracle_src',
  );
}
