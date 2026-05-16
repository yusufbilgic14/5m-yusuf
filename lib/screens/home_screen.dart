import 'package:flutter/material.dart';
import 'dart:async';
import '../constants/app_constants.dart';
import '../themes/app_themes.dart';
import '../widgets/common/app_drawer_widget.dart';
import '../widgets/common/bottom_navigation_widget.dart';
import 'inbox_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common/app_bar_widget.dart';
import '../services/user_courses_service.dart';
import '../models/user_course_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentAnnouncementIndex = 0;
  late PageController _pageController;
  Timer? _autoAdvanceTimer;
  bool _showNotifications = false;
  bool _showCafeteriaMenu = false;

  // Firebase service and user courses
  final UserCoursesService _coursesService = UserCoursesService();
  List<UserCourse> _todaysUserCourses = [];
  bool _isLoadingCourses = true;
  StreamSubscription<List<UserCourse>>? _coursesSubscription;

  // Duyuru listesi
  static const List<Map<String, String>> _announcements = [
    {
      'title': 'Mezuniyet Töreni 2025',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '20.06.2025',
      'description': 'Mezuniyet törenimiz 20 Haziran\'da yapılacaktır.',
    },
    {
      'title': 'Bahar Dönemi Final Sınavları',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '18.06.2025',
      'description': 'Final sınavları 18 Haziran\'da başlayacaktır.',
    },
    {
      'title': 'Yaz Okulu Kayıtları Başladı',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '15.06.2025',
      'description': 'Yaz okulu kayıtları için son tarih 15 Haziran.',
    },
    {
      'title': 'Kariyer Günleri 2025',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '12.06.2025',
      'description': 'Kariyer günleri etkinliği 12 Haziran\'da.',
    },
    {
      'title': 'Burs Başvuruları Son Tarih',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '10.06.2025',
      'description': 'Burs başvuruları için son tarih 10 Haziran.',
    },
    {
      'title': 'Öğrenci Konseyi Seçimleri',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '08.06.2025',
      'description': 'Öğrenci konseyi seçimleri 8 Haziran\'da.',
    },
    {
      'title': 'Sosyal Etkinlik: Konser',
      'image': 'assets/images/announcement-image.jpeg',
      'date': '05.06.2025',
      'description': 'Müzik konserimiz 5 Haziran\'da yapılacaktır.',
    },
  ];

  // Bildirim listesi
  static const List<Map<String, dynamic>> _notifications = [
    {
      'title': 'Öğrenci Belgesi Talebiniz Hakkında',
      'message': 'Öğrenci İşleri müdürlüğünden yeni bir mesaj aldınız.',
      'time': '2 saat önce',
      'isRead': false,
      'type': 'email',
      'inboxId': 1,
    },
    {
      'title': 'Burs Başvuru Sonucu',
      'message': 'Burs ve Yardım İşleri müdürlüğünden yeni bir mesaj aldınız.',
      'time': '1 gün önce',
      'isRead': false,
      'type': 'email',
      'inboxId': 2,
    },
    {
      'title': 'Dönem Sonu Sınav Programı',
      'message': 'Akademik Birim müdürlüğünden yeni bir mesaj aldınız.',
      'time': '4 gün önce',
      'isRead': true,
      'type': 'email',
      'inboxId': 3,
    },
    {
      'title': 'Kütüphane Kitap İade Hatırlatması',
      'message': 'Kütüphane müdürlüğünden yeni bir mesaj aldınız.',
      'time': '5 gün önce',
      'isRead': true,
      'type': 'email',
      'inboxId': 4,
    },
    {
      'title': 'Mezuniyet Töreni Davetiyesi',
      'message': 'Protokol biriminden yeni bir mesaj aldınız.',
      'time': '1 hafta önce',
      'isRead': true,
      'type': 'email',
      'inboxId': 5,
    },
    {
      'title': 'Visual Programming Final Notunuz Paylaşılmıştır',
      'message':
          'Visual Programming dersi final sınavı notunuz sisteme yüklenmiştir.',
      'time': '2 saat önce',
      'isRead': false,
      'type': 'grade',
    },
    {
      'title': 'Kütüphane Kitap İade Hatırlatması',
      'message':
          'Ödünç aldığınız "Algorithm Design" kitabının iade tarihi yaklaşmaktadır.',
      'time': '5 saat önce',
      'isRead': false,
      'type': 'reminder',
    },
    {
      'title': 'Dönem Sonu Proje Teslim Tarihi',
      'message':
          'Database Management Systems dersi dönem sonu projesi için son teslim tarihi: 25 Haziran 2025',
      'time': '1 gün önce',
      'isRead': true,
      'type': 'assignment',
    },
    {
      'title': 'Burs Başvuru Sonucu',
      'message': 'Başarı bursu başvurunuz değerlendirme aşamasındadır.',
      'time': '2 gün önce',
      'isRead': true,
      'type': 'scholarship',
    },
    {
      'title': 'Yeni Duyuru: Mezuniyet Töreni',
      'message': 'Mezuniyet töreni için kayıt işlemleri başlamıştır.',
      'time': '3 gün önce',
      'isRead': true,
      'type': 'announcement',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _startAutoAdvance();
    _loadTodaysCourses();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _autoAdvanceTimer?.cancel();
    _coursesSubscription?.cancel();
    super.dispose();
  }

  void _startAutoAdvance() {
    _autoAdvanceTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_pageController.hasClients) {
        int nextPage = (_currentAnnouncementIndex + 1) % _announcements.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _goToAnnouncement(int index) {
    if (!mounted || !_pageController.hasClients) return;

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Load today's courses from Firebase
  void _loadTodaysCourses() {
    if (!_coursesService.isAuthenticated) {
      setState(() {
        _isLoadingCourses = false;
        _todaysUserCourses = [];
      });
      return;
    }

    _coursesSubscription = _coursesService.watchTodaysCourses().listen(
      (courses) {
        if (mounted) {
          setState(() {
            _todaysUserCourses = courses;
            _isLoadingCourses = false;
          });
        }
      },
      onError: (error) {
        debugPrint('❌ HomeScreen: Error loading today\'s courses - $error');
        if (mounted) {
          setState(() {
            _isLoadingCourses = false;
            _todaysUserCourses = [];
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppThemes.getBackgroundColor(context),
      drawer: const AppDrawerWidget(
        currentPageIndex: AppConstants.navIndexHome,
      ),
      appBar: ModernAppBar(
        title: l10n.homeWelcome,
        subtitle: AppConstants.userName,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFFDDB822)),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Menü',
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.restaurant, color: Color(0xFFDDB822)),
            tooltip: l10n.cafeteriaMenu,
            onPressed: () {
              setState(() {
                _showCafeteriaMenu = !_showCafeteriaMenu;
                _showNotifications = false;
              });
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_rounded, color: Color(0xFFDDB822)),
                if (_notifications.where((n) => !n['isRead']).isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red[500],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '${_notifications.where((n) => !n['isRead']).length}',
                        style: const TextStyle(
                          color: Color(0xFFDDB822),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            tooltip: 'Bildirimler',
            onPressed: () {
              setState(() {
                _showNotifications = !_showNotifications;
                _showCafeteriaMenu = false;
              });
            },
          ),
        ],
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Bildirim paneli
          AnimatedContainer(
            duration: AppConstants.animationNormal,
            curve: Curves.easeInOut,
            height: _showNotifications ? 350 : 0,
            child: _showNotifications ? _buildNotificationPanel(context) : null,
          ),
          // Cafeteria paneli
          AnimatedContainer(
            duration: AppConstants.animationNormal,
            curve: Curves.easeInOut,
            height: _showCafeteriaMenu ? 400 : 0,
            child: _showCafeteriaMenu ? _buildCafeteriaPanel(context) : null,
          ),
          // Ana içerik
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  // Duyurular bölümü
                  _buildAnnouncementsSection(context),
                  const SizedBox(height: 32),
                  // Günün dersleri bölümü
                  _buildTodaysCoursesSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationWidget(
        currentIndex: AppConstants.navIndexHome,
      ),
    );
  }

  // Duyurular bölümü
  Widget _buildAnnouncementsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildAnnouncementsSectionHeader(context),
        const SizedBox(height: 16),
        _buildAnnouncementsPageView(context),
        const SizedBox(height: 16),
        _buildAnnouncementsPageIndicators(context),
      ],
    );
  }

  // Duyurular bölümü başlığı
  Widget _buildAnnouncementsSectionHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(
          Icons.campaign_outlined,
          color: const Color(0xFFDDB822),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          l10n.announcements,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppThemes.getTextColor(context),
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => _openAnnouncementsPage(),
          child: Text(
            l10n.seeAll,
            style: TextStyle(
              color: const Color(0xFFDDB822),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // Duyuru kartları sayfa görünümü
  Widget _buildAnnouncementsPageView(BuildContext context) {
    return SizedBox(
      height: 180,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentAnnouncementIndex = index;
          });
        },
        itemCount: _announcements.length,
        itemBuilder: (context, index) {
          final announcement = _announcements[index];
          return _buildAnnouncementCard(context, announcement);
        },
      ),
    );
  }

  // Tek bir duyuru kartı
  Widget _buildAnnouncementCard(
    BuildContext context,
    Map<String, String> announcement,
  ) {
    return GestureDetector(
      onTap: () => _openAnnouncementsPage(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppThemes.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemes.getSecondaryTextColor(
              context,
            ).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              _buildAnnouncementCardBackground(context, announcement),
              _buildAnnouncementCardGradientOverlay(),
              _buildAnnouncementCardDateLabel(context, announcement),
              _buildAnnouncementCardContent(announcement),
            ],
          ),
        ),
      ),
    );
  }

  // Duyuru kartı arka plan resmi
  Widget _buildAnnouncementCardBackground(
    BuildContext context,
    Map<String, String> announcement,
  ) {
    return Positioned.fill(
      child: Image.asset(
        announcement['image']!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFDDB822),
                  const Color(0xFFDDB822).withValues(alpha: 0.7),
                ],
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.campaign_outlined,
                size: 40,
                color: Color(0xFFDDB822),
              ),
            ),
          );
        },
      ),
    );
  }

  // Duyuru kartı gradient katmanı
  Widget _buildAnnouncementCardGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
          ),
        ),
      ),
    );
  }

  // Duyuru kartı tarih etiketi
  Widget _buildAnnouncementCardDateLabel(
    BuildContext context,
    Map<String, String> announcement,
  ) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          announcement['date']!,
          style: TextStyle(
            color: const Color(0xFFDDB822),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Duyuru kartı içerik bölümü
  Widget _buildAnnouncementCardContent(Map<String, String> announcement) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              announcement['title']!,
              style: const TextStyle(
                color: Color(0xFFDDB822),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              announcement['description'] ?? '',
              style: TextStyle(
                color: const Color(0xFFDDB822).withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // Duyuru sayfa göstergeleri
  Widget _buildAnnouncementsPageIndicators(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_announcements.length, (index) {
        return GestureDetector(
          onTap: () => _goToAnnouncement(index),
          child: AnimatedContainer(
            duration: AppConstants.animationFast,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: index == _currentAnnouncementIndex ? 20 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: index == _currentAnnouncementIndex
                  ? const Color(0xFFDDB822)
                  : AppThemes.getSecondaryTextColor(
                      context,
                    ).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  // Duyurular sayfasını açma helper metodu
  Future<void> _openAnnouncementsPage() async {
    final url = Uri.parse('https://www.medipol.edu.tr/duyurular');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  // Günün dersleri bölümü
  Widget _buildTodaysCoursesSection(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bölüm başlığı
        Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              color: const Color(0xFFDDB822),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.todaysCourses,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppThemes.getTextColor(context),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppThemes.getPrimaryColor(
                  context,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.todayDate,
                style: TextStyle(
                  color: const Color(0xFFDDB822),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Ders kartları
        if (_isLoadingCourses)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_todaysUserCourses.isEmpty)
          _buildEmptyCoursesMessage(context)
        else
          ...List.generate(_todaysUserCourses.length, (index) {
            final course = _todaysUserCourses[index];
            return _buildUserCourseCard(context, course, index);
          }),
      ],
    );
  }

  // Boş dersler mesajı
  Widget _buildEmptyCoursesMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppThemes.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemes.getSecondaryTextColor(
              context,
            ).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: AppThemes.getSecondaryTextColor(
                context,
              ).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCoursesToday,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppThemes.getTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noCoursesTodayMessage,
              style: TextStyle(
                fontSize: 14,
                color: AppThemes.getSecondaryTextColor(context),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Firebase'den gelen UserCourse için ders kartı
  Widget _buildUserCourseCard(
    BuildContext context,
    UserCourse course,
    int index,
  ) {
    final todaysSchedules = course.getTodaysSchedules();
    final firstSchedule = todaysSchedules.isNotEmpty
        ? todaysSchedules.first
        : null;

    if (firstSchedule == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        _showUserCourseDetails(context, course);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppThemes.getSurfaceColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppThemes.getSecondaryTextColor(
              context,
            ).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Zaman göstergesi
              SizedBox(
                width: 50,
                child: Text(
                  firstSchedule.startTime,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                ),
              ),

              // Renk çubuğu
              Container(
                width: 3,
                height: 50,
                decoration: BoxDecoration(
                  color: course.colorAsColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(width: 12),

              // Ders ikonu
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: course.colorAsColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.book_outlined,
                  color: course.colorAsColor,
                  size: 20,
                ),
              ),

              const SizedBox(width: 12),

              // Ders bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.displayName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppThemes.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.courseCode,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: course.colorAsColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 12,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            course.instructor.name,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppThemes.getSecondaryTextColor(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          firstSchedule.room,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppThemes.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Süre bilgisi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: course.colorAsColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  firstSchedule.timeString,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: course.colorAsColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserCourseDetails(BuildContext context, UserCourse course) {
    final theme = Theme.of(context);
    final todaysSchedules = course.getTodaysSchedules();
    final firstSchedule = todaysSchedules.isNotEmpty
        ? todaysSchedules.first
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: course.colorAsColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    course.courseCode,
                    style: const TextStyle(
                      color: Color(0xFFDDB822),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              course.displayName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailRow(
              Icons.person_rounded,
              'Instructor',
              course.instructor.name,
              theme,
            ),
            if (firstSchedule != null) ...[
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.location_on_rounded,
                'Room',
                firstSchedule.room,
                theme,
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                Icons.access_time_rounded,
                'Time',
                firstSchedule.timeString,
                theme,
              ),
            ],
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.school_rounded,
              'Credits',
              '${course.credits} Credits',
              theme,
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              Icons.domain_rounded,
              'Department',
              course.department,
              theme,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Bildirim paneli
  Widget _buildNotificationPanel(BuildContext context) {
    return Container(
      decoration: _buildNotificationPanelDecoration(context),
      child: Column(
        children: [
          _buildNotificationPanelHeader(context),
          _buildNotificationsList(context),
        ],
      ),
    );
  }

  // Bildirim paneli dekorasyonu
  BoxDecoration _buildNotificationPanelDecoration(BuildContext context) {
    return BoxDecoration(
      color: AppThemes.getSurfaceColor(context),
      border: Border(
        bottom: BorderSide(
          color: AppThemes.getSecondaryTextColor(
            context,
          ).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    );
  }

  // Bildirim paneli başlığı
  Widget _buildNotificationPanelHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            Icons.notifications_outlined,
            color: const Color(0xFFDDB822),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.notifications,
              style: TextStyle(
                color: const Color(0xFFDDB822),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _buildMarkAllReadButton(context, l10n),
          _buildCloseNotificationsPanelButton(context),
        ],
      ),
    );
  }

  // Tümünü okundu işaretle butonu
  Widget _buildMarkAllReadButton(BuildContext context, AppLocalizations l10n) {
    return TextButton(
      onPressed: () {
        setState(() {
          for (var notification in _notifications) {
            notification['isRead'] = true;
          }
        });
      },
      child: Text(
        l10n.markAllRead,
        style: TextStyle(
          color: const Color(0xFFDDB822),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Bildirim panelini kapatma butonu
  Widget _buildCloseNotificationsPanelButton(BuildContext context) {
    return IconButton(
      onPressed: () {
        setState(() {
          _showNotifications = false;
        });
      },
      icon: Icon(
        Icons.keyboard_arrow_up_outlined,
        color: const Color(0xFFDDB822),
        size: 20,
      ),
    );
  }

  // Bildirimler listesi
  Widget _buildNotificationsList(BuildContext context) {
    return Expanded(
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return _buildNotificationItem(context, notification, index);
        },
      ),
    );
  }

  // Bildirim öğesi
  Widget _buildNotificationItem(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
  ) {
    return InkWell(
      onTap: () => _handleNotificationTap(context, notification, index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _buildNotificationItemDecoration(context, notification),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildNotificationItemIcon(notification),
            const SizedBox(width: 12),
            _buildNotificationItemContent(context, notification),
          ],
        ),
      ),
    );
  }

  // Bildirim tıklama işlemleri
  void _handleNotificationTap(
    BuildContext context,
    Map<String, dynamic> notification,
    int index,
  ) {
    setState(() {
      _notifications[index]['isRead'] = true;
    });

    if (notification['type'] == 'email' && notification['inboxId'] != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              InboxScreen(selectedMessageId: notification['inboxId']),
        ),
      );
    }
  }

  // Bildirim öğesi dekorasyonu
  BoxDecoration _buildNotificationItemDecoration(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    return BoxDecoration(
      color: notification['isRead']
          ? AppThemes.getSurfaceColor(context)
          : const Color(0xFFDDB822).withValues(alpha: 0.05),
      border: Border(
        bottom: BorderSide(
          color: AppThemes.getSecondaryTextColor(
            context,
          ).withValues(alpha: 0.1),
          width: 1,
        ),
      ),
    );
  }

  // Bildirim öğesi ikonu
  Widget _buildNotificationItemIcon(Map<String, dynamic> notification) {
    final notificationType = notification['type'] as String;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: _getNotificationColor(notificationType).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getNotificationIcon(notificationType),
        color: _getNotificationColor(notificationType),
        size: 18,
      ),
    );
  }

  // Bildirim öğesi içeriği
  Widget _buildNotificationItemContent(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotificationItemTitle(context, notification),
          const SizedBox(height: 4),
          _buildNotificationItemMessage(context, notification),
          const SizedBox(height: 4),
          _buildNotificationItemTime(context, notification),
        ],
      ),
    );
  }

  // Bildirim öğesi başlığı
  Widget _buildNotificationItemTitle(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            notification['title'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: notification['isRead']
                  ? FontWeight.w500
                  : FontWeight.w600,
              color: AppThemes.getTextColor(context),
            ),
          ),
        ),
        if (!notification['isRead'])
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: const Color(0xFFDDB822),
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }

  // Bildirim öğesi mesajı
  Widget _buildNotificationItemMessage(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    return Text(
      notification['message'],
      style: TextStyle(
        fontSize: 12,
        color: AppThemes.getSecondaryTextColor(context),
        fontWeight: FontWeight.w400,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  // Bildirim öğesi zamanı
  Widget _buildNotificationItemTime(
    BuildContext context,
    Map<String, dynamic> notification,
  ) {
    return Text(
      notification['time'],
      style: TextStyle(
        fontSize: 11,
        color: AppThemes.getSecondaryTextColor(context).withValues(alpha: 0.7),
        fontWeight: FontWeight.w400,
      ),
    );
  }

  // Bildirim ikonu helper metodu
  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'grade':
        return Icons.grade_outlined;
      case 'reminder':
        return Icons.schedule_outlined;
      case 'assignment':
        return Icons.assignment_outlined;
      case 'scholarship':
        return Icons.account_balance_wallet_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  // Bildirim rengi helper metodu
  Color _getNotificationColor(String type) {
    switch (type) {
      case 'grade':
        return Colors.green[600]!;
      case 'reminder':
        return Colors.orange[600]!;
      case 'assignment':
        return Colors.blue[600]!;
      case 'scholarship':
        return Colors.purple[600]!;
      case 'announcement':
        return Colors.red[600]!;
      case 'email':
        return Colors.teal[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  // Cafeteria paneli
  Widget _buildCafeteriaPanel(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      elevation: 4,
      color: theme.cardColor,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      child: Stack(
        children: [
          SizedBox(height: 400, child: _buildCafeteriaMenuSummary(context)),
        ],
      ),
    );
  }

  // Cafeteria menü özeti
  Widget _buildCafeteriaMenuSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildCafeteriaMenuDays(context),
        ),
      ),
    );
  }

  // Cafeteria menü günleri listesi
  List<Widget> _buildCafeteriaMenuDays(BuildContext context) {
    final now = DateTime.now();
    final menus = _getCafeteriaMenuData();

    return List.generate(4, (i) {
      final date = now.add(Duration(days: i));
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCafeteriaMenuDayHeader(context, date),
          const SizedBox(height: 8),
          _buildCafeteriaMenuItems(context, menus[i % menus.length]),
          if (i < 3) const Divider(height: 24),
        ],
      );
    });
  }

  // Cafeteria menü gün başlığı
  Widget _buildCafeteriaMenuDayHeader(BuildContext context, DateTime date) {
    final theme = Theme.of(context);
    final weekdayNames = _getWeekdayNames(context);
    final weekday = weekdayNames[date.weekday - 1];

    return Row(
      children: [
        Icon(
          Icons.restaurant_outlined,
          color: const Color(0xFFDDB822),
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context)!.cafeteriaMenu,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const Spacer(),
        Text(
          _formatMenuDate(date, weekday),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  // Cafeteria menü öğeleri
  Widget _buildCafeteriaMenuItems(
    BuildContext context,
    List<String> menuItems,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context)!.lunch,
          style: TextStyle(
            color: Colors.green[700],
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        ...menuItems.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 13,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Hafta gün isimleri helper metodu
  List<String> _getWeekdayNames(BuildContext context) {
    return [
      AppLocalizations.of(context)!.mondayShort,
      AppLocalizations.of(context)!.tuesdayShort,
      AppLocalizations.of(context)!.wednesdayShort,
      AppLocalizations.of(context)!.thursdayShort,
      AppLocalizations.of(context)!.fridayShort,
      AppLocalizations.of(context)!.saturdayShort,
      AppLocalizations.of(context)!.sundayShort,
    ];
  }

  // Menü tarihini formatlama helper metodu
  String _formatMenuDate(DateTime date, String weekday) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year} $weekday';
  }

  // Cafeteria menü verileri helper metodu
  List<List<String>> _getCafeteriaMenuData() {
    return [
      [
        'Naneli Yoğurt Çorba 171 KCAL',
        'Köfteli Izgara Patlıcan Beğendi ile 378 KCAL',
        'Soslu Piliç But 335 KCAL',
        'Sade Pirinç Pilavı 330 KCAL',
        'Soslu Spagetti 276 KCAL',
        'Kolatalı Vanilyalı Dondurma 207 KCAL',
        'Salata Bar',
        'Göbek Salata',
        'Karışık Turşu',
      ],
      [
        'Ezogelin Çorba 150 KCAL',
        'Izgara Tavuk 320 KCAL',
        'Fırın Makarna 250 KCAL',
        'Pirinç Pilavı 300 KCAL',
        'Mevsim Salata',
        'Ayran',
      ],
      [
        'Mercimek Çorba 140 KCAL',
        'Etli Türlü 350 KCAL',
        'Bulgur Pilavı 280 KCAL',
        'Yoğurt',
        'Çoban Salata',
      ],
      [
        'Domates Çorba 120 KCAL',
        'Karnıyarık 400 KCAL',
        'Şehriyeli Pilav 290 KCAL',
        'Cacık',
        'Mevsim Meyve',
      ],
    ];
  }
}
