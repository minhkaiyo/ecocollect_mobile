# EcoCollect - Hướng Dẫn Sử Dụng Code Đã Cải Thiện

## 📚 Tổng Quan

Dự án đã được refactor để cải thiện:
- ✅ **Maintainability** - Dễ bảo trì
- ✅ **Scalability** - Dễ mở rộng
- ✅ **Testability** - Dễ test
- ✅ **Performance** - Hiệu suất tốt hơn
- ✅ **Developer Experience** - Trải nghiệm dev tốt hơn

## 🗂️ Cấu Trúc Mới

```
lib/
├── constants/
│   ├── app_constants.dart      # Tất cả magic numbers, spacing, sizing
│   ├── app_strings.dart        # Tất cả strings (i18n ready)
│   ├── onboarding_contents.dart
│   └── size_config.dart
├── models/
│   └── user_profile.dart       # ✨ Đã cải thiện với helpers
├── repositories/
│   ├── user_repository.dart    # ✨ Đã thêm error handling
│   ├── order_repository.dart   # ✨ Đã thêm error handling
│   └── ...
├── ui/
│   ├── app_feedback.dart
│   ├── loading_widgets.dart    # ✨ MỚI - Loading, error, empty states
│   └── common_widgets.dart     # ✨ MỚI - Reusable widgets
├── utils/
│   └── error_handler.dart      # ✨ MỚI - Centralized error handling
└── screens/
    └── ...
```

## 🎯 Cách Sử Dụng

### 1. Constants

#### Spacing & Sizing
```dart
// ❌ TRƯỚC
const SizedBox(height: 18);
const EdgeInsets.all(16);
BorderRadius.circular(22);

// ✅ SAU
const SizedBox(height: AppConstants.spacingXl);
AppConstants.paddingL
BorderRadius.circular(AppConstants.radius3xl);
```

#### Strings
```dart
// ❌ TRƯỚC
Text('Trang chủ');
Text('Đăng nhập thành công');

// ✅ SAU
Text(AppStrings.navHome);
Text(AppStrings.successLoginComplete);
```

#### Breakpoints
```dart
// ❌ TRƯỚC
final isWide = constraints.maxWidth >= 1200;

// ✅ SAU
final isWide = constraints.maxWidth >= AppConstants.breakpointWide;
```

### 2. Error Handling

#### Trong Repository
```dart
// ❌ TRƯỚC
Future<void> createOrder(Map<String, dynamic> data) async {
  try {
    await _collection.doc(id).set(data);
  } catch (e) {
    throw Exception('Lỗi: $e');
  }
}

// ✅ SAU
Future<void> createOrder(Map<String, dynamic> data) async {
  try {
    await _collection.doc(id).set(data);
  } catch (e, stackTrace) {
    ErrorHandler.logError(e, stackTrace);
    throw Exception('Không thể tạo đơn: ${ErrorHandler.getErrorMessage(e)}');
  }
}
```

#### Trong UI
```dart
// ❌ TRƯỚC
try {
  await repository.createOrder(data);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Thành công')),
  );
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Lỗi: $e')),
  );
}

// ✅ SAU
try {
  await repository.createOrder(data);
  showEcoSnackBar(context, AppStrings.orderCreatedSuccess);
} catch (e) {
  final message = ErrorHandler.getErrorMessage(e);
  showEcoSnackBar(context, message, icon: Icons.error_outline_rounded);
}
```

### 3. Loading & Error States

#### StreamBuilder
```dart
// ❌ TRƯỚC
StreamBuilder<UserProfile>(
  stream: repository.watchProfile(uid),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error: ${snapshot.error}');
    }
    if (!snapshot.hasData) {
      return Text('No data');
    }
    return ProfileWidget(snapshot.data!);
  },
)

// ✅ SAU
EcoStreamBuilder<UserProfile>(
  stream: repository.watchProfile(uid),
  builder: (context, profile) => ProfileWidget(profile),
  loadingWidget: EcoLoadingIndicator(message: AppStrings.loadingUser),
  errorBuilder: (context, error) => EcoErrorWidget(
    message: ErrorHandler.getErrorMessage(error),
    onRetry: () => setState(() {}),
  ),
)
```

#### FutureBuilder
```dart
// ❌ TRƯỚC
FutureBuilder<Data>(
  future: fetchData(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return CircularProgressIndicator();
    }
    if (snapshot.hasError) {
      return Text('Error');
    }
    return DataWidget(snapshot.data!);
  },
)

// ✅ SAU
EcoFutureBuilder<Data>(
  future: fetchData(),
  builder: (context, data) => DataWidget(data),
)
```

### 4. Reusable Widgets

#### Panel
```dart
// ❌ TRƯỚC
Container(
  padding: EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(22),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 16,
        offset: Offset(0, 4),
      ),
    ],
  ),
  child: content,
)

// ✅ SAU
EcoPanel(child: content)
```

#### Icon Tile
```dart
// ❌ TRƯỚC
Container(
  width: 40,
  height: 40,
  decoration: BoxDecoration(
    color: color.withOpacity(0.12),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Icon(icon, color: color, size: 20),
)

// ✅ SAU
EcoIconTile(icon: icon, color: color)
```

#### Section Header
```dart
// ❌ TRƯỚC
Row(
  children: [
    Text(
      'Giá thị trường hôm nay',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
    ),
    Spacer(),
    Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: EcoColors.success,
        shape: BoxShape.circle,
      ),
    ),
    SizedBox(width: 6),
    Text('Live'),
  ],
)

// ✅ SAU
EcoSectionHeader(
  title: AppStrings.marketTitle,
  live: true,
)
```

#### Info Line
```dart
// ❌ TRƯỚC
Row(
  children: [
    Icon(Icons.check_circle, color: EcoColors.primary),
    SizedBox(width: 12),
    Expanded(child: Text('Some info text')),
  ],
)

// ✅ SAU
EcoInfoLine(
  icon: Icons.check_circle,
  text: 'Some info text',
)
```

### 5. Model Improvements

#### UserProfile Helpers
```dart
// ❌ TRƯỚC
if (user.role == 'collector') {
  // do something
}
Text('${user.greenPoints} Điểm');

// ✅ SAU
if (user.isCollector) {
  // do something
}
Text(user.pointsDisplay);
```

## 🔧 Migration Checklist

Khi refactor code cũ, làm theo thứ tự:

1. ✅ Replace magic numbers với `AppConstants`
2. ✅ Replace hard-coded strings với `AppStrings`
3. ✅ Wrap StreamBuilder/FutureBuilder với `EcoStreamBuilder`/`EcoFutureBuilder`
4. ✅ Replace custom containers với `EcoPanel`, `EcoIconTile`, etc.
5. ✅ Add proper error handling với `ErrorHandler`
6. ✅ Use `showEcoSnackBar` thay vì `ScaffoldMessenger`
7. ✅ Add loading states với `EcoLoadingIndicator`
8. ✅ Add error states với `EcoErrorWidget`
9. ✅ Add empty states với `EcoEmptyState`

## 📊 Benefits

### Before
```dart
// 50+ dòng code
Container(
  padding: EdgeInsets.all(18),
  decoration: BoxDecoration(...),
  child: Column(
    children: [
      Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(...),
            child: Icon(...),
          ),
          SizedBox(width: 12),
          Text('Title', style: TextStyle(fontSize: 22, ...)),
        ],
      ),
      SizedBox(height: 16),
      StreamBuilder<Data>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          return DataWidget(snapshot.data!);
        },
      ),
    ],
  ),
)
```

### After
```dart
// 10 dòng code - rõ ràng, dễ đọc
EcoPanel(
  child: Column(
    children: [
      EcoSectionHeader(title: AppStrings.title),
      const SizedBox(height: AppConstants.spacingL),
      EcoStreamBuilder<Data>(
        stream: stream,
        builder: (context, data) => DataWidget(data),
      ),
    ],
  ),
)
```

## 🎨 Best Practices

1. **Luôn sử dụng constants** - Không hard-code values
2. **Luôn handle errors** - Sử dụng ErrorHandler
3. **Luôn show loading states** - Sử dụng EcoLoadingIndicator
4. **Luôn log errors** - ErrorHandler.logError(e, stackTrace)
5. **Luôn sử dụng const** - Khi có thể để tối ưu performance
6. **Tái sử dụng widgets** - Không duplicate code
7. **Document code** - Thêm comments cho functions phức tạp

## 🚀 Next Steps

1. Refactor `home_screen.dart` (3987 dòng → nhiều files nhỏ)
2. Implement state management (Provider/Riverpod)
3. Add dependency injection (GetIt)
4. Write unit tests
5. Write widget tests
6. Implement proper i18n
7. Add analytics
8. Performance optimization

## 📞 Support

Nếu có câu hỏi về code mới, tham khảo:
- `REFACTORING_PROGRESS.md` - Tiến độ refactoring
- Code comments trong các file mới
- Examples trong file này

---

**Happy Coding! 🎉**
