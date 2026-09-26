# PHASE 2.1 — FIX-CALC-001R
## Residual Fix Specification — 3 điểm tồn đọng sau Source Audit

> **Mục tiêu:** xử lý đúng 3 điểm tồn đọng được phát hiện sau khi audit branch `main_phase2` tại commit `cc9410a50272296a5cb712ef642104d07bef59a6`.
>
> **Phạm vi:** chỉ sửa 3 vấn đề dưới đây. Không mở rộng thành FIX-CALC-002/003/004 và không rewrite calculator engine.
>
> **Nguyên tắc kiến trúc:** ưu tiên sửa ở validation / domain boundary / result mapping / state orchestration. **Không thay đổi công thức trong `calculator_core`** nếu không bắt buộc.

---

# 1. TÓM TẮT 3 VẤN ĐỀ CẦN SỬA

## P1 — Invalid `WallSpec` đang bị fallback thành Default Wall

### Hiện trạng

`LegacyInputMapper` hiện lọc:

```dart
final explicitWalls = details.walls
    .where((wall) => wall.length > 0 && wall.height > 0)
    .toList();
```

Sau đó:

```dart
final walls = explicitWalls.isNotEmpty
    ? explicitWalls
    : DefaultWallCalculator.buildDefaultWallEntries(...);
```

Điều này tạo ra một trường hợp sai:

```text
details.walls != []
+
có WallSpec invalid
→ invalid item bị filter bỏ
→ explicitWalls = []
→ mapper tưởng rằng không có WallSpec
→ fallback Default Wall
```

Business rule đã chốt:

```text
walls == []                → Default Wall
walls có item nhưng sai    → lỗi dữ liệu nhập, KHÔNG fallback
walls có item và hợp lệ    → dùng WallSpec, KHÔNG cộng Default
```

---

## P1 — `quantity == null` vẫn có thể bị silently drop

`LegacyResultMapper` hiện đã xử lý 6 mã `unsupportedCatalogCodes` bằng warning:

```text
material_not_supported
```

Nhưng nếu một material có:

```text
quantity == null
```

mà `catalogCode` không nằm trong known unsupported set thì code vẫn:

```dart
continue;
```

và material biến mất khỏi result mà không có issue.

Expected:

```text
selected material
→ quantity missing
→ explicit CalculationIssue
```

---

## P2 — Cubit status và Result status có 2 source of truth

`ProjectCalculationResult` hiện có:

```text
success
partial
failure
```

nhưng `ProjectCubit.calculate()` sau khi nhận bất kỳ result nào vẫn ghi:

```dart
calculationStatus: ProjectCalculationStatus.success
```

Có thể xảy ra:

```text
ProjectState.calculationStatus = success
ProjectCalculationResult.status = partial
```

hoặc:

```text
ProjectState.calculationStatus = success
ProjectCalculationResult.status = failure
```

Mục tiêu:

```text
calculating = transient Cubit state
completed state = phản ánh typed result
```

---

# 2. FILE ƯU TIÊN

## P1 — WallSpec

```text
lib/features/projects/domain/services/calculation/legacy_input_mapper.dart
lib/features/projects/domain/services/calculation/wall_dependency_helper.dart
lib/features/projects/domain/services/calculation/default_wall_calculator.dart
lib/features/projects/presentation/bloc/project_wizard_state.dart
test/calculation_service_test.dart
test/project_wizard_cubit_test.dart
```

## P1 — Missing quantity

```text
lib/features/projects/domain/services/calculation/legacy_result_mapper.dart
lib/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart
test/calculation_service_test.dart
test/unit_consistency_audit_test.dart
```

## P2 — State synchronization

```text
lib/features/projects/presentation/bloc/project_cubit.dart
lib/features/projects/presentation/bloc/project_state.dart
lib/features/projects/presentation/pages/project_detail_page.dart
test/calculation_service_test.dart
```

---

# 3. P1 — FIX INVALID WALLSPEC FALLBACK

## 3.1 Business rule bắt buộc

### Case A — Không nhập WallSpec

```dart
details.walls.isEmpty
```

→ hợp lệ.

→ calculation dùng `DefaultWallCalculator`.

### Case B — Có WallSpec và tất cả hợp lệ

```dart
details.walls.isNotEmpty
+
mọi item:
length > 0
height > 0
```

→ dùng đúng các WallSpec đã nhập.

→ Không cộng Default Wall.

### Case C — Có WallSpec nhưng có ít nhất một item không hợp lệ

```dart
details.walls.isNotEmpty
+
có item:
length <= 0
hoặc
height <= 0
```

→ **invalid input**.

→ Không fallback Default Wall.

→ Không tự bỏ item.

→ Không silently normalize.

---

# 4. P1 — CÁCH SỬA `LegacyInputMapper`

Không dùng việc filter để quyết định list có rỗng hay không.

Không dùng:

```dart
final explicitWalls = details.walls
    .where(...)
    .toList();
```

làm căn cứ xác định empty.

Ưu tiên logic:

```dart
final hasExplicitWalls = details.walls.isNotEmpty;
final hasInvalidExplicitWall = details.walls.any(
  (wall) => wall.length <= 0 || wall.height <= 0,
);

if (!hasExplicitWalls) {
  // Default Wall
} else if (hasInvalidExplicitWall) {
  // Invalid input
} else {
  // Explicit walls
}
```

Mapper là boundary dữ liệu, vì vậy:

```text
invalid input
→ validation/calculation error
```

không được biến thành:

```text
invalid input
→ default calculation
```

---

# 5. P1 — ERROR REPRESENTATION

Ưu tiên sử dụng cơ chế typed hiện tại:

```text
CalculationIssue
```

Ví dụ concept:

```dart
CalculationIssue(
  section: 'walls',
  code: 'invalid_wall_spec',
  severity: CalculationIssueSeverity.error,
)
```

Không để UI parse `error.toString()`.

Nếu cần l10n:

```text
calc_issue_invalid_wall_spec
```

phải được thêm đồng bộ vào:

```text
lib/l10n/vi.json
lib/l10n/en.json
```

Không đưa message tiếng Việt hard-code vào domain layer.

---

# 6. P1 — GIỮ NGUYÊN WIZARD BEHAVIOR

Không đổi:

```text
walls empty → valid
```

và:

```text
walls có item invalid → invalid
```

Không biến `interior_paint` thành lý do bắt buộc phải nhập WallSpec.

Default Wall vẫn là fallback chính thức khi thực sự không có WallSpec.

---

# 7. P1 — TEST INVALID WALL

Bắt buộc có:

### REG-R1

```text
walls=[]
interior_paint=selected
```

Expected:

```text
Default Wall
success
quantity > 0
```

### REG-R2

```text
walls=[valid WallSpec]
```

Expected:

```text
Explicit WallSpec
không double-count
```

### REG-R3 — MỚI, BẮT BUỘC

```text
walls=[
  valid WallSpec,
  invalid WallSpec
]
```

Expected:

```text
error = invalid_wall_spec
KHÔNG fallback Default Wall
```

### REG-R4 — MỚI, BẮT BUỘC

```text
walls=[
  invalid WallSpec(length=0, height=3)
]
```

Expected:

```text
error
KHÔNG Default Wall
```

### REG-R5 — MỚI, BẮT BUỘC

```text
walls=[
  invalid WallSpec(length=5, height=0)
]
```

Expected:

```text
error
KHÔNG Default Wall
```

---

# 8. P1 — FIX `quantity == null` SILENT DROP

Business rule:

```text
ProjectMaterial đã được chọn
+
quantity != null
→ ProjectMaterialLine
```

và:

```text
ProjectMaterial đã được chọn
+
quantity == null
→ CalculationIssue
```

Không có ngoại lệ “silent continue”.

---

# 9. P1 — PHÂN LOẠI MISSING QUANTITY

## Case A — Known unsupported catalog

Các mã hiện tại:

```text
tile
roof_tile
metal_sheet
insulated_metal_sheet
exterior_paint
composite_door
```

Giữ:

```text
material_not_supported
warning
```

## Case B — Unknown / unmapped catalog

Ví dụ:

```text
future_material
```

nhưng calculation không trả quantity.

Tạo issue rõ ràng, đề xuất:

```text
code = material_calculation_missing
severity = error
materialCode = catalogCode
```

Mục tiêu:

```text
known unsupported → warning
unexpected/unmapped → error
```

---

# 10. P1 — MATERIAL CUSTOM

Với:

```text
catalogCode == null
```

Agent phải trace flow thật:

```text
ProjectMaterial
→ selectionId
→ MaterialCalculator
→ result
```

Nếu custom material không có quantity:

```text
CalculationIssue(material_calculation_missing)
```

Không tự viết công thức custom trong scope này.

---

# 11. P1 — KHÔNG ĐỔI NULL THÀNH ZERO

Không làm:

```dart
quantity ?? 0
```

để che missing calculation.

Phải giữ distinction:

```text
0    = đã tính và kết quả thật sự bằng 0
null = chưa có calculation quantity
```

---

# 12. P1 — TEST MISSING QUANTITY

### REG-R6

Known unsupported:

```text
tile
```

Expected:

```text
material_not_supported
warning
```

### REG-R7

Unknown:

```text
future_material
quantity == null
```

Expected:

```text
material_calculation_missing
error
```

### REG-R8

Mixed:

```text
brick → success
tile → warning
future_material → error
```

Expected:

```text
brick line vẫn tồn tại
tile warning tồn tại
future_material error tồn tại
```

Không crash các material độc lập.

---

# 13. P2 — ĐỒNG BỘ CUBIT VÀ RESULT

Không để:

```text
Cubit = success
Result = partial
```

hoặc:

```text
Cubit = success
Result = failure
```

---

# 14. P2 — STATE MODEL

Có thể giữ:

```dart
enum ProjectCalculationStatus {
  idle,
  calculating,
  success,
  partial,
  failure,
}
```

Nếu chọn cách này, sau calculation:

```dart
final status = switch (result.status) {
  'success' => ProjectCalculationStatus.success,
  'partial' => ProjectCalculationStatus.partial,
  'failure' => ProjectCalculationStatus.failure,
  _ => ProjectCalculationStatus.failure,
};
```

Hoặc có thể giữ `calculationStatus` chỉ cho lifecycle:

```text
idle
calculating
completed
```

và dùng `ProjectCalculationResult.status` làm source of truth cho trạng thái hoàn tất.

**Không được duy trì hai trạng thái có thể mâu thuẫn.**

---

# 15. P2 — PROJECT DETAIL PAGE

Sau calculation:

```text
success
→ full result

partial
→ full successful lines + warnings/issues

failure
→ failure state
```

Không được để một chỗ đọc:

```text
calculationStatus
```

và chỗ khác đọc:

```text
result.status
```

với ý nghĩa không nhất quán.

---

# 16. P2 — `calculationError`

Không cần xóa ngay field:

```text
String? calculationError
```

nếu còn dependency.

Nhưng:

- Không dùng nó để truyền lỗi WallSpec mới ra UI.
- Không hiển thị raw exception.
- Ưu tiên structured `CalculationIssue`.
- Nếu exception tầng ngoài không map được, UI chỉ dùng fallback thân thiện như hiện tại.

---

# 17. KHÔNG SỬA CALCULATOR FORMULA

Residual fix này **không** được sửa các vấn đề:

```text
FIX-CALC-002
→ 6 material chưa có aggregated formula

FIX-CALC-003
→ aluminum_door unit mismatch
→ cement/steel suggestion unit

FIX-CALC-004
→ foundation hard-code assumptions

FUNCTIONAL GAP
→ gypsum ceiling area

BUSINESS ESTIMATE
→ Default Wall factor 1.5
```

Đây là các scope riêng.

Không rewrite:

```text
BrickCalculator
CementCalculator
SandCalculator
PaintCalculator
SteelCalculator
FoundationStructureCalculator
```

trừ khi sửa compile/type boundary là bắt buộc.

---

# 18. REGRESSION MATRIX CUỐI

| ID | Scenario | Expected |
|---|---|---|
| R1 | `walls=[]` + interior paint | Default Wall + success |
| R2 | valid WallSpec | Explicit WallSpec |
| R3 | valid + invalid WallSpec | Error, NO fallback |
| R4 | only invalid WallSpec | Error, NO fallback |
| R5 | no wall-dependent material | no unnecessary Default Wall |
| R6 | known unsupported | warning |
| R7 | unknown missing quantity | error issue |
| R8 | supported + unsupported + unknown | successful lines retained |
| R9 | result success | Cubit success |
| R10 | result partial | Cubit partial |
| R11 | result failure | Cubit failure |
| R12 | save/reload | calculation parity |
| R13 | Default Wall | never persisted as WallSpec |

---

# 19. VERIFICATION

Chạy:

```bash
flutter analyze
```

Nếu Flutter analyzer gặp lỗi môi trường:

```bash
dart analyze
```

Sau đó bắt buộc:

```bash
flutter test
```

Phải chạy **toàn bộ test suite**, không chỉ test mới.

Nếu môi trường hỗ trợ:

```bash
flutter build apk --debug
```

---

# 20. FINAL REPORT

Tạo:

```text
PHASE2.1R_FIX-CALC-001-RESIDUAL-REPORT.md
```

Report phải có:

```text
1. Commit trước khi sửa
2. Commit sau khi sửa
3. Files changed
4. P1 invalid WallSpec — root cause + fix
5. P1 missing quantity — root cause + fix
6. P2 state synchronization — root cause + fix
7. Tests added/updated
8. Full test result
9. Analyze result
10. APK build result nếu có
11. Remaining known issues
12. Confirmation:
    - WallSpec vẫn optional
    - Default Wall vẫn đúng công thức
    - Explicit WallSpec vẫn override Default Wall
    - Không calculator formula nào bị rewrite
    - Không mở scope FIX-CALC-002/003/004
```

---

# 21. DEFINITION OF DONE

```text
[ ] walls empty vẫn hợp lệ
[ ] walls empty + wall-dependent material → Default Wall
[ ] explicit valid walls → explicit calculation
[ ] invalid WallSpec → structured error
[ ] invalid WallSpec NEVER fallback Default Wall
[ ] valid + invalid → error
[ ] no double-count

[ ] quantity == null không còn silent drop
[ ] known unsupported → warning
[ ] unknown/unmapped → explicit issue
[ ] custom missing quantity → explicit issue
[ ] không null → 0 để che lỗi

[ ] Cubit và Result không còn status mâu thuẫn
[ ] ProjectDetailPage dùng một source of truth rõ ràng
[ ] raw exception không hiển thị cho user

[ ] regression tests pass
[ ] flutter test PASS
[ ] flutter analyze hoặc dart analyze PASS
[ ] APK debug build PASS nếu có thể
[ ] final residual report được tạo
```

---

# 22. FINAL BUSINESS RULE

AI Agent phải ghi nhớ và bảo vệ nguyên tắc sau trong toàn bộ implementation:

```text
                    WallSpec
                       │
             ┌─────────┴─────────┐
             │                   │
          EMPTY              NON-EMPTY
             │                   │
             ▼                   ▼
       Default Wall        Validate ALL
                                 │
                         ┌───────┴────────┐
                         │                │
                       VALID           INVALID
                         │                │
                         ▼                ▼
                 Explicit WallSpec    STRUCTURED ERROR
```

Tuyệt đối không được biến:

```text
NON-EMPTY + INVALID
```

thành:

```text
EMPTY
```

Đồng thời:

```text
quantity == null
```

phải luôn có trạng thái rõ ràng, và:

```text
Result.status
```

phải là nguồn xác định trạng thái calculation hoàn tất.

**End of PHASE 2.1R Residual Fix Specification.**
