# 🚀 EcoCollect - Quick Reference

> Cheat sheet cho code mới - Copy & paste friendly!

---

## 📁 Files Mới

```
lib/
├── constants/
│   ├── app_constants.dart      # Spacing, sizing, config
│   └── app_strings.dart        # All UI strings
├── ui/
│   ├── loading_widgets.dart    # Loading/Error/Empty
│   └── common_widgets.dart     # Reusable widgets
└── utils/
    └── error_handler.dart      # Error handling
```

---

## 🎨 Constants

### Spacing
```dart
AppConstants.spacingXs    // 4
AppConstants.spacingS     // 8
AppConstants.spacingM     // 12
AppConstants.spacingL     // 16
AppConstants.spacingXl    // 18
AppConstants.spacingXxl   // 24
AppConstants.spacing3xl   // 32
AppConstants.spacing4xl   // 48
```

### Border Radius
```dart
AppConstants.radiusS      // 12
AppConstants.radiusM      // 14
AppConstants.radiusL      // 16
AppConstants.radiusXl     // 18
AppConstants.radiusXxl    // 20
AppConstants.radius3xl    // 22
AppConstants.radius4xl    // 24
AppConstants.radius5xl    // 28
```

### Padding
```dart
AppConstants.paddingL              // EdgeInsets.all(16)
AppConstants.paddingXl             // EdgeInsets.all(18)
AppConstants.paddingHorizontalL    // EdgeInsets.symmetric(horizontal: 16)
```

---

## 📝 Strings

```dart
// Navigation
AppStrings.navHome
AppStrings.navHistory
AppStrings.navCollector
AppStrings.navWallet
AppStrings.navSettings

// Common
AppStrings.loadingPleaseWait
AppStrings.errorGeneric
AppStrings.successLoginComplete

// See app_strings.dart for full list
```

---

## 🔧 Error Handling

```dart
try {
  await someOperation();
} catch (e, stackTrace) {
  ErrorHandler.logError(e, stackTrace);
  final message = ErrorHandler.getErrorMessage(e);
  showEcoSnackBar(context, message);
}
```

---

## 🎯 Loading States

### StreamBuilder
```dart
EcoStreamBuilder<Data>(
  stream: repository.watchData(),
  builder: (context, data) => DataWidget(data),
)
```

### FutureBuilder
```dart
EcoFutureBuilder<Data>(
  future: repository.fetchData(),
  builder: (context, data) => DataWidget(data),
)
```

### Manual Loading
```dart
EcoLoadingIndicator(message: 'Loading...')
```

### Error Widget
```dart
EcoErrorWidget(
  message: 'Error message',
  onRetry: () => setState(() {}),
)
```

### Empty State
```dart
EcoEmptyState(
  message: 'No items found',
  icon: Icons.inbox_outlined,
)
```

---

## 🎨 Common Widgets

### Panel
```dart
EcoPanel(
  child: YourContent(),
)
```

### Icon Tile
```dart
EcoIconTile(
  icon: Icons.eco_rounded,
  color: EcoColors.primary,
)
```

### Section Header
```dart
EcoSectionHeader(
  title: 'Title',
  subtitle: 'Optional subtitle',
  live: true,  // Shows live indicator
)
```

### Info Line
```dart
EcoInfoLine(
  icon: Icons.check_circle,
  text: 'Some information',
)
```

### Icon Badge
```dart
EcoIconBadge(
  icon: Icons.notifications,
  badge: '3',
)
```

### Mini Logo
```dart
EcoMiniLogo(compact: false)
```

### Map Pill
```dart
EcoMapPill(
  icon: Icons.place,
  text: 'Station',
  color: EcoColors.primary,
)
```

### Live Pulse
```dart
EcoLivePulse(active: true)
```

---

## 🔄 Migration Patterns

### Replace Magic Numbers
```dart
// ❌ Before
const SizedBox(height: 18)
const EdgeInsets.all(16)
BorderRadius.circular(22)

// ✅ After
const SizedBox(height: AppConstants.spacingXl)
AppConstants.paddingL
BorderRadius.circular(AppConstants.radius3xl)
```

### Replace Strings
```dart
// ❌ Before
Text('Trang chủ')

// ✅ After
Text(AppStrings.navHome)
```

### Replace StreamBuilder
```dart
// ❌ Before (35 lines)
StreamBuilder<Data>(
  stream: stream,
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
    return DataWidget(snapshot.data!);
  },
)

// ✅ After (3 lines)
EcoStreamBuilder<Data>(
  stream: stream,
  builder: (context, data) => DataWidget(data),
)
```

### Replace Container
```dart
// ❌ Before (15 lines)
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

// ✅ After (1 line)
EcoPanel(child: content)
```

---

## 🎯 Common Use Cases

### Show Loading
```dart
EcoLoadingIndicator(message: AppStrings.loadingPleaseWait)
```

### Show Error
```dart
EcoErrorWidget(
  message: ErrorHandler.getErrorMessage(error),
  onRetry: _retry,
)
```

### Show Toast
```dart
showEcoSnackBar(
  context,
  AppStrings.orderCreatedSuccess,
  icon: Icons.check_circle,
)
```

### Handle Repository Error
```dart
try {
  await repository.createOrder(data);
  showEcoSnackBar(context, AppStrings.orderCreatedSuccess);
} catch (e) {
  showEcoSnackBar(
    context,
    ErrorHandler.getErrorMessage(e),
    icon: Icons.error_outline,
  );
}
```

### Watch Stream with Loading
```dart
EcoStreamBuilder<List<Order>>(
  stream: repository.watchOrders(userId),
  builder: (context, orders) {
    if (orders.isEmpty) {
      return EcoEmptyState(
        message: 'No orders yet',
        icon: Icons.shopping_bag_outlined,
      );
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) => OrderCard(orders[index]),
    );
  },
)
```

---

## 📚 Full Documentation

- **[README_REFACTORING.md](./README_REFACTORING.md)** - Start here
- **[REFACTORING_SUMMARY.md](./REFACTORING_SUMMARY.md)** - Overview
- **[IMPROVEMENTS_GUIDE.md](./IMPROVEMENTS_GUIDE.md)** - Detailed guide
- **[TODO.md](./TODO.md)** - Task list

---

## 💡 Pro Tips

1. Use Find & Replace for quick migration
2. Always use const constructors
3. Always handle errors properly
4. Always show loading states
5. Always use AppConstants and AppStrings
6. Commit frequently
7. Test after each change

---

**Happy Coding! 🎉**
