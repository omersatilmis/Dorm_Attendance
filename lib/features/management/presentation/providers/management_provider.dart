import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/management_service.dart';
import '../../domain/models/teacher_model.dart';
import '../../domain/models/group_model.dart';
import '../../domain/models/student_model.dart';

class ManagementProvider extends ChangeNotifier {
  final _managementService = ManagementService();

  bool _isLoading = false;
  String? _errorMessage;

  List<TeacherModel>? _teachers;
  List<GroupModel>? _groups;
  final Map<String, List<StudentModel>> _groupStudents = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<TeacherModel>? get teachers => _teachers;
  List<GroupModel>? get groups => _groups;
  List<StudentModel>? getStudentsForGroup(String groupId) =>
      _groupStudents[groupId];

  // Teachers
  Future<void> loadTeachers() async {
    if (_teachers == null) {
      // First load, show indicator
      _setLoading(true);
    }
    try {
      _teachers = await _managementService.fetchAllTeachers();
      notifyListeners();
    } catch (e) {
      _setErrorMessage("Hocalar yüklenemedi.");
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  Future<bool> createTeacher(String fullName) async {
    _setLoading(true);
    try {
      await _managementService.createTeacherProfile(_capitalize(fullName));
      _teachers = null; // Invalidate cache
      await loadTeachers(); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Hoca eklenemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteTeacher(String profileId) async {
    _setLoading(true);
    try {
      await _managementService.deleteTeacherProfile(profileId);
      _teachers = null; // Invalidate cache
      await loadTeachers(); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Hoca silinemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Groups
  Future<void> loadClassGroups() async {
    if (_groups == null) {
      _setLoading(true);
    }
    try {
      _groups = await _managementService.fetchClassGroups();

      final prefs = await SharedPreferences.getInstance();
      final encodedList = _groups!.map((g) => g.toJson()).toList();
      await prefs.setString('cached_groups', jsonEncode(encodedList));

      notifyListeners();
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cachedStr = prefs.getString('cached_groups');
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        _groups = decoded.map((d) => GroupModel.fromJson(d)).toList();
        clearError();
        notifyListeners();
        return;
      }
      _setErrorMessage("Gruplar yüklenemedi.");
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  Future<bool> createGroup(String name, String teacherId) async {
    _setLoading(true);
    try {
      await _managementService.createClassGroup(name, teacherId);
      _groups = null; // Invalidate cache
      await loadClassGroups(); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Grup oluşturulamadı.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteGroup(String groupId) async {
    _setLoading(true);
    try {
      await _managementService.deleteClassGroup(groupId);
      _groups = null; // Invalidate cache
      await loadClassGroups(); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Grup silinemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Students
  Future<void> loadStudentsForGroup(String groupId) async {
    if (!_groupStudents.containsKey(groupId)) {
      _setLoading(true);
    }
    try {
      _groupStudents[groupId] = await _managementService.fetchStudentsByGroup(
        groupId,
      );

      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_students_$groupId';
      final encodedList = _groupStudents[groupId]!
          .map((s) => s.toJson())
          .toList();
      await prefs.setString(cacheKey, jsonEncode(encodedList));

      notifyListeners();
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'cached_students_$groupId';
      final cachedStr = prefs.getString(cacheKey);
      if (cachedStr != null) {
        final List<dynamic> decoded = jsonDecode(cachedStr);
        _groupStudents[groupId] = decoded
            .map((d) => StudentModel.fromJson(d))
            .toList();
        clearError();
        notifyListeners();
        return;
      }
      _setErrorMessage("Öğrenciler yüklenemedi.");
    } finally {
      if (_isLoading) _setLoading(false);
    }
  }

  Future<bool> addStudent(String name, String groupId) async {
    _setLoading(true);
    try {
      await _managementService.addStudent(_capitalize(name), groupId);
      _groupStudents.remove(groupId); // Invalidate specific group cache
      await loadStudentsForGroup(groupId); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Öğrenci eklenemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> addStudents(String namesText, String groupId) async {
    final rawLines = namesText.split('\n');
    final validNames = rawLines
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) => _capitalize(line))
        .toList();

    if (validNames.isEmpty) return false;

    _setLoading(true);
    try {
      await _managementService.addStudents(validNames, groupId);
      _groupStudents.remove(groupId); // Invalidate specific group cache
      await loadStudentsForGroup(groupId); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Öğrenciler eklenemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteStudent(String studentId, String groupId) async {
    _setLoading(true);
    try {
      await _managementService.deleteStudent(studentId);
      _groupStudents.remove(groupId); // Invalidate specific group cache
      await loadStudentsForGroup(groupId); // Auto-refresh
      return true;
    } catch (e) {
      _setErrorMessage("Öğrenci silinemedi.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helpers
  String _capitalize(String text) {
    return text
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return; // Prevent unnecessary rebuilds
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
