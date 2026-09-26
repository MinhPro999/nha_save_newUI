import 'package:flutter_core_project/features/projects/domain/entities/construction_project.dart';

/// Helper xác định mối quan hệ "vật liệu phụ thuộc dữ liệu Tường".
///
/// FIX-CALC-001: sau khi chuyển sang chiến lược "Tường mặc định" (Default
/// Wall), helper này KHÔNG còn dùng để *chặn* wizard — mà dùng để:
/// 1. `LegacyInputMapper` quyết định có cần fallback Default Wall không
///    (chỉ khi có vật liệu phụ thuộc tường được chọn mà walls trống).
/// 2. UI (ProjectDetailPage — Phase 10) quyết định có hiển thị banner
///    "Ước tính" hay không.
class WallDependencyHelper {
  const WallDependencyHelper._();

  /// 5 catalogCode đọc trực tiếp `detailedParams['walls']` trong
  /// `MaterialCalculator._calculateWallMaterials`:
  /// brick, cement, sand, plaster_sand, interior_paint.
  /// (Xem FIX-CALC-001 mục 2 — không thêm code khác vào set này.)
  static const Set<String> wallDependentCatalogCodes = {
    'brick',
    'cement',
    'sand',
    'plaster_sand',
    'interior_paint',
  };

  /// `details.walls` có ít nhất 1 item hợp lệ (length > 0 && height > 0)?
  static bool hasValidExplicitWall(ProjectDetails details) {
    return details.walls.any((wall) => wall.length > 0 && wall.height > 0);
  }

  /// Project có ít nhất 1 vật liệu phụ thuộc tường được chọn?
  static bool hasWallDependentMaterial(ConstructionProject project) {
    return project.materials.any(
      (material) =>
          material.catalogCode != null &&
          wallDependentCatalogCodes.contains(material.catalogCode),
    );
  }

  /// Kết quả tính toán của project này có dùng Default Wall (ước lượng)?
  ///
  /// Đúng khi: không có WallSpec hợp lệ nào VÀ có vật liệu phụ thuộc tường
  /// được chọn — chính là điều kiện fallback Default Wall của
  /// `LegacyInputMapper`. UI dùng hàm này để quyết định hiển thị banner
  /// minh bạch "Ước tính" (Phase 10.3).
  static bool usesDefaultWallEstimate(ConstructionProject project) {
    return !hasValidExplicitWall(project.details) &&
        hasWallDependentMaterial(project);
  }
}
