import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/management/domain/models/teacher_model.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';

class TeacherManagementPage extends StatefulWidget {
  const TeacherManagementPage({super.key});

  @override
  State<TeacherManagementPage> createState() => _TeacherManagementPageState();
}

class _TeacherManagementPageState extends State<TeacherManagementPage> {
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagementProvider>();
      provider.loadTeachers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddTeacherSheet() {
    _nameController.clear();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.darkTextSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Yeni Hoca Ekle',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkTextPrimary)),
                const SizedBox(height: 24),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Ad Soyad',
                    filled: true,
                    fillColor: AppColors.darkSurfaceContainer,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_nameController.text.trim().isNotEmpty) {
                            final nav = Navigator.of(sheetContext);
                            await context
                                .read<ManagementProvider>()
                                .createTeacher(_nameController.text.trim());
                            nav.pop();
                          }
                        },
                        child: const Text('Ekle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDeleteTeacher(TeacherModel teacher) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Hocayı Sil',
            style: TextStyle(color: AppColors.darkTextPrimary)),
        content: Text(
            '${teacher.fullName} hocasını ve bağlı profilini silmek istediğinize emin misiniz?',
            style: const TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(dialogContext);
              await context.read<ManagementProvider>().deleteTeacher(teacher.id);
              nav.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();
    final teachers = provider.teachers ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Hoca Yönetimi'),
        backgroundColor: AppColors.darkBackground,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeacherSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Hoca Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : teachers.isEmpty
              ? const Center(
                  child: Text('Henüz hoca eklenmemiş',
                      style: TextStyle(color: AppColors.darkTextSecondary)))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return Card(
                      color: AppColors.darkSurface,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: Colors.blue),
                        ),
                        title: Text(teacher.fullName,
                            style: const TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text(
                            (teacher.email.isNotEmpty &&
                                    teacher.email.toLowerCase() != 'null' &&
                                    teacher.email.contains('@'))
                                ? 'Kayıtlı'
                                : 'Kayıtsız',
                            style: TextStyle(
                                color: (teacher.email.isNotEmpty &&
                                        teacher.email.toLowerCase() != 'null' &&
                                        teacher.email.contains('@'))
                                    ? Colors.green
                                    : AppColors.error)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () => _confirmDeleteTeacher(teacher),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
