import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Uygulama tema konfigürasyonları / App theme configurations
class AppThemes {
  // Ana renkler / Primary colors (tema bağımsız / theme independent)
  static const Color primaryNavy = Color(0xFF000000);
  static const Color primaryGold = Color(0xFFDDB822);

  /// Açık tema / Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Ana renk şeması / Primary color scheme
      colorScheme: const ColorScheme.light(
        primary: primaryNavy,
        onPrimary: primaryGold,
        secondary: primaryGold,
        onSecondary: primaryNavy,
        surface: Colors.white,
        onSurface: Colors.black87,
        error: Colors.red,
        onError: Colors.white,
      ),

      // AppBar teması / AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: primaryGold,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: AppConstants.fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: primaryGold,
        ),
      ),

      // Bottom navigation teması / Bottom navigation theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryGold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Koyu tema / Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Ana renk şeması / Primary color scheme
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        onPrimary: primaryNavy,
        secondary: primaryGold,
        onSecondary: primaryNavy,
        surface: Color(0xFF1E293B),
        onSurface: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
      ),

      // AppBar teması / AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: primaryGold,
        elevation: 0,
        titleTextStyle: TextStyle(
          fontSize: AppConstants.fontSizeXLarge,
          fontWeight: FontWeight.w600,
          color: primaryGold,
        ),
      ),

      // Bottom navigation teması / Bottom navigation theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E293B),
        selectedItemColor: primaryGold,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  /// Tema-aware renk alıcıları / Theme-aware color getters
  static Color getPrimaryColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getSurfaceColor(BuildContext context) {
    return Theme.of(context).colorScheme.surface;
  }

  static Color getTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSurface;
  }

  static Color getSecondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? Colors.grey[600]!
        : Colors.grey[400]!;
  }

  /// Gölge stilleri artık AppShadows'tan alınıyor / Shadow styles now come from AppShadows
  static List<BoxShadow> getCardShadow(BuildContext context) {
    return Theme.of(context).brightness == Brightness.light
        ? AppShadows.card
        : AppShadows.elevated;
  }

  /// Semantik renk paleti / Semantic color palette
  /// Tema-aware renkler - koyu/açık temaya göre otomatik ayarlanır
  /// Theme-aware colors - automatically adjusted for dark/light theme
  static const Map<String, Color> _lightSemanticColors = {
    // Not renkleri / Grade colors (Açık tema için optimized)
    'gradeExcellent': Color(0xFF10B981), // AA - Yeşil
    'gradeGood': Color(0xFF3B82F6), // BB - Mavi
    'gradeAverage': Color(0xFFF59E0B), // CC - Turuncu
    'gradePoor': Color(0xFFEF4444), // DD/FF - Kırmızı
    // Etkinlik türü renkleri / Event type colors
    'eventRegistration': Color(0xFF3B82F6), // Kayıt
    'eventEvaluation': Color(0xFF8B5CF6), // Değerlendirme
    'eventAnnouncement': Color(0xFF10B981), // Duyuru
    'eventExam': Color(0xFFEF4444), // Sınav
    'eventSemester': Color(0xFF6366F1), // Dönem
    'eventCourseSelection': Color(0xFFF59E0B), // Ders Seçimi
    // Genel UI renkleri / General UI colors
    'success': Color(0xFF10B981),
    'warning': Color(0xFFF59E0B),
    'error': Color(0xFFEF4444),
    'info': Color(0xFF3B82F6),
    'neutral': Color(0xFF6B7280),
  };

  static const Map<String, Color> _darkSemanticColors = {
    // Not renkleri / Grade colors (Koyu tema için optimized)
    'gradeExcellent': Color(0xFF34D399), // AA - Daha parlak yeşil
    'gradeGood': Color(0xFF60A5FA), // BB - Daha parlak mavi
    'gradeAverage': Color(0xFFFBBF24), // CC - Daha parlak turuncu
    'gradePoor': Color(0xFFF87171), // DD/FF - Daha parlak kırmızı
    // Etkinlik türü renkleri / Event type colors (Koyu tema için optimized)
    'eventRegistration': Color(0xFF60A5FA), // Kayıt
    'eventEvaluation': Color(0xFFA78BFA), // Değerlendirme
    'eventAnnouncement': Color(0xFF34D399), // Duyuru
    'eventExam': Color(0xFFF87171), // Sınav
    'eventSemester': Color(0xFF818CF8), // Dönem
    'eventCourseSelection': Color(0xFFFBBF24), // Ders Seçimi
    // Genel UI renkleri / General UI colors (Koyu tema için optimized)
    'success': Color(0xFF34D399),
    'warning': Color(0xFFFBBF24),
    'error': Color(0xFFF87171),
    'info': Color(0xFF60A5FA),
    'neutral': Color(0xFF9CA3AF),
  };

  /// Semantik renk alıcısı / Semantic color getter
  static Color getSemanticColor(BuildContext context, String colorKey) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorMap = isDark ? _darkSemanticColors : _lightSemanticColors;
    return colorMap[colorKey] ?? getPrimaryColor(context);
  }

  /// Not rengi alıcısı / Grade color getter
  static Color getGradeColor(BuildContext context, String grade) {
    switch (grade.toUpperCase()) {
      case 'AA':
        return getSemanticColor(context, 'gradeExcellent');
      case 'BA':
      case 'BB':
        return getSemanticColor(context, 'gradeGood');
      case 'CB':
      case 'CC':
        return getSemanticColor(context, 'gradeAverage');
      case 'DC':
      case 'DD':
      case 'FF':
        return getSemanticColor(context, 'gradePoor');
      default:
        return getSemanticColor(context, 'neutral');
    }
  }

  /// Etkinlik türü renk alıcısı / Event type color getter
  static Color getEventTypeColor(BuildContext context, String eventType) {
    final key = 'event${eventType.toLowerCase().replaceAll(' ', '')}';
    return getSemanticColor(context, key);
  }
}
