import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/management/presentation/widgets/student_card.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/features/management/domain/models/student_model.dart';
import 'package:yurt_yoklama/core/widgets/select_field.dart';

class StudentManagementPage extends StatefulWidget {
  const StudentManagementPage({super.key});

  @override
  State<StudentManagementPage> createState() => _StudentManagementPageState();
}

class _StudentManagementPageState extends State<StudentManagementPage> {
  final _studentNameController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedGroupName;
  String? _dialogSelectedGroupId;
  String? _dialogSelectedGroupName;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagementProvider>().loadClassGroups();
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    super.dispose();
  }

  void _showAddStudentSheet() {
    _studentNameController.clear();
    _dialogSelectedGroupId = null;
    _dialogSelectedGroupName = null;
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
                            'Öğrenci Kaydı (Toplu Ekleme)',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.darkTextPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Alt alta yazarak birden fazla öğenci ekleyebilirsiniz.',
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
                // İsim Input
                TextField(
                  controller: _studentNameController,
                  style: const TextStyle(color: AppColors.darkTextPrimary),
                  minLines: 1,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Öğrenci Adı Soyadı',
                    hintText: 'Örn:\nAli Demir\nAyşe Yılmaz',
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
                const SizedBox(height: 16),
                // Grup Seçimi — Custom SelectField
                SelectField<String>(
                  label: 'Grup Seçin',
                  prefixIcon: Icons.group_work_outlined,
                  selectedText: _dialogSelectedGroupName,
                  items: context
                      .read<ManagementProvider>()
                      .groups!
                      .map((g) => SelectFieldItem(value: g.id, label: g.name))
                      .toList(),
                  onSelected: (id) {
                    final group = context
                        .read<ManagementProvider>()
                        .groups!
                        .firstWhere((g) => g.id == id);
                    setSheetState(() {
                      _dialogSelectedGroupId = id;
                      _dialogSelectedGroupName = group.name;
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
                          if (_studentNameController.text.trim().isNotEmpty &&
                              _dialogSelectedGroupId != null) {
                            final nav = Navigator.of(sheetContext);
                            final success = await context
                                .read<ManagementProvider>()
                                .addStudents(
                                  _studentNameController.text,
                                  _dialogSelectedGroupId!,
                                );
                            nav.pop();
                            if (success && mounted) {
                              // Automatically refreshes via provider
                            }
                          }
                        },
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Kaydet'),
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

  void _confirmDeleteStudent(StudentModel student) {
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
              'Öğrenci Sil',
              style: TextStyle(fontSize: 18, color: AppColors.darkTextPrimary),
            ),
          ],
        ),
        content: Text(
          '"${student.fullName}" silinecek.\nBu işlem geri alınamaz.',
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
                  .deleteStudent(student.id, _selectedGroupId!);
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
    final students = _selectedGroupId != null
        ? provider.getStudentsForGroup(_selectedGroupId!)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Öğrenci Yönetimi')),
      body: Column(
        children: [
          // Grup Seçimi — Custom SelectField
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: groups == null
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : SelectField<String>(
                    label: 'Görüntülenecek Grubu Seçin',
                    prefixIcon: Icons.group_work_outlined,
                    selectedText: _selectedGroupName,
                    items: groups
                        .map((g) => SelectFieldItem(value: g.id, label: g.name))
                        .toList(),
                    onSelected: (id) {
                      final group = groups.firstWhere((g) => g.id == id);
                      setState(() {
                        _selectedGroupId = id;
                        _selectedGroupName = group.name;
                      });
                      context.read<ManagementProvider>().loadStudentsForGroup(
                        id,
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          // Öğrenci Listesi
          Expanded(
            child: _selectedGroupId == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: AppColors.darkTextSecondary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Lütfen bir grup seçin',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : students == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : students.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.person_off_outlined,
                          size: 64,
                          color: AppColors.darkTextSecondary.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bu grupta öğrenci yok',
                          style: TextStyle(
                            color: AppColors.darkTextSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: students.length,
                    itemBuilder: (context, index) {
                      final student = students[index];
                      return StudentCard(
                        student: student,
                        onDelete: () => _confirmDeleteStudent(student),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final p = context.read<ManagementProvider>();
          if ((p.groups ?? []).isNotEmpty) {
            // Add sheet needs to have _cachedGroups populated, let's keep it simple
            // and maybe modify _showAddStudentSheet to read from provider if possible.
            // But wait, it doesn't even take an argument, it reads from `_cachedGroups` which I removed!
            // I need to fix `_showAddStudentSheet`
            _showAddStudentSheet();
          }
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        icon: const Icon(Icons.person_add),
        label: const Text('Öğrenci Ekle'),
      ),
    );
  }
}
