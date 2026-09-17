# PHASE 2 — CALCULATION CORE INTEGRATION
## Execution Plan cho AI Agent — bản cập nhật theo cây thư mục hiện tại

> **Mục tiêu:** tích hợp calculation engine legacy vào codebase UI mới mà **không làm thay đổi công thức, constants, units, rounding, waste factor, Hybrid/ensemble weighting hoặc result semantics**.

> **Ngôn ngữ phản hồi của Agent:** Tiếng Việt.

> **Phạm vi:** chỉ thực hiện Phase 2. Không redesign calculation engine. Không mass-refactor ngoài scope.

---

# 0. SOURCE OF TRUTH

## 0.1. Legacy calculation source

Repository:

```text
https://github.com/MinhPro999/nha_save
```

Branch chuẩn:

```text
main_toiuucodebase_wizard
```

**Đây là source of truth duy nhất cho calculation engine legacy.**

Không lấy calculation logic từ branch khác nếu chưa có chỉ thị mới.

## 0.2. New UI codebase

Repository:

```text
https://github.com/MinhPro999/nha_save_newUI
```

Branch:

```text
main
```

Codebase hiện tại theo tree được cung cấp là project:

```text
dutoan_x
```

---

# 1. CẤU TRÚC HIỆN TẠI — ĐÃ XÁC NHẬN

Cây mới đã có `lib/calculator_core/`; do đó **không tạo lại từ đầu và không copy lại hàng loạt**.

Các thành phần đã xuất hiện trong tree:

```text
lib/
├── calculator_core/
│   ├── calculators/
│   │   ├── brick_calculator.dart
│   │   ├── cement_calculator.dart
│   │   ├── custom_material_calculator.dart
│   │   ├── door_calculator.dart
│   │   ├── paint_calculator.dart
│   │   ├── sand_calculator.dart
│   │   ├── steel_calculator.dart
│   │   ├── stone_calculator.dart
│   │   └── tile_calculator.dart
│   │
│   ├── constants/
│   │   └── construction_constants.dart
│   │
│   ├── models/
│   │   ├── project/
│   │   │   └── foundation_structure_model.dart
│   │   ├── brick.dart
│   │   └── material_model.dart
│   │
│   ├── services/
│   │   ├── foundation_structure_calculator.dart
│   │   └── material_calculator.dart
│   │
│   └── utils/
│       ├── calculation_utils.dart
│       ├── number_formatter.dart
│       └── wall_calculator.dart
│
├── common/
├── constants/
├── core/
├── data/
├── domain/
├── features/
│   ├── material_library/
│   └── projects/
├── presentation/
├── services/
├── utils/
├── app/
├── base/
└── ...
```

Tree cũng cho thấy project có `injection_container.dart`, feature `projects`, feature `material_library`, và `ProjectCostEstimator` hiện vẫn tồn tại trong feature projects.

**Không coi build artifacts, `.dart_tool`, `.git`, `.DS_Store`, Pods/ephemeral... là dependency của calculation.**

---

# 2. NGUYÊN TẮC BẮT BUỘC

1. Không viết lại công thức calculation chỉ để phù hợp architecture.
2. Không tự ý thay đổi `ConstructionConstants`.
3. Không thay đổi semantics của `CalculationUtils`.
4. Không đổi đơn vị đầu vào/đầu ra.
5. Không đổi rounding.
6. Không đổi waste factor.
7. Không đổi opening deduction.
8. Không đổi Hybrid/ensemble weighting.
9. Không đổi thứ tự tính nếu không bắt buộc bởi integration.
10. Không map enum bằng `.index`.
11. Không đưa legacy `Project`/legacy UI model vào presentation mới nếu adapter là đủ.
12. `calculator_core` không được import ngược vào:
    - `features/`
    - `presentation/`
    - `widgets/`
    - UI domain mới
    - SQLite/repository/database
13. Không xóa MockCalculationService trước khi real calculation PASS regression.
14. Không dùng `ProjectCostEstimator` làm calculation engine production.
15. Không sửa expected result để che discrepancy.
16. Không sửa legacy source repo trong Phase 2.
17. Không mass-refactor calculation core.
18. Mọi mapping chưa chắc chắn phải đánh dấu:
    - `TODO`
    - `BLOCKED`
    - `NEEDS_REVIEW`
19. Không kéo dependency UI/database/network vào core chỉ để hết compile error.
20. Không copy thêm file legacy nếu dependency graph chưa chứng minh cần.
21. Không xóa file khỏi `calculator_core` chỉ vì file đó có tên "legacy"; phải xác định dependency thực tế trước.
22. Nếu một file cần thiết nhưng chứa coupling UI/Flutter, phải isolate tối thiểu thay vì kéo cả subsystem vào core.
23. Mọi thay đổi calculation-core phải có lý do integration được ghi lại.

---

# 3. KIẾN TRÚC MỤC TIÊU

```text
Presentation UI
      ↓
Project Cubit / UI orchestration
      ↓
CalculateProject UseCase
      ↓
CalculationService interface
      ↓
LegacyCalculationService
      ↓
LegacyInputMapper
      ↓
calculator_core
      ↓
LegacyResultMapper
      ↓
ProjectCalculationResult
      ↓
UI
```

`calculator_core` là **calculation boundary nội bộ**.

Nó không biết:

```text
Cubit
UI Widget
Presentation
SQLite Repository
ProjectDatabase
MaterialLibrary UI
Navigation
Network
```

---

# 4. GATE FLOW

Phase 2 thực hiện tuần tự:

```text
Gate 0  → Freeze + Security Audit
Gate 1  → Source Audit + Dependency Graph
Gate 2  → Complete calculator_core isolation
Gate 3  → Core Compile/Analyze
Gate 4  → Contracts + LegacyInputMapper + LegacyResultMapper
Gate 5  → CalculationService + DI
Gate 6  → Regression / Golden Cases
Gate 7  → Replace mock production path
Gate 8  → End-to-end + SQLite save/reload/recalculate
Gate 9  → Cleanup + Final Audit + Tag
```

Mỗi gate phải:

```text
PASS
```

hoặc

```text
FAIL
```

Nếu FAIL: dừng gate hiện tại và sửa nguyên nhân trước khi đi tiếp.

---

# 5. GATE 0 — FREEZE + SECURITY AUDIT

## 5.1. Ghi nhận source state

Ghi:

```text
Legacy repo URL
Legacy branch
Legacy commit SHA
New UI repo
New UI branch
New UI commit SHA
Flutter version
Dart version
pubspec dependency versions
```

Không sửa legacy repo.

## 5.2. Security/artifact audit

Kiểm tra:

```text
.env*
*.pem
*.key
*.jks
*.keystore
android/key.properties
GoogleService-Info.plist
google-services.json
```

Đặc biệt:

```text
upload_certificate.pem
dist/*.apk
```

Nếu có credential/private key/token thật:

```text
SECURITY_BLOCKER
```

Không copy vào new UI.

## 5.3. Generated artifacts

Không coi các thư mục sau là source dependency:

```text
build/
.dart_tool/
Pods/
macos/Flutter/ephemeral/
android/.gradle/
intermediate build outputs/
dist/
```

Tree hiện tại có các artifact/generated directory; Agent phải phân biệt chúng với source thật.

---

# 6. GATE 1 — SOURCE AUDIT + DEPENDENCY GRAPH

## 6.1. Calculation entry points phải được xác minh từ legacy source

Tối thiểu:

```text
lib/services/material_calculator.dart
lib/services/foundation_structure_calculator.dart

lib/services/calculators/brick_calculator.dart
lib/services/calculators/cement_calculator.dart
lib/services/calculators/sand_calculator.dart
lib/services/calculators/steel_calculator.dart
lib/services/calculators/stone_calculator.dart
lib/services/calculators/tile_calculator.dart
lib/services/calculators/paint_calculator.dart
lib/services/calculators/door_calculator.dart
lib/services/calculators/custom_material_calculator.dart

lib/utils/wall_calculator.dart

lib/services/constants/construction_constants.dart
lib/services/utils/calculation_utils.dart
```

**Không được giả định chỉ dựa trên tên file.**

## 6.2. Dependency closure

Từ từng entry point, truy tìm import closure.

Mỗi dependency phân loại:

```text
KEEP
```

Bắt buộc để calculation chạy.

```text
DROP
```

Chỉ phục vụ UI/legacy app, không cần trong core.

```text
BRIDGE
```

Cần adapter/model mapping bên ngoài core.

```text
UNKNOWN
```

Chưa xác minh; tuyệt đối không tự đoán.

## 6.3. Kiểm tra coupling

Phải xác định:

```text
calculator → calculator
calculator → model
calculator → result model
calculator → constants
calculator → utils
calculator → Flutter/UI
calculator → database
calculator → static/global state
```

Nếu phát hiện dependency không phù hợp:

```text
Không copy toàn bộ dependency subsystem.
```

Tìm cách isolate tối thiểu.

## 6.4. Output bắt buộc

Tạo:

```text
PHASE2_CALCULATION_CORE_MANIFEST.md
```

Nội dung:

```text
- Entry points
- Existing calculator_core files
- Dependency graph
- Dependency closure
- Model inventory
- Constants inventory
- Utility inventory
- Files already isolated
- Files still missing
- DROP dependencies
- BRIDGE dependencies
- Forbidden dependencies
- Unresolved dependencies
- Risks
```

**Chưa hoàn thành manifest thì không làm integration UI.**

---

# 7. GATE 2 — HOÀN THIỆN `lib/calculator_core/`

## 7.1. Boundary đã tồn tại

Tree hiện tại đã có:

```text
lib/calculator_core/
```

Do đó:

> Không tạo thư mục mới khác tên như `calculation_core`, `calculator`, `engine`, `legacy_core` nếu không có chỉ thị rõ ràng.

Giữ boundary:

```text
lib/calculator_core/
```

## 7.2. Quy tắc hoàn thiện dependency

Agent phải:

1. Giữ nguyên các file core đã có.
2. Đọc import của từng file hiện có.
3. So sánh với dependency closure của legacy source.
4. Chỉ bổ sung file còn thiếu thực sự.
5. Sửa import path tối thiểu.
6. Không đổi nội dung calculation ngoài import/path isolation cần thiết.
7. Không kéo UI/DB/network vào core.
8. Không copy cả `lib/models/`, `lib/services/` hoặc toàn bộ legacy tree.

## 7.3. Cấu trúc mục tiêu

```text
lib/calculator_core/
├── calculators/
├── constants/
├── models/
├── services/
└── utils/
```

File con cụ thể do **dependency manifest quyết định**, không được hard-code danh sách giả định.

## 7.4. `foundation_structure_model.dart`

Tree hiện tại đã có:

```text
calculator_core/models/project/foundation_structure_model.dart
```

Agent phải kiểm tra đây là:

```text
KEEP
```

hay:

```text
BRIDGE
```

dựa trên import/reference thực tế.

Không tự ý thay model nếu legacy calculator vẫn cần model này.

## 7.5. `number_formatter.dart`

Tree hiện tại có:

```text
calculator_core/utils/number_formatter.dart
```

Agent phải xác minh:

```text
calculator_core calculator nào import nó?
```

Nếu chỉ UI dùng:

```text
DROP
```

Nếu calculation runtime thực sự import:

```text
KEEP
```

Không giữ/xóa chỉ theo tên file.

## 7.6. `.DS_Store`

Không phải source.

Phải loại khỏi `calculator_core` và không đưa vào dependency manifest.

## 7.7. Không di chuyển calculator core sang root

Không tạo:

```text
/calculator_core
```

Ngoài `lib/`.

Boundary chuẩn:

```text
lib/calculator_core/
```

---

# 8. GATE 3 — CORE COMPILE / ANALYZE

Mục tiêu:

```text
calculator_core compile/analyze = PASS
```

Phải chạy ít nhất:

```bash
flutter analyze
```

và test Dart/Flutter phù hợp.

Nếu compile fail, phân loại lỗi:

```text
A. Import path
B. Missing legacy dependency
C. Model mismatch
D. Flutter/UI coupling
E. Package dependency
F. Genuine pre-existing legacy compile issue
G. Unknown
```

Không được giải quyết lỗi bằng cách sửa công thức.

---

# 9. GATE 4 — CONTRACTS + MAPPERS

## 9.1. Interface

Giữ hoặc hoàn thiện:

```text
CalculationService
MockCalculationService
```

Tạo real implementation:

```text
LegacyCalculationService
```

## 9.2. Input mapper

Tạo:

```text
LegacyInputMapper
```

Nhiệm vụ:

```text
new UI/domain models
        ↓
legacy calculation input structures
```

Không đưa legacy `Project` vào UI domain.

## 9.3. Result mapper

Tạo:

```text
LegacyResultMapper
```

Nhiệm vụ:

```text
legacy result
        ↓
ProjectCalculationResult
```

Không dùng raw legacy Map làm API production của UI nếu có thể tạo typed result mới.

## 9.4. Enum mapping

Không dùng:

```dart
newEnum.index
```

Phải mapping explicit:

```text
new semantic value → old semantic value
```

Đặc biệt verify:

```text
Foundation type
Structure type
Steel diameter
Wall type
Material category
```

---

# 10. MAPPING RULES BẮT BUỘC

## 10.1. Structure type

Semantic mapping dự kiến:

```text
reinforcedConcrete → concrete
steelFrame         → steel
masonry            → brick
timber             → wood
```

Phải verify source-level trước khi chốt.

## 10.2. Foundation type

Không map theo enum order.

Phải map theo semantic:

```text
strip
raft
isolated
pile
```

so với legacy equivalent.

## 10.3. Steel diameter

Nếu new model dùng số:

```text
16
20
...
```

phải map explicit sang legacy:

```text
SteelDiameter.d16
SteelDiameter.d20
...
```

## 10.4. Wall type

Verify mapping:

```text
100mm ↔ legacy "10"
200mm ↔ legacy "20"
```

Không được giả định nếu source chưa xác minh.

---

# 11. GATE 5 — SERVICE + DI

## 11.1. CalculateProject use case

Tạo/hoàn thiện:

```text
CalculateProject
```

Use case chịu trách nhiệm orchestration ở application/domain boundary.

Không đặt toàn bộ calculation vào `ProjectCubit`.

## 11.2. Dependency Injection

Đăng ký tại:

```text
lib/injection_container.dart
```

Phải bảo đảm dependency direction:

```text
UI
 ↓
Cubit
 ↓
UseCase
 ↓
CalculationService
 ↓
LegacyCalculationService
 ↓
calculator_core
```

## 11.3. Không dùng `ProjectCostEstimator`

Hiện tree có:

```text
lib/features/projects/domain/services/project_cost_estimator.dart
```

Đây là placeholder/mock estimator của UI architecture.

Không biến file này thành real calculator thứ hai.

Production path phải chuyển sang:

```text
CalculationService
```

Sau khi real integration PASS, `ProjectCostEstimator` có thể được xóa nếu không còn reference.

---

# 12. VAI TRÒ CỦA MATERIAL LIBRARY

Tree hiện có:

```text
features/material_library/
features/projects/
```

Material library đang là domain/data của UI mới.

Không đưa implementation của material library vào `calculator_core` chỉ để calculate.

Nếu calculation cần:

```text
price
unit
catalogCode
material selection
```

thì adapter/use case mới cung cấp dữ liệu cần thiết cho calculation.

Không để:

```text
calculator_core → material_library_repository
```

trực tiếp.

---

# 13. COST VS QUANTITY

Ưu tiên tách:

```text
legacy core
    ↓
quantities / calculation outputs
    ↓
new domain/material price snapshots
    ↓
cost calculation
```

Nếu legacy engine thực sự là source of truth cho cost ở một trường hợp cụ thể, phải xác minh source-level trước khi thay đổi.

Không tự ý chuyển cách tính cost chỉ vì architecture mới đẹp hơn.

---

# 14. GATE 6 — REGRESSION / GOLDEN CASES

Phải tạo test cases cố định để so sánh:

```text
legacy engine
       VS
new adapter architecture
```

So sánh tối thiểu:

```text
Brick
Cement
Sand
Plaster sand
Concrete
Steel
Stone
Tile
Paint
Doors
Custom materials
Labor
Plumbing
Total
```

Với foundation cases:

```text
Foundation quantity
Foundation structure outputs
Steel outputs
```

## 14.1. Kiểm tra

```text
quantity
unit
rounding
price
cost
intermediate outputs
final totals
```

Ưu tiên:

```text
exact equality
```

sau legacy-defined rounding.

Không dùng tolerance tùy tiện để che discrepancy.

## 14.2. Discrepancy protocol

Nếu khác:

```text
1. Stop
2. Record exact input
3. Record legacy output
4. Record new output
5. Trace first divergence
6. Identify mapping/import/unit/rounding issue
7. Fix adapter/integration
8. Do NOT change formula to match
```

---

# 15. GATE 7 — REPLACE MOCK PRODUCTION PATH

Chỉ khi:

```text
Gate 3 PASS
Gate 4 PASS
Gate 5 PASS
Gate 6 PASS
```

mới chuyển:

```text
MockCalculationService
```

sang:

```text
LegacyCalculationService
```

production path.

Mock vẫn có thể giữ trong source cho development/test cho đến Gate 9.

Không xóa mock sớm.

---

# 16. GATE 8 — END-TO-END + SQLITE RELOAD

Luồng bắt buộc:

```text
Create Project
   ↓
Fill Wizard
   ↓
Save SQLite
   ↓
Reload Project
   ↓
Calculate
   ↓
Compare with pre-save calculation
```

Kết quả phải nhất quán:

```text
same input
→ same mapped legacy input
→ same calculation output
```

Kiểm tra serialization không làm mất:

```text
dimensions
floors
foundation parameters
wall parameters
materials
prices/snapshots
steel information
```

---

# 17. GATE 9 — CLEANUP + FINAL AUDIT

Sau khi real engine PASS:

Có thể loại bỏ:

```text
ProjectCostEstimator
unused temporary bridge classes
unused duplicate calculation code
unused test scaffolding
unused legacy UI models
```

Nhưng chỉ xóa khi:

```text
0 references
```

và không ảnh hưởng calculation/regression.

Không xóa:

```text
MockCalculationService
```

nếu vẫn cần cho test/dev.

---

# 18. KIỂM TRA KIẾN TRÚC CUỐI

Phải PASS:

```text
[ ] calculator_core exists under lib/
[ ] calculator_core has no UI dependency
[ ] calculator_core has no database dependency
[ ] calculator_core has no network dependency
[ ] UI does not import legacy calculator internals directly
[ ] UI talks through CalculationService
[ ] LegacyInputMapper is the input boundary
[ ] LegacyResultMapper is the output boundary
[ ] CalculateProject is separated from ProjectCubit
[ ] DI registered in lib/injection_container.dart
[ ] ProjectCostEstimator not used as production calculation engine
```

---

# 19. CALCULATION INTEGRITY CHECKLIST

```text
[ ] No formula change
[ ] No constant change
[ ] No unit change
[ ] No rounding change
[ ] No waste-factor change
[ ] No opening-deduction change
[ ] No Hybrid weighting change
[ ] No result semantic change
[ ] No enum-index mapping
[ ] No change to legacy repo
```

---

# 20. ACCEPTANCE CRITERIA

## Architecture

```text
[ ] Calculation engine behind service boundary
[ ] calculator_core independent from UI
[ ] UI independent from legacy internals
[ ] DI works
[ ] UseCase exists
```

## Mapping

```text
[ ] Foundation mapping verified
[ ] Wall mapping verified
[ ] Steel diameter mapping verified
[ ] Structure type mapping verified
[ ] Material mapping verified
[ ] Missing/default policy documented
```

## Regression

```text
[ ] Golden cases PASS
[ ] Quantity parity PASS
[ ] Unit parity PASS
[ ] Rounding parity PASS
[ ] Cost parity PASS when same price snapshot is used
[ ] Foundation parity PASS
```

## Persistence

```text
[ ] Save/reload/recalculate PASS
[ ] SQLite serialization verified
```

## Quality

```text
[ ] flutter analyze PASS
[ ] flutter test PASS
[ ] Target build PASS
[ ] No secrets introduced
[ ] Temporary artifacts not used as dependencies
```

---

# 21. ROLLBACK

Nếu real integration gây regression:

```text
LegacyCalculationService
        ↓
rollback production binding
        ↓
MockCalculationService
```

Không rollback UI nếu UI vẫn hoạt động.

Không sửa legacy source để che regression.

Nếu cần rollback toàn bộ Phase 2:

```text
1. restore new UI snapshot/commit
2. giữ nguyên legacy source repo
3. giữ lại manifest
4. giữ regression report
5. điều tra nguyên nhân
```

---

# 22. AGENT REPORT FORMAT

Sau mỗi gate:

```text
GATE: X
STATUS: PASS | FAIL

Đã làm:
- ...

File thay đổi:
- ...

File thêm:
- ...

File xóa:
- ...

Dependency closure:
- KEEP:
- DROP:
- BRIDGE:
- UNKNOWN:

Kiểm tra:
- flutter analyze: PASS/FAIL
- flutter test: PASS/FAIL
- build: PASS/FAIL/NOT RUN

Calculation integrity:
- formula unchanged: YES/NO
- constants unchanged: YES/NO
- units unchanged: YES/NO
- rounding unchanged: YES/NO
- Hybrid weights unchanged: YES/NO

Rủi ro còn lại:
- ...

Gate tiếp theo:
- ...
```

Nếu FAIL:

```text
GATE: X
STATUS: FAIL

Blocker:
- ...

Nguyên nhân:
- ...

Không tiếp tục gate tiếp theo.
```

---

# 23. START COMMAND — CỰC KỲ QUAN TRỌNG

Tại thời điểm hiện tại, `lib/calculator_core/` **đã tồn tại và đã có nhiều file legacy**.

Vì vậy Agent **KHÔNG được bắt đầu bằng việc copy lại toàn bộ calculator engine**.

Thứ tự bắt buộc:

```text
1. Read this plan.
2. Inspect current tree.
3. Inspect current git diff/status.
4. Inspect all existing files under lib/calculator_core/.
5. Compare them with legacy branch:
   main_toiuucodebase_wizard
6. Build exact dependency graph.
7. Create/update:
   PHASE2_CALCULATION_CORE_MANIFEST.md
8. Only then add missing dependencies.
9. Fix import paths minimally.
10. Run Gate 3.
```

### First task for Agent

> **Phân tích dependency closure của `lib/calculator_core/` hiện tại, xác định chính xác toàn bộ file legacy còn thiếu, chỉ bổ sung dependency cần thiết, sửa import path tối thiểu, tuyệt đối không thay đổi calculation logic, constants, units, rounding, Hybrid weighting hoặc result semantics.**

Không được bắt đầu Gate 4 khi dependency closure chưa được xác minh.

---

# 24. QUY TẮC CUỐI CÙNG

> **Ưu tiên tính đúng của calculation hơn vẻ đẹp của code.**

> **Ưu tiên adapter hơn sửa legacy core.**

> **Ưu tiên regression evidence hơn suy đoán.**

> **Không thay đổi công thức chỉ để code compile.**

> **Không đánh dấu PASS nếu chưa đối chiếu với legacy.**

> **Không dùng enum index để mapping.**

> **Không xóa mock trước khi real calculation PASS.**

> **Không coi `ProjectCostEstimator` là calculation engine.**

> **Không kéo UI/database/network vào `calculator_core`.**

> **Mọi điểm chưa xác minh phải được đánh dấu rõ.**

---

# END

Phase 2 chỉ được hoàn tất khi:

```text
Legacy calculation
        ↓
calculator_core
        ↓
LegacyCalculationService
        ↓
CalculationService
        ↓
CalculateProject
        ↓
New UI
```

hoạt động ổn định và có regression evidence chứng minh parity với legacy engine.
