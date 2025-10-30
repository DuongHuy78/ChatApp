
# ChatApp — Hướng dẫn thiết lập sau khi pull dự án

Tài liệu này giúp bạn chạy dự án ngay sau khi clone/pull về máy.

## Mục lục
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Yêu cầu hệ thống](#yêu-cầu-hệ-thống)
- [Thiết lập nhanh](#thiết-lập-nhanh)
  - [Backend (Node.js)](#backend-nodejs)
  - [Client (chat_app)](#client-chat_app)
- [Cách chạy toàn bộ dự án](#cách-chạy-toàn-bộ-dự-án)
- [Cấu hình môi trường (gợi ý)](#cấu-hình-môi-trường-gợi-ý)
- [Khắc phục lỗi thường gặp](#khắc-phục-lỗi-thường-gặp)
- [Liên hệ](#liên-hệ)

---

## Cấu trúc thư mục

```
.
├─ backend/
│  ├─ server.js
│  ├─ package.json
│  ├─ package-lock.json
│  └─ node_modules/ (tự động tạo sau khi cài)
└─ chat_app/
   └─ (mã nguồn ứng dụng client)
```

## Yêu cầu hệ thống

- Git
- Node.js >= 18 và npm >= 8 (cho thư mục `backend`)
- Yêu cầu cho `chat_app`:
  - Nếu là Flutter: Flutter SDK (3.x khuyến nghị), Android Studio/Xcode, thiết bị/giả lập
  - Nếu là React/React Native: Node.js, npm/yarn, (tuỳ công nghệ dùng trong `chat_app`)

> Mẹo: Vào thư mục `chat_app` kiểm tra:
> - Có `pubspec.yaml` → dự án Flutter
> - Có `package.json` → dự án web/mobile (React/React Native)

## Thiết lập nhanh

### Backend (Node.js)
1. Di chuyển vào thư mục backend:
   ```bash
   cd backend
   ```
2. Cài đặt dependencies:
   ```bash
   # Nếu có package-lock.json:
   npm ci
   # Hoặc:
   npm install
   ```
3. Cấu hình biến môi trường (xem phần [Cấu hình môi trường](#cấu-hình-môi-trường-gợi-ý)).
4. Chạy server:
   ```bash
   # Nếu trong package.json có script:
   npm run dev      # hoặc
   npm start
   # Nếu chưa có script, chạy trực tiếp:
   node server.js
   ```
5. Mặc định server sẽ chạy tại:
   ```
   http://localhost:3000
   ```
   (hoặc theo biến `PORT` bạn cấu hình)

### Client (`chat_app`)
Vào thư mục `chat_app` và xác định công nghệ:

- Trường hợp Flutter:
  ```bash
  cd chat_app
  flutter pub get
  # Cập nhật endpoint API trong file cấu hình của app (ví dụ: lib/constants.dart) nếu có
  flutter run
  ```
- Trường hợp React/React Native/Expo:
  ```bash
  cd chat_app
  npm install    # hoặc yarn
  # Cập nhật endpoint API trong file .env hoặc file cấu hình (ví dụ: src/config.ts) nếu có
  npm start      # hoặc npm run android / npm run ios / expo start
  ```

## Cách chạy toàn bộ dự án
1. Khởi động Backend trước (trong thư mục `backend`).
2. Khởi động Client (trong thư mục `chat_app`) sau khi Backend đã chạy.
3. Đảm bảo Client đang trỏ tới đúng API URL (ví dụ: `http://localhost:3000`).

## Cấu hình môi trường (gợi ý)

Trong `backend`, tạo file `.env` (nếu chưa có). Tuỳ nhu cầu dự án, bạn có thể cần một số biến như:
```
PORT=3000
# Ví dụ thêm:
# MONGODB_URI=mongodb://localhost:27017/chatapp
# JWT_SECRET=your-secret
# CLIENT_ORIGIN=http://localhost:5173
```

Trong `chat_app`, cấu hình endpoint API:
- Flutter: thường qua file hằng số (ví dụ `lib/constants.dart`) hoặc `--dart-define`.
- React/React Native: qua `.env` (ví dụ `VITE_API_URL`/`EXPO_PUBLIC_API_URL`) hoặc file cấu hình riêng.

> Lưu ý: Tên biến/thư mục cấu hình có thể khác tuỳ theo cách bạn tổ chức mã nguồn.

## Khắc phục lỗi thường gặp

- Port đã được sử dụng:
  ```bash
  # Đổi PORT trong .env hoặc dừng tiến trình đang chiếm port 3000
  ```
- Sai phiên bản Node:
  - Kiểm tra phiên bản: `node -v`
  - Dùng nvm để chuyển phiên bản phù hợp.
- Lỗi dependency:
  ```bash
  # 1) Xoá thư mục node_modules và cài lại
  rm -rf backend/node_modules
  cd backend && npm ci  # hoặc npm install

  # 2) Xoá cache nếu cần
  npm cache clean --force
  ```
- Client không gọi được API:
  - Kiểm tra URL backend trong cấu hình client.
  - Kiểm tra CORS (nếu backend bật kiểm soát nguồn truy cập).

## Liên hệ

- Maintainer: [DuongHuy78](https://github.com/DuongHuy78)

Nếu bạn gặp vấn đề khi thiết lập, vui lòng tạo issue hoặc liên hệ maintainer.
