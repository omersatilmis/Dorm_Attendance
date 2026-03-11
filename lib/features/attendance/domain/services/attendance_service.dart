import 'package:supabase_flutter/supabase_flutter.dart';

/// Service responsible for fetching past attendances and saving
/// new attendance records in batch for groups.
class AttendanceService {
  final _supabase = Supabase.instance.client;

  Future<void> saveAttendance({
    required String studentId,
    required String groupId,
    required String status,
  }) async {
    await _supabase.from('attendance').upsert({
      'student_id': studentId,
      'group_id': groupId,
      'status': status,
      'attendance_date': DateTime.now().toIso8601String().split('T')[0],
    });
  }

  Future<void> saveBatchAttendance(List<Map<String, dynamic>> records) async {
    await _supabase.from('attendance').upsert(records);
  }

  Future<List<Map<String, dynamic>>> fetchAttendanceRecords({
    required String dateStr,
    required String checkType,
  }) async {
    final response = await _supabase
        .from('attendance')
        .select()
        .eq('attendance_date', dateStr)
        .eq('check_type', checkType);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> fetchStudentPerformance({
    required String groupId,
    required String startDate,
    required String endDate,
  }) async {
    final response = await _supabase.rpc(
      'get_student_performance',
      params: {
        'p_group_id': groupId,
        'start_date': startDate,
        'end_date': endDate,
      },
    );
    return List<Map<String, dynamic>>.from(response);
  }
}
