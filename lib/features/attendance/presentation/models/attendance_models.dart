import 'package:flutter/material.dart';
import 'package:yurt_yoklama/features/management/domain/models/group_model.dart';

class StudentAttendanceModel {
  final String id;
  final String fullName;
  final ValueNotifier<String> statusNotifier;

  StudentAttendanceModel({
    required this.id,
    required this.fullName,
    String initialStatus = 'UNSET',
  }) : statusNotifier = ValueNotifier<String>(initialStatus);

  String get status => statusNotifier.value;
  set status(String value) => statusNotifier.value = value;

  void dispose() {
    statusNotifier.dispose();
  }
}

class GroupAttendanceModel {
  final GroupModel group;
  final List<StudentAttendanceModel> students;

  GroupAttendanceModel({required this.group, required this.students});

  void dispose() {
    for (var s in students) {
      s.dispose();
    }
  }
}

class StudentPerformanceModel {
  final String studentId;
  final String studentName;
  final int totalClasses;
  final int presentCount;
  final double attendancePercentage;

  StudentPerformanceModel({
    required this.studentId,
    required this.studentName,
    required this.totalClasses,
    required this.presentCount,
    required this.attendancePercentage,
  });

  factory StudentPerformanceModel.fromJson(Map<String, dynamic> json) {
    return StudentPerformanceModel(
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String,
      totalClasses: (json['total_classes'] as num?)?.toInt() ?? 0,
      presentCount: (json['present_count'] as num?)?.toInt() ?? 0,
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
