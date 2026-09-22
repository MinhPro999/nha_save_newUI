# FIX-CALC-001 — Tường mặc định khi thiếu WallSpec, cô lập lỗi tính toán & chuẩn hoá trạng thái kết quả

> **Đối tượng đọc:** AI coding agent (DeepSeek) — thực thi tuần tự theo đúng thứ tự Phase, không nhảy cóc.

---

## 0. QUYẾT ĐỊNH CHIẾN LƯỢC TƯỜNG MẶC ĐỊNH (đọc trước tiên)

`WallSpec` là dữ liệu **tuỳ chọn**. Khi người dùng không nhập, hệ thống **không được chặn** hay báo lỗi — thay vào đó tự tính diện tích tường ước lượng từ kích thước tầng bằng công thức Default Wall (xem Phase 1), chấp nhận sai số ước lượng để đổi lấy tốc độ nhập liệu.

→ **Không chặn wizard** chỉ vì `walls.isEmpty` (không có `isStepValid` return `false` chỉ vì lý do này).
→ **Áp dụng chiến lược "Tường mặc định" (Default Wall Calculator):** khi không nhập, hệ thống tự tính diện tích tường ước lượng từ kích thước tầng.
→ **Business rule cốt lõi phải giữ xuyên suốt từ validation → mapper → calculator → result → UI:**

```
walls.isNotEmpty  → dùng CHÍNH XÁC WallSpec người dùng nhập (không cộng thêm default)
walls.isEmpty     → dùng Default Wall Calculation (ước lượng theo tầng)
wall nhập SAI     → vẫn bị từ chối (length <= 0 hoặc height <= 0 trên 1 item đã tồn tại) — đây là lỗi nhập liệu thật, khác với "không nhập"
```

→ **Đồng thời giữ nguyên** các phần xử lý không liên quan đến chiến lược wall: cô lập lỗi theo nhóm vật liệu, chuẩn hoá trạng thái UI, không hiển thị exception thô — và **bổ sung thêm** các hạng mục audit sâu hơn (đơn vị tính, API trùng lặp, catalog mapping, hard-code móng).

---

## 1. Bối cảnh & nguyên nhân gốc (đã xác minh trực tiếp trên code, không suy đoán)

```
Project có "Sơn nội thất" đã chọn (Step 4) + details.walls = [] (Step 5 không nhập)
        ↓
LegacyInputMapper.mapMaterialInput → walls: [] (rỗng, vì map thẳng từ details.walls)
        ↓
MaterialCalculator.calculateMaterialsFromDetailedParams
  → _calculateWallMaterials → PaintCalculator.calculateInteriorPaintQuantity
        ↓
paint_calculator.dart: totalPaintArea = 0 (vòng for trên list rỗng không chạy)
        ↓
throw ArgumentError('Diện tích sơn nội thất phải lớn hơn 0')   ← đúng lỗi trong ảnh chụp
        ↓
Exception thoát khỏi TOÀN BỘ calculateMaterialsFromDetailedParams
  (móng/cửa/WC/cầu thang phía sau trong hàm KHÔNG BAO GIỜ được tính, dù dữ liệu đầy đủ)
        ↓
ProjectCubit.calculate() catch → calculationResult = null, calculationError = error.toString()
        ↓
UI: banner đỏ hiện nguyên văn exception + 2 panel "chưa chọn vật tư" (SAI, gây hiểu lầm — user đã chọn)
```

**Đã xác minh thêm (quan trọng cho Phase 5 bên dưới):** trong entity hiện tại, `ConstructionProject.roof` là field **tách biệt hoàn toàn** khỏi `ConstructionProject.floors` (`List<BuildingFloor>`) — xem `construction_project.dart` dòng ~291-314. Nghĩa là **mái không bao giờ lẫn vào danh sách tầng xây dựng**, yêu cầu "không tự ý coi Mái bằng là 1 tầng tường" đã tự động được thoả mãn bởi model hiện có — Agent **không cần** thêm bất kỳ enum/flag mới nào để phân biệt mái, chỉ cần dùng thẳng `project.details.floors` (trừ `roof`).

**Vấn đề cùng họ, chưa gây crash nhưng đang âm thầm sai số (xử lý ở Phase 6):** 6 catalogCode (`tile`, `roof_tile`, `metal_sheet`, `insulated_metal_sheet`, `exterior_paint`, `composite_door`) không có mapping trong `legacy_material_selection_key_mapper.dart` → chọn các vật liệu này bị `legacy_result_mapper.dart` (dòng ~35, `if (quantity == null) continue;`) **âm thầm loại bỏ khỏi kết quả**, không báo lỗi.

---

## 2. Vật liệu phụ thuộc dữ liệu "Tường" (đối tượng áp dụng Default Wall)

Rà `MaterialCalculator._calculateWallMaterials` — 5 catalogCode sau đọc trực tiếp `detailedParams['walls']`:

| catalogCode | Tên hiển thị | Hành vi hiện tại khi `walls` rỗng |
|---|---|---|
| `brick` | Gạch xây | Trả `0` âm thầm |
| `cement` | Xi măng | Có nhánh throw `'Thiếu thông số cần thiết: walls hoặc wallArea'` |
| `sand` | Cát xây | Trả `0` âm thầm |
| `plaster_sand` | Cát trát | Trả `0` âm thầm |
| `interior_paint` | Sơn nội thất | **Luôn throw** — đây là ca trong ảnh chụp |

Sau Phase 1-2, cả 5 vật liệu này đều sẽ nhận được dữ liệu tường hợp lệ (từ WallSpec thật hoặc Default Wall), không còn trả `0` âm thầm hay throw nữa.

---

## 3. PHASE 1 — `DefaultWallCalculator` (nguồn tính Default Wall duy nhất)

**Nguyên tắc:** **một nguồn tính duy nhất** cho Default Wall — không rải công thức ở nhiều nơi. Đặt tại tầng **domain**, không đụng `calculator_core`, để giữ tuyệt đối nguyên tắc "không sửa legacy calculator".

**File mới:** `lib/features/projects/domain/services/calculation/default_wall_calculator.dart`

**Thiết kế kỹ thuật quan trọng (đã kiểm chứng khớp với `paint_calculator.dart`/`brick_calculator.dart`/`cement_calculator.dart`/`sand_calculator.dart` hiện có):** các calculator này đều tính diện tích trát của 1 "wall entry" bằng `length × height × plasterSides`, và `brick_calculator.dart` phân biệt tường 10/20 qua field `type`. Vì vậy, thay vì tạo 1 entry gộp, ta sinh **2 entry tách loại tường** để vừa tái tạo đúng chính xác công thức mục tiêu, vừa giữ đúng tỉ lệ tường 10/20 cho gạch/xi măng/cát (chính xác hơn cách gộp 1 dòng):

- Entry A — "tường bao 20": `length = perimeter`, `height = H`, `type = '20'`, `plasterSides = 2`
- Entry B — "tường ngăn 10 (ước lượng)": `length = perimeter × 0.5`, `height = H`, `type = '10'`, `plasterSides = 2`

Kiểm chứng công thức: tổng diện tích trát = `(perimeter × H × 2) + (perimeter × 0.5 × H × 2) = perimeter × H × 2 × 1.5` — **khớp chính xác 100%** với công thức `Σ [2×(L+W)×H×2×1.5]` mà bạn cung cấp, đồng thời tương thích nguyên vẹn với mọi calculator hiện có mà **không cần sửa 1 dòng nào trong `calculator_core`**.

```dart
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
```

**Test mới:** `test/default_wall_calculator_test.dart`
- 1 tầng `L=10, W=8, H=3.3` → `perimeter = 36` → tổng diện tích trát (2 mặt, đã gộp 1.5) phải bằng `36 × 3.3 × 2 × 1.5 = 356.4 m²` (tính lại từ 2 entry trả về, cộng `length×height×plasterSides` của cả 2).
- 3 tầng khác kích thước → tổng = tổng từng tầng (kiểm tra tính cộng dồn đúng theo `Σ`).
- Tầng có `height = 0` → bị bỏ qua, không góp phần vào tổng, không throw.
- `floors` rỗng → trả về list rỗng (không throw) — trường hợp cực hiếm nhưng phải an toàn.

---

## 4. PHASE 2 — `LegacyInputMapper` ưu tiên WallSpec thật, fallback Default Wall

**File sửa:** `lib/features/projects/domain/services/calculation/legacy_input_mapper.dart`

Sửa đoạn build `walls` (hiện tại dòng ~63-72), áp đúng quy tắc ưu tiên:

```dart
final explicitWalls = details.walls
    .where((wall) => wall.length > 0 && wall.height > 0)
    .toList();

final walls = explicitWalls.isNotEmpty
    ? explicitWalls.map((wall) => <String, dynamic>{
          'type': mapWallType(wall.type),
          'plasterSides': wall.plasterSides,
          'length': wall.length,
          'height': wall.height,
          'area': wall.area,
          'isDefaultEstimate': false,
        }).toList()
    : DefaultWallCalculator.buildDefaultWallEntries(floors: project.floors);

final totalWallArea =
    walls.fold<double>(0, (sum, wall) => sum + (wall['area'] as double));
```

> Lưu ý field `project.floors` — kiểm tra đúng tên getter trong `ConstructionProject` hiện tại trước khi dùng (đã xác minh ở mục 1: field tên `floors`, kiểu `List<BuildingFloor>`, KHÔNG lẫn `roof`).

**Quy tắc ưu tiên (đã verify khả thi với code thật):**
- `details.walls` có **ít nhất 1 item hợp lệ** (`length>0 && height>0`) → dùng **đúng và chỉ** các item hợp lệ đó, **không cộng thêm Default Wall**.
- `details.walls` rỗng, hoặc toàn bộ item đều không hợp lệ → dùng Default Wall Calculator.
- **Không được** trộn lẫn 2 nguồn trong cùng 1 lần tính (tránh double-count).

**Test cập nhật:** `test/calculation_service_test.dart` — thêm 3 case:
1. `walls=[]` + `interior_paint` đã chọn + floors đầy đủ → **không throw**, `interior_paint` quantity > 0, giá trị khớp công thức Phase 1.
2. `walls=[WallSpec hợp lệ]` + `interior_paint` → dùng đúng số liệu từ `WallSpec`, **không lớn hơn/khác** giá trị mong đợi nếu cộng thêm default (chứng minh không bị double-count).
3. `walls=[WallSpec(length: 0, height: 0)]` (đã thêm dòng nhưng chưa nhập số) → coi như "không hợp lệ" → rơi vào nhánh Default Wall (không phải nhánh lỗi) — **đây là điểm khác với v1**, vì giờ "chưa nhập số" cũng được cứu bằng Default Wall thay vì bị chặn.

---

## 5. PHASE 3 — Sửa `ProjectWizardState.isStepValid` (bỏ yêu cầu bắt buộc walls)

**File sửa:** `lib/features/projects/presentation/bloc/project_wizard_state.dart`

`case 4` (Step 5) **giữ nguyên toàn bộ điều kiện hiện có ngoại trừ dòng walls** — điểm mấu chốt: **không được coi `walls.isEmpty` là lỗi**, chỉ reject khi **có item nhưng item đó sai**:

```dart
case 4:
  return details.isNotEmpty &&
      details.foundationSegments.every((item) => item.length > 0) &&
      // Không bắt buộc walls.isNotEmpty. Không nhập tường = hợp lệ
      // (Default Wall Calculator sẽ xử lý ở tầng tính toán — xem Phase 1/2).
      // Chỉ reject nếu người dùng ĐÃ THÊM dòng tường nhưng để trống/sai số.
      details.walls.every(
        (item) => item.length > 0 && item.height > 0,
      ) &&
      details.openings.every(
        (item) => item.width > 0 && item.height > 0 && item.quantity > 0,
      ) &&
      details.bathrooms.every((item) => item.area > 0) &&
      details.stairs.every((item) => item.steps > 0);
```

> **Thực ra đoạn code này KHÔNG cần sửa gì cả** — `details.walls.every(...)` trên list rỗng vốn đã trả `true` (vacuous truth), đúng ý "không nhập = hợp lệ". Agent chỉ cần **thêm comment giải thích rõ chủ đích** (như trên) để tránh người sau tưởng đây là bug và "sửa" nhầm thành `walls.isNotEmpty &&` — đây là rủi ro cần tránh khi bảo trì code sau này. **Không cần thêm bất kỳ cross-check nào giữa Step 4 (vật liệu) và Step 5 (tường)** — vì giờ thiếu tường không còn là lỗi.

**Test:** `test/project_wizard_cubit_test.dart` — thêm case: chọn `interior_paint`, không thêm wall nào, điền đủ mục khác → `next()`/`canComplete` → **expect `true`** — xác nhận wizard **không chặn** trường hợp này.

---

## 6. PHASE 4 — `CalculationIssue` có cấu trúc (thay vì string lỗi thô)

Dùng kiểu dữ liệu có cấu trúc thay cho `Map<String, String>` đơn giản — chuẩn hoá cách domain giao tiếp lỗi/cảnh báo tới UI.

**File sửa:** `lib/features/projects/domain/services/calculation/project_calculation_result.dart`

```dart
enum CalculationIssueSeverity { warning, error }

class CalculationIssue extends Equatable {
  const CalculationIssue({
    required this.section,        // 'walls' | 'foundation' | 'doors' | 'others' | catalogCode cụ thể
    required this.code,           // mã ổn định, KHÔNG phải chuỗi tiếng Việt tự do — UI tra l10n theo code
    required this.severity,
    this.materialCode,            // catalogCode liên quan, nếu có (VD 'interior_paint', 'tile')
  });

  final String section;
  final String code;
  final CalculationIssueSeverity severity;
  final String? materialCode;

  @override
  List<Object?> get props => [section, code, severity, materialCode];
}

class ProjectCalculationResult extends Equatable {
  const ProjectCalculationResult({
    this.materialLines = const [],
    this.foundation,
    this.issues = const [],
  });

  final List<ProjectMaterialLine> materialLines;
  final FoundationStructureSection? foundation;

  /// Danh sách vấn đề phát sinh khi tính toán — rỗng nếu hoàn toàn thành
  /// công. Cho phép phân biệt success / partial / failure mà KHÔNG dùng
  /// exception text làm kênh giao tiếp domain → UI.
  final List<CalculationIssue> issues;

  bool get hasErrors =>
      issues.any((i) => i.severity == CalculationIssueSeverity.error);
  bool get hasWarnings =>
      issues.any((i) => i.severity == CalculationIssueSeverity.warning);

  /// success: không issue nào | partial: có issue nhưng vẫn có materialLines
  /// | failure: có issue error và materialLines rỗng hoàn toàn
  String get status {
    if (issues.isEmpty) return 'success';
    if (materialLines.isNotEmpty) return 'partial';
    return 'failure';
  }

  @override
  List<Object?> get props => [materialLines, foundation, issues];
}
```

> Mã lỗi (`code`) ổn định, tra cứu qua l10n ở tầng UI (Phase 10) — **không** nhét message tiếng Việt cứng vào domain layer, giữ đúng nguyên tắc tách domain khỏi presentation.

---

## 7. PHASE 5 — Cô lập lỗi tính toán theo từng nhóm vật liệu

**File sửa:** `lib/calculator_core/services/material_calculator.dart`

Sau Phase 1-3, nhóm "walls" **về lý thuyết sẽ không còn throw nữa** (vì luôn có dữ liệu tường, thật hoặc mặc định). Nhưng vẫn phải cô lập lỗi ở tầng này để:
(a) an toàn cho **project cũ** tạo trước bản fix (đã lưu DB với trạng thái lỗi),
(b) phòng vệ chung cho các lỗi khác không lường trước (VD input dị dạng).

```dart
final calculationErrors = <String, Object>{};

if (detailedParams.containsKey('walls')) {
  try {
    _calculateWallMaterials(
      detailedParams, selectedMaterialIds, quantities,
      intermediateResults, brickLength, brickWidth, brickHeight,
    );
  } catch (e) {
    calculationErrors['walls'] = e;
  }
}
if (detailedParams.containsKey('foundation')) {
  try {
    _calculateFoundationMaterials(
      detailedParams, selectedMaterialIds, quantities, intermediateResults,
    );
  } catch (e) {
    calculationErrors['foundation'] = e;
  }
}
if (detailedParams.containsKey('doors')) {
  try {
    _calculateDoorMaterials(
      detailedParams, selectedMaterialIds, quantities, intermediateResults,
    );
  } catch (e) {
    calculationErrors['doors'] = e;
  }
}
if (detailedParams.containsKey('others')) {
  try {
    _calculateOtherMaterials(
      detailedParams, selectedMaterialIds, quantities, intermediateResults, floors,
    );
  } catch (e) {
    calculationErrors['others'] = e;
  }
}

return {
  'quantities': quantities,
  'costs': costs,
  'intermediateResults': intermediateResults,
  'errors': calculationErrors, // MỚI — rỗng nếu không có lỗi nào
};
```

> ⚠️ Thay đổi **duy nhất** được phép trong `calculator_core` ở toàn bộ kế hoạch này — chỉ là orchestration (bọc try/catch quanh lời gọi), **không đổi 1 dòng công thức nào**. **Nghiêm cấm** kiểu `catch (_) { return 0; }` hay `catch (_) {}` im lặng nuốt lỗi — lỗi bắt được **phải** được đưa vào `calculationErrors`, không được bỏ qua.

**`legacy_result_mapper.dart`:** map `legacyResults['errors']` (Map section → Exception) thành `List<CalculationIssue>` với `code` ổn định:

```dart
static const _knownErrorCodes = {
  'Diện tích sơn nội thất phải lớn hơn 0': 'walls_calculation_failed',
  'Thiếu thông số cần thiết: walls hoặc wallArea': 'walls_calculation_failed',
};

static List<CalculationIssue> _mapIssues(Map<String, dynamic> legacyResults) {
  final raw = legacyResults['errors'];
  if (raw is! Map) return const [];
  final issues = <CalculationIssue>[];
  raw.forEach((section, error) {
    final message = error.toString();
    final code = _knownErrorCodes.entries
        .firstWhere(
          (entry) => message.contains(entry.key),
          orElse: () => const MapEntry('', 'unknown_calculation_error'),
        )
        .value;
    issues.add(CalculationIssue(
      section: section.toString(),
      code: code,
      severity: CalculationIssueSeverity.error,
    ));
  });
  return issues;
}
```

---

## 8. PHASE 6 — Audit & xử lý minh bạch 6 catalogCode chưa hỗ trợ tính toán

**Nguyên tắc:** không ẩn 6 vật liệu này khỏi gợi ý chọn (ẩn = che giấu vấn đề thay vì minh bạch) — thay vào đó **báo cáo rõ ràng qua `CalculationIssue`**.

**File sửa:** `lib/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart`

- Audit toàn bộ 19 catalogCode hiện có trong `default_material_catalog.dart`, xác nhận rõ trạng thái từng mã: `supported` (có key mapping, đã tính được) hay `unsupported` (chưa có công thức nào trong `calculator_core` phục vụ nó).
- Với 6 mã `unsupported` (`tile`, `roof_tile`, `metal_sheet`, `insulated_metal_sheet`, `exterior_paint`, `composite_door`): trong `legacy_result_mapper.dart`, khi `quantities[key] == null` **và** material này thuộc set `unsupportedCatalogCodes` → **không `continue` im lặng nữa**, thay bằng:
  ```dart
  issues.add(CalculationIssue(
    section: 'materials',
    code: 'material_not_supported',
    severity: CalculationIssueSeverity.warning, // warning, không phải error — không chặn kết quả các vật tư khác
    materialCode: material.catalogCode,
  ));
  continue; // vẫn bỏ qua khỏi materialLines vì không có số liệu thật, nhưng ĐÃ ghi nhận issue
  ```
- **Phạm vi Phase 6 chỉ dừng ở AUDIT + BÁO CÁO MINH BẠCH** — việc thật sự bổ sung công thức tính cho 6 vật liệu này (nếu cần) là phạm vi của kế hoạch riêng `FIX-CALC-002`, không mở rộng scope ở đây (nguyên tắc: không mở rộng scope thành rewrite toàn bộ calculation engine trong 1 bản fix).

---

## 9. PHASE 7 — Audit tính nhất quán đơn vị (quantity / unit / unitPrice / cost)

*(Đây là loại lỗi nguy hiểm nhất vì hoàn toàn im lặng — không có exception nào để phát hiện.)*

Agent phải kiểm tra **từng catalogCode** hiện có công thức tính (13 mã `supported`), đối chiếu 3 điểm:
1. Đơn vị mà `MaterialCalculator`/`calculator_core` trả về cho `quantity` (VD: kg, tấn, m², m³, viên, bộ...).
2. Đơn vị mà `default_material_catalog.dart` / dữ liệu giá (`unitPrice`) đang niêm yết (VD: giá theo tấn hay theo kg).
3. Đơn vị hiển thị trên UI (`ProjectMaterialLine.unit` hoặc tương đương).

**Đặc biệt chú ý 2 mã có rủi ro cao nhất** (đơn vị hay bị nhầm trong ngành xây dựng): `cement` (bao/kg/tấn) và `steel` (kg/tấn/cây). Nếu phát hiện lệch đơn vị giữa `quantity` và `unitPrice` (VD quantity tính ra kg nhưng giá niêm yết theo tấn) → đây là **bug độc lập, nghiêm trọng, ưu tiên cao**, phải:
- Ghi nhận rõ trong báo cáo cuối cùng (mục 15) kèm bằng chứng cụ thể (dòng code, giá trị mẫu).
- **KHÔNG tự ý sửa hệ số quy đổi** nếu không có 100% chắc chắn đơn vị đúng phải là gì — việc này cần xác nhận từ chủ dự án tương tự công thức Default Wall ở Phase 1, vì sửa sai hệ số quy đổi đơn vị nguy hiểm hơn cả bug gốc.
- Nếu phát hiện, mở riêng 1 ticket/kế hoạch `FIX-CALC-003` thay vì sửa trực tiếp trong phạm vi `FIX-CALC-001`.

**Test:** `test/unit_consistency_audit_test.dart` — với mỗi catalogCode `supported`, viết 1 test dựng input mẫu cố định, in ra `(quantity, unit, unitPrice, cost)` và assert `cost == quantity * unitPrice` theo đúng đơn vị đã xác nhận khớp — nếu không khớp, test **phải fail rõ ràng** kèm message chỉ đích danh mã nào sai, không được để test pass "cho qua".

---

## 10. PHASE 8 — Audit API trùng lặp / dead code trong `calculator_core`


Agent quét toàn bộ `lib/calculator_core/` tìm các API công khai (`static` method hoặc method trên model, VD trong `lib/calculator_core/models/`) có khả năng gây nhầm lẫn với API thật đang được `MaterialCalculator` sử dụng — đặc biệt các method throw `UnimplementedError` hoặc không được gọi từ bất kỳ đâu trong `lib/` (dead code).

- Kết quả audit: liệt kê rõ trong báo cáo cuối (mục 15) — API nào là canonical (đang dùng thật), API nào là dead/duplicate.
- **Không xoá code trong phạm vi Phase này** trừ khi chắc chắn 100% không có side-effect (VD file hoàn toàn không được import ở đâu) — nếu nghi ngờ, chỉ **đánh dấu `@Deprecated('...')`** kèm comment giải thích, để tránh rủi ro xoá nhầm code đang dùng gián tiếp qua reflection/dynamic dispatch (dù project này không có, vẫn giữ nguyên tắc thận trọng).

---

## 11. PHASE 9 — Audit giả định hard-code trong công thức móng

*(Chỉ audit, không sửa công thức trừ khi có bằng chứng sai rõ ràng theo business rule đã biết.)*

Agent rà `_calculateFoundationMaterials` trong `material_calculator.dart` và các calculator liên quan móng (`foundation_structure_calculator.dart`), liệt kê mọi hằng số/giả định hard-code (VD tỷ lệ thép mặc định, kích thước tiết diện giả định khi thiếu input...).

- Ghi nhận đầy đủ trong báo cáo cuối (mục 15), kèm dòng code cụ thể.
- **Không sửa** trong phạm vi `FIX-CALC-001` trừ khi công thức chắc chắn sai theo business rule đã có sẵn trong project (VD mâu thuẫn với 1 golden test hiện có — nếu vậy đó là bug khác, không phải audit).
- Đây là input đầu vào cho 1 kế hoạch audit riêng (`FIX-CALC-004` hoặc tương đương), không mở rộng scope ở đây.

---

## 12. PHASE 10 — UI: 4 trạng thái rõ ràng + nhãn minh bạch "ước tính mặc định"

**File sửa:** `lib/features/projects/presentation/pages/project_detail_page.dart`

### 12.1. Chuẩn hoá 4 trạng thái (diễn giải theo `ProjectCalculationResult.status` ở Phase 4):

| Trạng thái | Điều kiện | Hiển thị |
|---|---|---|
| **A. Chưa chọn vật tư** | `project.materials.isEmpty` | Giữ nguyên `project_no_materials` — đúng nghĩa |
| **B. Tính lỗi hoàn toàn** | `materials.isNotEmpty` và `calculationResult.status == 'failure'` (hoặc `calculationResult == null` do lỗi tầng ngoài `MaterialCalculator`) | Banner lỗi thân thiện theo `code` (Phase 10.2), **không** in `error.toString()` thô, **không** dùng `project_no_materials` |
| **C. Tính thành công một phần** | `calculationResult.status == 'partial'` | Hiển thị **đầy đủ** các dòng vật tư đã tính được + banner cảnh báo liệt kê phần thiếu (dùng `issues`) |
| **D. Thành công hoàn toàn** | `calculationResult.status == 'success'` | Hiển thị bình thường như hiện tại |

### 12.2. Banner lỗi/cảnh báo — l10n tra theo `code`, không hard-code:

```dart
if (calculationResult != null && calculationResult.issues.isNotEmpty)
  _CalculationIssuesBanner(
    issues: calculationResult.issues,
    onEdit: () => _editProject(context), // method sẵn có trong file
  ),
```

`_CalculationIssuesBanner`: với mỗi `issue`, tra `context.tr('calc_issue_${issue.code}')`; nếu `issue.materialCode != null`, ghép thêm tên vật liệu (tra từ catalog) vào cuối câu — **ghép ở code Dart, không dùng placeholder trong JSON** (đồng bộ với hạn chế của `AppLocalizations.translate()` hiện tại — không hỗ trợ interpolation).

### 12.3. Nhãn minh bạch "ước tính mặc định" (cần thiết để không vi phạm nguyên tắc minh bạch tài chính với người dùng cuối)

Vì chấp nhận sai số Default Wall đổi lấy tốc độ nhập liệu, **bắt buộc** người dùng phải biết số nào là số họ tự nhập, số nào là máy ước lượng — nếu không, một khách hàng 30-60 tuổi có thể hiểu nhầm con số ước lượng là số đo thật, ảnh hưởng quyết định tài chính thực tế (mua vật tư, báo giá cho thợ).

- Trong danh sách vật tư (`_MaterialLineTile` hay tương đương trong `project_detail_page.dart`), nếu dòng vật tư này được tính từ Default Wall (cần truyền cờ `isDefaultEstimate` — xem Phase 1 — xuyên suốt từ `DefaultWallCalculator` → `LegacyInputMapper` → có thể cần thêm field tương tự trên `ProjectMaterialLine` để giữ thông tin này tới tận UI), hiển thị 1 badge nhỏ: **"Ước tính"** cạnh tên vật liệu, có thể kèm tooltip/subtitle: *"Tính theo diện tích sàn — chưa nhập tường chi tiết"*.
- Đây là bổ sung **khuyến nghị mạnh** nhưng nếu Agent đánh giá tốn quá nhiều effort để truyền cờ xuyên suốt tới `ProjectMaterialLine` trong phạm vi `FIX-CALC-001`, có thể làm tối giản hơn: chỉ hiển thị 1 banner **chung** ở đầu trang khi **bất kỳ** vật liệu nào trong kết quả dùng Default Wall (không cần gắn badge từng dòng) — ghi rõ trong báo cáo cuối lựa chọn nào đã áp dụng.

---

## 13. PHASE 11 — l10n mới (thêm đồng thời cả `vi.json` và `en.json`, giữ đồng bộ 100% khoá)

`vi.json`:
```json
"calc_issue_walls_calculation_failed": "Không thể tính vật tư liên quan đến Tường. Vào Chỉnh sửa → bước Thông số chi tiết để kiểm tra lại.",
"calc_issue_unknown_calculation_error": "Có lỗi khi tính một phần khối lượng. Vào Chỉnh sửa để kiểm tra lại thông số đã nhập.",
"calc_issue_material_not_supported": "Vật liệu này hiện chưa được hỗ trợ tính khối lượng tự động, sẽ được cập nhật trong bản sau:",
"project_partial_result_banner_title": "Kết quả tính toán chưa đầy đủ",
"project_edit_cta": "Chỉnh sửa dự án",
"project_default_wall_badge": "Ước tính",
"project_default_wall_hint": "Tính theo diện tích sàn — chưa nhập tường chi tiết",
"project_default_wall_banner": "Một số vật tư (tường, sơn nội thất...) đang được tính theo ước lượng diện tích sàn vì bạn chưa nhập chi tiết Tường ở bước 5. Vào Chỉnh sửa nếu muốn nhập chính xác hơn.",
```

`en.json`:
```json
"calc_issue_walls_calculation_failed": "Wall-related materials could not be calculated. Go to Edit → Details step to review.",
"calc_issue_unknown_calculation_error": "Part of the quantity calculation failed. Go to Edit to review your inputs.",
"calc_issue_material_not_supported": "This material isn't supported for automatic quantity calculation yet, coming in a future update:",
"project_partial_result_banner_title": "Calculation incomplete",
"project_edit_cta": "Edit project",
"project_default_wall_badge": "Estimated",
"project_default_wall_hint": "Estimated from floor area — no detailed wall data entered",
"project_default_wall_banner": "Some materials (walls, interior paint...) are being estimated from floor area because you haven't entered detailed wall data in Step 5. Edit the project for a more precise result.",
```

---

## 14. PHASE 12 — Test tổng hợp bắt buộc

### Unit test
- `test/default_wall_calculator_test.dart` (Phase 1)
- `test/calculation_service_test.dart` — bổ sung các case Phase 2 + case dưới đây:
  - **Không chọn Sơn nội thất + không có WallSpec** → không được tính interior paint, không throw (trạng thái hợp lệ, khác các case trên).
  - **WallSpec có 1 item hợp lệ + 1 item sai** (`height <= 0`) → phải bị `isStepValid` reject ở wizard (Phase 3), **không** được âm thầm fallback sang Default Wall để che giấu lỗi nhập liệu thật.
  - **Material khác lỗi không làm mất material hợp lệ**: dựng input brick+cement thành công, giả lập 1 lỗi ở nhóm khác → expect brick/cement vẫn có quantity, `issues` chỉ chứa đúng nhóm lỗi.
  - **Cost calculation**: `quantity=10, unitPrice=65_000` → `cost=650_000`, `totalCost` tổng hợp đúng.
- `test/unit_consistency_audit_test.dart` (Phase 7)
- `test/wall_dependent_material_rule_test.dart` — **giữ nguyên** vai trò cũ nhưng đổi mục đích dùng: không còn dùng để *chặn* wizard, mà dùng để Phase 10 xác định *có cần hiển thị banner "ước tính"* hay không (đổi tên khuyến nghị: `wall_dependent_material_helper_test.dart` để phản ánh đúng vai trò mới — không bắt buộc đổi tên, Agent tự quyết định miễn nhất quán).

### Widget test
- `test/project_wizard_widget_test.dart` — case chọn `interior_paint`, không thêm Tường, bấm "Hoàn tất" → **expect: hoàn tất thành công**.
- `test/project_detail_widget_test.dart` — case project (mới hoặc cũ) có `interior_paint` + `walls=[]` → mở `ProjectDetailPage` → expect: **không còn** banner exception thô, hiển thị đầy đủ material lines (bao gồm sơn nội thất với giá trị > 0), có banner "Ước tính"/`project_default_wall_banner`.

### Golden test
- Không cần thêm golden case mới cho `calculator_core` (Phase 5 chỉ đổi orchestration, không đổi công thức bên trong). Chạy lại toàn bộ `flutter test test/golden/` sau khi sửa để xác nhận không regression.

### E2E test
- `test/e2e/project_calculation_persistence_e2e_test.dart` — thêm kịch bản: wizard → chọn `interior_paint`, bỏ qua Tường → lưu thành công → mở lại → `ProjectDetailPage` hiển thị đúng số liệu Default Wall, không lỗi.

---

## 15. Danh sách file — checklist cho Agent

**File mới:**
- [ ] `lib/features/projects/domain/services/calculation/default_wall_calculator.dart` (Phase 1)
- [ ] `test/default_wall_calculator_test.dart`
- [ ] `test/unit_consistency_audit_test.dart` (Phase 7)
- [ ] `test/wall_dependent_material_rule_test.dart` (dùng cho UI banner, không dùng để chặn)

**File sửa:**
- [ ] `lib/features/projects/domain/services/calculation/legacy_input_mapper.dart` (Phase 2)
- [ ] `lib/features/projects/presentation/bloc/project_wizard_state.dart` (Phase 3 — chủ yếu thêm comment giải thích, xác nhận KHÔNG có `walls.isNotEmpty`)
- [ ] `lib/features/projects/domain/services/calculation/project_calculation_result.dart` (Phase 4 — thêm `CalculationIssue`)
- [ ] `lib/calculator_core/services/material_calculator.dart` (Phase 5 — CHỈ orchestration, không đổi công thức)
- [ ] `lib/features/projects/domain/services/calculation/legacy_result_mapper.dart` (Phase 5 + Phase 6)
- [ ] `lib/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart` (Phase 6 — audit + đánh dấu supported/unsupported)
- [ ] `lib/features/projects/presentation/pages/project_detail_page.dart` (Phase 10)
- [ ] `lib/features/projects/domain/entities/construction_project.dart` (chỉ nếu Phase 10.3 cần thêm field `isDefaultEstimate` lên `ProjectMaterialLine` — xác nhận trước khi sửa entity)
- [ ] `lib/l10n/vi.json` **và** `lib/l10n/en.json` (Phase 11 — bắt buộc sửa đồng thời cả 2)
- [ ] `test/project_wizard_cubit_test.dart`
- [ ] `test/calculation_service_test.dart`
- [ ] `test/project_wizard_widget_test.dart`
- [ ] `test/project_detail_widget_test.dart`
- [ ] `test/e2e/project_calculation_persistence_e2e_test.dart`

**File chỉ audit, không sửa công thức (trừ khi phát hiện bug độc lập nghiêm trọng — báo cáo riêng, không tự sửa):**
- [ ] `lib/calculator_core/services/material_calculator.dart` (`_calculateFoundationMaterials` — Phase 9)
- [ ] `lib/calculator_core/models/` (Phase 8, audit API trùng lặp/dead code)
- [ ] `lib/features/projects/domain/services/calculation/mock_calculation_service.dart` (**không được sửa để "làm cho UI chạy"** — DI production dùng `LegacyCalculationService` thật, sửa mock không giải quyết gì và có thể che giấu bug)

---

## 16. Nguyên tắc "Không làm / Phải làm" (áp dụng xuyên suốt mọi Phase)

### Không làm
- Không ép `WallSpec` thành bắt buộc (đã chốt ở mục 0).
- Không tự ý đổi hệ số `1.5` hoặc công thức Default Wall — đây là thông số đã được chủ dự án xác nhận, chỉ thay đổi nếu có yêu cầu mới bằng văn bản.
- Không xoá `throw` trong `paint_calculator.dart`/các calculator khác bằng cách đổi thành `return 0` — bản fix đúng đắn là đảm bảo **upstream luôn cung cấp dữ liệu hợp lệ** (Phase 1-2), không phải tắt tiếng cảnh báo tại nơi phát hiện.
- Không nuốt exception im lặng (`catch (_) {}`, `catch (_) { return 0; }`, `continue` không ghi issue).
- Không sửa `MockCalculationService` để che bug production.
- Không sửa công thức trong `calculator_core` ngoài phạm vi orchestration đã nêu ở Phase 5.
- Không mở rộng scope thành rewrite toàn bộ calculation engine, không tự tạo model/enum mới nếu kiến trúc hiện tại đã có cách biểu diễn tương đương (VD roof/floors đã tách sẵn — không cần thêm gì).
- Không thay đổi UI layout nếu không cần thiết cho mục tiêu Phase 10.

### Phải làm
- Giữ backward compatibility với mọi field/API hiện có (chỉ thêm field mới, không đổi kiểu field cũ).
- Explicit `WallSpec` luôn ưu tiên hơn Default Wall — không bao giờ cộng dồn cả hai.
- Structured `CalculationIssue` thay cho exception string ở ranh giới domain → UI.
- Default Wall calculation phải **deterministic** (cùng input luôn ra cùng output, có test khẳng định con số cụ thể).
- Material unsupported phải được thông báo rõ ràng (Phase 6), không âm thầm biến mất.
- Mọi chuỗi hiển thị người dùng đi qua `context.tr('key')`, có mặt ở cả `vi.json`/`en.json`.
- Viết regression test tái hiện đúng bug trước khi sửa, xác nhận fail trước / pass sau.

---

## 17. Quy trình thực hiện tuần tự cho AI Agent (bắt buộc theo đúng thứ tự)

```
STEP 1  — Audit: đọc toàn bộ file trong mục 15 (Primary + Secondary), KHÔNG sửa code.
STEP 2  — Viết regression test tái hiện đúng bug ảnh chụp (walls=[] + interior_paint),
          xác nhận test FAIL trên code hiện tại.
STEP 3  — Implement Phase 1 (DefaultWallCalculator) + test Phase 1. Chạy test, xác nhận pass.
STEP 4  — Implement Phase 2 (LegacyInputMapper ưu tiên WallSpec/fallback Default Wall)
          + test Phase 2. Chạy lại STEP 2's regression test — xác nhận giờ đã PASS.
STEP 5  — Implement Phase 3 (xác nhận wizard không chặn walls rỗng) + test.
STEP 6  — Implement Phase 4 (CalculationIssue) + Phase 5 (cô lập lỗi theo nhóm) + test.
STEP 7  — Implement Phase 6 (audit + xử lý minh bạch 6 catalogCode chưa hỗ trợ) + test.
STEP 8  — Thực hiện Phase 7 (audit đơn vị tính) + Phase 8 (audit API trùng lặp)
          + Phase 9 (audit móng) — CHỈ AUDIT, ghi nhận vào báo cáo cuối, không tự sửa
          công thức trừ khi có xác nhận rõ ràng.
STEP 9  — Implement Phase 10 (UI 4 trạng thái + nhãn minh bạch) + Phase 11 (l10n).
STEP 10 — Chạy toàn bộ Phase 12 (test tổng hợp), bao gồm golden test hiện có
          (`flutter test test/golden/`) để xác nhận KHÔNG regression công thức cũ.
STEP 11 — Chạy `flutter analyze` toàn repo — 0 lỗi/warning mới.
STEP 12 — Kiểm tra regression thủ công toàn luồng: Project creation → Step 1-5 →
          Project detail → Calculation → Material result → Cost result.
STEP 13 — Viết báo cáo cuối cùng (mục 20 bên dưới).
```

---

## 18. Rủi ro & ghi chú

- **Rủi ro chính:** hệ số `1.5`/công thức Default Wall là ước lượng có chủ đích — nếu sau này phát hiện sai lệch quá lớn so với thực tế, cần một kế hoạch riêng để hiệu chỉnh hệ số (không thuộc phạm vi `FIX-CALC-001`).
- **Rủi ro phụ:** field `isDefaultEstimate` (Phase 10.3) nếu cần truyền xuyên suốt tới `ProjectMaterialLine` có thể đụng nhiều lớp mapping hơn dự kiến — nếu effort quá lớn, dùng phương án tối giản (banner chung) đã nêu, không được bỏ qua hoàn toàn yêu cầu minh bạch.
- **Không có migration DB nào trong toàn bộ kế hoạch này** — mọi dữ liệu Default Wall chỉ tồn tại tạm thời trong bộ nhớ lúc tính toán, không ghi ngược DB. Rollback = revert nhánh/PR, không cần xử lý dữ liệu.
- Field mới trên `ProjectCalculationResult` (`issues` thay cho các field lỗi cũ nếu có từ lần chạy trước) — kiểm tra không có consumer nào khác đang đọc field cũ trước khi xoá.

---

## 19. Báo cáo cuối cùng — Agent PHẢI xuất sau khi hoàn thành

1. Danh sách file đã thay đổi (theo checklist mục 15, đánh dấu hoàn thành/chưa).
2. Root cause đã fix — đối chiếu với mục 1.
3. Chi tiết Default Wall logic đã implement (công thức, vị trí, test đối chiếu số liệu cụ thể).
4. Thay đổi kiến trúc calculation (CalculationIssue, cô lập lỗi theo nhóm).
5. Thay đổi trạng thái/UI (4 trạng thái, nhãn "Ước tính").
6. Kết quả audit Phase 6/7/8/9 — liệt kê từng phát hiện, kèm khuyến nghị (sửa ngay / mở kế hoạch riêng / không cần sửa).
7. Danh sách test đã thêm/sửa.
8. Kết quả `flutter test` (pass/fail, số lượng test).
9. Kết quả `flutter analyze` (số lỗi/warning).
10. Vấn đề còn tồn đọng (known issues) — đặc biệt các phát hiện ở Phase 7-9 chưa được sửa trong phạm vi này.

---

# DEFINITION OF DONE — FIX-CALC-001

```text
[ ] Bug trong ảnh chụp (interior_paint + walls=[]) được tái hiện bằng regression test TRƯỚC khi sửa
[ ] Bug đó được xác nhận ĐÃ SỬA bằng cùng regression test SAU khi sửa (test đổi từ fail → pass)
[ ] WallSpec vẫn là dữ liệu tuỳ chọn — wizard KHÔNG chặn hoàn tất khi walls rỗng
[ ] Explicit WallSpec (khi có item hợp lệ) luôn được ưu tiên, KHÔNG cộng dồn với Default Wall
[ ] WallSpec nhập sai (length/height <= 0 trên item đã tồn tại) vẫn bị wizard từ chối như cũ
[ ] Default Wall Calculator triển khai đúng công thức Σ[2×(L+W)×H×2×1.5], có test khẳng định số liệu cụ thể
[ ] Default Wall chỉ tính trên floors thực tế, xác nhận roof (field tách biệt) không bị tính nhầm
[ ] Sơn nội thất (và brick/cement/sand/plaster_sand) hoạt động đúng khi không có WallSpec, không còn throw
[ ] Một material lỗi không còn làm sập toàn bộ calculation — các material độc lập khác vẫn tính được
[ ] CalculationIssue có cấu trúc (section/code/severity) thay cho exception string ở domain layer
[ ] Không còn material bị "biến mất" khỏi kết quả mà không có issue giải thích (kể cả 6 catalogCode unsupported)
[ ] Catalog mapping đã được audit đầy đủ, mỗi mã có trạng thái rõ ràng supported/unsupported
[ ] Đơn vị tính (quantity/unit/unitPrice/cost) đã được audit cho toàn bộ material supported, có test xác nhận cost = quantity × unitPrice đúng đơn vị
[ ] API trùng lặp/dead code trong calculator_core đã được audit và ghi nhận (không bắt buộc xoá)
[ ] Giả định hard-code trong công thức móng đã được audit và ghi nhận (không bắt buộc sửa)
[ ] UI phân biệt rõ 4 trạng thái: chưa chọn vật tư / lỗi hoàn toàn / thành công một phần / thành công hoàn toàn
[ ] Không còn hiển thị exception thô (error.toString()) trực tiếp cho người dùng cuối
[ ] Không còn hiển thị "chưa chọn vật tư" khi thực tế là lỗi tính toán
[ ] Có cơ chế minh bạch cho người dùng biết khi nào số liệu là "ước tính mặc định" thay vì họ tự nhập
[ ] MockCalculationService không bị sửa để che giấu bug production
[ ] Không có dòng công thức nào trong calculator_core bị thay đổi ngoài phạm vi orchestration đã duyệt
[ ] l10n vi.json/en.json đồng bộ 100% khoá (kiểm bằng script so sánh set khoá)
[ ] flutter analyze: 0 lỗi/warning mới
[ ] flutter test: toàn bộ pass, bao gồm 44 golden test không đổi kết quả (không regression công thức cũ)
[ ] Regression thủ công toàn luồng (tạo dự án → 5 step → chi tiết → tính toán) hoạt động bình thường
[ ] Báo cáo cuối cùng theo đúng 10 mục ở mục 19 đã được xuất
```

**Kết thúc kế hoạch FIX-CALC-001.**
