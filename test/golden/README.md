# GATE 6 — GOLDEN REGRESSION

## Source of truth

| Item | Giá trị |
|---|---|
| Legacy repo | `https://github.com/MinhPro999/nha_save.git` |
| Legacy branch | `main_toiuucodebase_wizard` |
| **Legacy SHA** | `e5fc8943daaab5953c75bd161061cd83a934b5fd` |
| Local authoritative clone | `/Users/m.mac/app_dev/nha_save` (bắt buộc khớp SHA) |

TUYỆT ĐỐI không dùng clone `.../coder/nha_save` nếu SHA không khớp.

## Cách expected value được sinh (provenance)

Expected values trong `test/golden/expected/<caseId>.json` được sinh bằng cách
**chạy trực tiếp code legacy tại SHA `e5fc8943`** — không lấy từ implementation mới:

1. `dart run tool/golden/sync_oracle.dart [legacyRepoPath]`
   — verify `git rev-parse HEAD` == `e5fc8943...` (sai SHA → TỪ CHỐI),
   rồi copy 17 file calculation legacy **byte-exact** vào
   `tool/golden/oracle_src/` (thư mục generated, gitignored).
2. `dart run tool/golden/generate_expected.dart`
   — với mỗi canonical case trong `test/golden/cases/`, chạy
   `MaterialCalculator.calculateMaterialsFromDetailedParams` +
   `FoundationStructureCalculator.calculate` của **legacy**, ghi JSON kèm
   `sourceSha` + `generatedAt`.

Canonical cases (`test/golden/cases/`) chứa ĐỦ hai phía cho mỗi case:
- `project` — input new UI (chạy qua LegacyInputMapper → calculator_core → LegacyResultMapper).
- canonical legacy input (`detailedParams`, `selectedMaterialIds`,
  `brickDimensions`, `floors`, `foundation`) — input chính xác cho legacy
  (author theo contract Gate 4, PHASE2_MAPPING_SPEC.md).

## Chạy regression

```bash
flutter test test/golden/golden_regression_test.dart
```

Test so sánh 3 tầng:
1. **INPUT STAGE** — `LegacyInputMapper` phải tạo đúng canonical legacy input.
2. **CALCULATION** — quantity từ `LegacyCalculationService` khớp **exact** với
   legacy oracle (legacy đã `roundToDecimal(...,2)`; so sánh exact, không tolerance).
3. **RESULT** — join theo legacy selection key (không mất `'Thép'`/`'Bê tông'`/`'Nhôm'`);
   foundation section khớp từng field; cost = `unitPrice × quantity`; totalCost = Σ.

Khi fail, diagnostic chỉ rõ: `CASE / FIELD / LEGACY / NEW / DELTA / STAGE`.

## Phân loại discrepancy (nếu phát sinh)

1. LEGACY ORACLE ISSUE · 2. INPUT MAPPING ISSUE · 3. CALCULATOR CORE PARITY ISSUE ·
4. RESULT MAPPING ISSUE · 5. COST CONVENTION ISSUE · 6. UI DOMAIN GAP ·
7. TEST HARNESS ISSUE · 8. TOOLING ISSUE

→ STOP, không tự sửa formula để match. Báo cáo và chờ review.
