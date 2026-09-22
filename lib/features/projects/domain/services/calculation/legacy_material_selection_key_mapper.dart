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

  /// FIX-CALC-001 Phase 6 — AUDIT toàn bộ 19 catalogCode của
  /// `default_material_catalog.dart`, đối chiếu từng nhánh
  /// `_calculateWallMaterials/_calculateFoundationMaterials/
  /// _calculateDoorMaterials/_calculateOtherMaterials`.
  ///
  /// SUPPORTED (13) — có legacy selection key VÀ được check thật trong
  /// `MaterialCalculator`:
  ///   brick → 'Gạch xây' (_calculateWallMaterials)
  ///   cement → 'Xi măng' (_calculateWallMaterials)
  ///   sand → 'Cát xây' (_calculateWallMaterials)
  ///   plaster_sand → 'Cát trát' (_calculateWallMaterials)
  ///   interior_paint → 'Sơn nội thất' (_calculateWallMaterials)
  ///   concrete_sand → 'Bê tông' (_calculateFoundationMaterials)
  ///   steel → 'Thép' (_calculateFoundationMaterials)
  ///   stone → 'Đá' (_calculateFoundationMaterials)
  ///   aluminum_door → 'Nhôm' (_calculateDoorMaterials)
  ///   gypsum → 'Thạch cao' (_calculateOtherMaterials; quantity = 0 khi
  ///             gypsumCeilingArea = 0.0 — FUNCTIONAL GAP đã ghi nhận)
  ///   labor → 'Nhân công xây dựng' (_calculateOtherMaterials)
  ///   plumbing_labor → 'Nhân công điện nước' (_calculateOtherMaterials)
  ///   plumbing_material → 'Vật tư điện nước' (_calculateOtherMaterials)
  ///
  /// UNSUPPORTED (6) — `calculator_core` CÓ method tính riêng nhưng KHÔNG
  /// được gọi từ `calculateMaterialsFromDetailedParams` (không có nhánh
  /// aggregated check nào):
  ///   tile → calculateTile6060Quantity (dead trong flow tổng hợp)
  ///   roof_tile → calculateRoofTileQuantity (dead trong flow tổng hợp)
  ///   metal_sheet → calculateMetalSheetQuantity (dead trong flow tổng hợp)
  ///   insulated_metal_sheet → calculateInsulatedMetalQuantity (dead)
  ///   exterior_paint → calculateExteriorPaintQuantity (dead)
  ///   composite_door → calculateCompositeDoorQuantity (dead)
  ///
  /// Xử lý trong FIX-CALC-001: chỉ AUDIT + BÁO CÁO MINH BẠCH qua
  /// `CalculationIssue(code: 'material_not_supported')` trong
  /// `LegacyResultMapper` — KHÔNG bổ sung công thức (scope của
  /// FIX-CALC-002).

  /// 13 catalogCode `supported` (có key mapping + có nhánh tính thật).
  static const Set<String> supportedCatalogCodes = {
    'brick',
    'cement',
    'sand',
    'plaster_sand',
    'interior_paint',
    'concrete_sand',
    'steel',
    'stone',
    'aluminum_door',
    'gypsum',
    'labor',
    'plumbing_labor',
    'plumbing_material',
  };

  /// 6 catalogCode `unsupported` (chưa có công thức nào trong
  /// `calculateMaterialsFromDetailedParams` phục vụ nó).
  /// `LegacyResultMapper` dùng set này để sinh warning issue thay vì
  /// âm thầm bỏ qua material.
  static const Set<String> unsupportedCatalogCodes = {
    'tile',
    'roof_tile',
    'metal_sheet',
    'insulated_metal_sheet',
    'exterior_paint',
    'composite_door',
  };

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
