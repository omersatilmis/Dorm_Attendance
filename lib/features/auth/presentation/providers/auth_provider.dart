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

  // Role Checks
  bool get isAdmin => _userProfile?['role'] == 'admin';
  bool get isSubAdmin => _userProfile?['role'] == 'sub_admin';
  bool get isAnyAdmin => isAdmin || isSubAdmin;

  // --- FETCH AVAILABLE PROFILES FOR REGISTRATION ---
  Future<List<Map<String, dynamic>>> fetchAvailableProfiles() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('is_registered', false); // Kayıt olmamış hocaları çek

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _setErrorMessage("Profiller yüklenirken hata oluştu.");
      return [];
    }
  }

  // --- LOGIN ---
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

  // --- REGISTER (CLAIM PROFILE) ---
  Future<bool> registerWithProfile({
    required String profileId,
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // 1. Supabase Auth Kaydı
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        // 2. Profile tablosunu güncelle
        await _supabase
            .from('profiles')
            .update({'auth_id': response.user!.id, 'is_registered': true})
            .eq('id', profileId);

        await _fetchUserProfile(response.user!.id);
        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setErrorMessage(e.message);
      return false;
    } catch (e) {
      _setErrorMessage("Kayıt hatası oluştu.");
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
      _setErrorMessage("Profil yüklenemedi.");
    }
  }

  // --- LOGOUT ---
  Future<void> logout() async {
    await _supabase.auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  // --- MANAGEMENT: TEACHERS ---
  Future<List<Map<String, dynamic>>> fetchAllTeachers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'teacher');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<bool> createTeacherProfile(String fullName) async {
    try {
      await _supabase.from('profiles').insert({
        'full_name': fullName,
        'role': 'teacher',
        'is_registered': false,
      });
      return true;
    } catch (e) {
      _setErrorMessage("Hoca eklenemedi.");
      return false;
    }
  }

  // --- MANAGEMENT: CLASS GROUPS ---
  Future<List<Map<String, dynamic>>> fetchClassGroups() async {
    try {
      // Teacher bilgisi ile birlikte çekelim
      final response = await _supabase
          .from('class_groups')
          .select('*, profiles(full_name)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<bool> createClassGroup(String name, String teacherId) async {
    try {
      await _supabase.from('class_groups').insert({
        'name': name,
        'teacher_id': teacherId,
      });
      return true;
    } catch (e) {
      _setErrorMessage("Grup oluşturulamadı.");
      return false;
    }
  }

  // --- MANAGEMENT: STUDENTS ---
  Future<List<Map<String, dynamic>>> fetchStudentsByGroup(
    String groupId,
  ) async {
    try {
      final response = await _supabase
          .from('students')
          .select()
          .eq('group_id', groupId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<bool> addStudent(String name, String groupId) async {
    try {
      await _supabase.from('students').insert({
        'full_name': name,
        'group_id': groupId,
      });
      return true;
    } catch (e) {
      _setErrorMessage("Öğrenci eklenemedi.");
      return false;
    }
  }

  // --- ATTENDANCE ---
  Future<bool> saveAttendance({
    required String studentId,
    required String groupId,
    required String status,
  }) async {
    try {
      await _supabase.from('attendance').upsert({
        'student_id': studentId,
        'group_id': groupId,
        'status': status,
        'attendance_date': DateTime.now().toIso8601String().split('T')[0],
      });
      return true;
    } catch (e) {
      _setErrorMessage("Yoklama kaydedilemedi.");
      return false;
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
