# Hệ Thống Đặt Sân Thể Thao (Sports Field Booking - sportsbook_36vn)

Ứng dụng Flutter đặt sân thể thao đa nền tảng (Android / iOS / Web) được port từ hệ thống ASP.NET Core MVC (PRN222), áp dụng kiến trúc **MVVM**, quản lý trạng thái bằng **Riverpod**, xác thực và lưu trữ dữ liệu thời gian thực bằng **Firebase** (Authentication, Cloud Firestore, Cloud Messaging) cùng **SharedPreferences** lưu trữ cấu hình.

---

## 1. Yêu cầu môi trường (Prerequisites)

- **Flutter SDK**: `>= 3.2.0` (Khuyên dùng Flutter 3.47.x trở lên, Dart SDK `>= 3.13.7`).
- **Android Studio / VS Code**: Đã cài đặt Flutter & Dart extension.
- **Thiết bị chạy**: Máy ảo Android (Emulator Android API >= 21), thiết bị thật (bật USB Debugging), hoặc trình duyệt Google Chrome.
- **Tài khoản Firebase**: Có quyền tạo project trên [Firebase Console](https://console.firebase.google.com).

---

## 2. Hướng dẫn cấu hình Firebase chi tiết (Từng bước)

Dự án sử dụng cơ chế khởi tạo Firebase qua file cấu hình Dart (`lib/core/config/firebase_options_local.dart`), giúp ứng dụng có thể chạy trên mọi nền tảng mà không bị phụ thuộc chặt vào cấu hình native phức tạp.

### Bước 2.1: Tạo dự án Firebase
1. Truy cập [Firebase Console](https://console.firebase.google.com) và đăng nhập tài khoản Google.
2. Bấm **Add project** (Tạo dự án mới), đặt tên ví dụ: `sportsbook-36vn`.
3. Có thể tắt Google Analytics để khởi tạo nhanh hơn, sau đó bấm **Create project**.

### Bước 2.2: Kích hoạt Authentication (Đăng nhập Email/Password)
1. Trong menu bên trái, chọn **Product categories** > **Security** > **Authentication** > bấm **Get Started**.
2. Tại tab **Sign-in method**, bấm vào **Email/Password**.
3. Bật công tắc **Enable** ở dòng đầu tiên (Email/Password), sau đó bấm **Save**.

### Bước 2.3: Kích hoạt Cloud Firestore Database
1. Trong menu bên trái, chọn **Product categories** > **Database & Storage** > **Firestore** > bấm **Create database**.
2. Chọn vị trí máy chủ (Location) gần nhất (khuyên dùng `asia-southeast1` hoặc `asia-east1`) hoặc để default.
3. Chọn chế độ bảo mật:
   - **Start in test mode**: Thích hợp để test phát triển trong 30 ngày (cho phép đọc/ghi tự do).
   - Hoặc thiết lập **Rules** an toàn sau khi tạo database (tab **Rules**):
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /{document=**} {
           allow read, write: if request.auth != null;
         }
       }
     }
     ```
   - Bấm **Publish** để lưu luật.

### Bước 2.4: Đăng ký App trên Firebase & Cấu hình chi tiết `firebase_options_local.dart`

> [!IMPORTANT]
> **Quy tắc quan trọng về thông số cấu hình:**
> 1. **`projectId` & `messagingSenderId` là BẮT BUỘC cho Android:**
>    - `projectId`: Cực kỳ quan trọng để **Cloud Firestore** và **Firebase Auth** kết nối đúng database của bạn. Nếu sai, app sẽ báo lỗi kết nối hoặc không tìm thấy dữ liệu.
>    - `messagingSenderId` (chính là Project Number): Cực kỳ quan trọng cho tính năng **Notification (FCM)**. Nếu để sai hoặc để mẫu `1234567890`, thiết bị Android **sẽ không bao giờ nhận được thông báo**.
> 2. **`appId` là BẮT BUỘC RIÊNG BIỆT từng nền tảng:**
>    - Android có `appId` dạng `1:...:android:...` gắn với Package name.
>    - Web có `appId` dạng `1:...:web:...`.
>    - iOS có `appId` dạng `1:...:ios:...`.
>    - **Tuyệt đối không lấy `appId` của Web điền cho Android**, vì sẽ gây lỗi xác thực hoặc lỗi nhận thông báo.
> 3. **File `firebase_options_local.dart` đã nằm trong `.gitignore`:** Người clone dự án về máy cần tạo file này theo hướng dẫn bên dưới để ứng dụng có thể build và chạy ổn định.

---

#### Hướng dẫn lấy thông số và điền cấu hình từng bước:

##### 1. Đăng ký App Android (Bắt buộc nếu bạn chạy máy ảo / điện thoại Android):
1. Trong Firebase Console, bấm **Add app** (hoặc biểu tượng con robot **Android**).
2. **Android package name**: Nhập chính xác `com.example.sportsbook_36vn` (khớp với file `android/app/build.gradle.kts`).
3. Bấm **Register app** > Tải file **`google-services.json`** về.
4. **Copy file `google-services.json` vừa tải bỏ vào thư mục `android/app/`** của dự án.
5. Mở file `google-services.json` bằng Notepad / VS Code để lấy các thông số cho khối `android`:

| Tên trường trong file `google-services.json` | Vị trí trong file JSON | Điền vào `FirebaseOptions android` | Ví dụ thực tế |
|---|---|---|---|
| **`projectId`** | `"project_info" -> "project_id"` | `projectId: ...` | `sportsbook-36vn-abc12` |
| **`messagingSenderId`** | `"project_info" -> "project_number"` | `messagingSenderId: ...` | `987654321098` |
| **`storageBucket`** | `"project_info" -> "storage_bucket"` | `storageBucket: ...` | `sportsbook-36vn-abc12.appspot.com` |
| **`apiKey`** | `"client[0]" -> "api_key[0]" -> "current_key"` | `apiKey: ...` | `AIzaSyA1b2C3d4...` |
| **`appId`** | `"client[0]" -> "client_info" -> "mobilesdk_app_id"` | `appId: ...` | `1:987654321098:android:a1b2c3d4...` |

*(Hoặc trên Firebase Console: Bấm vào biểu tượng bánh răng ⚙️ **Project settings > General**, bạn sẽ thấy ngay dòng **Project ID** và **Project number** ở ngay đầu trang).*

---

##### 2. Đăng ký App Web (Nếu bạn muốn chạy thử trên trình duyệt Chrome):
1. Trong Firebase Console, bấm **Add app** > chọn biểu tượng **Web** `</>`.
2. Đặt tên app (VD: `sportsbook_36vn`) > Bấm **Register app**.
3. Firebase sẽ hiển thị đoạn mã `firebaseConfig`. Bạn đối chiếu sang khối `web`:
   - `apiKey` -> `apiKey: ...`
   - `appId` -> `appId: 1:...:web:...`
   - `messagingSenderId` -> `messagingSenderId: ...`
   - `projectId` -> `projectId: ...`
   - `authDomain` -> `authDomain: ...`
   - `storageBucket` -> `storageBucket: ...`

---

##### 3. Đăng ký App iOS (Nếu bạn chạy trên macOS / iPhone):
1. Bấm **Add app** > chọn biểu tượng **iOS**.
2. **Apple bundle ID**: Nhập `com.example.sportsbook36vn`.
3. Tải file `GoogleService-Info.plist` (bỏ vào thư mục `ios/Runner/`).
4. Lấy `appId` (dạng `1:...:ios:...`) và `apiKey` điền vào khối `ios`.

---

##### 4. Tạo và lưu file `firebase_options_local.dart`:
1. Mở terminal tại thư mục dự án và chạy lệnh sao chép từ file mẫu:
   ```bash
   cp lib/core/config/firebase_options_sample.dart lib/core/config/firebase_options_local.dart
   ```
2. Mở file `lib/core/config/firebase_options_local.dart`:
   - Đổi tên class từ `SampleFirebaseOptions` thành `LocalFirebaseOptions`.
   - Điền đầy đủ các thông số thật vừa lấy ở các bước trên:

```dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class LocalFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return android;
      case TargetPlatform.iOS: return ios;
      default: return android;
    }
  }

  // Cấu hình từ App Web trên Firebase Console
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSy...-WEB',
    appId: '1:987654321098:web:abcdef123456',
    messagingSenderId: '987654321098',
    projectId: 'sportsbook-36vn-abc12',
    authDomain: 'sportsbook-36vn-abc12.firebaseapp.com',
    storageBucket: 'sportsbook-36vn-abc12.appspot.com',
  );

  // Cấu hình từ file google-services.json của App Android
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSy...-ANDROID',
    appId: '1:987654321098:android:abcdef123456',
    messagingSenderId: '987654321098',
    projectId: 'sportsbook-36vn-abc12',
    storageBucket: 'sportsbook-36vn-abc12.appspot.com',
  );

  // Cấu hình từ App iOS
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSy...-IOS',
    appId: '1:987654321098:ios:abcdef123456',
    messagingSenderId: '987654321098',
    projectId: 'sportsbook-36vn-abc12',
    storageBucket: 'sportsbook-36vn-abc12.appspot.com',
    iosBundleId: 'com.example.sportsbook36vn',
  );
}
```

> **Lưu ý tiện lợi:** Nếu bạn chỉ chạy ứng dụng trên máy Android, bạn chỉ cần điền chính xác khối **`android`** (kèm file `android/app/google-services.json`). Khối `web` và `ios` có thể để nguyên giá trị mẫu mà không ảnh hưởng gì đến việc chạy trên Android.

---

#### Cách 2: Tự động đăng ký toàn bộ App bằng FlutterFire CLI (Lựa chọn nhanh nhất)
Nếu máy tính của bạn đã cài đặt sẵn `firebase-cli` và `flutterfire_cli`:
```bash
flutterfire configure
```
Lệnh này sẽ tự động kết nối tài khoản Firebase của bạn, tự đăng ký cả 3 App (Android, Web, iOS) và tự động sinh mã cấu hình chuẩn 100%. Sau khi chạy xong, bạn chỉ cần copy nội dung vào file `lib/core/config/firebase_options_local.dart`.

---

## 3. Hướng dẫn cài đặt & Khởi chạy ứng dụng

### Bước 3.1: Tải các gói thư viện (Dependencies)
Mở terminal tại thư mục dự án và chạy:
```bash
flutter pub get
```

### Bước 3.2: Kiểm tra phân tích mã nguồn
Đảm bảo mã nguồn đạt chuẩn 0 lỗi:
```bash
flutter analyze
```

### Bước 3.3: Chạy ứng dụng
Khởi động máy ảo Android hoặc cắm điện thoại, sau đó chạy:
```bash
flutter run
```
*(Hoặc bấm **Run without Debugging (Ctrl+F5)** trên Android Studio / VS Code).*

---

## 4. Khởi tạo Dữ liệu mẫu (Seed Data) & Quản lý tài khoản

Dự án đã tích hợp sẵn công cụ **Seed Data tự động** (`lib/seed_main.dart`) để khởi tạo toàn bộ dữ liệu mẫu:
- **4 tài khoản mẫu**: Admin (`admin@sfb.com`), Staff (`staff@sfb.com`), Customer (`customer@sfb.com` & `hoa@gmail.com`) với mật khẩu chung `123456`.
- **4 loại sân**: Bóng đá, Cầu lông, Tennis, Bóng rổ.
- **4 sân thể thao mẫu** liên kết với tài khoản Staff.
- **64 khung giờ** (mỗi sân có 16 khung giờ từ 06:00 đến 22:00).
- **2 mã voucher**: `SUMMER26` (-20%) và `NEWBIE10` (-10%).

---

### Cách 1: Tự động nạp dữ liệu mẫu bằng 1 lệnh (Khuyên dùng)
Sau khi đã cấu hình xong file `firebase_options_local.dart`, bạn chỉ cần chạy lệnh sau:
```bash
flutter run -t lib/seed_main.dart
```
Trên màn hình công cụ, nhấn nút **"Bắt đầu nạp dữ liệu mẫu lên Firestore"**. Hệ thống sẽ tự động tạo tài khoản Firebase Auth, gán quyền và nạp toàn bộ collections lên Firestore theo thời gian thực.

Sau khi hoàn tất, bạn chỉ cần tắt và chạy app chính bằng lệnh `flutter run` để đăng nhập test ngay!

---

### Cách 2: Khởi tạo thủ công trên ứng dụng và Firebase Console

### 4.1. Tạo tài khoản người dùng
1. Mở ứng dụng, tại màn hình Đăng nhập, bấm **Chưa có tài khoản? Đăng ký ngay**.
2. Đăng ký tài khoản (ví dụ: `admin@sfb.com` hoặc `staff@sfb.com`, mật khẩu: `123456`).
3. Mặc định mọi tài khoản khi đăng ký đều có quyền `Customer`.

### 4.2. Nâng quyền Admin hoặc Staff
1. Vào Firebase Console > **Firestore Database** > collection **`users`**.
2. Tìm document tương ứng với email tài khoản vừa đăng ký.
3. Nhấp đúp vào trường **`role`** và sửa giá trị:
   - Thành `"Admin"` (nếu là quản trị viên)
   - Thành `"Staff"` (nếu là chủ sân)
4. Trên ứng dụng, đăng xuất và đăng nhập lại: Menu của Drawer và trang chủ sẽ tự động cập nhật đúng quyền!

### 4.3. Tạo dữ liệu sân bóng & Khung giờ
1. Đăng nhập bằng tài khoản **Staff** hoặc **Admin**.
2. Mở Drawer > chọn **Quản lý sân bóng** > bấm nút **+** (Thêm sân).
3. Nhập thông tin sân:
   - Tên sân (VD: `Sân bóng Thống Nhất`)
   - Loại sân (chọn Bóng đá, Cầu lông, Tennis, Bóng rổ)
   - Địa chỉ, Quận/Huyện, Thành phố (VD: `TP.HCM`)
   - Giá giờ thường (VD: `300000`), Giá giờ cao điểm (VD: `450000`)
4. Bấm **Tạo sân**: Hệ thống sẽ **tự động sinh sẵn 16 khung giờ từ 06:00 đến 22:00** cho sân bóng đó.

### 4.4. Tạo mã khuyến mãi (Voucher)
1. Đăng nhập bằng tài khoản **Admin** > Mở Drawer > **Quản lý khuyến mãi** > bấm **+**.
2. Nhập mã (VD: `SUMMER26`), phần trăm giảm (VD: `20`%), giảm tối đa (`100000`), số lượng (`100`), ngày bắt đầu & kết thúc.
3. Bấm **Tạo khuyến mãi**.

---

## 5. Các nghiệp vụ cốt lõi đã chuyển giao từ C#

| Nghiệp vụ | Chi tiết thực thi trên Flutter |
|---|---|
| **Chống trùng lịch (Concurrency)** | Sử dụng **Firestore Transaction** (`runTransaction`) để kiểm tra nguyên tử: Nếu 2 người cùng bấm đặt 1 khung giờ cùng ngày, request sau sẽ nhận thông báo khung giờ vừa được người khác đặt trước. |
| **Strategy tính giá theo khung giờ** | Tự động phân loại: Giờ cao điểm (17:00 – 21:00) áp dụng `peakPricePerHour`, các giờ còn lại áp dụng `pricePerHour`. |
| **Quy định hủy sân** | Khách hàng chỉ được phép hủy trước giờ đá tối thiểu `CancelBeforeHours` (mặc định 2 tiếng, lưu trong `SharedPreferences`). Khi hủy: Slot tự động mở lại cho người khác, hoàn tiền `Refunded`, hoàn lượt voucher. |
| **Thanh toán mô phỏng** | Hỗ trợ 3 hình thức: VNPay, Ví MoMo, Tiền mặt. Sau khi thanh toán, đơn tự động xác nhận (`Confirmed`). |
| **Báo cáo doanh thu** | Admin xem tổng doanh thu, lượt đặt, khách hàng, số sân, biểu đồ bảng theo ngày và Top 5 sân doanh thu cao nhất theo khoảng ngày tùy chọn. |

---

## 6. Cấu trúc thư mục dự án (MVVM Pattern)

```text
lib/
├── core/
│   ├── config/              # AppConfig (SharedPreferences) & FirebaseOptions
│   ├── constants/           # Roles (Admin, Staff, Customer), Statuses
│   └── utils/               # Currency VNĐ & Date formatters
├── data/
│   ├── models/              # UserModel, FieldModel, BookingModel, PromotionModel...
│   ├── repositories/        # Auth, Field, Booking, Promotion, User, Report repositories
│   └── services/            # FirebaseService (Auth, Firestore, Messaging)
├── viewmodels/              # Riverpod StateNotifiers (Auth, Field, Booking, Report...)
├── views/
│   ├── auth/                # Login, Register
│   ├── customer/            # Home, FieldDetail, Booking, Payment, History
│   ├── staff/               # StaffBookings, ManageFields, FieldForm
│   ├── admin/               # Reports, UserManagement, PromotionManagement
│   └── shared/              # AppDrawer phân quyền, Dialogs
└── main.dart                # Điểm khởi chạy ứng dụng với ProviderScope & AuthGate
```

---

## 7. Khắc phục sự cố thường gặp (Troubleshooting)

1. **Lỗi `FirebaseApp not initialized` khi vừa mở app:**
   - Nguyên nhân: Chưa điền thông tin thật vào `lib/core/config/firebase_options_local.dart`.
   - Khắc phục: Điền đúng `apiKey`, `appId`, `projectId` lấy từ Firebase Console của bạn.

2. **Lỗi `minSdkVersion` khi build Android:**
   - Đảm bảo trong `android/app/build.gradle.kts`, `minSdk = flutter.minSdkVersion` hoặc tối thiểu `21`.

3. **Lỗi permission denied khi thêm/sửa dữ liệu Firestore:**
   - Kiểm tra tab **Rules** trong Firestore Database trên Firebase Console đã cho phép đọc/ghi với người dùng đã đăng nhập chưa.
