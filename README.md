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
1. Trong menu bên trái, chọn **Build** > **Authentication** > bấm **Get Started**.
2. Tại tab **Sign-in method**, bấm vào **Email/Password**.
3. Bật công tắc **Enable** ở dòng đầu tiên (Email/Password), sau đó bấm **Save**.

### Bước 2.3: Kích hoạt Cloud Firestore Database
1. Trong menu bên trái, chọn **Build** > **Firestore Database** > bấm **Create database**.
2. Chọn vị trí máy chủ (Location) gần nhất (khuyên dùng `asia-southeast1` hoặc `asia-east1`).
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

### Bước 2.4: Đăng ký App trên Firebase và tạo file `firebase_options_local.dart`

> [!IMPORTANT]
> **Quy tắc bắt buộc về App Config trên Firebase:**
> - **KHÔNG DÙNG CHUNG CẤU HÌNH** giữa các nền tảng (Android, Web, iOS).
> - Mặc dù `projectId` và `messagingSenderId` giống nhau, nhưng mỗi nền tảng có một **`appId` riêng biệt** gắn với định danh hệ thống (Package Name trên Android, Bundle ID trên iOS).
> - Nếu lấy cấu hình của Web điền cho Android, **Firebase Auth và Notification (FCM) sẽ bị lỗi xác thực**.
> - Do file `firebase_options_local.dart` chứa các mã định danh bảo mật nên đã được đưa vào `.gitignore` (không đẩy lên GitHub). Người clone dự án về máy cần tạo file này để ứng dụng chạy ổn định.

---

#### Cách 1: Đăng ký thủ công từng App (Khuyên dùng nếu chỉ chạy 1-2 platform)

##### 1. Đăng ký App Android (bắt buộc nếu chạy trên máy ảo Android / điện thoại thật):
- Trong Firebase Console, bấm **Add app** (hoặc biểu tượng **Android**).
- **Android package name**: Điền chính xác `com.example.sportsbook_36vn` (khớp với file `android/app/build.gradle.kts`).
- Bấm **Register app**.
- Tải file `google-services.json` (nếu có) bỏ vào thư mục `android/app/` của dự án.
- Lấy giá trị `appId` (có dạng `1:xxxx:android:yyyy`) và `apiKey`.

##### 2. Đăng ký App Web (nếu muốn chạy thử trên trình duyệt Chrome):
- Trong Firebase Console, bấm **Add app** > chọn biểu tượng **Web** `</>`.
- Đặt tên app: `sportsbook_36vn` > Bấm **Register app**.
- Firebase hiển thị `firebaseConfig` gồm: `apiKey`, `appId` (có dạng `1:xxxx:web:yyyy`), `authDomain`, `storageBucket`.

##### 3. Đăng ký App iOS (nếu bạn chạy trên macOS / iPhone):
- Bấm **Add app** > chọn biểu tượng **iOS**.
- **Apple bundle ID**: Điền `com.example.sportsbook36vn`.
- Lấy `appId` (có dạng `1:xxxx:ios:yyyy`).

##### 4. Tạo và điền file `firebase_options_local.dart`:
- Sao chép từ file mẫu có sẵn trong thư mục dự án:
  ```bash
  cp lib/core/config/firebase_options_sample.dart lib/core/config/firebase_options_local.dart
  ```
- Mở file `lib/core/config/firebase_options_local.dart`:
  - Đổi tên class thành `LocalFirebaseOptions`.
  - Điền đúng các thông số riêng biệt của từng app bạn vừa đăng ký ở trên vào các khối tương ứng:
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
      appId: '1:1234567890:web:abcdef',
      messagingSenderId: '1234567890',
      projectId: 'sportsbook-36vn',
      authDomain: 'sportsbook-36vn.firebaseapp.com',
      storageBucket: 'sportsbook-36vn.appspot.com',
    );

    // Cấu hình từ App Android (Package: com.example.sportsbook_36vn)
    static const FirebaseOptions android = FirebaseOptions(
      apiKey: 'AIzaSy...-ANDROID',
      appId: '1:1234567890:android:abcdef',
      messagingSenderId: '1234567890',
      projectId: 'sportsbook-36vn',
      storageBucket: 'sportsbook-36vn.appspot.com',
    );

    // Cấu hình từ App iOS (Bundle ID: com.example.sportsbook36vn)
    static const FirebaseOptions ios = FirebaseOptions(
      apiKey: 'AIzaSy...-IOS',
      appId: '1:1234567890:ios:abcdef',
      messagingSenderId: '1234567890',
      projectId: 'sportsbook-36vn',
      storageBucket: 'sportsbook-36vn.appspot.com',
      iosBundleId: 'com.example.sportsbook36vn',
    );
  }
  ```

*(Ghi chú: Nếu bạn chỉ chạy trên Android, bạn chỉ cần tạo App Android và điền đúng khối `android`, các khối Web/iOS có thể để tạm giá trị mẫu).*

---

#### Cách 2: Tự động đăng ký toàn bộ App bằng FlutterFire CLI (Khuyên dùng)
Nếu máy bạn đã cài `firebase-cli` và `flutterfire_cli`, công cụ này sẽ tự động đăng ký cả Android, iOS, Web trên Firebase Console và tạo cấu hình chuẩn xác chỉ trong một lệnh:
```bash
flutterfire configure
```
Sau đó bạn chỉ cần sao chép nội dung file sinh ra vào `lib/core/config/firebase_options_local.dart`.

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

## 4. Hướng dẫn khởi tạo tài khoản & Dữ liệu mẫu ban đầu

Hệ thống phân chia 3 vai trò: **Customer**, **Staff** (chủ sân) và **Admin** (quản trị viên).

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
