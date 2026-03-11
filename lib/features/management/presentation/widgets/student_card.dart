import 'package:flutter/material.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/features/management/domain/models/student_model.dart';

class StudentCard extends StatelessWidget {
  final StudentModel student;
  final VoidCallback onDelete;

  const StudentCard({super.key, required this.student, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkSurfaceContainer),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.person_outline,
            color: AppColors.primary,
            size: 22,
          ),
        ),
        title: Text(
          student.fullName,
          style: const TextStyle(
            color: AppColors.darkTextPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.darkTextSecondary),
          color: AppColors.darkSurfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) {
            if (value == 'delete') {
              onDelete();
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                  SizedBox(width: 10),
                  Text('Sil', style: TextStyle(color: AppColors.error)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
