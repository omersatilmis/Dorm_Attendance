import 'package:flutter/material.dart';
import '../../domain/services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final _attendanceService = AttendanceService();

  // Cache for getAttendanceRecords (Date+CheckType -> Map of Student Statuses)
  final Map<String, Map<String, String>> _attendanceCache = {};

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
      _setErrorMessage("Yoklama kaydedilemedi.");
      return false;
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
      _setErrorMessage("Toplu yoklama kaydedilemedi.");
      return false;
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
