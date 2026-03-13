import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yurt_yoklama/features/management/presentation/providers/management_provider.dart';
import 'package:yurt_yoklama/features/management/domain/models/student_model.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagementProvider>();
      provider.loadClassGroups();
    });
  }

  @override
  void dispose() {
    _studentNameController.dispose();
    super.dispose();
  }

  void _showAddStudentSheet() {
    _studentNameController.clear();
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
                          Icons.person_add,
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
                              'Öğrenci Kaydı (Toplu)',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkTextPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Öğrenci isimlerini alt alta yazın',
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
                  if (_selectedGroupName != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.group_work_outlined, color: AppColors.primary, size: 20),
                          const SizedBox(width: 10),
                          const Text('Grup: ', style: TextStyle(color: AppColors.darkTextSecondary)),
                          Text(_selectedGroupName!, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _studentNameController,
                    maxLines: 5,
                    style: const TextStyle(color: AppColors.darkTextPrimary),
                    decoration: InputDecoration(
                      labelText: 'Öğrenci İsimleri',
                      hintText: 'Ahmet Yılmaz\nMehmet Demir',
                      filled: true,
                      fillColor: AppColors.darkSurfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
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
                            if (_studentNameController.text.trim().isNotEmpty &&
                                _selectedGroupId != null) {
                              final nav = Navigator.of(sheetContext);
                              await context.read<ManagementProvider>().addStudents(
                                    _studentNameController.text,
                                    _selectedGroupId!,
                                  );
                              nav.pop();
                            }
                          },
                          child: const Text('Kaydet'),
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

  void _confirmDeleteStudent(StudentModel student) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Öğrenciyi Sil', style: TextStyle(color: AppColors.darkTextPrimary)),
        content: Text('${student.fullName} öğrencisini silmek istediğinize emin misiniz?',
            style: const TextStyle(color: AppColors.darkTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () async {
              final nav = Navigator.of(dialogContext);
              await context.read<ManagementProvider>().deleteStudent(student.id, _selectedGroupId!);
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
    final students = _selectedGroupId == null ? <StudentModel>[] : provider.getStudentsForGroup(_selectedGroupId!) ?? [];

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: const Text('Öğrenci Yönetimi'),
        backgroundColor: AppColors.darkBackground,
      ),
      floatingActionButton: _selectedGroupId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddStudentSheet,
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Öğrenci Ekle', style: TextStyle(color: Colors.white)),
            ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SelectField<String>(
              label: 'Grup Seçin',
              prefixIcon: Icons.group_outlined,
              selectedText: _selectedGroupName,
              items: (provider.groups ?? [])
                  .map((g) => SelectFieldItem(value: g.id, label: g.name))
                  .toList(),
              onSelected: (id) {
                setState(() {
                  _selectedGroupId = id;
                  _selectedGroupName = provider.groups!.firstWhere((g) => g.id == id).name;
                });
                provider.loadStudentsForGroup(id);
              },
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedGroupId == null
                    ? const Center(child: Text('Lütfen bir grup seçin', style: TextStyle(color: AppColors.darkTextSecondary)))
                    : students.isEmpty
                        ? const Center(child: Text('Bu grupta öğrenci yok', style: TextStyle(color: AppColors.darkTextSecondary)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: students.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final student = students[index];
                              return Card(
                                color: AppColors.darkSurface,
                                child: ListTile(
                                  title: Text(student.fullName, style: const TextStyle(color: AppColors.darkTextPrimary)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                                    onPressed: () => _confirmDeleteStudent(student),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
