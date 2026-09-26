# PHASE2 — MAPPING SPEC (Gate 4)

> Sinh bởi AI Agent — Gate 4: Contracts + Mappers.
> Ngày: 2026-09-16
> Legacy SHA đối chiếu: `e5fc8943` (branch `main_toiuucodebase_wizard`)
> Nguyên tắc: **KHÔNG map enum bằng `.index`**; mọi mapping phải có evidence source-level; thứ gì chưa chứng minh được → NEEDS_REVIEW/BLOCKED.

---

## 1. INPUT CONTRACT — `MaterialCalculator.calculateMaterialsFromDetailedParams` (ĐÃ XÁC MINH)

Evidence: `legacy lib/screens/project_wizard/steps/step5_detailed_parameters.dart:1408-1508` (build `detailedParameters` + `paramsMap` + call).

```text
detailedParams = {
  'foundation': { 'lengths': [double,...], 'columns': int },
  'walls':      { 'walls': [ {'type': '10'|'20', 'plasterSides': int, 'length': double, 'height': double, 'area': double}, ... ],
                  'area': double },                       // tổng diện tích tường (compat cũ)
  'doors':      { 'windows':      [ {'width','height','quantity','area'}, ... ],
                  'doors':        [ ... ],
                  'rollingDoors': [ ... ],
                  'windowArea': double, 'doorArea': double, 'rollingDoorArea': double },
  'others':     { 'bathrooms': [ {'area': double}, ... ], 'gypsumCeilingArea': double,
                  'stairs': [ {'steps': int}, ... ], 'bathroomCount': int, 'stairsSteps': int },
}
selectedMaterialIds = List<String>   // = material.name (tên tiếng Việt, evidence: step4_materials.dart:215-233)
brickDimensions   = {'length': double, 'width': double, 'height': double}   // từ MaterialProvider.getBrickDimensions
floors            = [ {'number','length','width','height','area'}, ... ]    // Floor.toMap() (building_model.dart)
```

Ghi chú runtime:
- `'type'` tường là **string** `'10'`/`'20'` (default `'10'`; step5 init `wall['type'] ?? '10'`).
- `plasterSides` default `2` (step5: `wall['plasterSides'] ?? 2`).
- `brickDimensions` legacy runtime **luôn** được truyền từ `MaterialProvider.getBrickDimensions()` — trả về `{0.2, 0.1, 0.05}` (default của class `Brick` trong `legacy lib/models/brick.dart`) — **KHÁC** fallback nội bộ của calculator (`0.22/0.10/0.05` chỉ dùng khi tham số null). Quyết định: adapter luôn truyền tường minh `{0.2, 0.1, 0.05}` = đúng hành vi legacy app. (Đã xác minh; lưu ý khi đọc lại calculator.)
- `calculateTotalFloorArea` chỉ đọc `floor['area']` (calculation_utils.dart:27-31).
- Roof **không** được truyền vào material calculation (paramsMap không có key roof) — RoofType không cần mapping cho material path.
- `costs` và `intermediateResults` trong kết quả **luôn rỗng** (legacy không gán) — cost tính riêng ở UI bằng `pricePerUnit * quantity`.

## 2. INPUT CONTRACT — `FoundationStructureCalculator.calculate` (ĐÃ XÁC MINH)

Evidence: `legacy step3_foundation_structure.dart:1817-1857` (tính l1/w1/area1/hTotal) + `legacy lib/services/foundation_structure_calculator.dart`.

```text
l1     = floors.first.length
w1     = floors.first.width
area1  = floors.first.area
hTotal = Σ floors.height
foundationData = FoundationStructureData {
  foundationType: FoundationTypeNew?,
  columns: List<ColumnInfo>,
  bangInfo / beInfo / cocInfo / cocPileInfo,
}
```

Thứ calculator tiêu thụ (đã đọc từng nhánh `_calculateFoundation*`):
- `bang`: chỉ đọc `bangInfo.mainBarDiameter` (attribute **không** được tiêu thụ — chỉ UI).
- `be`: chỉ đọc `beInfo.mainBarDiameter`.
- `coc`: `cocInfo.length/width/height/mainBarDiameter`.
- `coc_pile`: `cocPileInfo.pileCaps.first` (length/width/height) + `mainBarDiameter`; pileCaps rỗng → kết quả rỗng.
- `columns`: width, thickness, quantity, mainBarsCount, mainBarDiameter.value.

## 3. MAPPING ENUM — ĐÃ XÁC MINH SOURCE

### 3.1 FoundationType (new) → FoundationTypeNew (legacy)

| New field | Legacy field | Transformation | Default | Unit | Evidence | Status |
|---|---|---|---|---|---|---|
| `FoundationType.strip` | `FoundationTypeNew.bang` | explicit switch | — | — | step3: bang = "Móng băng" | **VERIFIED** |
| `FoundationType.raft` | `FoundationTypeNew.be` | explicit switch | — | — | step3: be = "Móng bè" | **VERIFIED** |
| `FoundationType.isolated` | `FoundationTypeNew.coc` | explicit switch | — | — | step3: coc = "Móng cốc"; new UI isolated = móng đơn/cốc | **VERIFIED** |
| `FoundationType.pile` | `FoundationTypeNew.coc_pile` | explicit switch | — | — | step3: coc_pile = "Móng cọc" | **VERIFIED** |
| null | null | giữ null | null | — | FoundationStructureData cho phép null; calculator trả empty | **VERIFIED** |

> ⚠️ Legacy còn enum cũ `FoundationType {strip, isolated, pile, raft}` (building_model.dart) với **thứ tự khác** enum mới — càng khẳng định phải map semantic, không `.index`. Enum cũ này KHÔNG được dùng trong calculation (chỉ UI/DB cũ).

### 3.2 FoundationAlignment (new) → FoundationBangAttribute (legacy)

| New field | Legacy field | Default | Evidence | Status |
|---|---|---|---|---|
| `FoundationAlignment.balanced` | `FoundationBangAttribute.can_2_ben` | dùng khi alignment null | step3: can_2_ben = "Cân 2 bên" | **VERIFIED** |
| `FoundationAlignment.offsetOneSide` | `FoundationBangAttribute.lech_1_ben` | — | step3: lech_1_ben = "Lệch 1 bên" | **VERIFIED** |
| `FoundationAlignment.offsetTwoSides` | `FoundationBangAttribute.lech_2_ben` | — | step3: lech_2_ben = "Lệch 2 bên" | **VERIFIED** |

> Ghi chú: calculator **không** tiêu thụ `attribute` (chỉ UI hiển thị) — mapper vẫn set để giữ fidelity dữ liệu.

### 3.3 Steel diameter (int mm) → SteelDiameter (legacy)

| New field | Legacy field | Transformation | Default | Evidence | Status |
|---|---|---|---|---|---|
| `int? mainBarDiameter` (14/16/18/20/22) | `SteelDiameter.d14/d16/d18/d20/d22` | map **theo `.value`** (`firstWhere((d) => d.value == mm)`), không `.index` | — | step3 dropdown hiển thị `φ{value} mm`, default `d16`; enum d14(14)…d22(22) | **VERIFIED** |
| null / missing | `SteelDiameter.d16` | policy: default | `d16` | legacy UI default `d16` ở mọi dropdown (step3) | **VERIFIED** |
| giá trị không thuộc {14,16,18,20,22} | — | **ném `ArgumentError`** — KHÔNG silent-map về d16 | — | không có evidence legacy map giá trị lạ → policy validation/error (yêu cầu review trước Gate 5) | **VERIFIED (policy)** |

### 3.4 Wall type (new) → string legacy

| New field | Legacy field | Transformation | Default | Evidence | Status |
|---|---|---|---|---|---|
| `WallType.wall100` | `'10'` | explicit switch | — | legacy tường 10cm ↔ `'10'` (step5 init `'10'`; calculator so `'20'` → 0.20 else 0.10) | **VERIFIED** |
| `WallType.wall200` | `'20'` | explicit switch | — | tường 20cm ↔ `'20'` | **VERIFIED** |

### 3.5 plasterSides

| New field | Legacy field | Default | Evidence | Status |
|---|---|---|---|---|
| `WallSpec.plasterSides` (int 0/1/2) | `wall['plasterSides']` (int) | giữ nguyên giá trị (new UI default 2; legacy default 2) | step5: `?? 2` | **VERIFIED** |

### 3.6 OpeningType (new) → doors map (legacy)

| New field | Legacy field | Evidence | Status |
|---|---|---|---|
| `OpeningType.window` | `doors['windows']` list | step5 thu thập windows riêng | **VERIFIED** |
| `OpeningType.door` | `doors['doors']` list | step5 | **VERIFIED** |
| `OpeningType.rollingDoor` | `doors['rollingDoors']` list | step5 | **VERIFIED** |

### 3.7 Material selection (new → legacy `selectedMaterialIds`) — MATERIAL KEY BOUNDARY

New UI giữ: `catalogCode` = **stable identity**, `name` = display name. **Không dùng `name` làm identity calculation khi có `catalogCode`.**

Boundary: `LegacyMaterialSelectionKeyMapper` (`lib/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart`).

| catalogCode (new) | legacy selection key | Ghi chú | Evidence | Status |
|---|---|---|---|---|
| `brick` | `'Gạch xây'` | | material_calculator check | **VERIFIED** |
| `cement` | `'Xi măng'` | | ✓ | **VERIFIED** |
| `sand` | `'Cát xây'` | | ✓ | **VERIFIED** |
| `plaster_sand` | `'Cát trát'` | | ✓ | **VERIFIED** |
| `interior_paint` | `'Sơn nội thất'` | | ✓ | **VERIFIED** |
| `concrete_sand` | `'Bê tông'` | legacy runtime: name `'Cát bê tông'` khớp check `'Bê tông'` qua `contains` | ✓ | **VERIFIED** (giữ nguyên hành vi runtime) |
| `steel` | `'Thép'` | **điểm review 1**: legacy check `'Thép'`; tên hiển thị legacy `'Sắt thép'` case-mismatch nên app cũ không bao giờ khớp → boundary map theo catalogCode để quantity thép không bị mất | ✓ | **VERIFIED (directive user) + test** |
| `stone` | `'Đá'` | | ✓ | **VERIFIED** |
| `aluminum_door` | `'Nhôm'` | legacy check `'Nhôm'`; tên hiển thị `'Cửa nhôm Xingfa'` case-mismatch ở app cũ → map theo catalogCode | ✓ | **VERIFIED + NEEDS_REVIEW (semantic key 'Nhôm' = kg)** |
| `gypsum` | `'Thạch cao'` | | ✓ | **VERIFIED** |
| `labor` | `'Nhân công xây dựng'` | | ✓ | **VERIFIED** |
| `plumbing_labor` | `'Nhân công điện nước'` | | ✓ | **VERIFIED** |
| `plumbing_material` | `'Vật tư điện nước'` | | ✓ | **VERIFIED** |

Policy:
- `catalogCode` có trong bảng → dùng legacy key (identity ổn định, không phụ thuộc tên hiển thị).
- `catalogCode` không có key (`tile`, `roof_tile`, `metal_sheet`, `insulated_metal_sheet`, `exterior_paint`, `composite_door` — aggregated path legacy không kiểm tra các key này) → **fallback `name`** đúng như legacy runtime (không khớp check → không sinh quantity). NEEDS_REVIEW: các vật liệu này hiện chỉ tính được qua API đơn lẻ của calculator, ngoài scope aggregated path.
- `catalogCode == null` (vật liệu tùy chỉnh) → `name` (hành vi legacy).
- Key `'Nước'` tồn tại trong calculator nhưng **không có catalog code/material nào map** → không bao giờ được chọn (giống legacy: không có material tên 'Nước').

Test chứng minh (test/legacy_input_mapper_test.dart):
- `catalogCode 'steel'` → `selectedMaterialIds` chứa `'Thép'` (không chứa `'Sắt thép'`) → chạy engine thật: `quantities['Thép'] > 0`.
- `catalogCode 'concrete_sand'` → chứa `'Bê tông'` → `quantities['Bê tông'] > 0`.
- fallback name khi code không có key / null.

### 3.8 brickDimensions (new → legacy)

| New field | Legacy field | Default | Evidence | Status |
|---|---|---|---|---|
| (override từ service/material library nếu có) | `brickDimensions` | `{'length': 0.2, 'width': 0.1, 'height': 0.05}` | legacy `Brick` defaults (brick.dart) = new catalog brick dims (0.2/0.1/0.05) | **VERIFIED** (xem ghi chú runtime ở mục 1) |

### 3.9 floors (new → legacy)

| New field | Legacy field | Transformation | Evidence | Status |
|---|---|---|---|---|
| `BuildingFloor` | floor map | `{'number','length','width','height','area': length*width}` | legacy `Floor.toMap()`; calculator chỉ đọc `area` | **VERIFIED** |

### 3.10 StructureType — SEMANTIC DECISION

| New field | Legacy | Decision | Evidence | Status |
|---|---|---|---|---|
| `StructureType.reinforcedConcrete/steelFrame/masonry/timber` | `StructureType {concrete, steel, brick, wood}` (chỉ UI/DB cũ) | **KHÔNG truyền vào legacy engine** — legacy calculation không có tham số structureType, `FoundationStructureCalculator.calculate` không nhận | grep toàn legacy: structureType chỉ xuất hiện trong project_provider/detail_screen/home_screen/project_database; không file calculator nào đọc | **DECISION: NOT PASSED (VERIFIED)** |

## 4. MAPPING DATA — ĐÃ XÁC MINH

### 4.1 Foundation structure

| New field | Legacy field | Transformation | Default | Evidence | Status |
|---|---|---|---|---|---|
| `floors.first.length` | `l1` | pass-through | — | step3:1819-1821 | **VERIFIED** |
| `floors.first.width` | `w1` | pass-through | — | step3 | **VERIFIED** |
| `floors.first.area` | `area1` | length×width | — | step3 | **VERIFIED** |
| `Σ floors.height` | `hTotal` | fold | — | step3:1824-1828 | **VERIFIED** |
| `ColumnSpec.width` | `ColumnInfo.width` | pass-through | — | ColumnInfo cùng tên field | **VERIFIED** |
| `ColumnSpec.thickness` | `ColumnInfo.thickness` | pass-through | — | ✓ | **VERIFIED** |
| `ColumnSpec.quantity` | `ColumnInfo.quantity` | pass-through | — | ✓ | **VERIFIED** |
| `ColumnSpec.mainBarsCount` | `ColumnInfo.mainBarsCount` | pass-through | — | ✓ | **VERIFIED** |
| `ColumnSpec.mainBarDiameter` (int) | `ColumnInfo.mainBarDiameter` (SteelDiameter) | theo mục 3.3 | d16 | ✓ | **VERIFIED** |
| `isolatedLength/Width/Height` | `FoundationCocInfo.length/width/height` | `?? 0.0` | 0.0 (legacy controller default 0) | step3 cocInfo init 0.0 | **VERIFIED** |
| `PileCapSpec{length,width,height}` | `FoundationPileCapInfo{width,length,height}` | pass-through từng field | — | model cùng field | **VERIFIED** |
| `pileCaps` rỗng | `cocPileInfo = null` | — | — | calculator trả empty khi pileCaps rỗng | **VERIFIED** |
| `alignment` null | `FoundationBangAttribute.can_2_ben` | default | can_2_ben | step3 default | **VERIFIED** |
| `foundationType` null | `foundationType = null` | — | — | calculator trả empty | **VERIFIED** |

### 4.2 Walls / Openings / Others

| New field | Legacy field | Transformation | Default | Evidence | Status |
|---|---|---|---|---|---|
| `WallSpec.type` | `wall['type']` | mục 3.4 | — | ✓ | **VERIFIED** |
| `WallSpec.plasterSides` | `wall['plasterSides']` | pass-through | 2 | ✓ | **VERIFIED** |
| `WallSpec.length/height` | `wall['length'/'height']` | pass-through | — | ✓ | **VERIFIED** |
| `WallSpec.area` | `wall['area']` | length×height | — | step5:1321-1330 | **VERIFIED** |
| tổng walls | `walls['area']` | Σ length×height | — | step5 | **VERIFIED** |
| `OpeningSpec{width,height,quantity}` | door map `{width,height,quantity,area}` | area = width×height×quantity | — | step5 | **VERIFIED** |
| tổng theo loại | `windowArea/doorArea/rollingDoorArea` | Σ | — | step5 | **VERIFIED** |
| `FoundationSegment.length` | `foundation['lengths']` | list | [] | step5:1410 | **VERIFIED** |
| `columns.length` | `foundation['columns']` | count | 0 | step5:1411 (`int.tryParse` columns count) | **VERIFIED** |
| `BathroomSpec.area` | `others['bathrooms'][i]['area']` | pass-through | [] | step5 | **VERIFIED** |
| `bathrooms.length` | `others['bathroomCount']` | count | 0 | step5 | **VERIFIED** |
| `StairSpec.steps` | `others['stairs'][i]['steps']` | pass-through | [] | step5 | **VERIFIED** |
| Σ steps | `others['stairsSteps']` | Σ | 0 | step5 | **VERIFIED** |
| (không có field) | `others['gypsumCeilingArea']` | **hằng 0.0** | 0.0 | legacy controller rỗng → 0.0 | **FUNCTIONAL GAP / NEEDS_REVIEW: new UI chưa có input diện tích trần thạch cao → quantity 'Thạch cao' hiện tại = 0; không tự thêm UI field trong Phase 2** |

### 4.3 Cost convention (ĐÃ XÁC MINH)

Evidence: `legacy project_detail_screen.dart:913-916, 985-989`.

```text
quantity   = results['quantities']?[material.name] ?? 0.0
line cost  = material.pricePerUnit * quantity        // KHÔNG round, chỉ format khi hiển thị
total cost = Σ line cost                              // KHÔNG round
```

- Price snapshot = giá vật liệu tại thời điểm hiển thị (`MaterialProvider.materials`). New UI tương đương = `ProjectMaterial.unitPrice` (snapshot lưu trong project).
- Join theo **legacy selection key** (catalogCode → key, fallback name) — xem mục 5. Legacy UI cũ join theo `material.name` (điều này khiến các key khác tên hiển thị như `'Bê tông'` không hiển thị được ở app cũ); typed boundary mới join theo selection key để không mất quantity.
- Không dùng `results['costs']` (luôn rỗng) và `results['intermediateResults']` (luôn rỗng).

## 5. RESULT CONTRACT — Typed boundary

- `ProjectCalculationResult` (typed) thay cho raw Map khi ra UI.
- `ProjectMaterialLine {name, quantity, unit, unitPrice, cost}` — quantity lấy nguyên từ legacy (đã round 2), cost = unitPrice×quantity không round thêm.
- **Join theo legacy selection key** (`LegacyMaterialSelectionKeyMapper.selectionIdFor`) — KHÔNG theo display name: key `'Thép'` join với material có name `'Sắt thép'` (catalogCode `steel`); key `'Bê tông'` join với `'Cát bê tông'`. Tên hiển thị trên dòng kết quả là `material.name`. (Cập nhật Gate 5 — trước đó join theo name sẽ làm mất quantity thép/bê tông.)
- `FoundationStructureSection` mirror **1-1** toàn bộ field của `FoundationStructureResult` (giữ nguyên giá trị, đơn vị, không tính lại). Key toMap/fromMap giữ nguyên tên legacy để Gate 8 persist không mất dữ liệu.
- `totalCost` = Σ line.cost.

## 6. FILES TẠO TRONG GATE 4/5 (đã cập nhật theo review)

- `lib/features/projects/domain/services/calculation/project_calculation_result.dart`
- `lib/features/projects/domain/services/calculation/legacy_input_mapper.dart`
- `lib/features/projects/domain/services/calculation/legacy_material_selection_key_mapper.dart` — **material key boundary (catalogCode → legacy selection key)**
- `lib/features/projects/domain/services/calculation/legacy_result_mapper.dart`
- `lib/features/projects/domain/services/calculation/calculation_service.dart` — **interface (Gate 5)**
- `lib/features/projects/domain/services/calculation/legacy_calculation_service.dart` — **orchestration thật (Gate 5)**
- `lib/features/projects/domain/services/calculation/mock_calculation_service.dart` — **mock, giữ đến Gate 6 PASS (Gate 5)**
- `lib/features/projects/domain/usecases/calculate_project.dart` — **use case (Gate 5)**
- `test/legacy_input_mapper_test.dart`
- `test/calculation_service_test.dart` — **wiring Gate 5**

DI: `lib/injection_container.dart` — `CalculationService` → Mock (mặc định), `LegacyCalculationService` đăng ký sẵn, `CalculateProject(sl())`. Production binding chỉ chuyển sang Legacy ở Gate 7.

Không tạo: `CalculationService`, `MockCalculationService`, `LegacyCalculationService`, `CalculateProject`, DI binding (Gate 5).
Không sửa file nào trong `lib/calculator_core/`.

## 7. FINAL RESOLVED STATUS (sau Gate 4/6/8/9)

| Item | Trạng thái FINAL | Ghi chú |
|---|---|---|
| `gypsumCeilingArea` = 0.0 cố định | **DOCUMENTED FUNCTIONAL GAP / FUTURE UI INPUT** | new UI chưa có input diện tích trần thạch cao → quantity 'Thạch cao' = 0; giữ nguyên default legacy 0.0; bổ sung input thuộc UI/domain tương lai (không blocker). |
| `aluminum_door` → `'Nhôm'` (kg, ×3 kg/m² theo legacy) | **DOCUMENTED LEGACY SEMANTIC** | boundary map theo catalogCode; Gate 6 golden đã xác minh behavior legacy. |
| `concrete_sand` → `'Bê tông'` (m³) | **DOCUMENTED LEGACY SEMANTIC** | giữ nguyên hành vi legacy runtime (contains 'Bê tông'); Gate 6 đã xác minh. |
| Các catalog code không có key aggregated path (`tile`, `roof_tile`, `metal_sheet`, `insulated_metal_sheet`, `exterior_paint`, `composite_door`) | **DOCUMENTED LEGACY AGGREGATED PATH LIMITATION** | legacy aggregated path không kiểm tra → fallback name, không sinh quantity (đúng legacy runtime). |
| Steel diameter không hợp lệ | **VERIFIED (POLICY)** | null/missing → d16 (legacy default); giá trị ngoài {14,16,18,20,22} → ném ArgumentError, KHÔNG silent-map. |
| Legacy calculator fallback brick dims `{0.22,0.10,0.05}` vs runtime `{0.2,0.1,0.05}` | DOCUMENTED | adapter chọn `{0.2,0.1,0.05}` = hành vi legacy app thực tế |
| `StructureType` | **VERIFIED DECISION** | không truyền vào engine (mục 3.10) |
| Roof (RoofType) | DOCUMENTED | material calculation không tiêu thụ roof — không map |
