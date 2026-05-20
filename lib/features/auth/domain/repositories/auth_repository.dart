import 'package:btl/features/auth/domain/entities/auth_session.dart';

abstract class AuthRepository {
  Future<AuthSession> login({
    required String email,
    required String password,
    bool rememberMe = true,
  });

  Future<AuthSession> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<AuthSession> updateProfile({
    String? displayName,
    String? avatarUrl,
  });

  Future<void> sendPasswordResetEmail({
    required String email,
  });

  Future<AuthSession?> getSession();

  Future<void> clearSession();
}

