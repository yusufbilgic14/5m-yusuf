import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/authentication_provider.dart';
import '../providers/language_provider.dart';
import '../services/firebase_auth_service.dart';
import '../services/secure_storage_service.dart';
import '../models/user_model.dart';
import 'home_screen.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdSignupController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _isLanguageDropdownOpen = false;
  bool _rememberMe = false;

  // Authentication mode toggle
  AuthMode _authMode = AuthMode.signIn;
  String? _selectedDepartment;
  String? _selectedYearOfStudy;
  String? _selectedGender;
  DateTime? _selectedBirthDate;
  bool _agreeToTerms = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _languageDropdownController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _languageDropdownAnimation;
  
  // Services
  final _secureStorage = SecureStorageService();

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcülerini başlat / Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _languageDropdownController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

    _languageDropdownAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _languageDropdownController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Animasyonları başlat / Start animations
    _fadeController.forward();
    _slideController.forward();
    
    // Hatırlanan giriş bilgilerini yükle / Load remembered credentials
    _loadRememberedCredentials();
  }
  
  /// Hatırlanan giriş bilgilerini yükle / Load remembered credentials
  Future<void> _loadRememberedCredentials() async {
    try {
      final credentials = await _secureStorage.getRememberedCredentials();
      final rememberMe = await _secureStorage.getRememberMe();
      
      if (rememberMe && mounted) {
        setState(() {
          _rememberMe = true;
          if (credentials['email'] != null) {
            _studentIdController.text = credentials['email']!;
          }
          if (credentials['password'] != null) {
            _passwordController.text = credentials['password']!;
          }
        });
      }
    } catch (e) {
      // Hatırlanan bilgileri yüklerken hata oluştu, devam et / Error loading remembered credentials, continue
      debugPrint('Remember me credentials loading error: $e');
    }
  }

  /// Dil dropdown menüsünü aç/kapat / Toggle language dropdown
  void _toggleLanguageDropdown() {
    setState(() {
      _isLanguageDropdownOpen = !_isLanguageDropdownOpen;
    });

    if (_isLanguageDropdownOpen) {
      _languageDropdownController.forward();
    } else {
      _languageDropdownController.reverse();
    }
  }

  /// Dil seçimi yap / Select language
  void _selectLanguage(Locale locale) {
    final languageProvider = Provider.of<LanguageProvider>(
      context,
      listen: false,
    );
    languageProvider.setLocale(locale);
    _toggleLanguageDropdown();
  }

  /// Şifre sıfırlama URL'sini aç / Open password reset URL
  Future<void> _launchPasswordResetUrl() async {
    final Uri url = Uri.parse('https://mebis.medipol.edu.tr/PasswordReset');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          _showSnackBar(
            AppLocalizations.of(context)!.urlCouldNotOpen,
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          AppLocalizations.of(context)!.anErrorOccurred,
          isError: true,
        );
      }
    }
  }

  /// SnackBar gösterici / SnackBar helper
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        margin: const EdgeInsets.all(AppConstants.paddingMedium),
      ),
    );
  }

  /// Yedek logo widget'ı / Fallback logo widget
  Widget _buildFallbackLogo() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        color: const Color(0xFFDDB822),
        borderRadius: BorderRadius.circular(AppConstants.radiusXLarge),
      ),
      child: const Icon(Icons.school, color: Colors.white, size: 80),
    );
  }

  /// Giriş işlemi / Login process
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simülasyon için kısa bekleme / Short wait for simulation
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isLoading = false;
    });

    // Ana sayfaya yönlendir / Navigate to home page
    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: AppConstants.animationNormal,
        ),
      );
    }
  }

  /// Firebase email/password ile giriş yap / Sign in with Firebase email/password
  Future<void> _handleFirebaseSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Auth Service ile giriş yap / Sign in with Firebase Auth Service
      final authService = FirebaseAuthService();

      // Check if Firebase is configured / Firebase'in konfigüre olup olmadığını kontrol et
      if (!authService.isFirebaseConfigured) {
        _showSnackBar(
          'Firebase henüz konfigüre edilmedi. Lütfen Firebase Console kurulumunu tamamlayın.',
          isError: true,
        );
        return;
      }

      final result = await authService.signInWithEmailAndPassword(
        email: _studentIdController.text.trim(),
        password: _passwordController.text,
      );

      if (result.isSuccess && mounted) {
        // Save credentials if remember me is checked / Beni hatırla seçiliyse bilgileri kaydet
        if (_rememberMe) {
          try {
            await _secureStorage.storeRememberedCredentials(
              email: _studentIdController.text.trim(),
              password: _passwordController.text,
              authType: 'firebase',
            );
          } catch (e) {
            debugPrint('Failed to store remembered credentials: $e');
          }
        } else {
          // Clear remembered data if remember me is not checked / Beni hatırla seçili değilse verileri temizle
          try {
            await _secureStorage.clearRememberMeData();
          } catch (e) {
            debugPrint('Failed to clear remember me data: $e');
          }
        }
        
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: AppConstants.animationNormal,
          ),
        );
      } else if (mounted) {
        _showSnackBar(result.errorMessage ?? 'Giriş başarısız', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Giriş sırasında hata oluştu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Firebase email/password ile kayıt ol / Sign up with Firebase email/password
  Future<void> _handleFirebaseSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    if (!_agreeToTerms) {
      _showSnackBar(l10n.pleaseAcceptTerms, isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Firebase Auth Service ile kayıt ol / Sign up with Firebase Auth Service
      final authService = FirebaseAuthService();

      // Check if Firebase is configured / Firebase'in konfigüre olup olmadığını kontrol et
      if (!authService.isFirebaseConfigured) {
        _showSnackBar(
          'Firebase henüz konfigüre edilmedi. Lütfen Firebase Console kurulumunu tamamlayın.',
          isError: true,
        );
        return;
      }

      final result = await authService.signUpWithEmailAndPassword(
        email: _studentIdController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim(),
        department: _selectedDepartment,
        phoneNumber: _phoneController.text.trim().isNotEmpty
            ? _phoneController.text.trim()
            : null,
      );

      if (result.isSuccess && mounted) {
        _showSnackBar(l10n.accountCreatedSuccessfully);
        // Navigate to email verification screen or main app
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: AppConstants.animationNormal,
          ),
        );
      } else if (mounted) {
        _showSnackBar(result.errorMessage ?? 'Kayıt başarısız', isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Kayıt sırasında hata oluştu: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Authentication mode'u değiştir / Toggle authentication mode
  void _toggleAuthMode() {
    setState(() {
      _authMode = _authMode == AuthMode.signIn
          ? AuthMode.signUp
          : AuthMode.signIn;
      // Clear form when switching modes
      _studentIdController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _displayNameController.clear();
      _phoneController.clear();
      _studentIdSignupController.clear();
      _selectedDepartment = null;
      _selectedYearOfStudy = null;
      _selectedGender = null;
      _selectedBirthDate = null;
      _agreeToTerms = false;
      _rememberMe = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final safeAreaTop = MediaQuery.of(context).padding.top;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark
        ? [
            const Color(0xFF181F2A),
            const Color(0xFF232B3E),
            const Color(0xFF1A2233),
          ]
        : [
            const Color(0xFFF3F6FB),
            const Color(0xFFE9F0FA),
            const Color(0xFFD6E4F0),
          ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF181F2A) : Colors.grey.shade50,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: bgGradient,
              ),
            ),
            child: SafeArea(
              minimum: const EdgeInsets.only(top: 4),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: screenSize.height - safeAreaTop - keyboardHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.paddingXLarge,
                      vertical: AppConstants.paddingMedium,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 0), // Üst boşluk minimum
                        // Logo ve dil seçici aynı satırda
                        // Logo
                        Image.asset(
                          'assets/images/black&yellow.png',
                          width: 320,
                          height: 210,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildFallbackLogo();
                          },
                        ),
                        // Form kartı / Form card
                        SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: _buildLoginCard(),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingXLarge),
                        // Alt bölüm / Footer section
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildFooterSection(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logo bölümü widget'ı / Logo section widget
  Widget _buildLogoSection({bool showFlags = true}) {
    return Column(
      children: [
        // Logo resmi - Standalone büyük logo / Standalone large logo
        Image.asset(
          'assets/images/black&yellow.png',
          width: 280,
          height: 280,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print('=== LOGO ERROR DEBUG ===');
            print('Error: $error');
            print('StackTrace: $stackTrace');
            print('Trying to load: assets/images/black&yellow.png');
            print('========================');
            return _buildFallbackLogo();
          },
        ),
        if (showFlags) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bayraklar burada gösterilecek (ama artık yukarıda gösteriliyor)
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFlagButton({
    required String imagePath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Image.asset(imagePath, width: 38, height: 28, fit: BoxFit.cover),
      ),
    );
  }

  /// Giriş kartı widget'ı / Login card widget
  Widget _buildLoginCard() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2634) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade100,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sade başlık bölümü / Simple header section
              Center(
                child: Column(
                  children: [
                    Text(
                      _authMode == AuthMode.signIn
                          ? l10n.loginTitle
                          : l10n.signUpTitle,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : const Color(0xFFDDB822),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _authMode == AuthMode.signIn
                          ? l10n.loginSubtitle
                          : l10n.signUpSubtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form fields based on auth mode / Auth moduna göre form alanları
              if (_authMode == AuthMode.signUp) ..._buildSignUpFields(),
              if (_authMode == AuthMode.signIn) ..._buildSignInFields(),

              // Authentication mode specific button / Kimlik doğrulama moduna özgü buton
              _buildAuthButton(l10n),
              const SizedBox(height: 20),

              // Mode toggle / Mod değiştirici
              _buildAuthModeToggle(l10n),
              const SizedBox(height: 20),

              // Ayırıcı çizgi / Divider
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.or,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.4)
                            : Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sade Microsoft OAuth giriş butonu / Clean Microsoft OAuth login button
              _buildCleanMicrosoftButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  /// Sade input alanı oluşturucu / Clean input field builder
  Widget _buildCleanInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isConfirmPassword = false,
    TextInputType textInputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark
        ? const Color(0xFF2A3441)
        : const Color(0xFFF8FAFC);
    final inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final labelColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark
        ? Colors.white.withValues(alpha: 0.4)
        : Colors.grey.shade500;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText:
              isPassword &&
              (isConfirmPassword
                  ? !_isConfirmPasswordVisible
                  : !_isPasswordVisible),
          keyboardType: textInputType,
          validator: validator,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: hintColor,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey.shade500,
              size: 20,
            ),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isConfirmPassword
                          ? (_isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility)
                          : (_isPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.4)
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        if (isConfirmPassword) {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        } else {
                          _isPasswordVisible = !_isPasswordVisible;
                        }
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFDDB822),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  /// Sade Microsoft OAuth giriş butonu / Clean Microsoft OAuth login button
  Widget _buildCleanMicrosoftButton(AppLocalizations l10n) {
    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        return SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: authProvider.isLoading
                ? null
                : () => _handleMicrosoftLogin(authProvider),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0078D4),
              backgroundColor: Colors.transparent,
              side: const BorderSide(color: Color(0xFF0078D4), width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: authProvider.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF0078D4),
                      ),
                    ),
                  )
                : Image.asset(
                    'assets/images/microsoft-logo-png_seeklogo-258454.png',
                    width: 16,
                    height: 16,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.business,
                        size: 16,
                        color: Color(0xFF0078D4),
                      );
                    },
                  ),
            label: Text(
              authProvider.isLoading
                  ? 'Giriş yapılıyor...'
                  : l10n.loginWithMicrosoft,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0078D4),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Microsoft OAuth giriş işlemi / Microsoft OAuth login process
  Future<void> _handleMicrosoftLogin(
    AuthenticationProvider authProvider,
  ) async {
    try {
      final success = await authProvider.signInWithMicrosoft();

      if (success && mounted) {
        // Save remember me state for Microsoft login / Microsoft girişi için beni hatırla durumunu kaydet
        if (_rememberMe) {
          try {
            await _secureStorage.storeRememberMe(true);
            // Note: We don't store password for Microsoft OAuth, just the preference
            // Not: Microsoft OAuth için şifre saklamıyoruz, sadece tercih durumunu
          } catch (e) {
            debugPrint('Failed to store Microsoft remember me state: $e');
          }
        } else {
          try {
            await _secureStorage.clearRememberMeData();
          } catch (e) {
            debugPrint('Failed to clear remember me data: $e');
          }
        }
        
        // Başarılı giriş, ana sayfaya yönlendir / Successful login, navigate to home
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const HomeScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
            transitionDuration: AppConstants.animationNormal,
          ),
        );
      } else if (mounted && authProvider.hasError) {
        // Hata durumunda kullanıcıya bilgi ver / Show error to user
        _showSnackBar(
          authProvider.errorMessage ??
              'Microsoft giriş hatası / Microsoft sign in error',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          'Microsoft giriş işlemi başarısız / Microsoft sign in failed: $e',
          isError: true,
        );
      }
    }
  }

  /// Dil seçici dropdown widget'ı / Language selector dropdown widget
  Widget _buildLanguageDropdown() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _toggleLanguageDropdown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white24 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.earthAmericas,
              size: 18,
              color: AppConstants.getIconColor(context),
            ),
            const SizedBox(width: 4),
            AnimatedRotation(
              turns: _isLanguageDropdownOpen ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Dil seçici overlay dropdown'u / Language selector overlay dropdown
  Widget _buildLanguageDropdownOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentLocale = Provider.of<LanguageProvider>(context).locale;
    final isTurkish = currentLocale.languageCode == 'tr';

    if (!_isLanguageDropdownOpen) return const SizedBox.shrink();

    return Positioned(
      top: 195, // Position below the logo/language button area
      right: 24,
      child: AnimatedBuilder(
        animation: _languageDropdownAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _languageDropdownAnimation.value,
            alignment: Alignment.topRight,
            child: Opacity(
              opacity: _languageDropdownAnimation.value,
              child: Material(
                elevation: 50,
                borderRadius: BorderRadius.circular(12),
                color: isDark ? const Color(0xFF2A3441) : Colors.white,
                shadowColor: Colors.black.withValues(alpha: 0.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildLanguageOption(
                      imagePath: 'assets/images/turkey.png',
                      label: 'Türkçe',
                      isSelected: isTurkish,
                      onTap: () => _selectLanguage(const Locale('tr')),
                    ),
                    Divider(
                      height: 1,
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                    _buildLanguageOption(
                      imagePath: 'assets/images/uk.png',
                      label: 'English',
                      isSelected: !isTurkish,
                      onTap: () => _selectLanguage(const Locale('en')),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Dil seçenek widget'ı / Language option widget
  Widget _buildLanguageOption({
    required String imagePath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                    ? const Color(0xFFDDB822).withValues(alpha: 0.2)
                    : const Color(0xFFDDB822).withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(imagePath, width: 24, height: 18, fit: BoxFit.cover),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppConstants.fontSizeSmall,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFFDDB822))
                    : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            if (isSelected) ...[],
          ],
        ),
      ),
    );
  }

  /// Alt bölüm widget'ı / Footer section widget
  Widget _buildFooterSection() {
    return Column(
      children: [
        Text(
          'Medipol Üniversitesi',
          style: TextStyle(
            fontSize: AppConstants.fontSizeMedium,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: AppConstants.paddingSmall),

        Text(
          'Öğrenci Bilgi Sistemi',
          style: TextStyle(
            fontSize: AppConstants.fontSizeSmall,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  /// Sign-up form fields / Kayıt formu alanları
  List<Widget> _buildSignUpFields() {
    final l10n = AppLocalizations.of(context)!;

    return [
      // Display name field / Ad soyad alanı
      _buildCleanInputField(
        controller: _displayNameController,
        label: l10n.fullName,
        hint: l10n.fullNameHint,
        icon: Icons.person_outline,
        textInputType: TextInputType.name,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return l10n.fullNameRequired;
          }
          if (value!.trim().split(' ').length < 2) {
            return l10n.fullNameInvalid;
          }
          return null;
        },
      ),
      const SizedBox(height: 20),

      // Email field / Email alanı
      _buildCleanInputField(
        controller: _studentIdController,
        label: l10n.emailAddress,
        hint: l10n.emailHint,
        icon: Icons.email_outlined,
        textInputType: TextInputType.emailAddress,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return l10n.emailRequired;
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
            return l10n.emailInvalid;
          }
          return null;
        },
      ),
      const SizedBox(height: 20),

      // Password field / Şifre alanı
      _buildCleanInputField(
        controller: _passwordController,
        label: l10n.createPassword,
        hint: l10n.createPasswordHint,
        icon: Icons.lock_outline,
        isPassword: true,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return l10n.passwordRequired;
          }
          if (value!.length < 8) {
            return l10n.passwordTooShort;
          }
          if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
            return l10n.passwordTooWeak;
          }
          return null;
        },
      ),
      const SizedBox(height: 20),

      // Confirm password field / Şifre tekrar alanı
      _buildCleanInputField(
        controller: _confirmPasswordController,
        label: l10n.confirmPassword,
        hint: l10n.confirmPasswordHint,
        icon: Icons.lock_outline,
        isPassword: true,
        isConfirmPassword: true,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return l10n.confirmPasswordRequired;
          }
          if (value != _passwordController.text) {
            return l10n.passwordsDoNotMatch;
          }
          return null;
        },
      ),
      const SizedBox(height: 20),

      // Department dropdown / Bölüm seçimi
      _buildDepartmentDropdown(),
      const SizedBox(height: 20),

      // Phone field (optional) / Telefon alanı (opsiyonel)
      _buildCleanInputField(
        controller: _phoneController,
        label: l10n.phoneOptional,
        hint: l10n.phoneHint,
        icon: Icons.phone_outlined,
        textInputType: TextInputType.phone,
        validator: (value) {
          if (value?.isNotEmpty == true) {
            if (!RegExp(
              r'^(\+90|0)?[5-9]\d{9}$',
            ).hasMatch(value!.replaceAll(' ', ''))) {
              return l10n.phoneInvalid;
            }
          }
          return null;
        },
      ),
      const SizedBox(height: 20),

      // Student ID field (optional) / Öğrenci no alanı (opsiyonel)
      _buildCleanInputField(
        controller: _studentIdSignupController,
        label: l10n.studentIdOptional,
        hint: l10n.studentIdHintSignup,
        icon: Icons.badge_outlined,
        textInputType: TextInputType.number,
      ),
      const SizedBox(height: 20),

      // Year of study dropdown / Sınıf seçimi
      _buildYearOfStudyDropdown(),
      const SizedBox(height: 20),

      // Gender dropdown / Cinsiyet seçimi
      _buildGenderDropdown(),
      const SizedBox(height: 20),

      // Birth date picker / Doğum tarihi seçimi
      _buildBirthDatePicker(),
      const SizedBox(height: 20),

      // Terms checkbox / Kullanım şartları onay kutusu
      _buildTermsCheckbox(),
      const SizedBox(height: 28),
    ];
  }

  /// Sign-in form fields / Giriş formu alanları
  List<Widget> _buildSignInFields() {
    final l10n = AppLocalizations.of(context)!;

    return [
      // Email field / Email alanı
      _buildCleanInputField(
        controller: _studentIdController,
        label: 'Email Adresi',
        hint: 'ornek@email.com',
        icon: Icons.email_outlined,
        textInputType: TextInputType.emailAddress,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Email adresi gerekli';
          }
          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
            return 'Geçerli bir email adresi girin';
          }
          return null;
        },
      ),
      const SizedBox(height: 20),

      // Password field / Şifre alanı
      _buildCleanInputField(
        controller: _passwordController,
        label: l10n.password,
        hint: l10n.password,
        icon: Icons.lock_outline,
        isPassword: true,
        validator: (value) {
          if (value?.isEmpty ?? true) {
            return 'Şifre gerekli';
          }
          return null;
        },
      ),
      const SizedBox(height: 16),

      // Forgot password and Remember me row / Şifremi unuttum ve Beni hatırla satırı
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Remember me checkbox / Beni hatırla checkbox'ı
          Expanded(
            child: Row(
              children: [
                Checkbox(
                  value: _rememberMe,
                  onChanged: (value) {
                    setState(() {
                      _rememberMe = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFFDDB822),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _rememberMe = !_rememberMe;
                      });
                    },
                    child: Text(
                      AppLocalizations.of(context)!.rememberMe,
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70
                            : Colors.grey.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Forgot password link / Şifremi unuttum linki
          TextButton(
            onPressed: _launchPasswordResetUrl,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              l10n.forgotPassword,
              style: TextStyle(
                color: const Color(0xFFDDB822),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 28),
    ];
  }

  /// Department dropdown / Bölüm seçim dropdown'ı
  Widget _buildDepartmentDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark
        ? const Color(0xFF2A3441)
        : const Color(0xFFF8FAFC);
    final inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final labelColor = isDark ? Colors.white : Colors.black87;

    const departments = [
      'Bilgisayar Mühendisliği',
      'Tıp Fakültesi',
      'Hukuk Fakültesi',
      'İşletme',
      'Psikoloji',
      'Mimarlık',
      'Endüstri Mühendisliği',
      'Elektrik-Elektronik Mühendisliği',
      'Diğer',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.departmentOptional,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 0,
                maxWidth: constraints.maxWidth,
              ),
              child: DropdownButtonFormField<String>(
                isExpanded: true, // Satırı tamamen kapla, taşmayı önle
                value: _selectedDepartment,
                decoration: InputDecoration(
                  hintText: l10n.selectDepartment,
                  hintStyle: TextStyle(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.school_outlined,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.grey.shade500,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: inputFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: const Color(0xFFDDB822),
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                items: departments.map((department) {
                  return DropdownMenuItem<String>(
                    value: department,
                    child: Text(
                      department,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Terms and conditions checkbox / Kullanım şartları onay kutusu
  Widget _buildTermsCheckbox() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _agreeToTerms,
          onChanged: (value) {
            setState(() {
              _agreeToTerms = value ?? false;
            });
          },
          activeColor: const Color(0xFFDDB822),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _agreeToTerms = !_agreeToTerms;
              });
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                  children: [
                    const TextSpan(text: 'Medipol Uygulaması '),
                    TextSpan(
                      text: 'Kullanım Şartları',
                      style: TextStyle(
                        color: const Color(0xFFDDB822),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: ' ve '),
                    TextSpan(
                      text: 'Gizlilik Politikası',
                      style: TextStyle(
                        color: const Color(0xFFDDB822),
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(
                      text: 'ını okuduğumu ve kabul ettiğimi onaylarım.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Authentication button / Kimlik doğrulama butonu
  Widget _buildAuthButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading
            ? null
            : (_authMode == AuthMode.signIn
                  ? _handleFirebaseSignIn
                  : _handleFirebaseSignUp),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDDB822),
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: const Color(0xFFDDB822).withValues(
            alpha: 0.6,
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _authMode == AuthMode.signIn
                    ? l10n.loginButton
                    : l10n.createAccount,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }

  /// Authentication mode toggle / Kimlik doğrulama modu değiştirici
  Widget _buildAuthModeToggle(AppLocalizations l10n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _authMode == AuthMode.signIn
              ? l10n.dontHaveAccount
              : l10n.alreadyHaveAccount,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        TextButton(
          onPressed: _toggleAuthMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          ),
          child: Text(
            _authMode == AuthMode.signIn ? l10n.signUpHere : l10n.signInHere,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDDB822),
            ),
          ),
        ),
      ],
    );
  }

  /// Year of study dropdown / Sınıf seçim dropdown'u
  Widget _buildYearOfStudyDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark
        ? const Color(0xFF2A3441)
        : const Color(0xFFF8FAFC);
    final inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final labelColor = isDark ? Colors.white : Colors.black87;

    final years = [
      l10n.firstYear,
      l10n.secondYear,
      l10n.thirdYear,
      l10n.fourthYear,
      l10n.graduateStudent,
      l10n.phdStudent,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.yearOfStudyOptional,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedYearOfStudy,
          decoration: InputDecoration(
            hintText: l10n.selectYearOfStudy,
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey.shade500,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.school_outlined,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey.shade500,
              size: 20,
            ),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFDDB822),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: years.map((year) {
            return DropdownMenuItem<String>(
              value: year,
              child: Text(
                year,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedYearOfStudy = value;
            });
          },
        ),
      ],
    );
  }

  /// Gender dropdown / Cinsiyet seçim dropdown'u
  Widget _buildGenderDropdown() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark
        ? const Color(0xFF2A3441)
        : const Color(0xFFF8FAFC);
    final inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final labelColor = isDark ? Colors.white : Colors.black87;

    final genders = [l10n.male, l10n.female, l10n.preferNotToSay];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.genderOptional,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            hintText: l10n.selectGender,
            hintStyle: TextStyle(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey.shade500,
              fontWeight: FontWeight.w400,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              Icons.person_outline,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.4)
                  : Colors.grey.shade500,
              size: 20,
            ),
            filled: true,
            fillColor: inputFill,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: inputBorder, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: const Color(0xFFDDB822),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: genders.map((gender) {
            return DropdownMenuItem<String>(
              value: gender,
              child: Text(
                gender,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
        ),
      ],
    );
  }

  /// Birth date picker / Doğum tarihi seçici
  Widget _buildBirthDatePicker() {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputFill = isDark
        ? const Color(0xFF2A3441)
        : const Color(0xFFF8FAFC);
    final inputBorder = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade200;
    final labelColor = isDark ? Colors.white : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.birthDateOptional,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: _selectedBirthDate ?? DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (picked != null && picked != _selectedBirthDate) {
              setState(() {
                _selectedBirthDate = picked;
              });
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: inputFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: inputBorder, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.grey.shade500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedBirthDate == null
                        ? l10n.selectBirthDate
                        : '${_selectedBirthDate!.day}/${_selectedBirthDate!.month}/${_selectedBirthDate!.year}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _selectedBirthDate == null
                          ? (isDark
                                ? Colors.white.withValues(alpha: 0.4)
                                : Colors.grey.shade500)
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _studentIdSignupController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _languageDropdownController.dispose();
    super.dispose();
  }
}

/// Authentication mode enum / Kimlik doğrulama modu enum'ı
enum AuthMode { signIn, signUp }
