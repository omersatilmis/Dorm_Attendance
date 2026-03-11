import 'teacher_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String? teacherId;
  final TeacherModel? teacher;
  final DateTime createdAt;

  GroupModel({
    required this.id,
    required this.name,
    this.teacherId,
    this.teacher,
    required this.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    TeacherModel? parsedTeacher;
    if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      parsedTeacher = TeacherModel.fromJson(
        json['profiles'] as Map<String, dynamic>,
      );
    }

    return GroupModel(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'İsimsiz Grup',
      teacherId: json['teacher_id']?.toString(),
      teacher: parsedTeacher,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'teacher_id': teacherId,
      'profiles': teacher?.toJson(),
      'created_at': createdAt.toIso8601String(),
    };
  }
}
