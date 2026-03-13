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
    // Supabase Auth Join case: if json['user'] exists, take email from there
    String authEmail = '';
    if (json['user_data'] != null && json['user_data'] is Map) {
      authEmail = (json['user_data']['email'] ?? '').toString();
    } else if (json['user'] != null && json['user'] is Map) {
      authEmail = (json['user']['email'] ?? '').toString();
    }

    return TeacherModel(
      id: json['id'].toString(),
      email: authEmail.isNotEmpty 
          ? authEmail 
          : (json['email'] ?? json['email_address'] ?? '').toString(),
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
