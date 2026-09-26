# PHASE 2.1R — FIX-CALC-001 RESIDUAL REPORT

> Báo cáo hoàn tất residual fix theo `PHASE2.1R_FIX-CALC-001_RESIDUAL.md`.
> Ngày thực hiện: 2026-09-27. Branch: `main_phase2`.

---

## 1. Commit trước khi sửa

```text
cc9410a  PHASE2.1 FIX-CALC-001-wall-dependent done
```

## 2. Commit sau khi sửa

```text
d1006cf  PHASE2.1R FIX-CALC-001 residual: invalid WallSpec structured error,
         missing quantity issues, cubit/result status sync
```

## 3. Files changed

```text
lib/features/projects/domain/services/calculation/legacy_input_mapper.dart      (sửa)
lib/features/projects/domain/services/calculation/legacy_calculation_service.dart (sửa)
lib/features/projects/domain/services/calculation/legacy_result_mapper.dart     (sửa)
lib/features/projects/presentation/bloc/project_state.dart                      (sửa)
lib/features/projects/presentation/bloc/project_cubit.dart                      (sửa)
lib/features/projects/presentation/pages/project_detail_page.dart               (sửa)
lib/l10n/vi.json                                                                (sửa)
lib/l10n/en.json                                                                (sửa)
test/calculation_service_test.dart                                              (sửa)
test/unit_consistency_audit_test.dart                                           (sửa)
test/project_calculation_status_sync_test.dart                                  (mới)
PHASE2.1R_FIX-CALC-001_RESIDUAL.md                                              (spec, thêm vào repo)
```

12 files changed, 1502 insertions(+), 58 deletions(-).

## 4. P1 — Invalid WallSpec: root cause + fix

### Root cause

`LegacyInputMapper.mapMaterialInput` dùng filter để quyết định list rỗng:

```dart
final explicitWalls = details.walls
    .where((wall) => wall.length > 0 && wall.height > 0)
    .toList();
```

Khi `details.walls` non-empty nhưng chứa item không hợp lệ, filter bỏ item
invalid → `explicitWalls = []` → mapper tưởng "không có WallSpec" → fallback
Default Wall. `NON-EMPTY + INVALID` bị biến thành `EMPTY`, vi phạm business rule.

### Fix

- Mapper chuyển sang logic 3 nhánh theo spec mục 4:
  - `walls.isEmpty` → Default Wall (chỉ khi có wall-dependent material);
  - non-empty + có item invalid → **ném `InvalidWallSpecException`** (typed
    exception, boundary dữ liệu — cùng chính sách với `mapSteelDiameter`);
  - non-empty + all valid → dùng đúng WallSpec, không cộng Default.
- `LegacyCalculationService.calculate` bắt exception và trả
  `ProjectCalculationResult` failure với
  `CalculationIssue(section: 'walls', code: 'invalid_wall_spec', severity: error)`.
- UI tra l10n theo code `calc_issue_invalid_wall_spec` (vi + en) — không parse
  `error.toString()`, không in raw exception.
- Không thay đổi wizard validation (`walls empty → valid`; `invalid → invalid`
  giữ nguyên), không thay đổi công thức `DefaultWallCalculator`.

## 5. P1 — Missing quantity: root cause + fix

### Root cause

`LegacyResultMapper.mapMaterialResult` chỉ xử lý `quantity == null` cho 6 mã
`unsupportedCatalogCodes` (warning `material_not_supported`). Mọi material khác
bị `continue` im lặng — material chọn rồi biến mất khỏi result không issue.

### Fix

- `quantity == null` giờ luôn có trạng thái rõ ràng:
  - known unsupported (6 mã) → warning `material_not_supported` (giữ Phase 6);
  - unknown/unmapped/custom còn lại → **error `material_calculation_missing`**,
    `materialCode = catalogCode` (null với vật liệu tùy chỉnh);
  - ngoại lệ duy nhất: nếu `legacyResults['errors']` đã có lỗi section thì
    nguyên nhân đã được báo → không double-report per-material.
- KHÔNG đổi `null → 0` để che missing calculation (giữ distinction 0 vs null).
- UI tra l10n `calc_issue_material_calculation_missing` (vi + en).

## 6. P2 — State synchronization: root cause + fix

### Root cause

`ProjectCubit.calculate` luôn ghi `calculationStatus: success` sau khi nhận
result, trong khi `ProjectCalculationResult.status` có thể là `partial`/`failure`
→ 2 source of truth mâu thuẫn. `ProjectDetailPage` đọc cả hai nguồn.

### Fix

- `ProjectCalculationStatus` thêm giá trị `partial`:
  `idle, calculating, success, partial, failure`.
- `ProjectCubit.calculate` map 1-1:

```dart
final status = switch (result.status) {
  'success' => ProjectCalculationStatus.success,
  'partial' => ProjectCalculationStatus.partial,
  'failure' => ProjectCalculationStatus.failure,
  _ => ProjectCalculationStatus.failure,
};
```

- `ProjectDetailPage` chỉ đọc `calculationStatus` (single source of truth),
  không derive lại từ `result.status`; failure banner vẫn fallback
  `unknown_calculation_error` khi exception tầng ngoài (result null).
- `calculationError` giữ nguyên cho exception tầng ngoài, không dùng truyền
  lỗi WallSpec mới, không hiển thị raw exception.

## 7. Tests added/updated

### `test/calculation_service_test.dart`

- REG-003 cập nhật: `length=0,height=0` → error `invalid_wall_spec`, KHÔNG Default Wall.
- REG-R3 (mới): `[valid, invalid]` → error, KHÔNG fallback, KHÔNG tự bỏ item.
- REG-R4 (mới): `[length=0,height=3]` → error, KHÔNG Default Wall.
- REG-R5 (mới): `[length=5,height=0]` → error, KHÔNG Default Wall.
- REG-R6 (mới): `tile` → warning `material_not_supported`.
- REG-R7 (mới): `future_material` null quantity → error `material_calculation_missing`.
- REG-R8 (mới): brick + tile + future_material → brick line giữ, warning + error độc lập.
- custom material (catalogCode null) → error `material_calculation_missing`.
- section error → KHÔNG double-report per-material.

### `test/project_calculation_status_sync_test.dart` (mới)

- R9: result success → Cubit success.
- R10: result partial → Cubit partial.
- R11: result failure → Cubit failure (không dùng calculationError).
- exception tầng ngoài → Cubit failure + calculationError, result null.

### `test/unit_consistency_audit_test.dart`

- 6 unsupported codes qua full service → warning `material_not_supported`, không dòng.
- unknown catalog qua full service → error `material_calculation_missing`.

## 8. Full test result

```text
flutter test
→ +145: All tests passed!
```

20/20 test files chạy (bao gồm golden regression, e2e persistence, widget tests).
Chạy lại riêng 3 file liên quan: 31/31 pass.

## 9. Analyze result

- `flutter analyze`: analysis server crashed (lỗi môi trường, không phải code).
- `dart analyze` (fallback theo spec): **PASS — 0 errors, 0 warnings**.
  9 info lints còn lại đều pre-existing trong `calculator_core` và
  `tool/golden/oracle_src` (ngoài scope) + 1 trong test cũ — không thuộc
  thay đổi này.

## 10. APK build result

```text
flutter build apk --debug
→ ✓ Built build/app/outputs/flutter-apk/app-dev-debug.apk (521.1s)
```

PASS. (Có warning khuyến nghị nâng Gradle 8.14 → 9.1, AGP 8.11.1 → 9.0.1,
Kotlin 2.2.20 → 2.3.20 — ngoài scope, không chặn build.)

## 11. Remaining known issues

- FIX-CALC-002: 6 material chưa có aggregated formula (tile, roof_tile,
  metal_sheet, insulated_metal_sheet, exterior_paint, composite_door) — hiện
  báo warning minh bạch.
- FIX-CALC-003: `aluminum_door` unit mismatch (kg vs m²) + gợi ý đơn vị
  cement/steel — có registry trong `unit_consistency_audit_test.dart`.
- FIX-CALC-004: foundation hard-code assumptions.
- FUNCTIONAL GAP: gypsum ceiling area (luôn 0.0).
- BUSINESS ESTIMATE: Default Wall factor 1.5 (ước lượng có chủ đích).

## 12. Confirmation

- [x] WallSpec vẫn optional (wizard không bắt buộc nhập tường).
- [x] Default Wall vẫn đúng công thức (`DefaultWallCalculator` không đổi).
- [x] Explicit WallSpec vẫn override Default Wall (không double-count).
- [x] KHÔNG calculator formula nào bị rewrite (không sửa Brick/Cement/Sand/
      Paint/Steel/FoundationStructure calculator).
- [x] KHÔNG mở scope FIX-CALC-002/003/004.

### Definition of Done

- [x] walls empty vẫn hợp lệ
- [x] walls empty + wall-dependent material → Default Wall
- [x] explicit valid walls → explicit calculation
- [x] invalid WallSpec → structured error
- [x] invalid WallSpec NEVER fallback Default Wall
- [x] valid + invalid → error
- [x] no double-count
- [x] quantity == null không còn silent drop
- [x] known unsupported → warning
- [x] unknown/unmapped → explicit issue
- [x] custom missing quantity → explicit issue
- [x] không null → 0 để che lỗi
- [x] Cubit và Result không còn status mâu thuẫn
- [x] ProjectDetailPage dùng một source of truth rõ ràng
- [x] raw exception không hiển thị cho user
- [x] regression tests pass
- [x] flutter test PASS (145/145)
- [x] dart analyze PASS (flutter analyze gặp lỗi môi trường)
- [x] APK debug build PASS
- [x] final residual report được tạo
