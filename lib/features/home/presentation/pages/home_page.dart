import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:btl/features/auth/presentation/controllers/auth_controller.dart';
import 'package:btl/features/auth/presentation/pages/login_page.dart';
import 'package:btl/features/learning/domain/entities/course.dart';
import 'package:btl/features/learning/data/repositories/learning_repository.dart';
import 'package:btl/features/learning/presentation/theme/course_visuals.dart';
import 'package:btl/features/quiz/data/repositories/quiz_repository.dart';
import 'package:btl/features/home/presentation/pages/contact_page.dart';
import 'package:btl/features/home/presentation/pages/introduction_page.dart';
import 'package:btl/features/home/presentation/pages/policy_page.dart';
import 'package:btl/features/courses/presentation/pages/my_courses_page.dart';
import 'package:btl/features/learning/presentation/pages/lesson_list_page.dart';
import 'package:btl/features/profile/presentation/pages/profile_page.dart';
import 'package:btl/features/quiz/presentation/pages/exercises_page.dart';
import 'package:btl/features/home/presentation/pages/history_page.dart';
import 'package:btl/features/home/presentation/pages/ranking_page.dart';
import 'package:btl/features/notifications/presentation/pages/notification_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    this.learningRepository,
    this.quizRepository,
  });

  static const String routeName = '/home';
  final AuthController controller;
  final LearningRepository? learningRepository;
  final QuizRepository? quizRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  String? _initialSearchQuery;

  late AnimationController _bannerController;
  late Animation<double> _bannerAnimation;

  late final LearningRepository _learningRepository =
      widget.learningRepository ?? LearningRepository();

  @override
  void initState() {
    super.initState();
    _bannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _bannerAnimation = CurvedAnimation(
      parent: _bannerController,
      curve: Curves.easeOutBack,
    );
    _bannerController.forward();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _bannerController.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  /// Get first character of displayName, default to 'H' if empty
  String _getFirstCharacter(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return 'H';
    }
    return displayName.trim()[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;

    // Prepare avatar image (supports both Base64 data URL and remote URL)
    ImageProvider? avatarImage;
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      if (user.avatarUrl!.startsWith('data:image')) {
        try {
          final base64Data = user.avatarUrl!.split(',').last;
          avatarImage = MemoryImage(base64Decode(base64Data));
        } catch (_) {}
      } else {
        avatarImage = NetworkImage(user.avatarUrl!);
      }
    }

    return Theme(
      data: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      child: Scaffold(
        drawer: _buildModernDrawer(context, user, avatarImage: avatarImage),
        body: _selectedIndex == 0
            ? _HomeContent(
          controller: widget.controller,
          learningRepository: _learningRepository,
          quizRepository: widget.quizRepository,
          isDarkMode: _isDarkMode,
          bannerAnimation: _bannerAnimation,
          onSearch: (query) {
            setState(() {
              _initialSearchQuery = query;
              _selectedIndex = 1;
            });
          },
        )
                : CourseCatalogPage(
                    userId: widget.controller.currentUser?.id ?? '',
                    initialQuery: _initialSearchQuery,
                  ),
        bottomNavigationBar: _buildModernBottomNav(),
      ),
    );
  }

  // ==================== DRAWER ====================
  Widget _buildModernDrawer(BuildContext context, dynamic user, {ImageProvider? avatarImage}) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
            ),
            accountName: Text(
              user?.displayName ?? "Học viên",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: CircleAvatar(
              radius: 28,
              backgroundColor: Colors.white,
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? Text(
                      _getFirstCharacter(user?.displayName),
                      style: const TextStyle(fontSize: 32, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
          _drawerItem(Icons.person_outline_rounded, 'Trang cá nhân', () => _navigateTo(context, ProfilePage(controller: widget.controller))),
          _drawerItem(Icons.history_rounded, 'Lịch sử học', () => _navigateTo(context, const HistoryPage())),
          _drawerItem(Icons.assignment_rounded, 'Kiểm tra', () => _navigateTo(context, ExercisesPage(controller: widget.controller))),
          _drawerItem(Icons.leaderboard_rounded, 'Xếp hạng', () => _navigateTo(context, const RankingPage())),
          _drawerItem(Icons.policy_outlined, 'Chính sách', () => _navigateToNamed(context, PolicyPage.routeName)),
          _drawerItem(Icons.info_outline_rounded, 'Giới thiệu', () => _navigateToNamed(context, IntroductionPage.routeName)),
          _drawerItem(Icons.contact_mail_outlined, 'Liên hệ', () => _navigateToNamed(context, ContactPage.routeName)),
          const Spacer(),
          SwitchListTile(
            title: const Text('Chế độ tối'),
            value: _isDarkMode,
            onChanged: (v) => setState(() => _isDarkMode = v),
          ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            onTap: () async {
              await widget.controller.logout();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, LoginPage.routeName);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.indigo),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _navigateToNamed(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }

  Widget _buildModernBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (i) => setState(() => _selectedIndex = i),
      selectedItemColor: Colors.indigo,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      elevation: 12,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded, size: 28), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.school_rounded, size: 28), label: 'Khóa học'),
      ],
    );
  }
}

// ==================== NỘI DUNG TRANG CHỦ ====================
class _HomeContent extends StatefulWidget {
  const _HomeContent({
    required this.controller,
    required this.learningRepository,
    this.quizRepository,
    required this.isDarkMode,
    required this.bannerAnimation,
    required this.onSearch,
  });

  final AuthController controller;
  final LearningRepository learningRepository;
  final QuizRepository? quizRepository;
  final bool isDarkMode;
  final Animation<double> bannerAnimation;
  final Function(String) onSearch;

  @override
  State<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<_HomeContent> {
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Chào buổi sáng';
    if (hour < 18) return 'Chào buổi chiều';
    return 'Chào buổi tối';
  }

  String _getFirstChar(String? displayName) {
    if (displayName == null || displayName.trim().isEmpty) {
      return 'H';
    }
    return displayName.trim()[0].toUpperCase();
  }

  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.controller.currentUser;

    // Prepare avatar image for header (supports Base64 or remote URL)
    ImageProvider? avatarImage;
    if (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) {
      if (user.avatarUrl!.startsWith('data:image')) {
        try {
          final base64Data = user.avatarUrl!.split(',').last;
          avatarImage = MemoryImage(base64Decode(base64Data));
        } catch (_) {}
      } else {
        avatarImage = NetworkImage(user.avatarUrl!);
      }
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          stretch: true,
          backgroundColor: const Color(0xFF6366F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
            background: Stack(
              children: [
                // Layer 1: Base Gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF6366F1), Color(0xFF818CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                // Layer 2: Animated Decorative Circles
                Positioned(
                  top: -40,
                  right: -30,
                  child: _buildDecorativeCircle(160, Colors.white.withOpacity(0.12)),
                ),
                Positioned(
                  bottom: 20,
                  left: -20,
                  child: _buildDecorativeCircle(100, Colors.white.withOpacity(0.08)),
                ),
                // Layer 3: Main Content
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                    child: Row(
                      children: [
                        // Avatar with Glow & Ring
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, spreadRadius: 2),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.white,
                            backgroundImage: avatarImage,
                            child: avatarImage == null
                                ? Text(
                                    _getFirstChar(user?.displayName),
                                    style: const TextStyle(fontSize: 32, color: Color(0xFF4F46E5), fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Text with Shadow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getGreeting(),
                                style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "${user?.displayName ?? 'Học viên'}! 👋",
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                  shadows: [Shadow(color: Colors.black26, offset: Offset(0, 2), blurRadius: 4)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            StreamBuilder(
              stream: FirebaseDatabase.instance.ref('notifications/${user?.id}').onValue,
              builder: (context, snapshot) {
                bool hasUnread = false;
                if (snapshot.hasData && snapshot.data?.snapshot.value != null) {
                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  hasUnread = data.values.any((e) => (e as Map)['isRead'] == false);
                }

                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                      onPressed: () {
                        if (user?.id != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NotificationPage(userId: user?.id ?? ''),
                            ),
                          );
                        }
                      },
                    ),
                    if (hasUnread)
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),

        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () {
              // Bấm vào bất cứ nơi nào sẽ unfocus keyboard
              _searchFocusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        _searchFocusNode.unfocus();
                        widget.onSearch(value.trim());
                      }
                    },
                    onEditingComplete: () {
                      _searchFocusNode.unfocus();
                    },
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm khóa học...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: () {
                          if (_searchController.text.trim().isNotEmpty) {
                            _searchFocusNode.unfocus();
                            widget.onSearch(_searchController.text.trim());
                          }
                        },
                      ),
                      filled: true,
                      fillColor: widget.isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Banner
                  FadeTransition(
                    opacity: widget.bannerAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(widget.bannerAnimation),
                      child: _buildFeaturedBanner(widget.isDarkMode),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Text("Tiếp tục học", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  _HomeEnrolledCoursesPreview(
                    controller: widget.controller,
                    learningRepository: widget.learningRepository,
                    quizRepository: widget.quizRepository,
                    isDarkMode: widget.isDarkMode,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedBanner(bool isDarkMode) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED), Color(0xFF06B6D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.4), blurRadius: 30, offset: const Offset(0, 15))],
      ),
      child: Stack(
        children: [
          // Particle Effect
          Positioned.fill(
            child: Opacity(
              opacity: 0.2,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                itemCount: 20,
                itemBuilder: (_, i) => TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0.6, end: 1.0),
                  duration: Duration(milliseconds: 600 + (i % 8) * 80),
                  builder: (_, value, __) => Transform.scale(
                    scale: value,
                    child: Icon(Icons.code_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.whatshot_rounded, color: Colors.white, size: 17),
                      SizedBox(width: 7),
                      Text("2026 • NEXT GEN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Làm chủ công nghệ tương lai",
                      style: TextStyle(fontSize: 26, height: 1.15, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Học lập trình cơ bản ",
                      style: TextStyle(fontSize: 15, color: Colors.white70, height: 1.3),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Bắt đầu học",
                        style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== ENROLLED COURSES PREVIEW ====================
class _HomeEnrolledCoursesPreview extends StatefulWidget {
  const _HomeEnrolledCoursesPreview({
    required this.controller,
    required this.learningRepository,
    this.quizRepository,
    required this.isDarkMode,
  });

  final AuthController controller;
  final LearningRepository learningRepository;
  final QuizRepository? quizRepository;
  final bool isDarkMode;

  @override
  State<_HomeEnrolledCoursesPreview> createState() => _HomeEnrolledCoursesPreviewState();
}

class _HomeEnrolledCoursesPreviewState extends State<_HomeEnrolledCoursesPreview> {
  late final Future<List<Course>> _enrolledCoursesFuture;
  FirebaseDatabase? get _database => Firebase.apps.isEmpty ? null : FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _enrolledCoursesFuture = _loadEnrolledCourses();
  }

  Future<List<Course>> _loadEnrolledCourses() async {
    final uid = widget.controller.currentUser?.id;
    final database = _database;
    if (uid == null || database == null) {
      debugPrint('❌ [HOME] No user logged in');
      return [];
    }

    debugPrint('🏠 [HOME] Loading enrolled courses for user: $uid');

    try {
      final userSnap = await database.ref('users/$uid').get();
      debugPrint('🏠 [HOME] User snapshot exists: ${userSnap.exists}');

      final enrolled = <String>[];

      if (userSnap.exists) {
        final data = userSnap.value as Map?;
        debugPrint('🏠 [HOME] User data: $data');

        if (data != null && data.containsKey('enrolledCourses')) {
          final raw = data['enrolledCourses'];
          debugPrint('🏠 [HOME] enrolledCourses value: $raw');
          debugPrint('🏠 [HOME] enrolledCourses type: ${raw.runtimeType}');

          if (raw is Map) {
            enrolled.addAll(raw.keys.map((k) => k.toString()));
            debugPrint('🏠 [HOME] Found ${enrolled.length} courses (Map type)');
          } else if (raw is List) {
            enrolled.addAll(raw.map((e) => e.toString()));
            debugPrint('🏠 [HOME] Found ${enrolled.length} courses (List type)');
          }
        } else {
          debugPrint('⚠️ [HOME] No enrolledCourses field');
        }
      } else {
        debugPrint('⚠️ [HOME] User data not found');
      }

      if (enrolled.isEmpty) {
        debugPrint('⚠️ [HOME] No enrolled courses');
        return [];
      }

      final coursesSnap = await database.ref('courses').get();
      debugPrint('🏠 [HOME] Courses snapshot exists: ${coursesSnap.exists}');

      final courses = <Course>[];

      if (coursesSnap.exists && coursesSnap.value is Map) {
        final all = Map<String, dynamic>.from(coursesSnap.value as Map);
        debugPrint('🏠 [HOME] Total courses in DB: ${all.length}');

        for (final id in enrolled) {
          if (all.containsKey(id)) {
            final c = Map<String, dynamic>.from(all[id] as Map);
            courses.add(Course(
              id: id,
              title: c['title'] ?? '',
              description: c['desc'] ?? '',
              level: c['level'] ?? '',
              comprehensiveQuizId: c['finalQuiz'],
            ));
            debugPrint('✅ [HOME] Added course: $id - ${c['title']}');
          } else {
            debugPrint('⚠️ [HOME] Course not found in DB: $id');
          }
        }
      }

      debugPrint('🏠 [HOME] Final loaded courses: ${courses.length}');
      return courses;
    } catch (e) {
      debugPrint('❌ [HOME] Error loading courses: $e');
      debugPrint('❌ [HOME] Error type: ${e.runtimeType}');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Course>>(
      future: _enrolledCoursesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        final courses = snapshot.data ?? [];
        if (courses.isEmpty) {
          return _buildEmptyState(context);
        }

        return SizedBox(
          height: 280,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: courses.length,
            itemBuilder: (context, index) => _CourseCard(
              course: courses[index],
              isDarkMode: widget.isDarkMode,
              controller: widget.controller,
              learningRepository: widget.learningRepository,
              quizRepository: widget.quizRepository,
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerLoading() {
    return SizedBox(
      height: 260,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        itemBuilder: (_, __) => Container(
          width: 205,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_stories_outlined, size: 60, color: Colors.indigo[400]),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bắt đầu hành trình nào!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bạn chưa tham gia khóa học nào. Hãy khám phá kho tàng kiến thức của EduCode ngay.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Tìm đến State của HomePage để đổi index sang 1 (Course Catalog)
              final homeState = context.findAncestorStateOfType<_HomePageState>();
              if (homeState != null) {
                homeState.setState(() {
                  homeState._selectedIndex = 1;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('KHÁM PHÁ NGAY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ==================== COURSE CARD ====================
class _CourseCard extends StatefulWidget {
  const _CourseCard({
    required this.course,
    required this.isDarkMode,
    required this.controller,
    required this.learningRepository,
    this.quizRepository,
  });

  final Course course;
  final bool isDarkMode;
  final AuthController controller;
  final LearningRepository learningRepository;
  final QuizRepository? quizRepository;

  @override
  State<_CourseCard> createState() => _CourseCardState();
}

class _CourseCardState extends State<_CourseCard> {
  late Future<double> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  Future<double> _loadProgress() async {
    try {
      final userId = widget.controller.currentUser?.id;
      if (userId == null) return 0.0;
      return await widget.learningRepository.getCourseProgress(widget.course.id, userId);
    } catch (e) {
      debugPrint('❌ Error loading progress: $e');
      return 0.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final courseStyle = courseVisualStyleFor(widget.course.id);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LessonListPage(
              controller: widget.controller,
              course: widget.course,
              learningRepository: widget.learningRepository,
              quizRepository: widget.quizRepository,
            ),
          ),
        );

        if (!mounted) {
          return;
        }

        setState(() {
          _progressFuture = _loadProgress();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 220,
        margin: const EdgeInsets.only(right: 18, bottom: 10),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: widget.isDarkMode ? Colors.black45 : Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: Container(
                    height: 125,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.isDarkMode
                            ? courseStyle.gradient.map((color) => color.withOpacity(0.85)).toList()
                            : courseStyle.gradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        courseStyle.icon,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                     widget.course.title,
                     maxLines: 1,
                     overflow: TextOverflow.ellipsis,
                     style: TextStyle(
                       fontWeight: FontWeight.bold,
                       fontSize: 16,
                       color: widget.isDarkMode ? Colors.white : Colors.black87,
                     ),
                   ),
                  const SizedBox(height: 6),
                   Text(
                     widget.course.level.toUpperCase(),
                     style: TextStyle(
                       fontSize: 11,
                        color: courseStyle.primary,
                       fontWeight: FontWeight.w800,
                       letterSpacing: 0.5,
                     ),
                   ),
                  const SizedBox(height: 16),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tiến độ",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                      FutureBuilder<double>(
                        future: _progressFuture,
                        builder: (context, snapshot) {
                          final progress = snapshot.data ?? 0.0;
                          return Text(
                            '${progress.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12, 
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54, 
                              fontWeight: FontWeight.bold
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: FutureBuilder<double>(
                      future: _progressFuture,
                      builder: (context, snapshot) {
                        final progress = (snapshot.data ?? 0.0) / 100;
                        return LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: widget.isDarkMode ? Colors.white10 : Colors.grey[200],
                          color: const Color(0xFF6366F1),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



