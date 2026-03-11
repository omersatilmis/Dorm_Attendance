class StudentModel {
  final String id;
  final String fullName;
  final String groupId;
  final DateTime createdAt;

  StudentModel({
    required this.id,
    required this.fullName,
    required this.groupId,
    required this.createdAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'].toString(),
      fullName: json['full_name'] as String? ?? 'İsimsiz Öğrenci',
      groupId: json['group_id'].toString(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'group_id': groupId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
