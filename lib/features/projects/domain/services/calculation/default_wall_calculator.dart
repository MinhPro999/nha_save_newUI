import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

/// Nguồn tính DUY NHẤT cho "Tường mặc định" — dùng khi người dùng không
/// nhập WallSpec chi tiết ở Step 5.
///
/// CÔNG THỨC (do chủ dự án cung cấp, chấp nhận sai số ước lượng có chủ đích):
///   Diện tích tường trát (m²) = Σ [ 2 × (L + W) × H × 2 × 1.5 ]
///   tính trên từng tầng xây dựng thực tế (KHÔNG bao gồm mái — `roof` là
///   field tách biệt khỏi `floors` trong `ConstructionProject`, đã xác minh).
///
/// Đây là dữ liệu TÍNH TOÁN TẠM THỜI, chỉ tồn tại trong bộ nhớ khi build
/// input cho calculation engine — KHÔNG ghi ngược vào `ProjectDetails`/DB.
class DefaultWallCalculator {
  const DefaultWallCalculator._();

  /// Hệ số quy đổi tường ngăn 10 gộp vào tường bao 20.
  /// Nguồn: chủ dự án (chuyên môn dự toán xây dựng). Sai số ước lượng
  /// được CHẤP NHẬN có chủ đích để đổi lấy tốc độ nhập liệu khi người
  /// dùng bỏ qua bước khai báo tường chi tiết.
  static const double partitionWallFactor = 1.5;

  /// Sinh danh sách wall-entry giả lập dùng làm input cho
  /// `LegacyInputMapper` khi `details.walls` rỗng. Định dạng entry khớp
  /// 100% với field mà `paint_calculator.dart` / `brick_calculator.dart`
  /// / `cement_calculator.dart` / `sand_calculator.dart` đang đọc
  /// (`length`, `height`, `type`, `plasterSides`) — không cần sửa
  /// calculator_core.
  static List<Map<String, dynamic>> buildDefaultWallEntries({
    required List<BuildingFloor> floors,
  }) {
    final entries = <Map<String, dynamic>>[];
    for (final floor in floors) {
      if (floor.length <= 0 || floor.width <= 0 || floor.height <= 0) {
        continue; // tầng thiếu kích thước hợp lệ, bỏ qua thay vì tính sai
      }
      final perimeter = 2 * (floor.length + floor.width);

      entries.add({
        'type': '20',
        'plasterSides': 2,
        'length': perimeter,
        'height': floor.height,
        'area': perimeter * floor.height,
        'isDefaultEstimate': true, // cờ để Phase 10 gắn nhãn "ước tính" trên UI
      });
      entries.add({
        'type': '10',
        'plasterSides': 2,
        'length': perimeter * 0.5,
        'height': floor.height,
        'area': perimeter * 0.5 * floor.height,
        'isDefaultEstimate': true,
      });
    }
    return entries;
  }
}
