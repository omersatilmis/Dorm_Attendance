import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/management/domain/models/teacher_model.dart';
import 'package:yurt_yoklama/features/management/presentation/widgets/teacher_card.dart';
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
      context.read<ManagementProvider>().loadTeachers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showAddTeacherDialog() {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
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
              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_add,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yeni Hoca Ekle',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Sisteme yeni bir hoca kaydı oluşturun',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Input
              TextField(
                controller: _nameController,
                style: const TextStyle(color: AppColors.darkTextPrimary),
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  hintText: 'Örn: Ahmet Yılmaz',
                  prefixIcon: const Icon(
                    Icons.badge_outlined,
                    color: AppColors.darkTextSecondary,
                  ),
                  filled: true,
                  fillColor: AppColors.darkSurfaceContainer,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: AppColors.darkTextSecondary.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'İptal',
                        style: TextStyle(color: AppColors.darkTextSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_nameController.text.trim().isNotEmpty) {
                          final nav = Navigator.of(sheetContext);
                          final success = await context
                              .read<ManagementProvider>()
                              .createTeacher(_nameController.text.trim());
                          nav.pop();
                          if (success && mounted) {
                            // Automatically refreshes via provider
                          }
                        }
                      },
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Ekle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.delete_outline,
                color: AppColors.error,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Hoca Sil',
              style: TextStyle(fontSize: 18, color: AppColors.darkTextPrimary),
            ),
          ],
        ),
        content: Text(
          '"${teacher.fullName}" silinecek.\nBu işlem geri alınamaz.',
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'İptal',
              style: TextStyle(color: AppColors.darkTextSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final navigator = Navigator.of(dialogContext);
              final success = await context
                  .read<ManagementProvider>()
                  .deleteTeacher(teacher.id);
              navigator.pop();
              if (success && mounted) {
                // Automatically refreshes via provider
              }
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();
    final teachers = provider.teachers;

    return Scaffold(
      appBar: AppBar(title: const Text('Hoca Yönetimi')),
      body: teachers == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : teachers.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 64,
                    color: AppColors.darkTextSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz hoca eklenmemiş',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _showAddTeacherDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('İlk hocayı ekle'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: teachers.length,
              itemBuilder: (context, index) {
                final teacher = teachers[index];
                return TeacherCard(
                  teacher: teacher,
                  onDelete: () => _confirmDeleteTeacher(teacher),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTeacherDialog,
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Hoca Ekle'),
      ),
    );
  }
}
