# PHASE2 — CALCULATION CORE MANIFEST (Gate 1)

> Sinh bởi AI Agent — Gate 1: Source Audit + Dependency Graph.
> Ngày: 2026-09-16
> Source of truth: `https://github.com/MinhPro999/nha_save.git` — branch `main_toiuucodebase_wizard`
> Legacy SHA đối chiếu: `e5fc8943daaab5953c75bd161061cd83a934b5fd`
> Local clone tham chiếu: `/Users/m.mac/app_dev/nha_save` (khớp SHA remote, read-only)
> New UI repo: `https://github.com/MinhPro999/nha_save_newUI.git` — `main` @ `0a20fe5b2d5eea36fdbfd3cecb206826b25013bc`

---

## 1. ENTRY POINTS (đã xác minh từ legacy source)

### 1.1. Material (tổng hợp)
- `lib/calculator_core/services/material_calculator.dart`
  - `MaterialCalculator.calculateMaterialsFromDetailedParams(detailedParams, {selectedMaterialIds, brickDimensions, floors})`
  - Trả về: `{quantities, costs, intermediateResults}`
  - ⚠️ `costs` **luôn là `{}`** và `intermediateResults` **luôn là `{}`** trong bản legacy này (đã xác minh bằng grep: không có chỗ nào gán). Cost phải được tính ở adapter/use case từ price snapshot × quantity.
  - 21 method static đơn lẻ: `calculateBrickQuantity`, `calculateSandQuantity`, `calculatePlasteringSandQuantity`, `calculateCementQuantity`, `calculateWaterQuantity`, `calculateSteelQuantity`, `calculateStoneQuantity`, `calculateConcreteSandQuantity`, `calculateTile6060Quantity`, `calculateRoofTileQuantity`, `calculateMetalSheetQuantity`, `calculateInsulatedMetalQuantity`, `calculateGypsumQuantity`, `calculateExteriorPaintQuantity`, `calculateInteriorPaintQuantity`, `calculateAluminumDoorQuantity`, `calculateCompositeDoorQuantity`, `calculateLaborQuantity`, `calculatePlumbingLaborQuantity`, `calculatePlumbingMaterialQuantity`, `calculateCustomMaterialQuantity`, `calculateTotalFloorArea`.

### 1.2. Foundation structure
- `lib/calculator_core/services/foundation_structure_calculator.dart`
  - `FoundationStructureCalculator.calculate({required FoundationStructureData foundationData, required double l1, w1, area1, hTotal})`
  - Trả về: `FoundationStructureResult` (concrete m³, cement kg, sand m³, stone m³, water L, steel kg cho cột/móng/tổng + quy đổi bags50kg/ton/m³).

### 1.3. Calculators (public classes)
- `calculators/brick_calculator.dart` → `BrickCalculator` (private `_Wall`)
- `calculators/cement_calculator.dart` → `CementCalculator` (private `_Wall`)
- `calculators/sand_calculator.dart` → `SandCalculator`, `PlasteringSandCalculator` (private `_Wall`)
- `calculators/steel_calculator.dart` → `SteelCalculator`
- `calculators/stone_calculator.dart` → `StoneCalculator`
- `calculators/tile_calculator.dart` → `TileCalculator`
- `calculators/paint_calculator.dart` → `PaintCalculator`
- `calculators/door_calculator.dart` → `DoorCalculator`
- `calculators/custom_material_calculator.dart` → `CustomMaterialCalculator`

### 1.4. Input contract chi tiết của `calculateMaterialsFromDetailedParams`
```text
detailedParams = {
  'walls': {
     'walls': [ {'type': '10'|'20', 'length': num, 'height': num, 'plasterSides'?: int}, ... ],
     'area'?: num                       // dùng khi không có danh sách walls
  },
  'foundation': { 'lengths': [num,...] } | { 'length': num },   // ưu tiên 'lengths'
  'doors': {
     'windows':      [ {'width','height','quantity'?}, ... ],
     'doors':        [ {'width','height','quantity'?}, ... ],
     'rollingDoors': [ {'width','height','quantity'?}, ... ],
  },
  'others': { 'gypsumCeilingArea'?: num }
}
selectedMaterialIds = List<String>   // key tiếng Việt: 'Gạch xây','Xi măng','Cát xây','Cát trát',
                                     // 'Nước','Sơn nội thất','Bê tông','Thép','Đá','Nhôm',
                                     // 'Nhân công xây dựng','Nhân công điện nước','Vật tư điện nước','Thạch cao'
brickDimensions = {'length': 0.22, 'width': 0.10, 'height': 0.05} (default nếu null)
floors = [ {'area': num}, ... ]      // CalculationUtils.calculateTotalFloorArea chỉ đọc floor['area']
```
Output: `quantities` key bằng **tên tiếng Việt** (vd `'Gạch xây'`, `'Xi măng'`…), giá trị đã `roundToDecimal(...,2)`.

---

## 2. FILES HIỆN CÓ TRONG `lib/calculator_core/` — PHÂN LOẠI

Phân loại dựa trên **dependency thực tế** (import + usage), không theo tên file.

### 2.1. KEEP (trong dependency closure — bắt buộc)
| File | Lý do |
|---|---|
| `services/material_calculator.dart` | Entry point tổng hợp; import 9 calculators + calculation_utils |
| `services/foundation_structure_calculator.dart` | Entry point móng; import foundation_structure_model |
| `calculators/brick_calculator.dart` | Dùng `WallType` (brick.dart), constants, calculation_utils |
| `calculators/cement_calculator.dart` | constants, calculation_utils + **import brick_calculator.dart** (calculator→calculator) |
| `calculators/sand_calculator.dart` | brick.dart, constants, calculation_utils + brick_calculator |
| `calculators/steel_calculator.dart` | constants, calculation_utils |
| `calculators/stone_calculator.dart` | calculation_utils |
| `calculators/tile_calculator.dart` | dart:math, constants, calculation_utils |
| `calculators/paint_calculator.dart` | calculation_utils |
| `calculators/door_calculator.dart` | calculation_utils |
| `calculators/custom_material_calculator.dart` | constants, calculation_utils |
| `constants/construction_constants.dart` | Không import gì; constants Hybrid + TCVN (không được sửa) |
| `utils/calculation_utils.dart` | Không import gì; validation/rounding/conversion (không được sửa semantics) |
| `utils/number_formatter.dart` | **KEEP** — được `models/material_model.dart` import (compile + `getFormattedQuantity/Cost`) |
| `models/material_model.dart` | `MaterialType`, `MeasurementUnit`, `Material` — được `brick.dart` extend |
| `models/brick.dart` | `WallType` (runtime, dùng trong switch ở brick/sand calculator), `Brick` (compile) |
| `models/project/foundation_structure_model.dart` | **KEEP** — self-contained, được foundation calculator import; định nghĩa `FoundationTypeNew`, `SteelDiameter`, `ColumnInfo`, `Foundation*Info`, `FoundationStructureData`; có `fromMap/toMap` |

### 2.2. DROP / BRIDGE — ĐÃ XỬ LÝ TẠI GATE 2
| File | Kết quả | Chứng cứ |
|---|---|---|
| `utils/wall_calculator.dart` | **ĐÃ XÓA (Gate 2)** | Xác nhận cuối: (1) không file core nào import — `paint_calculator.dart:39` chỉ nhắc tên trong **comment**; (2) zero reference ngoài core (lib + test); (3) legacy chỉ có UI `lib/tabs/add_house_tab.dart` dùng (input helper cho tab cũ), không thuộc calculation closure. New UI có `WallSpec.area` riêng. |
| `.DS_Store` trong `lib/calculator_core/` | **ĐÃ XÓA (Gate 2)** | Không phải source. |

> Ghi chú: `calculators/paint_calculator.dart:39` còn comment nhắc `wall_calculator.dart` (văn bản legacy nguyên bản). Không sửa để giữ byte-parity với legacy — chỉ là comment, không ảnh hưởng compile/runtime.

### 2.3. HISTORICAL UNKNOWN AT GATE 4 — RESOLVED (bản ghi lịch sử)

Các mục từng là UNKNOWN tại thời điểm Gate 1/4 — đã resolved/verified ở Gate 4/6:
- `FoundationBangAttribute` ↔ `FoundationAlignment`: **RESOLVED / VERIFIED** — `balanced→can_2_ben`, `offsetOneSide→lech_1_ben`, `offsetTwoSides→lech_2_ben` (Gate 4); calculator móng băng KHÔNG tiêu thụ attribute (đã xác minh source-level).
- `StructureType`: **RESOLVED / VERIFIED DECISION** — legacy calculator không tiêu thụ → không truyền vào engine (vẫn giữ trong domain model + persistence).
- Cost convention legacy: **RESOLVED / VERIFIED** — price snapshot × quantity, không round, total = Σ (Gate 4 + Gate 6 golden parity).

---

## 3. DEPENDENCY GRAPH (recursive, đã xác minh)

```text
services/material_calculator.dart
 ├── utils/calculation_utils.dart
 ├── calculators/brick_calculator.dart
 │     ├── models/brick.dart
 │     │     └── models/material_model.dart
 │     │           └── utils/number_formatter.dart
 │     │                 └── package:intl/intl.dart
 │     ├── constants/construction_constants.dart
 │     └── utils/calculation_utils.dart
 ├── calculators/cement_calculator.dart
 │     ├── constants/construction_constants.dart
 │     ├── utils/calculation_utils.dart
 │     └── calculators/brick_calculator.dart          ← calculator → calculator
 ├── calculators/sand_calculator.dart
 │     ├── models/brick.dart
 │     ├── constants/construction_constants.dart
 │     ├── utils/calculation_utils.dart
 │     └── calculators/brick_calculator.dart          ← calculator → calculator
 ├── calculators/steel_calculator.dart
 │     ├── constants/construction_constants.dart
 │     └── utils/calculation_utils.dart
 ├── calculators/stone_calculator.dart  └── utils/calculation_utils.dart
 ├── calculators/tile_calculator.dart   ├── dart:math, constants, calculation_utils
 ├── calculators/paint_calculator.dart  └── utils/calculation_utils.dart
 ├── calculators/door_calculator.dart   └── utils/calculation_utils.dart
 └── calculators/custom_material_calculator.dart
       ├── constants/construction_constants.dart
       └── utils/calculation_utils.dart

services/foundation_structure_calculator.dart
 └── models/project/foundation_structure_model.dart   (self-contained, 0 import)

(ĐÃ XÓA tại Gate 2: utils/wall_calculator.dart, .DS_Store — không thuộc closure)
```

## 4. DEPENDENCY CLOSURE — KẾT LUẬN

- **17/17 file .dart còn lại trong core thuộc closure đầy đủ; tất cả KEEP.** `wall_calculator.dart` + `.DS_Store` đã xóa tại Gate 2 (không thuộc closure).
- **Không thiếu file legacy nào trong closure.** Không cần copy thêm từ legacy.
- Đã đối chiếu nội dung với legacy SHA `e5fc8943` (18 file ban đầu): 15/18 file **byte-identical**; 3 file khác **chỉ** import path + whitespace (đã xác minh từng diff — không đổi logic). Sau khi xóa 1 file (wall_calculator) tại Gate 2, 17 file còn lại vẫn giữ parity logic.

## 5. MODEL INVENTORY

| Model | Vị trí | Vai trò |
|---|---|---|
| `WallType` (6 giá trị: wall10cmNoPlaster/1Side/2Side, wall20cmNoPlaster/1Side/2Side) | core `models/brick.dart` | Runtime — switch trong brick/sand calculator |
| `Brick` (extends `Material`) | core `models/brick.dart` | Compile + legacy material selection; không dùng trực tiếp trong formula mới |
| `Material`, `MaterialType` (19 giá trị), `MeasurementUnit` | core `models/material_model.dart` | Base class cho Brick |
| `FoundationTypeNew` (bang/be/coc/coc_pile), `FoundationBangAttribute`, `SteelDiameter` (d14–d22, `value` 14–22), `ColumnInfo`, `FoundationBangInfo/BeInfo/CocInfo/CocPileInfo/PileCapInfo`, `FoundationStructureData` | core `models/project/foundation_structure_model.dart` | Runtime — foundation calculator |
| Legacy UI models **không** copy: `cement.dart`, `sand.dart`, `steel.dart`, `stone.dart`, `tile6060.dart`, `custom_material.dart`, `*_paint.dart`, `aluminum/composite_door.dart`, `labor.dart`, `plumbing_*.dart`, `roof_tile.dart`, `metal_sheet.dart`, `insulated_metal.dart`, `gypsum.dart`, `concrete_sand.dart`, `plastering_sand.dart`, `material_provider.dart`, `project/*.dart` (trừ foundation) | legacy `lib/models/` | **DROP** — chỉ legacy UI/provider dùng, không trong closure |

## 6. CONSTANTS INVENTORY (KHÔNG ĐƯỢC SỬA)

- `constants/construction_constants.dart`: `waterPerCement=0.4`, `mortarRatioInWall=0.30`, `plasterThickness=0.018`, `sandRatioInMortar=0.75`, `cementForMortar=250.0`, `cementForPlastering=12.0`, `plasteringSandPerSquareMeter=0.0135`, `averageSteelWeight=0.888`, `standardTileArea=0.36`, **Hybrid**: `hybridMortarRatioInWall=0.380`, `hybridCementRatioInMortar=0.250`, `hybridCementDensity=1500.0`, `hybridSandBulkingFactor=1.25`, `hybridOpeningsDeduction=0.05`, `hybridBrickWaste=0.08`, `hybridBricksPerM2_10cm=90.0`, `hybridBricksPerM2_20cm=190.0`, `hybridCementPerM3_10cm=0.22`, `hybridCementPerM3_20cm=0.23`, `hybridSandPerM3_10cm=0.54`, `hybridSandPerM3_20cm=0.52`, `hybridBrickPerM3_10cm=550.0`, `hybridBrickPerM3_20cm=520.0`, `hybridEnsembleAlpha=0.250`, `cementBagWeight=50.0`, `wallThicknessThreshold=0.16`.
- Constants nằm trong service móng: `cementKgPerM3=430.0`, `sandM3PerM3=0.45`, `stoneM3PerM3=0.86`, `waterLPerM3=185.0`, `rhoSteel=7850.0`, `steelUnitWeight` (Map theo đường kính), `lossConcrete=0.03`, `lossSteel=0.05`, `lNeo=0.8`.

## 7. UTILITY INVENTORY

- `utils/calculation_utils.dart`: `toDouble`, `clamp01`, `roundToDecimal`, `calculateTotalFloorArea` (chỉ đọc `floor['area']`), `isWall10cm/20cm`, `classifyWallType`, `calculateWallVolume/Area`, `calculateBrickVolume`, `applyWasteFactor`, `kgToTon/tonToKg`, `bagsToKg/kgToBags`, `relativeError`, `validateParameters`, `validateNonNegative`, `validateArea`, `validateVolume`. — Không đổi semantics.
- `utils/number_formatter.dart`: `format`, `formatCurrency`, `formatCurrencyWithSymbol` (intl, locale `vi_VN`) — KEEP vì `material_model.dart` import.

## 8. FORBIDDEN DEPENDENCIES — KẾT QUẢ KIỂM TRA

Core hiện chỉ import: `dart:math`, `package:intl`, và import nội bộ tương đối.
✅ Không có: `flutter/*`, `features/`, `presentation/`, cubit, sqflite/database, repository, network, material library UI, navigation, provider.
✅ Không có inbound reference nào từ `lib/` ngoài core vào core (adapter chưa tồn tại).

## 9. FILES MISSING / CẦN TẠO (ngoài core — Gate 4/5) — TẤT CẢ ĐÃ TẠO

| Thành phần | Trạng thái |
|---|---|
| `CalculationService` (interface) | **ĐÃ TẠO (Gate 5)** — `lib/features/projects/domain/services/calculation/calculation_service.dart` |
| `MockCalculationService` | **ĐÃ TẠO (Gate 5), chuyển STUB thuần (Gate 9)** — `.../calculation/mock_calculation_service.dart`; không tính toán, không placeholder engine; chỉ cho test isolation; **giữ nguyên, không xóa** |
| `LegacyCalculationService` | **ĐÃ TẠO (Gate 5)** — `.../calculation/legacy_calculation_service.dart` (chỉ orchestration mapper → core → mapper) |
| `LegacyInputMapper` | **ĐÃ TẠO (Gate 4)** — `lib/features/projects/domain/services/calculation/legacy_input_mapper.dart` |
| `LegacyResultMapper` | **ĐÃ TẠO (Gate 4, sửa Gate 5)** — join theo legacy selection key thay vì display name |
| `ProjectCalculationResult` (typed) | **ĐÃ TẠO (Gate 4)** — `lib/features/projects/domain/services/calculation/project_calculation_result.dart` |
| `LegacyMaterialSelectionKeyMapper` | **ĐÃ TẠO (review Gate 4)** — catalogCode → legacy selection key |
| `CalculateProject` (use case) | **ĐÃ TẠO (Gate 5)** — `lib/features/projects/domain/usecases/calculate_project.dart` |
| Mapping spec | **ĐÃ TẠO (Gate 4)** — `PHASE2_MAPPING_SPEC.md` (mọi enum map đã xác minh source-level, không dùng `.index`) |
| DI registration | **ĐÃ CHUYỂN (Gate 7)** — `injection_container.dart`: `CalculationService` → **LegacyCalculationService** (production binding, sau khi Gate 6 PASS); `MockCalculationService` vẫn đăng ký cho dev/test (không xóa, không production); `CalculateProject(sl())`. |
| `ProjectCostEstimator` | **ĐÃ XÓA (Gate 9)** — 0 reference sau khi Mock chuyển sang stub; xóa file + test |

## 10. BRIDGE — NEW UI MODELS (nguồn cho LegacyInputMapper, Gate 4)

`lib/features/projects/domain/entities/construction_project.dart`:
- `ConstructionProject` {id, name, location, createdAt, updatedAt, floors `List<BuildingFloor>{number,length,width,height}` (area=length*width), roof `RoofSpec{RoofType flat/metal/tile, l,w,h}`, `FoundationStructureSpec`, materials `List<ProjectMaterial>`, details `ProjectDetails`, imagePath, province/district}
- `FoundationStructureSpec` {`FoundationType strip/raft/isolated/pile`, `StructureType reinforcedConcrete/steelFrame/masonry/timber`, `FoundationAlignment balanced/offsetOneSide/offsetTwoSides`, `mainBarDiameter int` (default 16), isolated l/w/h, `columns List<ColumnSpec>{width,thickness,quantity,mainBarsCount,mainBarDiameter}`, `pileCaps List<PileCapSpec>{l,w,h}`}
- `ProjectDetails` {foundationSegments `List<FoundationSegment>{length}`, walls `List<WallSpec>{WallType wall100/wall200, plasterSides, length, height}`, openings `List<OpeningSpec>{OpeningType window/door/rollingDoor, w,h,quantity}`, bathrooms `List<BathroomSpec>{area}`, stairs}
- `ProjectMaterial` {selectionKey, sourceLibraryId?, catalogCode?, name, unit (string), unitPrice, `ProjectMaterialType material/labor`}
- Material library: `features/material_library/domain/entities/material_library_item.dart` — nguồn price/unit/catalogCode.

### Enum mapping FINAL (đã verify source-level Gate 4, không dùng `.index`)
| Mới | Legacy | Trạng thái |
|---|---|---|
| `FoundationType.strip` | `FoundationTypeNew.bang` | **VERIFIED** |
| `FoundationType.raft` | `FoundationTypeNew.be` | **VERIFIED** |
| `FoundationType.isolated` | `FoundationTypeNew.coc` | **VERIFIED** |
| `FoundationType.pile` | `FoundationTypeNew.coc_pile` | **VERIFIED** |
| `FoundationAlignment.balanced` | `FoundationBangAttribute.can_2_ben` | **VERIFIED** |
| `FoundationAlignment.offsetOneSide` | `lech_1_ben` | **VERIFIED** |
| `FoundationAlignment.offsetTwoSides` | `lech_2_ben` | **VERIFIED** |
| `mainBarDiameter` int | `SteelDiameter` theo `value` (null → d16; invalid → ArgumentError) | **VERIFIED (POLICY)** |
| `WallType.wall100 + plasterSides` | `'10'` + pass-through | **VERIFIED** |
| `WallType.wall200 + plasterSides` | `'20'` + pass-through | **VERIFIED** |
| `ProjectMaterial.catalogCode` | legacy selection key qua `LegacyMaterialSelectionKeyMapper` | **VERIFIED** |
| `StructureType.*` | **KHÔNG truyền vào calculator** | **VERIFIED DECISION** |
| Cost | `unitPrice snapshot × quantity`, total = Σ, không round | **VERIFIED** |
| `gypsumCeilingArea` | 0.0 | **DOCUMENTED FUNCTIONAL GAP / FUTURE UI INPUT** |
| `aluminum_door` → `'Nhôm'` (kg) | giữ nguyên | **DOCUMENTED LEGACY SEMANTIC** |
| `concrete_sand` → `'Bê tông'` (m³) | giữ nguyên | **DOCUMENTED LEGACY SEMANTIC** |
| Materials không aggregated key | fallback name, không sinh quantity | **DOCUMENTED LEGACY AGGREGATED PATH LIMITATION** |

## 11. HISTORICAL RISKS — RESOLVED

> Các rủi ro được ghi nhận trong quá trình Phase 2 (bản ghi lịch sử — provenance
> giữ nguyên). Tất cả đã được xử lý/verify ở các Gate sau — **trạng thái cuối:
> RESOLVED**, không còn rủi ro mở nào thuộc các mục này.

1. `costs`/`intermediateResults` luôn rỗng từ core → adapter phải tái tạo đúng cost convention legacy (price snapshot × quantity) — **RESOLVED**: xác minh source-level ở Gate 4 (`project_detail_screen.dart`) và golden parity ở Gate 6.
2. `StructureType` mới chưa có chỗ tiêu thụ trong legacy foundation calculator — **RESOLVED / VERIFIED DECISION**: không truyền vào engine (Gate 4); giữ nguyên domain model + persistence (Gate 8).
3. `_calculateFoundationMaterials` giả định móng 0.3×0.5 m và 10 thanh thép (chính trong legacy) — **RESOLVED**: giữ nguyên legacy behavior, không "sửa" khi integration.
4. Key output là chuỗi tiếng Việt — LegacyResultMapper phải map sang typed result, tránh UI phụ thuộc raw Map — **RESOLVED**: UI chỉ nhận `ProjectCalculationResult` (Gate 8).
5. 2 local clone legacy tồn tại, 1 clone lệch SHA — **RESOLVED**: toàn bộ Phase 2 chỉ dùng `app_dev/nha_save` @ `e5fc8943` (SHA được verify mỗi lần chạy oracle).
6. `lib/calculator_core/` từng untracked — **RESOLVED**: đã commit trong snapshot `51e2794`.
7. `intl ^0.20.0` direct dep cho `number_formatter` — **RESOLVED**: đã commit trong `pubspec.yaml`.

## 12. HISTORICAL GATE 4 ITEMS — RESOLVED

> Các item dưới đây từng được đánh dấu `TODO` trong Gate 4 (bản ghi lịch sử —
> provenance giữ nguyên). Tất cả đã được verify/resolved ở các Gate sau; không
> còn unresolved item nào liên quan đến chúng.

- Enum mappings (bảng mục 10) — **RESOLVED / VERIFIED**: Gate 4 đã verify source-level bằng legacy wizard steps (`step3_foundation_structure.dart`, `step5_detailed_parameters.dart`); kết quả cuối ghi trong `PHASE2_MAPPING_SPEC.md` và bảng FINAL mục 10.
- Cost convention (price snapshot × quantity, không round, total = Σ) — **RESOLVED / VERIFIED**: Gate 4 xác minh từ `project_detail_screen.dart` (sau `_calculateCosts()`); Gate 6 golden xác nhận parity.
- `BLOCKED`: không có — closure đã đủ, không thiếu dependency (trạng thái này giữ nguyên từ Gate 4 đến kết thúc Phase 2).

## 13. GHI CHÚ TUÂN THỦ

- Không sửa legacy repo. Không copy thêm file legacy nào (closure đã đủ — đã chứng minh ở mục 4).
- Không sửa constants/units/rounding/waste/opening/Hybrid/result semantics.
- Mọi thay đổi import path đã được ghi nhận (chỉ 3 file, đúng layout mới).

## 14. KẾT QUẢ GATE 3 (2026-09-16)

- `dart analyze lib/calculator_core`: **PASS** — 0 error, 0 warning, 11 info (style lints legacy: 7× `prefer_const_declarations`, 4× `constant_identifier_names`). Giữ nguyên toàn bộ.
- `flutter analyze`: tooling crash (analysis server LSP `FormatException`) — lỗi môi trường (path workspace có khoảng trắng + tiếng Việt); dùng `dart analyze` thay thế.
- 1 error pre-existing `test/widget_test.dart` (`MyApp`) — ngoài scope, không sửa.
- Không có thay đổi file/import nào trong Gate 3.

## 15. KẾT QUẢ GATE 6 — REGRESSION (2026-09-16)

- Golden harness: `test/golden/` — 44 canonical cases; expected values sinh trực tiếp từ **legacy oracle SHA `e5fc8943`** (`tool/golden/sync_oracle.dart` + `tool/golden/generate_expected.dart`).
- `flutter test test/golden/golden_regression_test.dart`: **61/61 PASS** — quantity exact parity (round2), foundation từng field, cost convention, join-by-selection-key, steel d14–d22, invalid → ArgumentError, gypsum 0.0, brick dims {0.2,0.1,0.05}, materials không aggregated key, custom material, DI vẫn Mock.
- Full suite: +92, **−4 pre-existing UI widget failures** (`construction_plan_app_test`, `featured_project_navigation_test`, `project_detail_widget_test`, `project_wizard_widget_test`) — assertion `ListTile` trong `DecoratedBox` (province picker) của Flutter SDK mới, file UI không thuộc Phase 2.
- `dart analyze` (lib + golden + tool): 0 error/warning. calculator_core không đổi. Legacy repo clean @ e5fc8943.
- Gate 7 (production binding switch): `CalculationService` → `LegacyCalculationService`; Mock giữ cho test/dev. Golden regression 61/61 vẫn PASS; full suite +93/−4 (4 UI failures pre-existing, không mới).
- Ghi chú production: `project_detail_page.dart` còn reference `ProjectCostEstimator` trực tiếp (UI hiển thị placeholder) — đã ghi nhận, defer Gate 8/9 (không sửa UI trong Gate 7).
- Gate 8 có thể bắt đầu sau review.

## 16. KẾT QUẢ GATE 8 — E2E + PERSISTENCE (2026-09-17)

- ProjectDetailPage chuyển sang calculation thật: `ProjectCubit.calculate` → `CalculateProject` → `CalculationService` (Legacy) → `ProjectCalculationResult`; UI chỉ format/present, không formula riêng, không raw Map.
- `ProjectCubit` có trạng thái `calculating/success/failure` + result gắn `calculationProjectId` (không stale). Trigger: mở page + action `project_recalculate` + sau khi edit.
- SQLite đã xác nhận đủ: mọi field tính toán được persist (floors/roof/foundation/columns/pileCaps/segments/walls/openings/bathrooms/stairs/materials kèm `unit_price_snapshot`); enum persist theo **name** (semantic).
- E2E (`test/e2e/project_calculation_persistence_e2e_test.dart`): 10/10 PASS với SQLite thật (sqflite_common_ffi) + DI thật Legacy: Case A/B/C, price snapshot, 4 loại móng, special materials, enum round-trip.
- Golden 61/61 PASS; Gate 5/7 tests 18/18 PASS; full suite +103/−4 (4 UI failures pre-existing giống Gate 7 — đã probe chứng minh do home render, không phải Gate 8).
- Gate 9 có thể bắt đầu sau review.

## 17. KẾT QUẢ GATE 9 — CLEANUP + FINAL AUDIT (2026-09-17)

- **Xóa** `ProjectCostEstimator` (class + `test/project_cost_estimator_test.dart`) — 0 reference; `MockCalculationService` chuyển thành stub thuần (không placeholder, không formula) — Mock vẫn tồn tại cho test isolation.
- **Xử lý xong toàn bộ test failure còn lại**: fix assertion `ListTile`/`DecoratedBox` ở `profile_page.dart` (2 SwitchListTile bọc `Material(type: transparency)`) và `project_basic_step.dart` (province/district picker bọc Material); cập nhật expectation `viewportFraction 0.72 → 0.68` (production đã đổi) trong `construction_plan_app_test.dart`. `test/widget_test.dart` đã được sửa (không còn `MyApp`).
- **Full suite: +105, 0 failures.** Golden 61/61, mapper 12/12, service 6/6, E2E 10/10.
- `dart analyze lib test tool`: 0 error / 0 warning. `calculator_core` parity legacy (14 identical + 3 import/whitespace đã xác minh). Legacy repo clean @ `e5fc8943`.
- Git working tree (tại thời điểm Gate 9): chưa commit — **đã commit sau đó ở Final Closeout**: `51e2794` + tag `phase2-complete`; working tree hiện clean.
- Không build APK (bước tiếp theo sau review).
- **PHASE 2 = COMPLETE** (mọi success criteria PASS).

## FINAL PHASE 2 STATUS

- Gate 0 PASS
- Gate 1 PASS
- Gate 2 PASS
- Gate 3 PASS WITH TOOLING LIMITATION
- Gate 4 PASS
- Gate 5 PASS
- Gate 6 PASS
- Gate 7 PASS
- Gate 8 PASS
- Gate 9 PASS
- **Phase 2 COMPLETE**

Legacy source: `e5fc8943daaab5953c75bd161061cd83a934b5fd`

Golden: 61/61 PASS · Mapper: 12/12 PASS · Service: 6/6 PASS · E2E: 10/10 PASS
Full test: 105 PASS / 0 FAIL · Dart analyze: 0 error / 0 warning

calculator_core: unchanged / parity verified (14 byte-identical + 3 known benign import/whitespace)
Legacy repo: clean
ProjectCostEstimator: deleted
Production binding: `CalculationService → LegacyCalculationService`
Commit: `51e2794cfaa70c5516607badb07ca77f8d782a08` · Tag: `phase2-complete`
