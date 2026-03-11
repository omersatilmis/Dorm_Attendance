import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final _attendanceService = AttendanceService();

  // Cache for getAttendanceRecords (Date+CheckType -> Map of Student Statuses)
  final Map<String, Map<String, String>> _attendanceCache = {};

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _offlineQueueCount = 0;
  int get offlineQueueCount => _offlineQueueCount;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AttendanceProvider() {
    checkOfflineQueue();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (results.isNotEmpty && !results.contains(ConnectivityResult.none)) {
        // We got internet back
        if (_offlineQueueCount > 0) {
          syncOfflineAttendances();
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> checkOfflineQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString('offline_attendance_queue');
    if (queueStr != null) {
      final List<dynamic> queue = jsonDecode(queueStr);
      _offlineQueueCount = queue.length;
      notifyListeners();
    }
  }

  Future<void> _addToOfflineQueue(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString('offline_attendance_queue');
    List<dynamic> queue = [];
    if (queueStr != null) {
      queue = jsonDecode(queueStr);
    }

    // Filter out previously queued items for same student & checkType if desired, or just add
    queue.addAll(records);

    await prefs.setString('offline_attendance_queue', jsonEncode(queue));
    _offlineQueueCount = queue.length;
    notifyListeners();
  }

  Future<bool> syncOfflineAttendances() async {
    final prefs = await SharedPreferences.getInstance();
    final queueStr = prefs.getString('offline_attendance_queue');
    if (queueStr == null) return true;

    final List<dynamic> queue = jsonDecode(queueStr);
    if (queue.isEmpty) return true;

    _setLoading(true);
    try {
      final List<Map<String, dynamic>> records = queue
          .map((e) => e as Map<String, dynamic>)
          .toList();
      await _attendanceService.saveBatchAttendance(records);

      await prefs.remove('offline_attendance_queue');
      _offlineQueueCount = 0;
      _errorMessage = "Senkronizasyon başarılı!";
      notifyListeners();
      return true;
    } catch (e) {
      _setErrorMessage("Senkronizasyon başarısız, tekrar denenecek.");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveAttendance({
    required String studentId,
    required String groupId,
    required String status,
  }) async {
    _setLoading(true);
    try {
      await _attendanceService.saveAttendance(
        studentId: studentId,
        groupId: groupId,
        status: status,
      );
      _attendanceCache.clear(); // Invalidate cache on new save
      return true;
    } catch (e) {
      final record = {
        'student_id': studentId,
        'group_id': groupId,
        'status': status,
        'attendance_date': DateTime.now().toIso8601String().split('T')[0],
        'check_type':
            'morning', // default if missing, though typically not hitting this alone
      };
      await _addToOfflineQueue([record]);
      _setErrorMessage("Çevrimdışı kaydedildi (Senkronizasyon bekliyor)");
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveBatchAttendance(List<Map<String, dynamic>> records) async {
    if (records.isEmpty) return true;
    _setLoading(true);
    try {
      await _attendanceService.saveBatchAttendance(records);
      _attendanceCache.clear(); // Invalidate cache on new save
      return true;
    } catch (e) {
      debugPrint("Toplu yoklama kaydetme hatası: $e");
      await _addToOfflineQueue(records);
      _setErrorMessage("Çevrimdışı kaydedildi (Senkronizasyon bekliyor)");
      return true;
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, String>> getAttendanceRecords({
    required DateTime date,
    required String checkType,
  }) async {
    final dateStr = date.toIso8601String().split('T')[0];
    final cacheKey = "${dateStr}_${checkType.toLowerCase()}";

    // Return cached data if exist, avoiding network request
    if (_attendanceCache.containsKey(cacheKey)) {
      return Map<String, String>.from(_attendanceCache[cacheKey]!);
    }

    _setLoading(true);
    try {
      final records = await _attendanceService.fetchAttendanceRecords(
        dateStr: dateStr,
        checkType: checkType.toLowerCase(),
      );

      final Map<String, String> statusMap = {};
      for (var record in records) {
        final studentId = record['student_id'] as String;
        final status = record['status'] as String;
        // Map db status to UI status (e.g. 'present' -> 'PRESENT')
        if (status == 'present') {
          statusMap[studentId] = 'PRESENT';
        } else if (status == 'excused') {
          statusMap[studentId] = 'EXCUSED';
        } else if (status == 'absent') {
          statusMap[studentId] = 'ABSENT';
        }
      }

      // Save it to cache before returning
      _attendanceCache[cacheKey] = statusMap;
      return statusMap;
    } catch (e) {
      _setErrorMessage("Yoklama kayıtları alınamadı.");
      return {};
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, String>> getAttendanceRecordIds({
    required DateTime date,
    required String checkType,
  }) async {
    try {
      final dateStr = date.toIso8601String().split('T')[0];
      final records = await _attendanceService.fetchAttendanceRecords(
        dateStr: dateStr,
        checkType: checkType.toLowerCase(),
      );

      final Map<String, String> idMap = {};
      for (var record in records) {
        final studentId = record['student_id'] as String;
        final recordId = record['id'] as String;
        idMap[studentId] = recordId;
      }
      return idMap;
    } catch (e) {
      return {};
    }
  }

  void _setLoading(bool value) {
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

  // --- PERFORMANCE LOGIC ---
  Future<List<Map<String, dynamic>>> loadAllPerformanceData(
    List<dynamic> groups,
  ) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    // ALL TIME -> from 2000 to 2100
    const startAll = '2000-01-01';
    const endAll = '2100-01-01';

    final sWeek = startOfWeek.toIso8601String().split('T')[0];
    final eWeek = now
        .add(const Duration(days: 1))
        .toIso8601String()
        .split('T')[0];

    final sMonth = startOfMonth.toIso8601String().split('T')[0];
    final eMonth = DateTime(
      now.year,
      now.month + 1,
      0,
    ).toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> finalData = [];

    for (var group in groups) {
      final groupId = group.id;

      // Parallell execution for speed
      final results = await Future.wait([
        _attendanceService.fetchStudentPerformance(
          groupId: groupId,
          startDate: sWeek,
          endDate: eWeek,
        ),
        _attendanceService.fetchStudentPerformance(
          groupId: groupId,
          startDate: sMonth,
          endDate: eMonth,
        ),
        _attendanceService.fetchStudentPerformance(
          groupId: groupId,
          startDate: startAll,
          endDate: endAll,
        ),
      ]);

      final weeklyList = results[0];
      final monthlyList = results[1];
      final allList = results[2];

      // Merge by studentId
      final studentMap = <String, Map<String, dynamic>>{};

      for (var row in allList) {
        final id = row['student_id'];
        studentMap[id] = {
          'id': id,
          'name': row['student_name'],
          'all': (row['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
          'weekly': 0.0,
          'monthly': 0.0,
        };
      }

      for (var row in weeklyList) {
        final id = row['student_id'];
        if (studentMap.containsKey(id)) {
          studentMap[id]!['weekly'] =
              (row['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
        }
      }

      for (var row in monthlyList) {
        final id = row['student_id'];
        if (studentMap.containsKey(id)) {
          studentMap[id]!['monthly'] =
              (row['attendance_percentage'] as num?)?.toDouble() ?? 0.0;
        }
      }

      // Convert map to sorted list by name
      final studentStats = studentMap.values.toList()
        ..sort((a, b) => a['name'].compareTo(b['name']));

      finalData.add({'group': group, 'students': studentStats});
    }

    return finalData;
  }
}
