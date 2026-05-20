import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:btl/features/auth/domain/entities/auth_session.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _rememberMeKey = 'auth_remember_me';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  DatabaseReference get _usersRef => _database.ref('users');
  DatabaseReference get _profilesRef => _database.ref('profiles');
  DatabaseReference get _sessionsRef => _database.ref('sessions');

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Dang nhap that bai');
    }

    final user = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
    final String token = firebaseUser.uid;
    await _saveUserToFirebase(user, isNewSession: false);
    await _saveSession(token, user, rememberMe: rememberMe);
    return AuthSession(token: token, user: user);
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      throw Exception('Dang ky that bai');
    }

    await firebaseUser.updateDisplayName(displayName);
    await firebaseUser.reload();

    final now = DateTime.now().toUtc().toIso8601String();
    final user = AppUser(
      id: firebaseUser.uid,
      email: email,
      displayName: displayName,
      role: 'student',
      createdAt: now,
      updatedAt: now,
    );

    final String token = firebaseUser.uid;
    await _saveUserToFirebase(user, isNewSession: true);

    // Gửi thông báo chào mừng realtime
    await _database.ref('notifications/${user.id}').push().set({
      'title': 'Chào mừng bạn mới! 👋',
      'body': 'Chào mừng $displayName đã tham gia cộng đồng học tập. Hãy khám phá các khóa học thú vị ngay nhé!',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'isRead': false,
      'type': 'announcement',
    });

    await _saveSession(token, user, rememberMe: true);
    return AuthSession(token: token, user: user);
  }

  @override
  Future<AuthSession> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) {
      throw Exception('Chua dang nhap');
    }

    final normalizedName = displayName?.trim();
    if (normalizedName != null && normalizedName.isNotEmpty) {
      await firebaseUser.updateDisplayName(normalizedName);
      await firebaseUser.reload();
    }

    final existing = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
    final now = DateTime.now().toUtc().toIso8601String();
    final updated = existing.copyWith(
      displayName: (normalizedName != null && normalizedName.isNotEmpty)
          ? normalizedName
          : existing.displayName,
      avatarUrl: avatarUrl ?? existing.avatarUrl,
      updatedAt: now,
    );

    await _saveUserToFirebase(updated, isNewSession: false);
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? true;
    await _saveSession(firebaseUser.uid, updated, rememberMe: rememberMe);
    
    return AuthSession(token: firebaseUser.uid, user: updated);
  }

  Future<void> _saveSession(
    String token,
    AppUser user, {
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);
    if (rememberMe) {
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
    } else {
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
    }
  }

  Future<AppUser> _loadOrCreateUser(User firebaseUser, {required String fallbackRole}) async {
    final snapshot = await _usersRef.child(firebaseUser.uid).get();
    if (snapshot.exists && snapshot.value != null) {
      final data = _asMap(snapshot.value);
      return AppUser.fromJson(data);
    }

    final now = DateTime.now().toUtc().toIso8601String();
    return AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
      role: fallbackRole,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _saveUserToFirebase(
    AppUser user, {
    required bool isNewSession,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final payload = user.copyWith(updatedAt: now).toJson();

    // 🔧 Dùng .update() để không xóa enrolledCourses
    await _usersRef.child(user.id).update(payload);
    await _profilesRef.child(user.id).set({
      'userId': user.id,
      'displayName': user.displayName,
      'avatarUrl': user.avatarUrl,
      'bio': user.bio,
      'updatedAt': now,
    });
    await _sessionsRef.child(user.id).update({
      'userId': user.id,
      'email': user.email,
      'role': user.role,
      'isActive': true,
      'provider': 'firebase_auth',
      'lastSeenAt': now,
      if (isNewSession) 'lastLoginAt': now,
    });
  }

  Map<String, dynamic> _asMap(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, dynamic item) => MapEntry(key.toString(), item));
    }

    return <String, dynamic>{};
  }

  @override
  Future<AuthSession?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? true;

    final firebaseUser = _auth.currentUser;

    // Nếu không chọn ghi nhớ, và đây là lần nạp lại (firebaseUser null hoặc không có token lưu trữ)
    // thì xóa session. Nhưng nếu đang đăng nhập (firebaseUser != null) thì vẫn giữ lại session.
    if (!rememberMe) {
      final hasLocalToken = prefs.containsKey(_tokenKey);
      if (!hasLocalToken && firebaseUser == null) {
        return null;
      }
      
      // Nếu có firebaseUser nhưng không ghi nhớ, ta vẫn trả về session hiện tại
      if (firebaseUser != null) {
        final user = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
        return AuthSession(token: firebaseUser.uid, user: user);
      }
      return null;
    }

    if (firebaseUser != null) {
      final String token = firebaseUser.uid;
      final user = await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
      await _saveUserToFirebase(user, isNewSession: false);
      await _saveSession(token, user, rememberMe: true);
      return AuthSession(token: token, user: user);
    }

    // Firebase Realtime Database rules rely on auth token, so local-only
    // cached session is not enough to keep app requests working.
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    return null;
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    final normalized = email.trim();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw Exception('Vui lòng nhập email hợp lệ');
    }
    await _auth.sendPasswordResetEmail(email: normalized);
  }

  @override
  Future<void> clearSession() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      await _sessionsRef.child(firebaseUser.uid).update({
        'isActive': false,
        'lastSeenAt': DateTime.now().toUtc().toIso8601String(),
      });
    }
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_rememberMeKey);
  }

  /// Public: Lấy user mới nhất từ Firebase Auth và Realtime DB
  Future<AppUser?> fetchUserFromFirebase() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser == null) return null;
    return await _loadOrCreateUser(firebaseUser, fallbackRole: 'student');
  }
}
