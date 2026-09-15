# CODEBASE_UI — flutter_core_project (Construction Plan)

> Tài liệu quét tự động toàn bộ codebase Flutter. Mục đích: cung cấp cái nhìn tổng quan
> kiến trúc, cấu trúc thư mục, các class/module quan trọng, state management, networking,
> conventions và testing cho người mới tham gia dự án.

---

## 1. Tổng quan dự án

| Mục | Giá trị |
| --- | --- |
| Tên dự án | `flutter_core_project` |
| Mô tả | Construction Plan mobile application. (Ứng dụng lập kế hoạch / dự toán xây dựng nhà) |
| Version | `1.0.5+1` |
| SDK constraint | `>=3.1.4 <4.0.0` (Dart / Flutter) |
| Default flavor | `dev` (cấu hình `default-flavor: dev` trong pubspec) |

### Nền tảng hỗ trợ
Dựa vào các folder platform hiện có trong project:

| Platform | Folder | Trạng thái |
| --- | --- | --- |
| Android | `android/` | ✅ (đầy đủ flavors) |
| iOS | `ios/` | ✅ (có tool `add_ios_flavors.rb`) |
| Web | `web/` | ✅ |
| macOS | `macos/` | ✅ (có tool `add_macos_flavors.rb`) |
| Windows/Linux | ❌ | Không có folder |

### Flutter Flavors / Build variants
**Có.** Dùng 2 flavor:
- `dev` — entry `lib/main_dev.dart`, file env `.env.dev`, applicationIdSuffix `.dev`
- `prod` — entry `lib/main_prod.dart`, file env `.env.prod`

Cấu hình Android (`android/app/build.gradle`):
```gradle
flavorDimensions "environment"
productFlavors {
  dev  { dimension "environment"; applicationIdSuffix ".dev"; ... }
  prod { dimension "environment"; ... }
}
```
Command build ví dụ: `flutter build appbundle --flavor prod -t lib/main_prod.dart`

### Dependencies chính (từ `pubspec.yaml`)

| Nhóm | Package |
| --- | --- |
| **State management** | `flutter_bloc ^8.1.6`, `hydrated_bloc ^9.1.5` |
| **DI** | `get_it ^9.2.1` |
| **Networking** | `dio ^5.11.0`, `pretty_dio_logger ^1.4.0` |
| **Database** | `sqflite ^2.3.3+1`, `path ^1.9.0` |
| **Local storage** | `shared_preferences ^2.5.5`, `path_provider ^2.1.6` |
| **Firebase / Push** | `firebase_core ^4.14.0`, `firebase_messaging ^16.6.0`, `flutter_local_notifications ^22.3.0` |
| **Env** | `flutter_dotenv ^6.0.1` |
| **Image** | `image_picker ^1.2.0`, `flutter_image_compress ^2.5.1` |
| **UI / Utils** | `cupertino_icons`, `equatable ^2.1.0`, `flutter_native_splash ^2.4.0`, `flutter_localizations` (SDK) |
| **Dev dependencies** | `flutter_test`, `flutter_lints ^2.0.0`, `sqflite_common_ffi ^2.3.3`, `bloc_test ^9.1.7` |

> Ghi chú đặc biệt: `dependency_overrides: firebase_core_web: 3.10.0` — ghim để tránh lỗi
> `isA` không tồn tại trên Dart 3.10.7 (xem comment trong pubspec).

---

## 2. Cây thư mục đầy đủ

```
dutoan_x/
├── pubspec.yaml                        # ⭐ Manifest, deps, assets, fonts, splash
├── analysis_options.yaml
├── build-apk.sh / verify-setup.sh      # Script hỗ trợ build & verify môi trường
├── .env.dev / .env.prod                # ⭐ File env theo flavor
├── android/                            # Android (flavors dev/prod)
├── ios/                                # iOS
├── macos/                              # macOS
├── web/                                # Web
├── tool/                               # Script: add flavors, build ios, gen icon…
├── assets/
│   ├── data/                           # vietnam_legacy_districts.json (dữ liệu quận/huyện)
│   ├── fonts/                          # BeVietnamPro + Satoshi
│   ├── images/                         # logo, splash, project covers
│   └── vectors/                        # icon SVG (home, profile, sun, moon…)
├── test/                               # Unit & widget test
└── lib/
    ├── main.dart                       # ⭐ Entry dev (gọi bootstrap, env dev)
    ├── main_dev.dart                   # ⭐ Entry dev (giống main.dart)
    ├── main_prod.dart                  # ⭐ Entry prod
    ├── bootstrap.dart                  # ⭐ Khởi tạo app: splash, storage, DI, Firebase
    ├── injection_container.dart        # ⭐ DI container (get_it) — đăng ký toàn bộ dependency
    ├── app/
    │   └── construction_plan_app.dart  # ⭐ Root widget: MultiBlocProvider + MaterialApp
    ├── base/                           # Các class base dùng chung
    │   └── responses/base_response.dart
    ├── common/                         # Widget/helper dùng chung giữa các feature
    │   ├── helpers/                    # extension (isDarkMode…)
    │   └── widgets/                    # button, media, settings, sheets
    ├── constants/                      # Hằng số UI toàn cục
    ├── core/                           # Hạ tầng lõi (config, network, storage, data…)
    │   ├── bloc/                       # AppBlocObserver
    │   ├── configs/                    # app_config, theme, assets, api_error_config
    │   ├── data/                       # danh sách tỉnh/quận Việt Nam
    │   ├── formatters/                 # formatter tiền tệ VN
    │   ├── network/                    # ApiClient, DioFactory, ApiException
    │   └── storage/                    # LocalStorage (shared_preferences)
    ├── data/                           # Data sources + repository (feature notification)
    │   ├── data_sources/
    │   │   ├── local/                  # NotificationLocalDataSource
    │   │   └── remote/                 # NotificationRemoteDataSource
    │   └── repositories/notification/  # NotificationRepositoryImpl
    ├── domain/                         # Domain layer (feature notification)
    │   ├── entities/notification/      # DeviceTokenEntity
    │   ├── repository/notification/    # NotificationRepository (abstract)
    │   └── usecases/                   # RegisterDeviceToken, UseCase base
    ├── features/                       # Feature-first (Clean Architecture từng feature)
    │   ├── material_library/           # Feature: Thư viện vật liệu
    │   │   ├── data/                   # store, database, repository, catalog mặc định
    │   │   ├── domain/                 # entity, repository, usecases
    │   │   ├── models/                 # re-export tương thích ngược
    │   │   ├── pages/                  # material_library_page.dart
    │   │   └── presentation/bloc/      # cubit + state
    │   └── projects/                   # Feature: Dự án xây dựng (lớn nhất)
    │       ├── data/                   # database SQLite, store, repository, ảnh bìa
    │       ├── domain/                 # entity, repository, service (cost estimator), usecases
    │       └── presentation/           # bloc, pages (wizard 5 bước, detail), widgets
    ├── l10n/                           # vi.json, en.json (localization)
    ├── presentation/                   # UI layer toàn cục (main screen, home, profile)
    │   ├── choose_mode/bloc/           # LocaleCubit, ThemeCubit (hydrated)
    │   ├── pages/
    │   │   ├── home/                   # HomePage
    │   │   └── main/                   # MainScreen + MainNavigationCubit
    │   └── widgets/                    # appbar, dialog, no_internet_ui
    ├── services/                       # FirebaseMessaging, Localization, Navigation
    └── utils/                          # InMemoryStorage (fallback hydrated_bloc)
```

**Chú thích ⭐**: file entry point, DI container, root app widget, config quan trọng.

---

## 3. Kiến trúc tổng thể

### Pattern kiến trúc
Dự án kết hợp **2 phong cách**:

1. **Feature-first + Clean Architecture** — áp dụng cho 2 feature chính:
   - `features/projects/`
   - `features/material_library/`
   - Mỗi feature chia 3 tầng: `domain/` (entity, repository interface, usecase, service) → `data/` (repository impl, store/database) → `presentation/` (bloc/cubit, pages, widgets).

2. **Layer-first** — áp dụng cho tầng dùng chung và feature notification:
   - `core/` (config, network, storage, formatter)
   - `domain/` + `data/` (feature notification nằm ở đây)
   - `presentation/` (main screen, home, profile, các bloc toàn cục)
   - `common/`, `services/`, `utils/`

### Sơ đồ luồng dữ liệu

```
┌─────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION (UI)                         │
│  Widget (HomePage, MaterialLibraryPage, ProjectWizardPage…)        │
│      │  BlocBuilder / context.read<Cubit>()                        │
│      ▼                                                             │
│  Cubit / State (flutter_bloc + hydrated_bloc)                      │
│      │  gọi UseCase (domain)                                       │
└──────┼─────────────────────────────────────────────────────────────┘
       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                        DOMAIN (usecases)                           │
│  UseCase<Result, Params>.call(params)                              │
│      │  gọi Repository (interface)                                 │
└──────┼─────────────────────────────────────────────────────────────┘
       ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         DATA (repository impl)                     │
│  RepositoryImpl → Store / DataSource                               │
│      ├── Local: SQLite (sqflite) / InMemory fallback               │
│      ├── Local: SharedPreferences (LocalStorage)                   │
│      └── Remote: ApiClient (dio) — hiện chỉ dùng cho FCM token     │
└─────────────────────────────────────────────────────────────────────┘
```

### Cách tổ chức code
- **Theo feature** là chủ đạo (`features/projects`, `features/material_library`).
- Tầng **dùng chung** (core, services, common, presentation) tách theo layer để tái sử dụng.
- Feature **notification** nằm ở `domain/` + `data/` (cấu trúc layer-first), khác với 2 feature chính — đây là điểm không đồng nhất cần lưu ý.

### Sơ đồ ASCII kiến trúc

```
                    ┌───────────────────────────┐
                    │   bootstrap() / main      │
                    │  AppConfig.load(env)      │
                    │  initializeDependencies() │
                    └────────────┬──────────────┘
                                 ▼
              ┌──────────────────────────────────────┐
              │        ConstructionPlanApp           │  ← MultiBlocProvider
              │  ThemeCubit · LocaleCubit · Nav      │
              │  MaterialLibraryCubit · ProjectCubit │
              └────────────┬─────────────────────────┘
                           ▼
              ┌──────────────────────────────────────┐
              │           MainScreen (IndexedStack)  │
              │  HomePage · MaterialLibraryPage ·    │
              │  LocalToolPage · ProfilePage         │
              └────────────┬─────────────────────────┘
                           ▼
        ┌──────────────────┴───────────────────────┐
        ▼                                          ▼
  features/projects                        features/material_library
  ┌──────────────┐                          ┌──────────────┐
  │ presentation │  cubit → state           │ presentation │  cubit → state
  │   (bloc)     │                          │   (bloc)     │
  ├──────────────┤                          ├──────────────┤
  │   domain     │  entity/usecase/service  │   domain     │  entity/usecase
  ├──────────────┤                          ├──────────────┤
  │    data      │  repository/store/db     │    data      │  repository/store/db
  └──────┬───────┘                          └──────┬───────┘
         │  sqflite (SQLite) / InMemory             │  sqflite / InMemory
         ▼                                          ▼
   construction_projects.db                 construction_plan.db
```

---

## 4. Chi tiết từng thư mục chính trong `lib/`

### 4.1 `app/`
Mục đích: chứa root widget của ứng dụng.

| File | Mô tả |
| --- | --- |
| `construction_plan_app.dart` | ⭐ `ConstructionPlanApp` — Root `StatelessWidget`. Dựng `MultiBlocProvider` (5 bloc) + `MaterialApp` (theme, locale, delegates, `NavigationService.navigatorKey`, home = `MainScreen`). Hỗ trợ inject store tùy chỉnh cho test qua `materialLibraryStore` / `projectStore`. |

### 4.2 `base/`
Mục đích: class base dùng chung cho response/network.

| File | Mô tả |
| --- | --- |
| `responses/base_response.dart` | `BaseResponse<T>` — wrapper chung `{success, message, data}` với `fromJson`/`toJson`. |

### 4.3 `common/`
Mục đích: widget & helper tái sử dụng giữa các màn hình.

| File | Mô tả |
| --- | --- |
| `helpers/is_dark_mode.dart` | Extension `BuildContext.isDarkMode` — kiểm tra dark theme. |
| `widgets/button/basic_app_button.dart` | `BasicAppButton` — nút dùng gradient, chiều cao mặc định 80. |
| `widgets/button/gradient_app_button.dart` | `GradientAppButton` — nút gradient theo theme (AppColors). |
| `widgets/media/image_source_bottom_sheet.dart` | Bottom sheet chọn nguồn ảnh (camera/thư viện). |
| `widgets/settings/settings_widget.dart` | `SettingsWidget` — hàng setting chung. |
| `widgets/sheets/app_bottom_sheet_header.dart` | `AppBottomSheetHeader` — header cho bottom sheet. |

### 4.4 `constants/`
Mục đích: hằng số UI toàn cục.

| File | Mô tả |
| --- | --- |
| `constants.dart` | `defaultPagePadding = 22`, `defaultCardRadius = 24`. |

### 4.5 `core/`
Mục đích: hạ tầng lõi — config, network, storage, dữ liệu tĩnh, formatter.

| File | Mô tả |
| --- | --- |
| `bloc/app_bloc_observer.dart` | `AppBlocObserver` — log lỗi bloc ở chế độ debug. |
| `configs/app_config.dart` | ⭐ `AppConfig` + `enum AppEnvironment` — nạp `.env` theo flavor, cung cấp `apiBaseUrl`, `apiTimeoutMs`, `appTitle`, `fcmTokenEndpoint`, `hasRemoteApi`… |
| `configs/api_error_config.dart` | `ApiErrorConfigs`, `ApiErrorDialogConfig`, `ApiErrorActionConfig` — registry ánh xạ HTTP status → error dialog. |
| `configs/assets/app_images.dart` | `AppImages` — hằng số path ảnh. |
| `configs/assets/app_vectors.dart` | `AppVectors` — hằng số path icon SVG. |
| `configs/theme/app_colors.dart` | `AppColors` — bảng màu light/dark + helper gradient (button, navigation). |
| `configs/theme/app_text_styles.dart` | `AppTextStyles` — toàn bộ text style (h1…labelTiny, button, number…). Font `BeVietnamPro`. |
| `configs/theme/app_theme.dart` | `AppTheme` — `lightTheme`/`darkTheme`, Material 3, ColorScheme, component themes. |
| `data/vietnam_provinces.dart` | `VietnamProvince` + `vietnamProvinces` (34 đơn vị cấp tỉnh từ 1/7/2025). |
| `data/vietnam_districts.dart` | `VietnamDistrictCatalog`, `VietnamDistrict` — nạp quận/huyện (legacy) từ JSON asset. |
| `formatters/vietnamese_currency_input_formatter.dart` | `VietnameseCurrencyInputFormatter` — format số VND với dấu chấm ngàn, `parse`. |
| `network/api_client.dart` | `ApiClient` — bọc `dio` với các method `get/post/put/delete` + guard lỗi thành `ApiException`. |
| `network/api_exception.dart` | `ApiException` — chuyển `DioException` thành message thân thiện (tiếng Việt). |
| `network/dio_factory.dart` | `DioFactory` — tạo `Dio` với baseUrl, timeout, header, interceptor gắn Bearer token, logger debug. |
| `storage/local_storage.dart` | `LocalStorage` (abstract) + `SharedPreferencesLocalStorage` + `StorageKeys` (`auth_token`, `fcm_token`). |

### 4.6 `data/` (layer-first — feature notification)
Mục đích: data sources & repository cho tính năng thông báo/FCM.

| File | Mô tả |
| --- | --- |
| `data_sources/local/notification_local_data_source.dart` | `NotificationLocalDataSource` + Impl — lưu/đọc FCM token qua `LocalStorage`. |
| `data_sources/remote/notification_remote_data_source.dart` | `NotificationRemoteDataSource` + Impl — POST token lên endpoint `FCM_TOKEN_ENDPOINT` (nếu cấu hình). |
| `repositories/notification/notification_repository_impl.dart` | `NotificationRepositoryImpl` — phối hợp local + remote khi đăng ký device. |

### 4.7 `domain/` (layer-first — feature notification)
Mục đích: entity, repository interface, usecase cho thông báo.

| File | Mô tả |
| --- | --- |
| `entities/notification/device_token_entity.dart` | `DeviceTokenEntity` — `{token, platform}`. |
| `repository/notification/notification_repository.dart` | `NotificationRepository` (abstract) — `registerDevice`, `cachedToken`. |
| `usecases/usecase.dart` | ⭐ `UseCase<Result, Params>` + `NoParams` — base cho mọi usecase. |
| `usecases/register_device_token.dart` | `RegisterDeviceToken` — usecase đăng ký device token. |

### 4.8 `features/` (feature-first)
#### `features/material_library/` — Thư viện vật liệu (định mức giá vật liệu/nhân công)

| File | Mô tả |
| --- | --- |
| `domain/entities/material_library_item.dart` | `MaterialLibraryItem` + `enum LibraryItemType` (material/labor) — entity vật liệu. |
| `domain/repositories/material_library_repository.dart` | `MaterialLibraryRepository` (abstract) — CRUD vật liệu. |
| `domain/usecases/get_material_library_items.dart` | `GetMaterialLibraryItems`. |
| `domain/usecases/save_material_library_item.dart` | `SaveMaterialLibraryItem` + `SaveMaterialLibraryItemParams`. |
| `domain/usecases/delete_material_library_item.dart` | `DeleteMaterialLibraryItem` + params. |
| `data/material_library_store.dart` | `MaterialLibraryStore` (abstract) + `InMemoryMaterialLibraryStore` (seed danh mục mặc định). |
| `data/material_library_database.dart` | `MaterialLibraryDatabase` — SQLite (`construction_plan.db`, version 3), schema + seed catalog. |
| `data/material_library_store_factory.dart` | `MaterialLibraryStoreFactory` — chọn SQLite (mobile) hoặc InMemory (web/test). |
| `data/material_library_repository_impl.dart` | `MaterialLibraryRepositoryImpl` — ủy quyền cho store. |
| `data/default_material_catalog.dart` | `defaultMaterialCatalog` — danh mục vật liệu mặc định (gạch, cát, xi măng…). |
| `data/models/material_library_item_model.dart` | `MaterialLibraryItemModel` — map entity ↔ DB row. |
| `models/material_library_item.dart` | Re-export entity (tương thích ngược cho consumer cũ). |
| `presentation/bloc/material_library_cubit.dart` | `MaterialLibraryCubit` — load/save/delete. |
| `presentation/bloc/material_library_state.dart` | `MaterialLibraryState` + `enum MaterialLibraryStatus`. |
| `pages/material_library_page.dart` | `MaterialLibraryPage` — UI danh sách, editor sheet, details sheet. |

#### `features/projects/` — Dự án xây dựng (tính năng lớn nhất, wizard 5 bước + ước lượng chi phí)

| File | Mô tả |
| --- | --- |
| `domain/entities/construction_project.dart` | ⭐ `ConstructionProject` + hàng loạt spec class: `BuildingFloor`, `RoofSpec`, `ColumnSpec`, `PileCapSpec`, `FoundationStructureSpec`, `ProjectMaterial`, `WallSpec`, `OpeningSpec`, `BathroomSpec`, `StairSpec`, `ProjectDetails` + các enum (`RoofType`, `FoundationType`, `StructureType`, …). |
| `domain/repositories/project_repository.dart` | `ProjectRepository` (abstract) — get/save/delete project. |
| `domain/services/project_cost_estimator.dart` | ⭐ `ProjectCostEstimator`, `ProjectCostEstimate`, `ProjectCostLine` — ước lượng chi phí theo diện tích sàn (baseline 80 m²). |
| `domain/usecases/get_projects.dart` | `GetProjects`. |
| `domain/usecases/save_project.dart` | `SaveProject`. |
| `data/project_store.dart` | `ProjectStore` (abstract) + `InMemoryProjectStore`. |
| `data/project_database.dart` | ⭐ `ProjectDatabase` — SQLite (`construction_projects.db`, version 2) với 11 bảng liên kết (projects, floors, roofs, foundations, columns, pile_caps, materials, segments, walls, openings, bathrooms, stairs). |
| `data/project_store_factory.dart` | `ProjectStoreFactory` — chọn SQLite / InMemory theo nền tảng. |
| `data/project_repository_impl.dart` | `ProjectRepositoryImpl`. |
| `data/project_cover_image_service.dart` | `ProjectCoverImageService` — nén & lưu ảnh bìa dự án (max 1600px, JPEG quality 78). |
| `presentation/bloc/project_cubit.dart` | `ProjectCubit` — load/create/update dự án. |
| `presentation/bloc/project_state.dart` | `ProjectState` + `enum ProjectStatus`. |
| `presentation/bloc/project_wizard_cubit.dart` | ⭐ `ProjectWizardCubit` — quản lý toàn bộ draft wizard (floors, roof, foundation, materials, details, validation, điều hướng bước). |
| `presentation/bloc/project_wizard_state.dart` | `ProjectWizardState` — state wizard (5 bước, validation từng bước). |
| `presentation/pages/project_wizard_page.dart` | `ProjectWizardPage` — trang wizard (BlocProvider riêng cho `ProjectWizardCubit`). |
| `presentation/pages/project_detail_page.dart` | `ProjectDetailPage` — trang chi tiết dự án (metrics, technical overview, cost distribution donut chart). |
| `presentation/pages/steps/project_basic_step.dart` | `ProjectBasicStep` — bước 1: tên, địa chỉ, tỉnh/quận, ảnh bìa. |
| `presentation/pages/steps/project_floors_roof_step.dart` | `ProjectFloorsRoofStep` — bước 2: số tầng & mái. |
| `presentation/pages/steps/project_foundation_step.dart` | `ProjectFoundationStep` — bước 3: móng, cột, đài cọc. |
| `presentation/pages/steps/project_materials_step.dart` | `ProjectMaterialsStep` — bước 4: chọn vật liệu từ thư viện. |
| `presentation/pages/steps/project_details_step.dart` | `ProjectDetailsStep` — bước 5: chi tiết (tường, cửa, cầu thang, WC). |
| `presentation/widgets/project_cover_image.dart` | `ProjectCoverImage` — widget hiển thị ảnh bìa. |
| `presentation/widgets/project_wizard_stepper.dart` | `ProjectWizardStepper` — thanh bước (stepper). |

### 4.9 `l10n/`
Mục đích: file JSON dịch (custom localization, không dùng ARB).

| File | Mô tả |
| --- | --- |
| `vi.json` | Bản dịch tiếng Việt (key → chuỗi). |
| `en.json` | Bản dịch tiếng Anh. |

### 4.10 `presentation/`
Mục đích: UI layer toàn cục (không thuộc feature nào).

| File | Mô tả |
| --- | --- |
| `choose_mode/bloc/locale_cubit.dart` | `LocaleCubit` (HydratedCubit) — lưu locale (mặc định `vi`). |
| `choose_mode/bloc/theme_cubit.dart` | `ThemeCubit` (HydratedCubit) — lưu ThemeMode (mặc định light). |
| `pages/main/main_screen.dart` | `MainScreen` — bottom nav có notch + nút thêm dự án nổi, `IndexedStack` 4 tab. |
| `pages/main/bloc/main_navigation_cubit.dart` | `MainNavigationCubit` — `Cubit<int>` quản lý tab hiện tại. |
| `pages/home/home_page.dart` | `HomePage` — carousel dự án (PageView auto-scroll), danh sách dịch vụ. |
| `pages/profile/profile_page.dart` | `ProfilePage` — header, cài đặt theme/ngôn ngữ, thông tin. |
| `widgets/appbar/app_bar.dart` | `BasicAppBar` — AppBar dùng chung. |
| `widgets/dialog/dialog_service.dart` | `DialogService` — show dialog lỗi/thành công. |
| `widgets/dialogs/base_dialog.dart` | `BaseDialog` + `enum DialogType`. |
| `widgets/dialogs/under_development_dialog.dart` | Dialog "tính năng đang phát triển". |
| `widgets/no_internet_ui.dart` | `NoInternetUI` — giao diện khi mất mạng. |

### 4.11 `services/`
Mục đích: dịch vụ nền toàn cục.

| File | Mô tả |
| --- | --- |
| `firebase_messaging_service.dart` | ⭐ `FirebaseMessagingService` — khởi tạo FCM, local notifications, đăng ký token, background handler. |
| `localization_service.dart` | `AppLocalizations` — load JSON dịch, delegate + extension `context.tr(key)`. |
| `navigation_service.dart` | `NavigationService` — `GlobalKey<NavigatorState>` để điều hướng toàn cục. |

### 4.12 `utils/`
| File | Mô tả |
| --- | --- |
| `in_memory_storage.dart` | `InMemoryStorage` — fallback `Storage` cho hydrated_bloc khi file system lỗi. |

---

## 5. Các file cấu hình & điểm vào chính

### 5.1 Entry points
| File | Mô tả |
| --- | --- |
| `main.dart` | Entry mặc định — gọi `bootstrap(environment: AppEnvironment.dev, debugShowCheckedModeBanner: true)`. |
| `main_dev.dart` | Entry flavor dev — giống `main.dart`. |
| `main_prod.dart` | Entry flavor prod — `bootstrap(environment: AppEnvironment.prod)`. |
| `bootstrap.dart` | ⭐ Hàm `bootstrap()` — `ensureInitialized` → `FlutterNativeSplash.preserve` → `AppConfig.load(env)` → khởi tạo `HydratedBloc.storage` (web: webStorage/InMemory, mobile: documents/temporary/InMemory) → `Bloc.observer` → `initializeDependencies()` → init FirebaseMessaging (timeout 15s, không crash nếu lỗi) → `runApp(ConstructionPlanApp(...))` → remove splash. |

### 5.2 File cấu hình môi trường
- `core/configs/app_config.dart` — `AppConfig` đọc `.env` qua `flutter_dotenv`.
- `.env.dev` / `.env.prod` — `ENVIRONMENT`, `APP_TITLE`, `API_BASE_URL`, `API_TIMEOUT_MS`, `FCM_TOKEN_ENDPOINT` (hiện `API_BASE_URL` để trống → app chạy local-only).

### 5.3 Routing
**Không dùng go_router / auto_route.** Dùng `Navigator.push` + `MaterialPageRoute` trực tiếp + `NavigationService.navigatorKey`. Các màn hình chính:
- `MainScreen` (root, `home` của MaterialApp)
- `ProjectWizardPage`, `ProjectDetailPage` (push từ HomePage/MainScreen)
- Bottom sheets (MaterialLibrary editor/detail)

### 5.4 DI container
`injection_container.dart` — dùng **get_it** (`final sl = GetIt.instance`).
- `LocalStorage` (singleton, SharedPreferences)
- `Dio` → `ApiClient` (lazy)
- Notification: `NotificationLocalDataSource`, `NotificationRemoteDataSource`, `NotificationRepository`, `RegisterDeviceToken`, `FirebaseMessagingService`
- Material library: `MaterialLibraryStore` (factory), `MaterialLibraryRepository`, 3 usecase, `MaterialLibraryCubit` (factory)
- Projects: `ProjectStore` (factory), `ProjectRepository`, 2 usecase, `ProjectCubit` (factory)

### 5.5 Theme / Design system
- `core/configs/theme/app_colors.dart` — bảng màu.
- `core/configs/theme/app_text_styles.dart` — text styles.
- `core/configs/theme/app_theme.dart` — `ThemeData` light/dark (Material 3).

### 5.6 Localization
- `l10n/vi.json`, `l10n/en.json` + `services/localization_service.dart` (`AppLocalizations`, `context.tr()`).

### 5.7 API client / interceptors
- `core/network/api_client.dart` — wrapper các method HTTP, bắt `DioException`.
- `core/network/dio_factory.dart` — baseUrl, timeout, header JSON, interceptor Bearer token (đọc `StorageKeys.authToken`), `PrettyDioLogger` ở debug.
- `core/network/api_exception.dart` — map lỗi sang message tiếng Việt.
- `base/responses/base_response.dart` — wrapper response `{success, message, data}`.

### 5.8 Model / Entity chính
| Entity | Field quan trọng |
| --- | --- |
| `ConstructionProject` | `id`, `name`, `location`, `imagePath`, `provinceId/Name`, `districtId/Name`, `createdAt`, `updatedAt`, `floors[]`, `roof`, `foundationStructure`, `materials[]`, `details` |
| `MaterialLibraryItem` | `id`, `catalogCode`, `name`, `price`, `unit`, `type`, `length/width/height` |
| `DeviceTokenEntity` | `token`, `platform` |
| `BuildingFloor` | `number`, `length`, `width`, `height`, `area` |
| `FoundationStructureSpec` | `foundationType`, `structureType`, `alignment`, `mainBarDiameter`, `columns[]`, `pileCaps[]` |

---

## 6. Các class/module quan trọng nhất

| # | Class | File | Vai trò | Method/property chính |
| --- | --- | --- | --- | --- |
| 1 | `ConstructionPlanApp` | `lib/app/construction_plan_app.dart` | Root widget, cấu hình app | `build()` → MultiBlocProvider + MaterialApp |
| 2 | `AppConfig` | `lib/core/configs/app_config.dart` | Cấu hình runtime từ env | `load()`, `apiBaseUrl`, `apiTimeoutMs`, `appTitle`, `hasRemoteApi` |
| 3 | `bootstrap` | `lib/bootstrap.dart` | Khởi tạo toàn app | `bootstrap({environment, debugShowCheckedModeBanner})` |
| 4 | `initializeDependencies` | `lib/injection_container.dart` | Đăng ký DI (get_it) | `sl` (GetIt instance) |
| 5 | `ApiClient` | `lib/core/network/api_client.dart` | HTTP client (dio) | `get/post/put/delete` |
| 6 | `DioFactory` | `lib/core/network/dio_factory.dart` | Tạo & cấu hình Dio | `create()` |
| 7 | `LocalStorage` | `lib/core/storage/local_storage.dart` | Lưu trữ key-value | `readString`, `readBool`, `writeString`, `remove`, `clear` |
| 8 | `ConstructionProject` | `lib/features/projects/domain/entities/construction_project.dart` | Entity dự án (model lõi) | `totalFloorArea`, `copyWith` |
| 9 | `ProjectCubit` | `lib/features/projects/presentation/bloc/project_cubit.dart` | Quản lý danh sách dự án | `load()`, `create()`, `update()` |
| 10 | `ProjectWizardCubit` | `lib/features/projects/presentation/bloc/project_wizard_cubit.dart` | Quản lý wizard tạo dự án | `updateBasicInfo`, `addFloor`, `selectFoundationType`, `toggleMaterial`, `next`, `buildProject` |
| 11 | `ProjectDatabase` | `lib/features/projects/data/project_database.dart` | SQLite cho dự án | `getAll`, `save`, `delete` |
| 12 | `ProjectCostEstimator` | `lib/features/projects/domain/services/project_cost_estimator.dart` | Ước lượng chi phí | `estimate(project)` |
| 13 | `MaterialLibraryCubit` | `lib/features/material_library/presentation/bloc/material_library_cubit.dart` | Quản lý thư viện vật liệu | `load()`, `save()`, `delete()` |
| 14 | `MaterialLibraryDatabase` | `lib/features/material_library/data/material_library_database.dart` | SQLite cho vật liệu | `getAll`, `create`, `update`, `delete` |
| 15 | `FirebaseMessagingService` | `lib/services/firebase_messaging_service.dart` | FCM + local notification | `initialize()`, `getToken()`, `subscribeToTopic()` |
| 16 | `AppLocalizations` | `lib/services/localization_service.dart` | Dịch chuỗi JSON | `of()`, `load()`, `translate()` |
| 17 | `NavigationService` | `lib/services/navigation_service.dart` | Điều hướng toàn cục | `navigatorKey`, `navigator`, `context` |
| 18 | `ThemeCubit` / `LocaleCubit` | `lib/presentation/choose_mode/bloc/` | Theme & ngôn ngữ (hydrated) | `toggleTheme()`, `toggleLanguage()` |
| 19 | `AppTheme` | `lib/core/configs/theme/app_theme.dart` | Theme light/dark | `lightTheme`, `darkTheme` |
| 20 | `UseCase` | `lib/domain/usecases/usecase.dart` | Base cho mọi usecase | `call(params)` |

---

## 7. State Management

**Đang dùng: `flutter_bloc` (Cubit) + `hydrated_bloc`** (không dùng Riverpod/Provider/GetX).

Các Cubit trong app:

| Cubit | State | Persist | Nơi cung cấp |
| --- | --- | --- | --- |
| `ThemeCubit` | `ThemeMode` | ✅ hydrated | `ConstructionPlanApp` |
| `LocaleCubit` | `Locale` | ✅ hydrated | `ConstructionPlanApp` |
| `MainNavigationCubit` | `int` (tab index) | ❌ | `ConstructionPlanApp` |
| `MaterialLibraryCubit` | `MaterialLibraryState` | ❌ | `ConstructionPlanApp` |
| `ProjectCubit` | `ProjectState` | ❌ | `ConstructionPlanApp` |
| `ProjectWizardCubit` | `ProjectWizardState` | ❌ | `ProjectWizardPage` (scope riêng) |

### Ví dụ flow: Tạo dự án mới
1. **UI** `MainScreen._openProjectWizard` push `ProjectWizardPage`.
2. `ProjectWizardPage` tạo `ProjectWizardCubit(initialProject: null)` qua `BlocProvider`.
3. User nhập liệu qua 5 bước → mỗi bước gọi method của `ProjectWizardCubit` (VD `updateBasicInfo`, `addFloor`, `toggleMaterial`).
4. `ProjectWizardCubit.next()` kiểm tra `state.isStepValid(step)` → chuyển bước hoặc bật validation.
5. Khi hoàn tất, UI gọi `buildProject()` → `ConstructionProject` entity → gửi cho `ProjectCubit.create(project)`.
6. `ProjectCubit._persist` gọi usecase `SaveProject` → `ProjectRepositoryImpl` → `ProjectDatabase.save` (SQLite) → `load()` cập nhật state.
7. UI nhận state mới qua `BlocBuilder` / `BlocConsumer` và hiển thị.

---

## 8. Networking & Data layer

### HTTP client
- **dio** (`dio ^5.11.0`), bọc bởi `ApiClient`.
- `DioFactory.create()`: `BaseOptions(baseUrl: AppConfig.apiBaseUrl, timeout: AppConfig.apiTimeoutMs)`, header `Accept/Content-Type: application/json`.

### Định nghĩa API endpoint
- Chưa có file endpoint tập trung. Endpoint lấy từ `AppConfig` (`.env`): `apiBaseUrl`, `fcmTokenEndpoint`.
- Hiện tại chỉ có **1 call mạng**: `NotificationRemoteDataSourceImpl.registerDevice` POST `{deviceRegistrationId, platform}` tới `FCM_TOKEN_ENDPOINT` (chỉ chạy nếu `hasFcmTokenEndpoint`).

### Xử lý response/error
- `ApiClient._guard` bắt `DioException` → ném `ApiException.fromDio` (message tiếng Việt).
- `BaseResponse<T>` parse `{success, message, data}`.
- `ApiErrorConfigs` (core/configs/api_error_config.dart) — registry cấu hình error dialog theo status code.

### Serialize JSON
- **Manual** (không dùng json_serializable/freezed). Dùng `BaseResponse.fromJson` thủ công, entity/`toDatabaseMap` thủ công.
- Enum lưu DB bằng tên (`name`/`databaseValue`) và parse ngược bằng `firstWhere`.

### Local storage
| Công nghệ | Dùng cho |
| --- | --- |
| `shared_preferences` (qua `LocalStorage`) | auth token, FCM token |
| `sqflite` | dự án (`construction_projects.db`), thư viện vật liệu (`construction_plan.db`) |
| `hydrated_bloc` storage | persist theme & locale |
| `InMemoryStorage` | fallback khi file system lỗi |
| `InMemory*Store` | fallback trên web / widget test |

---

## 9. Quy ước code (conventions)

### Naming
- **File/folder**: `snake_case.dart` (VD `project_wizard_cubit.dart`, `material_library_page.dart`).
- **Class**: `PascalCase` (VD `ProjectCubit`, `ApiClient`).
- **Biến/hàm**: `lowerCamelCase` (VD `saveProject`, `totalFloorArea`).
- **Hằng số**: `lowerCamelCase` hoặc `SCREAMING_SNAKE` (VD `defaultPagePadding`, `_databaseName`).

### Cấu trúc đặt tên theo feature
- Feature-first: `features/<tên_feature>/<domain|data|presentation>/...`
- Trong domain: `entities/`, `repositories/` (interface), `usecases/`, `services/`.
- Trong data: `data_sources/`, `repositories/` (impl), `models/`, `database`, `store`.
- Trong presentation: `bloc/` (cubit + state), `pages/`, `widgets/`.

### Convention Bloc/Provider/Repository
- Dùng **Cubit** (không dùng Bloc với event). File cubit kèm `_state.dart`.
- Repository: interface ở domain, impl ở data (`XRepository` → `XRepositoryImpl`).
- Store: interface `XStore` + impl `InMemoryXStore` + `XDatabase` + `XStoreFactory`.
- UseCase: implement `UseCase<Result, Params>`.

### Barrel file (`index.dart`)
- **Không dùng** barrel file `index.dart`. Import theo đường dẫn đầy đủ.
- Chỉ có 1 file re-export: `features/material_library/models/material_library_item.dart` (tương thích ngược).

---

## 10. Testing

### Cấu trúc `test/`
Tất cả test nằm phẳng trong `test/` (không mirror cấu trúc lib).

### Loại test
Chủ yếu **unit test** và **widget test** (dùng `flutter_test`, `bloc_test`, `sqflite_common_ffi` cho DB test). Chưa thấy integration test.

| File test | Đối tượng |
| --- | --- |
| `construction_plan_app_test.dart` | Root widget `ConstructionPlanApp` |
| `featured_project_navigation_test.dart` | Điều hướng dự án nổi bật |
| `material_library_cubit_test.dart` | `MaterialLibraryCubit` |
| `material_library_database_test.dart` | `MaterialLibraryDatabase` (sqflite ffi) |
| `project_cost_estimator_test.dart` | `ProjectCostEstimator` |
| `project_database_test.dart` | `ProjectDatabase` (sqflite ffi) |
| `project_detail_widget_test.dart` | `ProjectDetailPage` |
| `project_wizard_cubit_test.dart` | `ProjectWizardCubit` |
| `project_wizard_widget_test.dart` | `ProjectWizardPage` |
| `vietnamese_currency_input_formatter_test.dart` | `VietnameseCurrencyInputFormatter` |
| `widget_test.dart` | Smoke test mặc định |

---

## 11. Assets & Resources

### Cấu trúc `assets/`
```
assets/
├── data/
│   ├── README.md
│   └── vietnam_legacy_districts.json   # Dữ liệu quận/huyện (legacy)
├── fonts/
│   ├── BeVietnamPro-*.ttf              # Font chính (tiếng Việt)
│   └── Satoshi-*.ttf                   # Font giữ lại (legacy)
├── images/
│   ├── app_logo.png
│   ├── app_launcher_icon.png
│   ├── splash_logo.png
│   ├── splash_logo_android12.png
│   └── projects/                       # Ảnh bìa dự án mẫu
└── vectors/
    └── *.svg                           # Icon (sun, moon, home, profile…)
```

### Khai báo trong `pubspec.yaml`
```yaml
assets:
  - assets/data/
  - assets/images/
  - assets/images/projects/
  - assets/vectors/
  - assets/fonts/
  - lib/l10n/
  - .env.dev
  - .env.prod

fonts:
  - family: BeVietnamPro  # weights 300–700 + italic
  - family: Satoshi       # weights 300–900
```

### Các file tài nguyên khác
- `.env.dev` / `.env.prod` — khai báo trong `assets:` để `flutter_dotenv` đọc.
- `lib/l10n/vi.json`, `lib/l10n/en.json` — JSON localization.
- Splash: cấu hình `flutter_native_splash` trong pubspec (màu trắng, logo trung tâm, Android 12 adaptive icon).

---

## Phụ lục: Thống kê scan

- **Số file Dart đã quét**: 78 file trong `lib/` (toàn bộ), 11 file test trong `test/`.
- **Tổng class/abstract class/enum phát hiện**: ~225 (bao gồm các class private `_...` nội bộ widget).
- **Feature chính**: 2 (projects, material_library) + 1 feature phụ (notification) + UI toàn cục.
- **Database SQLite**: 2 file (`construction_projects.db`, `construction_plan.db`).
- **Flavors**: 2 (dev, prod).
