class TeacherModel {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final DateTime createdAt;
  final DateTime updatedAt;

  TeacherModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TeacherModel.fromJson(Map<String, dynamic> json) {
    return TeacherModel(
      id: json['id'].toString(),
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'İsimsiz',
      role: json['role'] as String? ?? 'TEACHER',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
