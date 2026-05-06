# 📋 EcoCollect - TODO List

## ✅ Completed

### Phase 1: Foundation (DONE)
- [x] Create `lib/constants/app_constants.dart`
- [x] Create `lib/constants/app_strings.dart`
- [x] Create `lib/utils/error_handler.dart`
- [x] Create `lib/ui/loading_widgets.dart`
- [x] Create `lib/ui/common_widgets.dart`
- [x] Improve `lib/models/user_profile.dart`
- [x] Improve `lib/repositories/user_repository.dart`
- [x] Improve `lib/repositories/order_repository.dart`
- [x] Create documentation files

---

## 🚧 In Progress

### Phase 2: Home Screen Refactoring (HIGH PRIORITY)
- [ ] Backup original `home_screen.dart`
- [ ] Create `screens/home/` folder structure
- [ ] Extract `_HomeDashboard` → `screens/home/home_dashboard.dart`
- [ ] Extract `_HistoryPage` → `screens/home/home_history.dart`
- [ ] Extract `_CollectorPage` → `screens/home/home_collector.dart`
- [ ] Extract `_WalletPage` → `screens/home/home_wallet.dart`
- [ ] Extract `_ProfilePage` → `screens/home/home_profile.dart`
- [ ] Create `screens/home/widgets/` folder
- [ ] Extract `_CallPanel` → `screens/home/widgets/call_panel.dart`
- [ ] Extract `_RadarMap` → `screens/home/widgets/radar_map.dart`
- [ ] Extract `_TopBar` → `screens/home/widgets/top_bar.dart`
- [ ] Extract `_ActiveOrderBanner` → `screens/home/widgets/active_order_banner.dart`
- [ ] Extract `_MarketCard` → `screens/home/widgets/market_card.dart`
- [ ] Extract `_QuickActionsBar` → `screens/home/widgets/quick_actions_bar.dart`
- [ ] Extract `_ImpactStrip` → `screens/home/widgets/impact_strip.dart`
- [ ] Extract `_PaperBankCard` → `screens/home/widgets/paper_bank_card.dart`
- [ ] Extract `_AiScanCard` → `screens/home/widgets/ai_scan_card.dart`
- [ ] Extract `_SortingGuideCard` → `screens/home/widgets/sorting_guide_card.dart`
- [ ] Extract `_StationFinderCard` → `screens/home/widgets/station_finder_card.dart`
- [ ] Extract `_EcoReportCard` → `screens/home/widgets/eco_report_card.dart`
- [ ] Extract `_CollectorMatchCard` → `screens/home/widgets/collector_match_card.dart`
- [ ] Extract `_SchedulePickupCard` → `screens/home/widgets/schedule_pickup_card.dart`
- [ ] Extract `_OrderSheet` → `screens/home/sheets/order_sheet.dart`
- [ ] Extract `_SideNav` → `screens/home/widgets/side_nav.dart`
- [ ] Update imports in main `home_screen.dart`
- [ ] Test all functionality
- [ ] Delete old code after verification

---

## 📅 Planned

### Phase 3: Other Screens Refactoring
- [ ] Refactor `auth_screen.dart`
  - [ ] Use AppStrings
  - [ ] Use AppConstants
  - [ ] Use ErrorHandler
  - [ ] Use EcoLoadingIndicator
- [ ] Refactor `onboarding_screen.dart`
  - [ ] Use AppStrings
  - [ ] Use AppConstants
- [ ] Refactor `scan_screen.dart`
- [ ] Refactor `schedule_pickup_sheet.dart`
- [ ] Refactor `search_collector_sheet.dart`
- [ ] Refactor `create_voucher_sheet.dart`

### Phase 4: Improve Other Models
- [ ] Improve `lib/models/order.dart`
  - [ ] Add const constructor
  - [ ] Add helper methods
  - [ ] Add documentation
- [ ] Improve `lib/models/waste_type.dart`
- [ ] Improve `lib/models/pickup_location.dart`
- [ ] Improve `lib/models/point_transaction.dart`
- [ ] Improve `lib/models/paper_bank_group.dart`
- [ ] Improve `lib/models/voucher.dart`
- [ ] Improve `lib/models/pickup_schedule.dart`

### Phase 5: Improve Other Repositories
- [ ] Improve `lib/repositories/points_repository.dart`
- [ ] Improve `lib/repositories/collector_repository.dart`
- [ ] Improve `lib/repositories/market_price_repository.dart`
- [ ] Improve `lib/repositories/paper_bank_repository.dart`
- [ ] Improve `lib/repositories/pickup_location_repository.dart`
- [ ] Improve `lib/repositories/pickup_schedule_repository.dart`
- [ ] Improve `lib/repositories/stats_repository.dart`
- [ ] Improve `lib/repositories/voucher_repository.dart`
- [ ] Improve `lib/repositories/notification_repository.dart`
- [ ] Improve `lib/repositories/geocoding_repository.dart`

### Phase 6: State Management
- [ ] Choose state management solution (Provider/Riverpod/Bloc)
- [ ] Setup state management
- [ ] Create ViewModels/Controllers for:
  - [ ] HomeViewModel
  - [ ] AuthViewModel
  - [ ] ProfileViewModel
  - [ ] OrderViewModel
  - [ ] WalletViewModel
- [ ] Migrate screens to use ViewModels
- [ ] Remove setState where possible

### Phase 7: Dependency Injection
- [ ] Setup GetIt or Provider for DI
- [ ] Register repositories
- [ ] Register ViewModels
- [ ] Update screens to use DI
- [ ] Remove direct repository instantiation

### Phase 8: Testing
- [ ] Setup test environment
- [ ] Write unit tests for:
  - [ ] ErrorHandler
  - [ ] UserRepository
  - [ ] OrderRepository
  - [ ] PointsRepository
  - [ ] All other repositories
  - [ ] ViewModels (when implemented)
- [ ] Write widget tests for:
  - [ ] EcoLoadingIndicator
  - [ ] EcoErrorWidget
  - [ ] EcoEmptyState
  - [ ] EcoPanel
  - [ ] EcoIconTile
  - [ ] All common widgets
- [ ] Write integration tests for:
  - [ ] Auth flow
  - [ ] Order creation flow
  - [ ] Points redemption flow

### Phase 9: Internationalization (i18n)
- [ ] Setup flutter_localizations
- [ ] Create `l10n/` folder
- [ ] Create `app_en.arb` (English)
- [ ] Create `app_vi.arb` (Vietnamese)
- [ ] Generate localization files
- [ ] Replace AppStrings with generated l10n
- [ ] Test language switching

### Phase 10: Analytics & Monitoring
- [ ] Setup Firebase Analytics
- [ ] Setup Firebase Crashlytics
- [ ] Add analytics events:
  - [ ] Screen views
  - [ ] Button clicks
  - [ ] Order creation
  - [ ] Auth events
  - [ ] Error events
- [ ] Test analytics in debug mode
- [ ] Verify in Firebase Console

### Phase 11: Performance Optimization
- [ ] Profile app performance
- [ ] Optimize images
- [ ] Implement lazy loading
- [ ] Add const constructors everywhere
- [ ] Optimize StreamBuilder usage
- [ ] Implement caching strategy
- [ ] Reduce unnecessary rebuilds
- [ ] Optimize map rendering

### Phase 12: Additional Features
- [ ] Push notifications
  - [ ] Setup FCM
  - [ ] Handle notifications
  - [ ] Show in-app notifications
- [ ] Deep linking
  - [ ] Setup deep links
  - [ ] Handle navigation
- [ ] Offline support
  - [ ] Improve Firestore offline
  - [ ] Add offline indicators
  - [ ] Handle sync conflicts
- [ ] Image optimization
  - [ ] Compress images
  - [ ] Lazy load images
  - [ ] Cache images

### Phase 13: CI/CD
- [ ] Setup GitHub Actions / GitLab CI
- [ ] Automated testing
- [ ] Automated builds
- [ ] Automated deployment
- [ ] Code quality checks
- [ ] Coverage reports

### Phase 14: Documentation
- [ ] API documentation
- [ ] Architecture documentation
- [ ] Setup guide for new developers
- [ ] Deployment guide
- [ ] Troubleshooting guide

---

## 🎯 Quick Wins (Can do anytime)

- [ ] Replace all `const SizedBox(height: X)` with AppConstants
- [ ] Replace all `BorderRadius.circular(X)` with AppConstants
- [ ] Replace all hard-coded strings with AppStrings
- [ ] Add const constructors to all widgets
- [ ] Add documentation comments to public APIs
- [ ] Fix all analyzer warnings
- [ ] Format all code with `dart format`
- [ ] Run `flutter analyze` and fix issues

---

## 📊 Progress Tracking

### Overall Progress: 15% Complete

- ✅ Phase 1: Foundation - 100% (8/8 tasks)
- 🚧 Phase 2: Home Screen - 0% (0/25 tasks)
- ⏳ Phase 3-14: Not started

### Estimated Time Remaining:
- Phase 2: 4-6 hours
- Phase 3: 2-3 hours
- Phase 4-5: 6-8 hours
- Phase 6-7: 8-10 hours
- Phase 8: 8-10 hours
- Phase 9-14: 15-20 hours

**Total: ~45-60 hours of work**

---

## 🏆 Milestones

- [x] **Milestone 1**: Foundation Complete ✅
- [ ] **Milestone 2**: Home Screen Refactored
- [ ] **Milestone 3**: All Screens Refactored
- [ ] **Milestone 4**: State Management Implemented
- [ ] **Milestone 5**: Testing Complete
- [ ] **Milestone 6**: Production Ready

---

## 💡 Notes

- Commit frequently after each completed task
- Test thoroughly before moving to next phase
- Keep documentation updated
- Ask for code review when needed
- Don't rush - quality over speed

---

**Last Updated**: 2026-05-06
