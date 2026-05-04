# EcoCollect

EcoCollect là prototype Flutter cho hệ sinh thái "Đồng nát Online": kết nối người có phế liệu, người thu gom tự do và điểm tập kết/tái chế.

## Tính năng hiện có

- Onboarding 3 bước với animation.
- Trang chủ gọi thu gom, ước tính giá theo loại phế liệu và trọng lượng.
- Radar map mô phỏng người thu gom, tuyến gom và trạm tập kết.
- Bảng giá thị trường, AI scan demo, cẩm nang phân loại.
- Ví Điểm Xanh, đổi thưởng, lịch sử giao dịch.
- Giao diện người thu mua với heatmap, đơn gom và thống kê tuyến.
- PWA metadata cho web deploy.

## Chạy local

```powershell
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

## Build web

```powershell
flutter build web --release
```

Thư mục deploy sau khi build: `build/web`.
