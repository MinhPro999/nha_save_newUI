import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';
import 'package:flutter_core_project/features/projects/domain/services/calculation/default_wall_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultWallCalculator — nguồn tính Default Wall duy nhất', () {
    double plasterAreaOf(List<Map<String, dynamic>> entries) {
      return entries.fold<double>(
        0,
        (sum, entry) =>
            sum +
            (entry['length'] as double) *
                (entry['height'] as double) *
                (entry['plasterSides'] as int),
      );
    }

    test(
        '1 tầng L=10 W=8 H=3.3 → tổng diện tích trát = 36 × 3.3 × 2 × 1.5 '
        '= 356.4 m² (khớp công thức Σ[2×(L+W)×H×2×1.5])', () {
      const floors = [
        BuildingFloor(number: 1, length: 10, width: 8, height: 3.3),
      ];
      final entries = DefaultWallCalculator.buildDefaultWallEntries(
        floors: floors,
      );

      expect(entries, hasLength(2));

      // Entry A — "tường bao 20": length = perimeter = 36, height = 3.3.
      expect(entries[0]['type'], '20');
      expect(entries[0]['length'], 36.0);
      expect(entries[0]['height'], 3.3);
      expect(entries[0]['plasterSides'], 2);
      expect(entries[0]['isDefaultEstimate'], true);

      // Entry B — "tường ngăn 10 (ước lượng)": length = 36 × 0.5 = 18.
      expect(entries[1]['type'], '10');
      expect(entries[1]['length'], 18.0);
      expect(entries[1]['height'], 3.3);
      expect(entries[1]['plasterSides'], 2);
      expect(entries[1]['isDefaultEstimate'], true);

      // Tổng diện tích trát từ 2 entry.
      expect(plasterAreaOf(entries), closeTo(356.4, 1e-9));
      // Khớp đúng công thức chuẩn: 2×(10+8)×3.3×2×1.5.
      expect(plasterAreaOf(entries), closeTo(2 * 18 * 3.3 * 2 * 1.5, 1e-9));
    });

    test('3 tầng khác kích thước → tổng = Σ từng tầng (cộng dồn đúng)', () {
      const floors = [
        BuildingFloor(number: 1, length: 10, width: 8, height: 3.3),
        BuildingFloor(number: 2, length: 12, width: 6, height: 2.8),
        BuildingFloor(number: 3, length: 7, width: 5, height: 3.0),
      ];
      final entries = DefaultWallCalculator.buildDefaultWallEntries(
        floors: floors,
      );

      expect(entries, hasLength(6));
      final total = plasterAreaOf(entries);

      final expected = 2 * (10 + 8) * 3.3 * 2 * 1.5 +
          2 * (12 + 6) * 2.8 * 2 * 1.5 +
          2 * (7 + 5) * 3.0 * 2 * 1.5;
      expect(total, closeTo(expected, 1e-9));
    });

    test('tầng height = 0 → bị bỏ qua, không góp phần, không throw', () {
      const floors = [
        BuildingFloor(number: 1, length: 10, width: 8, height: 3.3),
        BuildingFloor(number: 2, length: 10, width: 8, height: 0),
      ];
      final entries = DefaultWallCalculator.buildDefaultWallEntries(
        floors: floors,
      );

      // Chỉ tầng 1 hợp lệ → 2 entry.
      expect(entries, hasLength(2));
      expect(plasterAreaOf(entries), closeTo(356.4, 1e-9));
    });

    test('floors rỗng → list rỗng (không throw)', () {
      expect(
        DefaultWallCalculator.buildDefaultWallEntries(floors: const []),
        isEmpty,
      );
    });

    test('kết quả deterministic — cùng input luôn cùng output', () {
      const floors = [
        BuildingFloor(number: 1, length: 9, width: 4.5, height: 3.1),
      ];
      final first = DefaultWallCalculator.buildDefaultWallEntries(
        floors: floors,
      );
      final second = DefaultWallCalculator.buildDefaultWallEntries(
        floors: floors,
      );
      expect(first, second);
      expect(plasterAreaOf(first), closeTo(plasterAreaOf(second), 1e-12));
    });
  });
}
