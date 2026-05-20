import 'package:flutter/foundation.dart';

import 'package:btl/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:btl/features/auth/domain/entities/auth_session.dart';
import 'package:btl/features/auth/domain/entities/app_user.dart';
import 'package:btl/features/auth/domain/repositories/auth_repository.dart';

class AuthController extends ChangeNotifier {
  AuthController({AuthRepository? repository}) : _repository = repository ?? AuthRepositoryImpl();

  final AuthRepository _repository;

  AppUser? currentUser;
  String? token;
  bool isLoading = false;
  String? error;

  bool get isLoggedIn => currentUser != null && token != null;

  Future<void> loadSession() async {
    final AuthSession? session = await _repository.getSession();
    if (session != null) {
      token = session.token;
      currentUser = session.user;
      notifyListeners();
    }
  }

  Future<void> login(
    String email,
    String password, {
    bool rememberMe = true,
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await _repository.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      token = session.token;
      currentUser = session.user;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String displayName) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await _repository.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      token = session.token;
      currentUser = session.user;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> updateDisplayName(String displayName) async {
    if (token == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await _repository.updateProfile(displayName: displayName);
      token = session.token;
      currentUser = session.user;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    if (token == null) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final session = await _repository.updateProfile(avatarUrl: avatarUrl);
      token = session.token;
      currentUser = session.user;
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUserFromFirebase() async {
    if (currentUser == null) return;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      if (_repository is AuthRepositoryImpl) {
        final user = await _repository.fetchUserFromFirebase();
        if (user != null) currentUser = user;
      }
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _repository.clearSession();
    token = null;
    currentUser = null;
    error = null;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await _repository.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      error = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
