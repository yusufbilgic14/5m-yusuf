import 'package:flutter/material.dart';
import '../services/firebase_auth_service.dart';

/// Uygulama genelinde kullanılan sabitler / App-wide constants
class AppConstants {
  // Ana renk referansları (AppThemes'de tanımlı) / Main color references (defined in AppThemes)
  static const Color primaryColor = Color(0xFF000000);

  /// Tema-aware ikon rengi / Theme-aware icon color
  static Color getIconColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Colors.white : primaryColor;
  }

  // Geriye uyumluluk için text color constants / Text color constants for backward compatibility
  static const Color textColorLight = Colors.white;
  static const Color textColorDark = Colors.black87;

  // Boyutlar / Dimensions
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 20.0;
  static const double paddingXLarge = 24.0;

  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  static const double bottomNavHeight = 60.0;
  static const double appBarHeight = 56.0;

  // Font boyutları / Font sizes
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 18.0;
  static const double fontSizeXXLarge = 24.0;

  // Animasyon süreleri / Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Kullanıcı bilgileri / User info
  static String get userName {
    final firebaseAuthService = FirebaseAuthService();
    return firebaseAuthService.currentAppUser?.displayName ?? 'Elif Yılmaz';
  }

  static const String userRole = 'Öğrenci';
  static const String userDepartment = 'Yönetim Bilişim Sistemleri';
  static const String userGrade = '3. Sınıf';
  static const String userStudentId = '2022520145';
  static const String userPhotoPath = 'assets/images/elifyılmaz.png';
  static const String logoPath = 'assets/images/medipol_logo.png';

  // Navigasyon indeksleri / Navigation indices
  static const int navIndexNavigation = 0;
  static const int navIndexCalendar = 1;
  static const int navIndexHome = 2;
  static const int navIndexScan = 3;
  static const int navIndexProfile = 4;
}

/// Bildirim türleri enum'u / Notification types enum
enum NotificationType {
  email('email'),
  grade('grade'),
  reminder('reminder'),
  assignment('assignment'),
  scholarship('scholarship'),
  announcement('announcement');

  const NotificationType(this.value);
  final String value;
}

/// Navigasyon sayfaları enum'u / Navigation pages enum
enum NavigationPage {
  navigation(0),
  calendar(1),
  home(2),
  scan(3),
  profile(4);

  const NavigationPage(this.navIndex);
  final int navIndex;
}

/// QR kod türleri enum'u / QR code types enum
enum QRCodeType {
  access('MEDIPOL_ACCESS'),
  payment('MEDIPOL_PAYMENT'),
  attendance('MEDIPOL_ATTENDANCE');

  const QRCodeType(this.prefix);
  final String prefix;
}

/// Uygulama mesajları / App messages
class AppMessages {
  static const String loading = 'Yükleniyor...';
  static const String error = 'Bir hata oluştu';
  static const String success = 'İşlem başarılı';
  static const String networkError = 'İnternet bağlantısı hatası';
  static const String permissionDenied = 'İzin reddedildi';
  static const String cameraError = 'Kamera erişim hatası';
  static const String qrRefreshed = 'QR kod yenilendi';
  static const String feedbackSubmitted =
      'Geri bildiriminiz başarıyla gönderildi! Teşekkür ederiz.';
}

/// Gölge stilleri / Shadow styles
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      offset: const Offset(0, 2),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  static List<BoxShadow> get bottomNav => [
    BoxShadow(
      color: Colors.grey.withValues(alpha: 0.2),
      spreadRadius: 0,
      blurRadius: 10,
      offset: const Offset(0, -2),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      offset: const Offset(0, 4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];
}
