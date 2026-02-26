import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  final _nameController = TextEditingController();

  void _showAddTeacherDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Hoca Ekle'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Hocanın Adı Soyadı',
            hintText: 'Ad Soyad',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_nameController.text.isNotEmpty) {
                final success = await context
                    .read<AuthProvider>()
                    .createTeacherProfile(_nameController.text.trim());
                if (success && mounted) {
                  _nameController.clear();
                  if (Navigator.canPop(context)) Navigator.pop(context);
                  setState(() {}); // Refresh list
                }
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hoca Yönetimi')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<AuthProvider>().fetchAllTeachers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final teachers = snapshot.data ?? [];
          if (teachers.isEmpty) {
            return const Center(child: Text('Henüz hoca eklenmemiş.'));
          }
          return ListView.builder(
            itemCount: teachers.length,
            itemBuilder: (context, index) {
              final teacher = teachers[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(teacher['full_name']),
                subtitle: Text(
                  teacher['is_registered'] ? 'Kayıtlı' : 'Bekliyor',
                ),
                trailing: Icon(
                  teacher['is_registered'] ? Icons.check_circle : Icons.pending,
                  color: teacher['is_registered']
                      ? Colors.green
                      : Colors.orange,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTeacherDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final _groupNameController = TextEditingController();
  String? _selectedTeacherId;

  void _showAddGroupDialog(List<Map<String, dynamic>> teachers) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Grup Oluştur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groupNameController,
                decoration: const InputDecoration(labelText: 'Grup Adı'),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: _selectedTeacherId,
                isExpanded: true,
                hint: const Text('Hoca Seçin'),
                items: teachers.map((t) {
                  return DropdownMenuItem(
                    value: t['id'].toString(),
                    child: Text(t['full_name']),
                  );
                }).toList(),
                onChanged: (val) =>
                    setDialogState(() => _selectedTeacherId = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_groupNameController.text.isNotEmpty &&
                    _selectedTeacherId != null) {
                  final success = await context
                      .read<AuthProvider>()
                      .createClassGroup(
                        _groupNameController.text.trim(),
                        _selectedTeacherId!,
                      );
                  if (success && mounted) {
                    _groupNameController.clear();
                    _selectedTeacherId = null;
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ders Grupları')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: auth.fetchClassGroups(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final groups = snapshot.data ?? [];
          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final teacherName =
                  group['profiles']?['full_name'] ?? 'Hoca Atanmamış';
              return ListTile(
                title: Text(group['name']),
                subtitle: Text('Hoca: $teacherName'),
                trailing: const Icon(Icons.edit_outlined),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final teachers = await auth.fetchAllTeachers();
          if (mounted) _showAddGroupDialog(teachers);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final _studentNameController = TextEditingController();
  Map<String, dynamic>? _selectedGroup;

  void _showAddStudentDialog(List<Map<String, dynamic>> groups) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Öğrenci Kaydı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _studentNameController,
                decoration: const InputDecoration(
                  labelText: 'Öğrenci Adı Soyadı',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButton<Map<String, dynamic>>(
                value: _selectedGroup,
                isExpanded: true,
                hint: const Text('Grup Seçin'),
                items: groups.map((g) {
                  return DropdownMenuItem(value: g, child: Text(g['name']));
                }).toList(),
                onChanged: (val) => setDialogState(() => _selectedGroup = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_studentNameController.text.isNotEmpty &&
                    _selectedGroup != null) {
                  final success = await context.read<AuthProvider>().addStudent(
                    _studentNameController.text.trim(),
                    _selectedGroup!['id'],
                  );
                  if (success && mounted) {
                    _studentNameController.clear();
                    Navigator.pop(context);
                    setState(() {});
                  }
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Öğrenci Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: auth.fetchClassGroups(),
              builder: (context, snapshot) {
                final groups = snapshot.data ?? [];
                return DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  hint: const Text('Görüntülenecek Grubu Seçin'),
                  value: _selectedGroup,
                  items: groups
                      .map(
                        (g) =>
                            DropdownMenuItem(value: g, child: Text(g['name'])),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _selectedGroup = val),
                );
              },
            ),
          ),
          Expanded(
            child: _selectedGroup == null
                ? const Center(child: Text('Lütfen bir grup seçin'))
                : FutureBuilder<List<Map<String, dynamic>>>(
                    future: auth.fetchStudentsByGroup(_selectedGroup!['id']),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final students = snapshot.data ?? [];
                      if (students.isEmpty) {
                        return const Center(
                          child: Text('Bu grupta öğrenci yok.'),
                        );
                      }
                      return ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) => ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(students[index]['full_name']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final groups = await auth.fetchClassGroups();
          if (mounted) _showAddStudentDialog(groups);
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
