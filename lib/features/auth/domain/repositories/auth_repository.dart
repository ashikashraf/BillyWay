import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  /// Sign out the current user
  Future<void> signOut();

  /// Get the current session
  Session? get currentSession;

  /// Stream of auth state changes
  Stream<AuthState> get authStateChanges;

  /// ValueNotifier that holds the current user's role
  ValueNotifier<String?> get currentUserRoleNotifier;

  /// Get the current user's role from the profiles table and update the notifier
  Future<String?> getUserRole();
}
