# Hướng dẫn dọn dẹp repo `mobile_core_project` trước khi phát triển tiếp

> **Đối tượng đọc:** AI coding agent (Claude Code, Cursor, v.v.) chạy trong thư mục repo đã clone về máy local.
> **Mục tiêu:** Loại bỏ toàn bộ dấu vết dự án cũ (công ty THP Group), secret bị rò rỉ trong lịch sử git, file build/nhị phân không cần thiết — để repo sạch 100%, an toàn để public/tiếp tục phát triển.
> **Trước khi chạy bất kỳ lệnh nào:** Xác nhận đang đứng đúng thư mục gốc của repo (`pubspec.yaml` phải tồn tại ở đây), và **KHÔNG** chạy guide này trên repo đang có người khác cùng làm việc chung mà chưa thông báo — vì bước 1 sẽ viết lại lịch sử git.

---

## Bối cảnh (để agent hiểu vì sao cần làm)

Repo này được rút gọn/đổi tên từ app nội bộ **"My THP"** của công ty **THP Group**. Dù thư mục làm việc hiện tại (`main` branch, HEAD) đã được dọn khá sạch, **lịch sử git đầy đủ** (đặc biệt ở nhánh phụ `construction_app` với 106 commit) vẫn còn chứa:

- File keystore ký app thật: `new-upload-key.jks` (commit `f5f92f3`)
- `GoogleService-Info.plist` / `google-services.json` chứa Firebase API key thật của project `mythp-9b465`
- `.env.dev` / `.env.prod` từng chứa endpoint API nội bộ thật: `https://mobile-app.thp.com.vn`

Vì Git lưu toàn bộ lịch sử, **ai clone repo đều đào lại được các file này** dù chúng đã bị xóa ở commit sau. Đây là rủi ro bảo mật thật, không phải lý thuyết.

Ngoài ra, thư mục làm việc hiện tại còn vài file không nên tồn tại trong git: file APK build sẵn, chứng chỉ ký của cá nhân/công ty cũ.

---

## Bước 1 — Xử lý lịch sử git (quan trọng nhất)

Có 2 lựa chọn. **Khuyến nghị Lựa chọn A** vì đơn giản, chắc chắn sạch 100%, và bạn không cần giữ lại lịch sử commit của dự án cũ cho một dự án bạn sẽ tiếp tục phát triển độc lập.

### Lựa chọn A — Reset git hoàn toàn (khuyến nghị)

Xóa toàn bộ `.git` cũ (kèm lịch sử chứa secret) và khởi tạo lại từ đầu, chỉ giữ code hiện tại ở working tree.

```bash
# 1. Xác nhận đang ở thư mục gốc repo
ls pubspec.yaml || { echo "SAI THƯ MỤC — dừng lại"; exit 1; }

# 2. Xóa toàn bộ lịch sử git cũ (bao gồm mọi commit, mọi branch, mọi secret trong đó)
rm -rf .git

# 3. Khởi tạo git mới, sạch hoàn toàn
git init -b main

# 4. Cấu hình identity của BẠN (không phải của người/công ty cũ)
git config user.name "TÊN_CỦA_BẠN"
git config user.email "EMAIL_CỦA_BẠN"

# 5. Add & commit toàn bộ code hiện tại làm điểm khởi đầu mới
git add -A
git commit -m "chore: initial clean commit (repo sanitized, old history removed)"
```

Sau bước này, repo không còn liên kết gì tới remote cũ, không còn commit nào của công ty THP, và không thể đào lại được keystore/API key cũ vì lịch sử đã bị xóa hoàn toàn khỏi máy bạn.

### Lựa chọn B — Giữ lịch sử nhưng lọc sạch secret (nếu thực sự cần giữ log commit)

Chỉ dùng nếu bạn có lý do cụ thể cần giữ lịch sử commit (ví dụ để tra cứu changelog). Cần cài `git-filter-repo`:

```bash
pip install git-filter-repo --break-system-packages

# Xóa vĩnh viễn các file nhạy cảm khỏi TOÀN BỘ lịch sử (mọi branch, mọi commit)
git filter-repo --force \
  --path new-upload-key.jks \
  --path android/app/google-services.json \
  --path android/app/src/dev/google-services.json \
  --path ios/Runner/GoogleService-Info.plist \
  --path .env.dev \
  --path .env.prod \
  --invert-paths
```

Sau đó vẫn phải thực hiện Bước 4 (ngắt remote cũ) và tạo lại `.env.dev`/`.env.prod` rỗng như hiện tại vì file này sẽ bị xóa khỏi lịch sử hoàn toàn.

⚠️ Lựa chọn B phức tạp hơn và dễ sai sót hơn Lựa chọn A. Nếu không chắc, dùng Lựa chọn A.

---

## Bước 2 — Xóa file không cần thiết khỏi working tree

Các file này không nên nằm trong git dù dùng lựa chọn nào ở Bước 1:

```bash
# File APK build sẵn (60MB+) — không nên commit file build vào git
rm -f dist/construction-plan-main-v1.0.5-prod-test.apk
rmdir dist 2>/dev/null || true

# Chứng chỉ ký của công ty/cá nhân cũ (O=THP Group, CN=Cuong Ngo) — không thuộc về bạn,
# cần tạo keystore + chứng chỉ ký MỚI của riêng bạn khi build release (xem Bước 5)
rm -f upload_certificate.pem
```

Nếu build script hoặc CI có tham chiếu tới `dist/` hoặc `upload_certificate.pem`, agent cần kiểm tra và cập nhật (xem `build-apk.sh`, `verify-setup.sh`, `docs/*.md`) trước khi xóa để không làm hỏng quy trình build. Chạy lệnh sau để kiểm tra tham chiếu còn sót:

```bash
grep -rn "upload_certificate.pem\|dist/construction-plan" --include="*.sh" --include="*.md" --include="*.gradle" --include="*.yaml" .
```

Sửa/xóa các dòng tham chiếu tìm được cho phù hợp (thường là hướng dẫn build test, có thể xóa đoạn liên quan hoặc thay bằng ghi chú "tự tạo keystore riêng").

---

## Bước 3 — Rà soát lại toàn bộ code hiện tại xem còn sót thông tin công ty cũ không

```bash
grep -rniI "thp\|digital\.thp\|my_thp\|mythp" \
  --include="*.dart" --include="*.gradle" --include="*.xml" \
  --include="*.plist" --include="*.yaml" --include="*.md" --include="*.json" . \
  2>/dev/null | grep -v "^Binary"
```

Nếu lệnh trên **không trả về kết quả nào** → sạch (đã xác nhận trạng thái hiện tại là sạch ở bước audit trước). Nếu có kết quả → agent xem xét từng dòng và thay thế bằng thông tin của dự án hiện tại (`com.constructionplan.app`, "Construction Plan").

---

## Bước 4 — Ngắt kết nối remote git cũ

Dù đã làm Bước 1 (reset hoàn toàn thì remote tự động mất, không cần làm lại bước này), nếu bạn chọn cách khác hoặc muốn chắc chắn:

```bash
git remote -v                    # xem danh sách remote hiện tại
git remote remove origin         # gỡ remote trỏ về repo github.com/ngonhatcuonguit/mobile_core_project cũ

# Khi đã sẵn sàng, add remote MỚI trỏ về repo của bạn (thay URL thực tế)
git remote add origin https://github.com/<tài-khoản-của-bạn>/<tên-repo-mới>.git
```

---

## Bước 5 — Chuẩn bị keystore & cấu hình ký app CỦA RIÊNG BẠN

Vì keystore cũ (`new-upload-key.jks`) đã coi như bị lộ (từng public trong lịch sử git), **không được tái sử dụng keystore đó** cho bản release thật. Agent hướng dẫn người dùng (không tự làm thay vì cần tương tác — tạo keystore cần nhập password, mã hoá, thông tin cá nhân):

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

Sau đó tạo `android/key.properties` (đã có sẵn `.gitignore` chặn commit, xem `android/key.properties.example` làm mẫu):

```bash
cp android/key.properties.example android/key.properties
# rồi tự điền storePassword, keyPassword, keyAlias, storeFile trỏ tới keystore MỚI vừa tạo
```

---

## Bước 6 — Kiểm tra `.gitignore` đã đủ chặt chưa

`.gitignore` hiện tại đã có sẵn các rule tốt (`*.jks`, `*.keystore`, `/android/key.properties`, `google-services.json`, `GoogleService-Info.plist`). Agent bổ sung thêm 2 rule còn thiếu để tránh lặp lại sự cố commit nhầm file build/secret trong tương lai:

```bash
cat >> .gitignore << 'EOF'

# Build output — không commit file build vào git
/dist/
*.apk
*.aab
*.ipa

# Chứng chỉ / khóa ký — chỉ tồn tại local, không commit
*.pem
*.p12
*.keystore
*.jks
EOF
```

---

## Bước 7 — Xác nhận trạng thái sạch cuối cùng

```bash
echo "== Git log (phải chỉ có 1 commit mới nếu dùng Lựa chọn A) ==" 
git log --oneline

echo "== Remote hiện tại =="
git remote -v

echo "== File còn được git track =="
git ls-files | grep -Ei "\.jks$|\.keystore$|\.pem$|\.apk$|google-services|GoogleService-Info"
echo "(rỗng ở dòng trên = sạch)"

echo "== Còn tham chiếu công ty cũ trong code không =="
grep -rniI "thp" --include="*.dart" --include="*.gradle" . 2>/dev/null
echo "(rỗng ở dòng trên = sạch)"
```

Nếu cả 2 lệnh `grep` cuối đều không trả về gì và `git log` chỉ hiện đúng 1 commit khởi tạo (với Lựa chọn A) → repo đã sạch, sẵn sàng để bạn tiếp tục phát triển và push lên remote mới.

---

## Tóm tắt việc cần agent thực hiện theo thứ tự

1. `rm -rf .git` + `git init -b main` + commit lại từ đầu (Bước 1, Lựa chọn A)
2. Xóa `dist/*.apk` và `upload_certificate.pem`, sửa các script còn tham chiếu tới chúng
3. Grep xác nhận không còn tham chiếu "thp"/"mythp" trong code
4. Gỡ remote `origin` cũ, thêm remote mới của người dùng
5. Nhắc người dùng tự tạo keystore mới bằng `keytool` (bước cần tương tác, không tự động hoá)
6. Bổ sung `.gitignore` chặn `*.apk`, `*.pem`, `/dist/`
7. Chạy script xác nhận ở Bước 7, báo cáo kết quả cho người dùng
