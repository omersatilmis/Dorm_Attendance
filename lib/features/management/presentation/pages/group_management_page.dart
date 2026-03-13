import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/management/domain/models/teacher_model.dart';
import 'package:yurt_yoklama/features/management/domain/models/group_model.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/core/widgets/select_field.dart';

class GroupManagementPage extends StatefulWidget {
  const GroupManagementPage({super.key});

  @override
  State<GroupManagementPage> createState() => _GroupManagementPageState();
}

class _GroupManagementPageState extends State<GroupManagementPage> {
  final _groupNameController = TextEditingController();
  String? _selectedTeacherId;
  String? _selectedTeacherName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagementProvider>();
      provider.loadClassGroups();
      provider.loadTeachers();
    });
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  void _showAddGroupSheet(List<TeacherModel> teachers) {
    _groupNameController.clear();
    _selectedTeacherId = null;
    _selectedTeacherName = null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.group_work,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yeni Grup Oluştur',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Ders grubu oluştur ve hoca atayın',
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
                  TextField(
                    controller: _groupNameController,
                    style: const TextStyle(color: AppColors.darkTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'Grup Adı',
                      hintText: 'Örn: Tekamül Altı',
                      prefixIcon: const Icon(
                        Icons.class_outlined,
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
                  const SizedBox(height: 16),
                  SelectField<String>(
                    label: 'Hoca Seçin',
                    prefixIcon: Icons.person_outline,
                    selectedText: _selectedTeacherName,
                    items: teachers
                        .map(
                          (t) => SelectFieldItem(value: t.id, label: t.fullName),
                        )
                        .toList(),
                    onSelected: (id) {
                      final teacher = teachers.firstWhere((t) => t.id == id);
                      setSheetState(() {
                        _selectedTeacherId = id;
                        _selectedTeacherName = teacher.fullName;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
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
                            if (_groupNameController.text.trim().isNotEmpty &&
                                _selectedTeacherId != null) {
                              final nav = Navigator.of(sheetContext);
                              await context
                                  .read<ManagementProvider>()
                                  .createGroup(
                                    _groupNameController.text.trim(),
                                    _selectedTeacherId!,
                                  );
                              nav.pop();
                            }
                          },
                          icon: const Icon(Icons.check, size: 20),
                          label: const Text('Oluştur'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
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
        ),
      ),
    );
  }

  void _confirmDeleteGroup(GroupModel group) {
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
              'Grubu Sil',
              style: TextStyle(fontSize: 18, color: AppColors.darkTextPrimary),
            ),
          ],
        ),
        content: Text(
          '${group.name} grubunu silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: const TextStyle(color: AppColors.darkTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal',
                style: TextStyle(color: AppColors.darkTextSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(dialogContext);
              await context.read<ManagementProvider>().deleteGroup(group.id);
              nav.pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagementProvider>();
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Grup Yönetimi'),
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGroupSheet(provider.teachers ?? []),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Yeni Grup', style: TextStyle(color: Colors.white)),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : (provider.groups ?? []).isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.group_off_outlined,
                          size: 64, color: AppColors.darkTextSecondary),
                      const SizedBox(height: 16),
                      const Text('Henüz grup oluşturulmamış',
                          style: TextStyle(color: AppColors.darkTextSecondary)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.groups!.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final group = provider.groups![index];
                    return Card(
                      color: AppColors.darkSurface,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.class_, color: AppColors.primary),
                        ),
                        title: Text(group.name,
                            style: const TextStyle(
                                color: AppColors.darkTextPrimary,
                                fontWeight: FontWeight.bold)),
                        subtitle: Text('Hoca: ${group.teacher?.fullName ?? 'Bilinmiyor'}',
                            style: const TextStyle(
                                color: AppColors.darkTextSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: AppColors.error),
                          onPressed: () => _confirmDeleteGroup(group),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
