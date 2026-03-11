import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _userProfile;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;

  // Role Checks
  bool get isAdmin => _userProfile?['role'] == 'admin';
  bool get isSubAdmin => _userProfile?['role'] == 'sub_admin';
  bool get isAnyAdmin => isAdmin || isSubAdmin;

  // --- SESSION RESTORE ---
  Future<void> tryRestoreSession() async {
    final user = _authService.currentUser;
    if (user != null) {
      await _fetchUserProfile(user.id);
    } else {
      // Offline fallback
      final prefs = await SharedPreferences.getInstance();
      final cachedProfile = prefs.getString('cached_user_profile');
      if (cachedProfile != null) {
        _userProfile = jsonDecode(cachedProfile);
        notifyListeners();
      }
    }
  }

  // --- FETCH AVAILABLE PROFILES FOR REGISTRATION ---
  Future<List<Map<String, dynamic>>> fetchAvailableProfiles() async {
    try {
      return await _authService.fetchAvailableProfiles();
    } catch (e) {
      debugPrint('❌ fetchAvailableProfiles hatası: $e');
      _setErrorMessage("Profiller yüklenirken hata oluştu.");
      return [];
    }
  }

  // --- LOGIN ---
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signIn(email, password);

      if (response.user != null) {
        await _fetchUserProfile(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setErrorMessage(e.message);
      return false;
    } catch (e) {
      debugPrint('❌ login hatası: $e');
      _setErrorMessage("Beklenmedik bir hata oluştu.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // --- REGISTER (CLAIM PROFILE) ---
  Future<bool> registerWithProfile({
    required String profileId,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signUp(email, password);

      if (response.user != null) {
        await _authService.claimProfile(profileId, response.user!.id);
        await _fetchUserProfile(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setErrorMessage(e.message);
      return false;
    } catch (e) {
      debugPrint('❌ register hatası: $e');
      _setErrorMessage("Kayıt hatası oluştu.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchUserProfile(String authId) async {
    try {
      _userProfile = await _authService.fetchProfile(authId);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', jsonEncode(_userProfile));
      notifyListeners();
    } catch (e) {
      debugPrint('❌ _fetchUserProfile hatası: $e');

      // Offline / Error fallback
      final prefs = await SharedPreferences.getInstance();
      final cachedProfile = prefs.getString('cached_user_profile');
      if (cachedProfile != null) {
        _userProfile = jsonDecode(cachedProfile);
        _clearError(); // Don't show error if we have cached data
        notifyListeners();
        return;
      }

      _setErrorMessage("Profil yüklenemedi.");
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _authService.signOut();
    _userProfile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cached_user_profile');
    notifyListeners();
  }

  // --- UPDATE PROFILE ---
  Future<bool> updateProfileName(String newName) async {
    final user = _authService.currentUser;
    if (user == null) return false;

    _setLoading(true);
    try {
      await _authService.updateProfileName(user.id, newName);
      // Reload profile to get updated data
      await _fetchUserProfile(user.id);
      return true;
    } catch (e) {
      debugPrint('❌ updateProfileName hatası: $e');
      _setErrorMessage("Profil güncellenemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
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
