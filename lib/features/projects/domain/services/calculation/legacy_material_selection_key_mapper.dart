/// Mapping boundary: `catalogCode` (stable identity của new UI)
/// → `legacy selection key` (key mà `MaterialCalculator` legacy kiểm tra).
///
/// New UI giữ:
/// - `catalogCode` = identity ổn định cho calculation,
/// - `name` = tên hiển thị (không dùng làm identity calculation khi có catalogCode).
///
/// Legacy `MaterialCalculator.calculateMaterialsFromDetailedParams` kiểm tra
/// `selectedMaterialIds.contains(<key tiếng Việt cố định>)` — ví dụ `'Thép'`,
/// trong khi tên hiển thị legacy của thép là `'Sắt thép'` (case-sensitive nên
/// app legacy runtime không bao giờ khớp). Boundary này map theo catalogCode
/// để quantity không bị mất chỉ vì khác tên hiển thị. KHÔNG sửa legacy calculator.
///
/// Evidence: PHASE2_MAPPING_SPEC.md mục 3.7.
class LegacyMaterialSelectionKeyMapper {
  LegacyMaterialSelectionKeyMapper._();

  /// Catalog code → key kiểm tra của `MaterialCalculator` legacy.
  ///
  /// Chỉ chứa các code có key thực sự được kiểm tra trong
  /// `calculateMaterialsFromDetailedParams` (đã rà từng nhánh
  /// `_calculateWallMaterials/_calculateFoundationMaterials/
  /// _calculateDoorMaterials/_calculateOtherMaterials`).
  static const Map<String, String> catalogCodeToLegacyKey = {
    // Tường
    'brick': 'Gạch xây',
    'cement': 'Xi măng',
    'sand': 'Cát xây',
    'plaster_sand': 'Cát trát',
    'interior_paint': 'Sơn nội thất',
    // Móng — legacy runtime: chọn 'Cát bê tông' → khớp check 'Bê tông' (contains)
    'concrete_sand': 'Bê tông',
    // Móng — legacy check 'Thép' (tên hiển thị cũ 'Sắt thép' case-mismatch)
    'steel': 'Thép',
    'stone': 'Đá',
    // Cửa — legacy check 'Nhôm' (tên hiển thị cũ 'Cửa nhôm Xingfa' case-mismatch)
    'aluminum_door': 'Nhôm',
    // Khác
    'gypsum': 'Thạch cao',
    'labor': 'Nhân công xây dựng',
    'plumbing_labor': 'Nhân công điện nước',
    'plumbing_material': 'Vật tư điện nước',
  };

  /// Trả về legacy selection id cho một [ProjectMaterial]-like input.
  ///
  /// Policy:
  /// - `catalogCode` có trong [catalogCodeToLegacyKey] → key legacy (identity
  ///   ổn định, không phụ thuộc tên hiển thị).
  /// - `catalogCode` không có key (vd `tile`, `roof_tile`, `metal_sheet`,
  ///   `insulated_metal_sheet`, `exterior_paint`, `composite_door` — legacy
  ///   aggregated path không kiểm tra) → fallback `name` đúng như legacy
  ///   runtime (không khớp check nào → không sinh quantity).
  /// - `catalogCode == null` (vật liệu tùy chỉnh) → `name` (hành vi legacy).
  static String selectionIdFor({
    required String? catalogCode,
    required String name,
  }) {
    final key =
        catalogCode == null ? null : catalogCodeToLegacyKey[catalogCode];
    return key ?? name;
  }
}
