import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_strings.dart';

/// Centralized error handling for the app
class ErrorHandler {
  /// Convert Firebase Auth exceptions to user-friendly messages
  static String getAuthErrorMessage(dynamic error) {
    if (error is! FirebaseAuthException) {
      return AppStrings.errorGeneric;
    }

    switch (error.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.errorInvalidCredentials;
      case 'email-already-in-use':
        return AppStrings.errorEmailInUse;
      case 'weak-password':
        return AppStrings.errorWeakPassword;
      case 'invalid-email':
        return AppStrings.validationEmailInvalid;
      case 'user-disabled':
        return 'Tài khoản đã bị vô hiệu hóa.';
      case 'too-many-requests':
        return 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
      case 'operation-not-allowed':
        return 'Phương thức đăng nhập này chưa được kích hoạt.';
      case 'popup-blocked':
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Cửa sổ đăng nhập đã bị đóng.';
      default:
        return '${AppStrings.errorGeneric} (${error.code})';
    }
  }

  /// Convert Firestore exceptions to user-friendly messages
  static String getFirestoreErrorMessage(dynamic error) {
    if (error is! FirebaseException) {
      return AppStrings.errorGeneric;
    }

    switch (error.code) {
      case 'permission-denied':
        return 'Bạn không có quyền truy cập dữ liệu này.';
      case 'unavailable':
        return 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại.';
      case 'not-found':
        return 'Dữ liệu không tồn tại.';
      case 'already-exists':
        return 'Dữ liệu đã tồn tại.';
      case 'resource-exhausted':
        return 'Đã vượt quá giới hạn sử dụng.';
      case 'failed-precondition':
        return 'Điều kiện thực hiện không đúng.';
      case 'aborted':
        return 'Thao tác bị hủy bỏ.';
      case 'out-of-range':
        return 'Giá trị nằm ngoài phạm vi cho phép.';
      case 'unimplemented':
        return 'Tính năng chưa được triển khai.';
      case 'internal':
        return 'Lỗi hệ thống nội bộ.';
      case 'deadline-exceeded':
        return 'Yêu cầu quá thời gian chờ.';
      case 'cancelled':
        return 'Yêu cầu đã bị hủy.';
      default:
        return '${AppStrings.errorGeneric} (${error.code})';
    }
  }

  /// Generic error message extractor
  static String getErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return error?.toString() ?? AppStrings.errorGeneric;
    }
  }

  /// Log error for debugging (can be extended to use logging service)
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    // TODO: Integrate with logging service (e.g., Firebase Crashlytics, Sentry)
    print('❌ Error: $error');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }
}
