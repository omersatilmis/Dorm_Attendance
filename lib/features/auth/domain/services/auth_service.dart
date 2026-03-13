import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for user authentication, registration,
/// and fetching user profiles. Wraps Supabase Auth and database operations.
class AuthService {
  final _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>> fetchProfile(String authId) async {
    return await _supabase
        .from('profiles')
        .select()
        .eq('auth_id', authId)
        .single();
  }

  Future<List<Map<String, dynamic>>> fetchAvailableProfiles() async {
    final response = await _supabase
        .from('profiles')
        .select()
        .eq('is_registered', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> claimProfile(String profileId, String authId, String email) async {
    await _supabase.from('profiles').update({
      'auth_id': authId,
      'is_registered': true,
      'email': email,
    }).eq('id', profileId);
  }

  Future<void> updateProfileName(String authId, String newName) async {
    await _supabase
        .from('profiles')
        .update({'full_name': newName})
        .eq('auth_id', authId);
  }
}
