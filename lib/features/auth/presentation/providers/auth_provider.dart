import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _supabase.auth.currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Check if Admin or Assistant Admin
  bool get isAdmin => _userProfile?['role'] == 'admin';
  bool get isAssistantAdmin => _userProfile?['role'] == 'assistant_admin';
  bool get isAnyAdmin => isAdmin || isAssistantAdmin;

  // --- GET TEACHERS FOR REGISTRATION ---
  Future<List<Map<String, dynamic>>> fetchAvailableTeachers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'teacher')
          .isFilter(
            'id',
            null,
          ); // Simplified check: profiles added by admin won't have a UUID 'id' matching auth.uid yet if we use a separate field or check email

      // Note: In a real scenario, we'd check if 'auth_id' or 'id' matches a valid auth user.
      // Let's assume 'auth_id' is the field that links to Supabase Auth.
      final available = await _supabase
          .from('profiles')
          .select()
          .isFilter('auth_id', null);

      return List<Map<String, dynamic>>.from(available);
    } catch (e) {
      _setErrorMessage("Hocalar yüklenirken hata oluştu.");
      return [];
    }
  }

  // --- LOGIN WITH ROLE FETCH ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _fetchUserProfile(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setErrorMessage(e.message);
      return false;
    } catch (e) {
      _setErrorMessage("Beklenmedik bir hata oluştu.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- REGISTER BY SELECTING PROFILE ---
  Future<bool> registerWithProfile({
    required String profileId,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Supabase Auth'a kayıt at
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 2. Seçilen profile auth_id ve email ekle
        await _supabase
            .from('profiles')
            .update({'auth_id': response.user!.id, 'email': email})
            .eq(
              'profile_id',
              profileId,
            ); // assuming 'profile_id' is the primary key

        await _fetchUserProfile(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setErrorMessage(e.message);
      return false;
    } catch (e) {
      _setErrorMessage("Kayıt sırasında bir hata oluştu.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchUserProfile(String authId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('auth_id', authId)
          .single();
      _userProfile = data;
      notifyListeners();
    } catch (e) {
      _setErrorMessage("Profil bilgileri alınamadı.");
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  // Helper Methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() => _errorMessage = null;

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
