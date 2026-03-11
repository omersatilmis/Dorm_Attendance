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
                        Icons.group_work,
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
                // Grup Adı Input
                TextField(
                  controller: _groupNameController,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Grup Adı',
                    hintText: 'Örn: 1-A Sınıfı',
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
                // Hoca Seçimi — Custom SelectField
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
                          if (_groupNameController.text.trim().isNotEmpty &&
                              _selectedTeacherId != null) {
                            final nav = Navigator.of(sheetContext);
                            final success = await context
                                .read<ManagementProvider>()
                                .createGroup(
                                  _groupNameController.text.trim(),
                                  _selectedTeacherId!,
                                );
                            nav.pop();
                            if (success && mounted) {
                              // Automatically refreshes via provider
                            }
                          }
                        },
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Oluştur'),
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
          '"${group.name}" silinecek.\nBu işlem geri alınamaz.',
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
                  .deleteGroup(group.id);
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
    final groups = provider.groups;
    final teachers = provider.teachers ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('Ders Grupları')),
      body: groups == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : groups.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.folder_off_outlined,
                    size: 64,
                    color: AppColors.darkTextSecondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Henüz grup oluşturulmamış',
                    style: TextStyle(
                      color: AppColors.darkTextSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      if (teachers.isNotEmpty) {
                        _showAddGroupSheet(teachers);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('İlk grubu oluştur'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final teacherName = group.teacher?.fullName ?? 'Hoca Atanmamış';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkSurfaceContainer),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withValues(alpha: 0.2),
                                AppColors.primary.withValues(alpha: 0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.group_work,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                group.name,
                                style: const TextStyle(
                                  color: AppColors.darkTextPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline,
                                    size: 14,
                                    color: AppColors.darkTextSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    teacherName,
                                    style: const TextStyle(
                                      color: AppColors.darkTextSecondary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppColors.darkTextSecondary,
                          ),
                          color: AppColors.darkSurfaceContainer,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'delete') {
                              _confirmDeleteGroup(group);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Sil',
                                    style: TextStyle(color: AppColors.error),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final p = context.read<ManagementProvider>();
          if ((p.teachers ?? []).isNotEmpty) {
            _showAddGroupSheet(p.teachers!);
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Grup Oluştur'),
      ),
    );
  }
}
