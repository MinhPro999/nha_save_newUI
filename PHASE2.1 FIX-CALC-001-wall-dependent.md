# PHASE 2.1 — Báo cáo thực thi FIX-CALC-001 (Wall-dependent material validation)

> **Ngày thực hiện:** 2026-09-22
> **Kế hoạch nguồn:** `FIX-CALC-001-wall-dependent-material-validation.md`
> **Nhánh:** `main_phase2`
> **Trạng thái:** ✅ HOÀN THÀNH — toàn bộ 12 STEP đã thực thi đúng thứ tự, mọi test PASS.

---

## 1. Tóm tắt

Bug gốc: project chọn "Sơn nội thất" (Step 4) nhưng bỏ qua nhập Tường (Step 5, `details.walls = []`) → `PaintCalculator` throw `ArgumentError('Diện tích sơn nội thất phải lớn hơn 0')` → exception làm sập **toàn bộ** `MaterialCalculator.calculateMaterialsFromDetailedParams` (móng/cửa/WC/cầu thang phía sau không bao giờ được tính) → `ProjectCubit` bắt lỗi, `calculationResult = null` → UI hiện **exception thô** + 2 panel **"chưa chọn vật tư"** (sai, gây hiểu lầm).

Giải pháp đã triển khai đúng chiến lược chốt sẵn: **WallSpec là dữ liệu tuỳ chọn** — không nhập thì dùng **Default Wall Calculator** ước lượng từ kích thước tầng (chấp nhận sai số có chủ đích, minh bạch với người dùng), kèm cô lập lỗi theo nhóm vật liệu và chuẩn hoá trạng thái kết quả.

---

## 2. Quy trình thực thi (đúng thứ tự STEP 1–13)

| STEP | Nội dung | Kết quả |
|---|---|---|
| 1 | Audit toàn bộ file trong checklist mục 15 (không sửa code) | ✅ |
| 2 | Viết regression test `REG-001` tái hiện bug | ✅ FAIL đúng lỗi ảnh chụp (`paint_calculator.dart:85`) |
| 3 | Phase 1 — `DefaultWallCalculator` + test | ✅ 5/5 test pass |
| 4 | Phase 2 — `LegacyInputMapper` ưu tiên WallSpec / fallback Default Wall + test | ✅ REG-001 chuyển FAIL → PASS |
| 5 | Phase 3 — xác nhận wizard không chặn walls rỗng (chỉ thêm comment) + test | ✅ 2 case cubit pass |
| 6 | Phase 4 (`CalculationIssue`) + Phase 5 (cô lập lỗi theo nhóm) + test | ✅ |
| 7 | Phase 6 — audit + xử lý minh bạch 6 catalogCode unsupported | ✅ |
| 8 | Phase 7 (đơn vị tính), 8 (API trùng lặp), 9 (hard-code móng) — chỉ audit | ✅ ghi nhận mục 6 |
| 9 | Phase 10 (UI 4 trạng thái + nhãn minh bạch) + Phase 11 (l10n) | ✅ |
| 10 | Chạy toàn bộ test tổng hợp + golden | ✅ 131/131 PASS |
| 11 | Analyze toàn repo | ✅ 0 errors / 0 warnings (`dart analyze`) |
| 12 | Smoke-test compile toàn luồng (`flutter build apk --debug`) | ✅ build thành công |
| 13 | Báo cáo cuối (file này) | ✅ |

---

## 3. Default Wall logic (Phase 1–2)

**Vị trí:** `lib/features/projects/domain/services/calculation/default_wall_calculator.dart` — **một nguồn tính duy nhất**, ở tầng domain, không đụng `calculator_core`.

**Công thức (chủ dự án cung cấp):** $S = \sum_{\text{tầng}} 2 \times (L + W) \times H \times 2 \times 1.5$ — tính trên `project.floors` thực tế, **không bao gồm mái** (field `roof` đã tách sẵn khỏi `floors` trong entity — đã xác minh, không cần enum/flag mới).

**Cách sinh entry** (2 entry/tầng để tái tạo đúng công thức & giữ đúng tỉ lệ tường 10/20 cho gạch/xi măng/cát):
- Entry A — "tường bao 20": `length = perimeter`, `height = H`, `type = '20'`, `plasterSides = 2`
- Entry B — "tường ngăn 10 (ước lượng)": `length = perimeter × 0.5`, `height = H`, `type = '10'`, `plasterSides = 2`

→ Tổng trát = `(P×H×2) + (P×0.5×H×2) = P×H×2×1.5` — khớp 100% công thức, tương thích nguyên vẹn mọi calculator hiện có.

**Quy tắc ưu tiên trong `LegacyInputMapper` (Phase 2):**
- Có ≥ 1 WallSpec hợp lệ (`length > 0 && height > 0`) → dùng **đúng và chỉ** các item hợp lệ, không cộng dồn default.
- Trống/toàn bộ item sai → Default Wall (khi có vật liệu phụ thuộc tường được chọn).
- Không trộn lẫn 2 nguồn trong cùng 1 lần tính (chống double-count).

> **Ghi chú thích ứng (giữ nguyên kết quả golden):** fallback Default Wall có điều kiện "có vật liệu phụ thuộc tường" (`WallDependencyHelper.hasWallDependentMaterial`). Golden cases foundation-only có `selectedMaterialIds = []` → walls vẫn là `[]` đúng canonical input → 44 golden test không đổi. Entry explicit **không** thêm key `isDefaultEstimate` (golden deep-compare shape legacy).

---

## 4. Thay đổi kiến trúc calculation

- `project_calculation_result.dart`: thêm `CalculationIssueSeverity { warning, error }`, `CalculationIssue` (section/code/severity/materialCode) và `ProjectCalculationResult.issues` + `hasErrors/hasWarnings/status` (`success | partial | failure`).
- `material_calculator.dart` (Phase 5 — thay đổi **duy nhất** được phép trong `calculator_core`): bọc 4 nhóm walls/foundation/doors/others trong try/catch riêng, lỗi đưa vào `calculationErrors` (key section) và trả trong `errors` — **không đổi 1 dòng công thức, không nuốt lỗi**.
- `legacy_result_mapper.dart`: `_mapIssues` map message legacy → code ổn định (`walls_calculation_failed`, `unknown_calculation_error`); `combine()` giữ nguyên issues; Phase 6: `quantity == null` + catalogCode ∈ `unsupportedCatalogCodes` → sinh warning `material_not_supported` thay vì `continue` im lặng.
- `legacy_material_selection_key_mapper.dart`: audit đầy đủ 19 catalogCode — thêm `supportedCatalogCodes` (13) và `unsupportedCatalogCodes` (6: `tile`, `roof_tile`, `metal_sheet`, `insulated_metal_sheet`, `exterior_paint`, `composite_door`) kèm tài liệu audit từng nhánh.
- `wall_dependency_helper.dart`: set 5 mã phụ thuộc tường (`brick`, `cement`, `sand`, `plaster_sand`, `interior_paint`) + `usesDefaultWallEstimate` — dùng chung cho mapper (Phase 2) và UI banner (Phase 10).

---

## 5. Trạng thái & UI (Phase 10–11)

4 trạng thái chuẩn hoá trong `project_detail_page.dart`:

| Trạng thái | Điều kiện | Hiển thị |
|---|---|---|
| A. Chưa chọn vật tư | `project.materials.isEmpty` | `project_no_materials` (đúng nghĩa) |
| B. Lỗi hoàn toàn | `calculationStatus == failure` **hoặc** `status == 'failure'` | `_CalculationIssuesBanner` theo code — **không** in `error.toString()` thô, **không** dùng `project_no_materials` |
| C. Thành công một phần | `status == 'partial'` | đầy đủ dòng đã tính + banner cảnh báo (issues) |
| D. Thành công hoàn toàn | `status == 'success'` | như cũ |

- Banner issues: tra `context.tr('calc_issue_${issue.code}')`; nếu có `materialCode` ghép tên vật liệu bằng Dart (l10n không hỗ trợ interpolation); CTA `project_edit_cta`.
- Banner minh bạch "Ước tính" (`project_default_wall_banner` + hint): **phương án tối giản** của Phase 10.3 — banner chung ở đầu trang khi `WallDependencyHelper.usesDefaultWallEstimate(project)`, không gắn badge từng dòng (đã ghi chú lựa chọn).
- l10n: thêm 8 khoá vào **cả** `vi.json` và `en.json`, đã kiểm set khoá **258/258 đồng bộ 100%**.

---

## 6. Kết quả audit (Phase 6/7/8/9)

### Phase 6 — catalog mapping (đã audit từng nhánh `_calculate*`)
- **13 supported** có key + nhánh tính thật.
- **6 unsupported**: có method tính riêng trong calculator_core nhưng **không** được nối vào `calculateMaterialsFromDetailedParams`. Xử lý FIX-CALC-001: chỉ **báo cáo minh bạch** (warning issue) — bổ sung công thức là scope **FIX-CALC-002**.

### Phase 7 — đơn vị tính (khuyến nghị sửa ngay → mở FIX-CALC-003)
- ⚠️ **`aluminum_door` — trộn đơn vị:** `_calculateDoorMaterials` lấy diện tích cửa (m²) × 3 ("3kg/m²") → quantity thực chất là **kg**, nhưng catalog niêm yết `m2` (giá/m²) → `cost = VNĐ/m² × kg`. Đã đăng ký trong `knownUnitMismatches` của audit test. **Không tự sửa hệ số** (cần chủ dự án xác nhận đơn vị đúng).
- Gợi ý wizard để `cement`/`steel` unit `kg` trong khi catalog + calculator dùng `ton` (unitPrice = 0 nên không ảnh hưởng cost, chỉ nhãn hiển thị) — ghi nhận cho FIX-CALC-003.
- 12 mã còn lại khớp: brick=piece, sand/plaster_sand/stone/concrete_sand=m³, cement/steel=tấn, sơn/thạch cao/nhân công=m².

### Phase 8 — API trùng lặp / dead code (đánh dấu `@Deprecated`, không xoá)
- 6 delegate unsupported (`calculateTile6060Quantity`, `calculateRoofTileQuantity`, `calculateMetalSheetQuantity`, `calculateInsulatedMetalQuantity`, `calculateExteriorPaintQuantity`, `calculateCompositeDoorQuantity`).
- `calculateCustomMaterialQuantity` — không có caller nào trong `lib/`.
- `calculateConcreteSandQuantity` — đường chạy thật gán thẳng `foundationVolume` cho 'Bê tông' (khác ngữ nghĩa hàm `volume × 0.7`).
- Legacy models: `Brick.calculateQuantity` (throw `UnimplementedError`), `Material.calculateCost/getFormattedQuantity/getFormattedCost`.

### Phase 9 — hard-code móng (chỉ ghi nhận, input cho FIX-CALC-004)
- `material_calculator._calculateFoundationMaterials`: giả định móng `0.3m × 0.5m`; thép `quantity: 10` thanh; đá `volume × 0.7`.
- `foundation_structure_calculator.dart`: `cement 430 kg/m³`, `sand 0.45`, `stone 0.86`, `water 185 L`, `lNeo 0.8`, hao hụt 3%/5%, `bw/bh = 0.3/0.5`, `nMainBeam = 4`, sàn bè `0.1 m`, `matDoThanh = 5 thanh/m`.

---

## 7. Danh sách test

**Mới:**
- `test/default_wall_calculator_test.dart` — 5 case (số liệu 356.4 m², cộng dồn Σ, bỏ tầng height=0, floors rỗng, deterministic).
- `test/unit_consistency_audit_test.dart` — audit 13 mã supported (cost = quantity × unitPrice + khớp đơn vị, fail rõ nếu lệch ngoài registry).
- `test/wall_dependent_material_helper_test.dart` — 5 case quyết định banner "Ước tính".
- `test/project_wizard_widget_default_wall_test.dart` — wizard chọn interior_paint, bỏ Tường → hoàn tất thành công.
- `test/project_detail_widget_default_wall_test.dart` — detail page: không exception thô, hiện đủ dòng + banner "Ước tính".

**Sửa/bổ sung:**
- `test/calculation_service_test.dart` — REG-001…004; 2 case cô lập lỗi nhóm (Phase 5); 1 case unsupported warning (Phase 6); 2 case cost convention + props (Phase 12).
- `test/project_wizard_cubit_test.dart` — 2 case Phase 3 (không chặn walls rỗng; WallSpec sai số vẫn reject).
- `test/e2e/project_calculation_persistence_e2e_test.dart` — 1 E2E Default Wall: quantity 356.4, không issue, save/reload **không ghi ngược** dữ liệu ước lượng vào DB.

> **Ghi chú harness:** pump `ConstructionPlanApp` 2 lần trong cùng 1 file test làm `rootBundle.loadString` của l10n treo ở lần 2 (không render Navigator) → 2 widget test mới được đặt ở file riêng; 2 file widget test gốc không thay đổi.

---

## 8. Kết quả kiểm tra

| Hạng mục | Kết quả |
|---|---|
| `flutter test` (toàn bộ) | **131/131 PASS** — gồm 44 golden test **không đổi kết quả** |
| `dart analyze` (toàn repo) | **0 errors / 0 warnings** (9 info-lint legacy sẵn có) |
| `flutter build apk --debug` | ✅ `build/app/outputs/flutter-apk/app-dev-debug.apk` |
| l10n vi/en key sync | ✅ 258/258 |

*`flutter analyze` crash analysis server trên máy này (môi trường sẵn có) → dùng `dart analyze` thay thế với kết quả tương đương.*

---

## 9. Known issues / tồn đọng

1. **FIX-CALC-003** — trộn đơn vị `aluminum_door` (kg vs m²) + nhãn gợi ý `cement`/`steel` = kg (cần chủ dự án xác nhận trước khi sửa hệ số quy đổi).
2. **FIX-CALC-002** — 6 catalogCode unsupported chưa có công thức (đang báo warning minh bạch).
3. **FIX-CALC-004** — giả định hard-code trong công thức móng cần audit chuyên sâu.
4. `gypsumCeilingArea = 0.0` (FUNCTIONAL GAP) — Thạch cao luôn quantity 0 đến khi bổ sung UI input.
5. Hệ số 1.5 Default Wall là ước lượng có chủ đích — đã có banner minh bạch; nếu lệch thực tế lớn cần kế hoạch hiệu chỉnh riêng.
6. Kiểm tra thủ công trên thiết bị thật (tạo dự án → Step 1-5 → detail → calculation → material → cost) là bước cuối cho người dùng xác nhận bằng mắt.

---

## 10. Definition of Done

```text
[x] Bug trong ảnh chụp được tái hiện bằng regression test TRƯỚC khi sửa (REG-001 FAIL)
[x] Bug ĐÃ SỬA bằng cùng regression test SAU khi sửa (REG-001 PASS)
[x] WallSpec vẫn là dữ liệu tuỳ chọn — wizard KHÔNG chặn hoàn tất khi walls rỗng
[x] Explicit WallSpec (item hợp lệ) luôn ưu tiên, KHÔNG cộng dồn Default Wall
[x] WallSpec nhập sai (length/height <= 0 trên item đã tồn tại) vẫn bị wizard từ chối
[x] Default Wall đúng công thức Σ[2×(L+W)×H×2×1.5], test khẳng định số liệu 356.4 m²
[x] Default Wall chỉ tính trên floors, roof (field tách biệt) không bị tính nhầm
[x] Sơn nội thất + brick/cement/sand/plaster_sand hoạt động đúng khi không có WallSpec
[x] Một material lỗi không còn làm sập toàn bộ calculation (cô lập theo nhóm)
[x] CalculationIssue có cấu trúc thay cho exception string ở domain layer
[x] Không còn material "biến mất" khỏi kết quả mà không có issue (6 mã unsupported → warning)
[x] Catalog mapping audited — mỗi mã có trạng thái supported/unsupported rõ ràng
[x] Đơn vị tính audited toàn bộ material supported, có test cost = quantity × unitPrice
[x] API trùng lặp/dead code trong calculator_core audited + @Deprecated (không xoá)
[x] Giả định hard-code móng audited + ghi nhận (không sửa)
[x] UI phân biệt 4 trạng thái: chưa chọn / lỗi hoàn toàn / thành công một phần / thành công
[x] Không còn hiển thị exception thô (error.toString()) cho người dùng cuối
[x] Không còn hiển thị "chưa chọn vật tư" khi thực tế là lỗi tính toán
[x] Có cơ chế minh bạch "ước tính mặc định" (banner toàn trang — phương án tối giản)
[x] MockCalculationService không bị sửa để che bug production
[x] Không có dòng công thức nào trong calculator_core bị thay đổi ngoài orchestration đã duyệt
[x] l10n vi/en đồng bộ 100% khoá (258/258, kiểm bằng script)
[x] analyze: 0 lỗi/warning mới (dart analyze — flutter analyze crash môi trường)
[x] flutter test: 131/131 pass, 44 golden không đổi kết quả
```
