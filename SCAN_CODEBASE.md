# YÊU CẦU: Tạo file CODEBASE_UI.md cho dự án Flutter


## Nhiệm vụ của bạn
Hãy scan toàn bộ workspace hiện tại và tạo file `CODEBASE_UI.md` ở thư mục gốc 
của dự án với nội dung theo cấu trúc dưới đây.

## Yêu cầu về nội dung file CODEBASE_UI.md

### 1. Tổng quan dự án
- Tên dự án (lấy từ pubspec.yaml)
- Mô tả ngắn (lấy từ `description` trong pubspec.yaml)
- Version, SDK constraint
- Các dependencies chính (từ pubspec.yaml) — nhóm theo: state management, 
  networking, database, UI, utils, dev dependencies
- Nền tảng hỗ trợ (android/ios/web/desktop) — dựa vào folder có trong project
- Có sử dụng Flutter flavors / build variants không?

### 2. Cây thư mục đầy đủ
- Vẽ cây thư mục từ thư mục gốc, độ sâu TỐI ĐA 4-5 cấp
- BỎ QUA các thư mục: `.git/`, `.dart_tool/`, `build/`, `.idea/`, `.vscode/`, 
  `ios/Pods/`, `android/.gradle/`, `node_modules/`, các file `.g.dart` 
  sinh tự động (trừ khi là file core), `*.freezed.dart`, `*.mocks.dart`
- Với mỗi folder trong `lib/`, thêm comment ngắn 1 dòng giải thích mục đích
- Đánh dấu ⭐ vào các file quan trọng (entry point, router, DI, main config)

### 3. Kiến trúc tổng thể
Xác định và mô tả:
- Pattern kiến trúc đang dùng (Clean Architecture / MVVM / MVC / Feature-first / Layer-first)
- Sơ đồ luồng dữ liệu (VD: UI → Provider/Bloc → Repository → API/Local)
- Cách tổ chức code: theo feature hay theo layer?
- Vẽ sơ đồ ASCII đơn giản mô tả kiến trúc

### 4. Chi tiết từng thư mục chính trong `lib/`
Với MỖI thư mục con trực tiếp trong `lib/`, liệt kê:
- Tên folder + mục đích
- Danh sách các file quan trọng bên trong
- Với mỗi file: 1-2 dòng mô tả class/chức năng chính, các public class/function 
  quan trọng nó export

### 5. Các file cấu hình & điểm vào chính
Mô tả chi tiết:
- `main.dart`: khởi tạo gì, có bao nhiêu entry (main_dev, main_prod...)?
- File cấu hình môi trường (env, config, constants)
- File routing (nếu có go_router / auto_route)
- File DI (get_it, riverpod, provider...)
- File theme / design system
- File localization (nếu có)
- File xử lý API client / interceptors
- File model / entity chính (chỉ liệt kê tên + field quan trọng, KHÔNG dump toàn bộ)

### 6. Các class/module quan trọng nhất
Liệt kê 10-20 class/abstract class quan trọng nhất của dự án (VD: AppRouter, 
ApiClient, AuthRepository, UserModel, HomeBloc...) — với mỗi cái:
- Đường dẫn file
- Vai trò trong hệ thống
- Các method/property public chính

### 7. State Management
- Đang dùng gì? (Bloc / Riverpod / Provider / GetX / MobX / setState)
- Cách chia state theo feature
- Ví dụ 1 flow cụ thể từ UI → state → data

### 8. Networking & Data layer
- HTTP client (dio/http)
- Cách định nghĩa API endpoint
- Cách xử lý response/error
- Cách serialize JSON (json_serializable / freezed / manual)
- Local storage (shared_preferences / hive / sqflite / isar)

### 9. Quy ước code (conventions)
- Naming convention đang dùng (file, class, biến)
- Cách đặt tên file/folder (snake_case? feature-based?)
- Convention cho Bloc/Provider/Repository
- Có dùng barrel file (`index.dart`) không?

### 10. Testing (nếu có)
- Cấu trúc thư mục `test/`
- Loại test đang dùng (unit / widget / integration)
- Các file test quan trọng

### 11. Assets & Resources
- Cấu trúc `assets/` (images, fonts, icons, lottie...)
- Cách khai báo trong pubspec.yaml

## Yêu cầu về format
- Dùng markdown heading rõ ràng (##, ###)
- Dùng code block cho cây thư mục và sơ đồ ASCII
- Dùng table khi liệt kê nhiều file/class có tính so sánh
- Ngắn gọn nhưng ĐẦY ĐỦ — không lan man, không copy nguyên code dài
- Tổng độ dài file: khoảng 800-2000 dòng tùy độ lớn dự án
- KHÔNG dump toàn bộ nội dung file source vào — chỉ mô tả + trích dẫn signature quan trọng

## Cách thực hiện
1. Bắt đầu bằng việc đọc `pubspec.yaml` và list toàn bộ file trong `lib/`
2. Đọc các file entry point trước (main.dart, router, DI)
3. Sau đó đọc dần các file trong từng feature
4. Tạo file `CODEBASE_UI.md` ở root project
5. Báo cáo lại: đã scan bao nhiêu file, cấu trúc file output như thế nào

Bắt đầu!