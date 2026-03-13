import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/teacher_model.dart';
import '../models/group_model.dart';
import '../models/student_model.dart';

/// Service responsible for managing teacher profiles, class groups,
/// and students. Interfaces directly with the Supabase database.
class ManagementService {
  final _supabase = Supabase.instance.client;

  // Teachers
  Future<List<TeacherModel>> fetchAllTeachers() async {
    // In Supabase, usually profiles table 'id' is a foreign key to auth.users 'id'
    // To get email from Auth, we need a view or just fetching it if column exists
    // Since Table Editor shows no email column in profiles, we assume it's in auth.users
    // IMPORTANT: For regular users (anon key), you can't join auth.users directly via .select()
    // UNLESS the DB has a view or a column.
    
    // We fetch all profiles
    final response = await _supabase
        .from('profiles')
        .select()
        .inFilter('role', ['teacher', 'admin', 'sub_admin']);

    return (response as List).map((json) => TeacherModel.fromJson(json)).toList();
  }

  Future<void> createTeacherProfile(String fullName) async {
    await _supabase.from('profiles').insert({
      'full_name': fullName,
      'role': 'teacher',
      'is_registered': false,
    });
  }

  Future<void> deleteTeacherProfile(String profileId) async {
    // Delete from profiles table
    await _supabase.from('profiles').delete().eq('id', profileId);

    // If there was an auth user, we should ideally delete it too.
    // However, Supabase client's auth.admin.deleteUser requires a service_role key.
    // If we only have the anon key, we can't delete the auth user directly from the client.
    // The best practice is to use a Postgres Trigger or an Edge Function.
    // For now, we inform that the auth user might still exist if not handled by DB.
  }

  // Groups
  Future<List<GroupModel>> fetchClassGroups() async {
    final response = await _supabase
        .from('class_groups')
        .select('*, profiles(full_name)');
    return (response as List).map((json) => GroupModel.fromJson(json)).toList();
  }

  Future<void> createClassGroup(String name, String teacherId) async {
    await _supabase.from('class_groups').insert({
      'name': name,
      'teacher_id': teacherId,
    });
  }

  Future<void> deleteClassGroup(String id) async {
    await _supabase.from('class_groups').delete().eq('id', id);
  }

  // Students
  Future<List<StudentModel>> fetchStudentsByGroup(String groupId) async {
    final response = await _supabase
        .from('students')
        .select()
        .eq('group_id', groupId);
    return (response as List)
        .map((json) => StudentModel.fromJson(json))
        .toList();
  }

  Future<void> addStudent(String name, String groupId) async {
    await _supabase.from('students').insert({
      'full_name': name,
      'group_id': groupId,
    });
  }

  Future<void> addStudents(List<String> names, String groupId) async {
    final rows = names
        .map((name) => {'full_name': name, 'group_id': groupId})
        .toList();

    await _supabase.from('students').insert(rows);
  }

  Future<void> deleteStudent(String id) async {
    await _supabase.from('students').delete().eq('id', id);
  }
}
