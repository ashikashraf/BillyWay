import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabaseClient;
  
  @override
  final ValueNotifier<String?> currentUserRoleNotifier = ValueNotifier<String?>(null);

  SupabaseAuthRepository(this._supabaseClient) {
    // Optionally listen to auth state changes to clear role on logout
    _supabaseClient.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedOut) {
        currentUserRoleNotifier.value = null;
      }
    });
  }

  @override
  Future<AuthResponse> signIn({required String email, required String password}) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    if (response.session != null) {
      await getUserRole(); // Fetch role on login
    }
    return response;
  }

  @override
  Future<void> signOut() async {
    await _supabaseClient.auth.signOut();
  }

  @override
  Session? get currentSession => _supabaseClient.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;

  @override
  Future<String?> getUserRole() async {
    final user = _supabaseClient.auth.currentUser;
    if (user == null) {
      currentUserRoleNotifier.value = null;
      return null;
    }

    try {
      final response = await _supabaseClient
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();
      
      final role = response['role'] as String?;
      currentUserRoleNotifier.value = role;
      return role;
    } catch (e) {
      // In case of error (e.g. no profile found)
      currentUserRoleNotifier.value = null;
      return null;
    }
  }
}

