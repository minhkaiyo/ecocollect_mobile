/// App-wide string constants
/// TODO: Replace with proper i18n solution (flutter_localizations)
abstract final class AppStrings {
  // App
  static const String appName = 'EcoCollect';
  static const String appTagline = 'Đồng nát Online';
  static const String appDescription =
      'Ngân hàng rác thải số kết nối hộ gia đình, người thu gom và trạm tái chế trong một quy trình sạch, minh bạch.';

  // Navigation
  static const String navHome = 'Trang chủ';
  static const String navHistory = 'Lịch sử';
  static const String navCollector = 'Thu mua';
  static const String navWallet = 'Ví Xanh';
  static const String navSettings = 'Cài đặt';

  // Home Screen
  static const String homeTitle = 'Dọn rác thông minh - Tích lũy sống xanh';
  static const String homeSubtitle =
      'Nhập địa chỉ, chọn nhóm phế liệu và phát tín hiệu để hệ thống ghép người thu gom hoặc trạm tập kết gần nhất.';
  static const String homeAddressLabel = 'Địa chỉ';
  static const String homeAddressHint = 'Ví dụ: Số 12 Chùa Bộc, Hà Nội';
  static const String homeWasteTypeLabel = 'Loại phế liệu';
  static const String homeWeightLabel = 'Trọng lượng ước tính';
  static const String homeEstimateLabel = 'Tạm tính';
  static const String homeCreateOrderButton = 'PHÁT TÍN HIỆU THU GOM';
  static const String homeRadarTitle = 'Radar Tìm Người Thu Gom';
  static const String homeRadarLive = 'Live';
  static const String homeRadarLocating = 'Đang định vị vệ tinh...';

  // Search
  static const String searchHint = 'Giá thị trường, trạm tập kết, cẩm nang phân loại';
  static const String searchMobileHint = 'Giá, trạm, cẩm nang phân loại…';
  static const String searchButton = 'Tìm kiếm';
  static const String searchEmptyQuery = 'Nhập từ khóa để tìm giá, trạm hoặc cẩm nang phân loại.';
  static const String searchResultsTitle = 'Kết quả tìm kiếm';

  // Notifications
  static const String notificationsTitle = 'Thông báo của bạn';
  static const String notificationsClose = 'Đóng';

  // Points
  static const String pointsLabel = 'Điểm';
  static const String pointsHistoryTitle = 'Lịch sử điểm';
  static const String pointsCurrentBalance = 'Số dư hiện tại';
  static const String pointsNoTransactions = 'Chưa có giao dịch điểm nào.';
  static const String pointsWalletOpened = 'Đã mở Ví Điểm Xanh.';

  // Orders
  static const String orderCreatedSuccess = 'Đã phát tín hiệu lên Firebase. Hệ thống đang ghép người thu gom.';
  static const String orderCreatedError = 'Lỗi gửi đơn';
  static const String orderTrackingTitle = 'Theo dõi đơn';
  static const String orderStatusLabel = 'Trạng thái';
  static const String orderTypeLabel = 'Loại';
  static const String orderChatInfo = 'Chat trong app sẽ mở khi đơn được ghép.';
  static const String orderCancelButton = 'Hủy đơn';
  static const String orderNoActive = 'Chưa có đơn đang chạy. Hãy phát tín hiệu thu gom từ trang chủ.';
  static const String orderActiveTitle = 'Đang xử lý tín hiệu thu gom';
  static const String orderActiveTracking = 'Theo dõi';

  // Market
  static const String marketTitle = 'Giá thị trường hôm nay';
  static const String marketPriceRange = 'Biên độ giá hôm nay';
  static const String marketEstimate = 'Ước tính nhanh';

  // Paper Bank
  static const String paperBankTitle = 'Ngân hàng giấy';

  // AI Scan
  static const String aiScanTitle = 'AI scan phế liệu';

  // Sorting Guide
  static const String sortingGuideTitle = 'Cẩm nang phân loại';

  // Stations
  static const String stationsTitle = 'Trạm tập kết gần bạn';
  static const String stationsMapLabel = 'Trạm tập kết';

  // Eco Report
  static const String ecoReportTitle = 'Báo cáo tác động';
  static const String ecoReportExportButton = 'Xuất PDF demo';
  static const String ecoReportExported = 'Đã xuất file PDF demo (bản xem trước).';

  // Schedule
  static const String scheduleTitle = 'Đặt lịch gom định kỳ';
  static const String scheduleCreated = 'Đã tạo lịch gom định kỳ vào sáng thứ 7.';
  static const String scheduleCreateButton = 'Tạo lịch demo';

  // Profile
  static const String profileSaveSuccess = 'Đã lưu thay đổi (demo).';

  // Auth
  static const String authWelcomeBack = 'Chào mừng trở lại!';
  static const String authGetStarted = 'Bắt đầu sống xanh';
  static const String authLoginSubtitle = 'Đăng nhập để quản lý đơn gom và ví Eco.';
  static const String authRegisterSubtitle = 'Đăng ký tài khoản để bắt đầu đổi rác lấy quà.';
  static const String authGoogleButton = 'Tiếp tục với Google';
  static const String authOrDivider = 'hoặc';
  static const String authEmailLabel = 'Email';
  static const String authEmailHint = 'ví dụ: nam@gmail.com';
  static const String authPasswordLabel = 'Mật khẩu';
  static const String authForgotPassword = 'Quên mật khẩu?';
  static const String authLoginButton = 'Đăng nhập';
  static const String authRegisterButton = 'Đăng ký';
  static const String authNoAccount = 'Chưa có tài khoản? ';
  static const String authHasAccount = 'Đã có tài khoản? ';
  static const String authRegisterNow = 'Đăng ký ngay';
  static const String authLoginNow = 'Đăng nhập';

  // Validation
  static const String validationEmailRequired = 'Vui lòng nhập email.';
  static const String validationEmailInvalid = 'Email không hợp lệ.';
  static const String validationPasswordRequired = 'Vui lòng nhập mật khẩu.';
  static const String validationPasswordTooShort = 'Mật khẩu phải có ít nhất 6 ký tự.';

  // Errors
  static const String errorGeneric = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  static const String errorInvalidCredentials = 'Email hoặc mật khẩu không chính xác.';
  static const String errorEmailInUse = 'Email này đã được đăng ký.';
  static const String errorWeakPassword = 'Mật khẩu quá yếu (cần tối thiểu 6 ký tự).';
  static const String errorLoadingData = 'Lỗi tải dữ liệu';
  static const String errorNoData = 'Không có dữ liệu';

  // Success
  static const String successLoginComplete = 'Đăng nhập thành công. Đang chuyển vào trang chính...';
  static const String successRegisterComplete = 'Đăng ký thành công. Đang đăng nhập...';
  static const String successGoogleLogin = 'Đăng nhập Google thành công. Đang chuyển vào trang chính...';

  // Loading
  static const String loadingPleaseWait = 'Đang tải...';
  static const String loadingUser = 'Đang tải thông tin người dùng...';

  // Onboarding
  static const String onboardingSkip = 'Bỏ qua';
  static const String onboardingStart = 'Bắt đầu';
  static const String onboardingTitle1 = 'Phân loại thông minh';
  static const String onboardingDesc1 =
      'Sử dụng AI để nhận diện và phân loại phế liệu chính xác. Tăng giá trị cho rác thải của bạn.';
  static const String onboardingTitle2 = 'Gọi thu gom tức thì';
  static const String onboardingDesc2 =
      'Phát tín hiệu Radar để kết nối với người thu gom gần nhất trong khu vực của bạn.';
  static const String onboardingTitle3 = 'Tích lũy Điểm Xanh';
  static const String onboardingDesc3 =
      'Mỗi kg rác thải được thu hồi sẽ đổi lại Điểm Xanh để nhận voucher và quà tặng hấp dẫn.';

  // Units
  static const String unitKg = 'kg';
  static const String unitVnd = 'đ';
  static const String unitVndPerKg = 'VND/kg';
  static const String unitKm = 'km';
}
