import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';

import 'package:yurt_yoklama/features/attendance/presentation/models/attendance_models.dart';

class StudentCard extends StatelessWidget {
  final int index;
  final StudentAttendanceModel student;
  final bool isReadOnly;
  final String? readOnlyStatus;

  const StudentCard({
    super.key,
    required this.index,
    required this.student,
    this.isReadOnly = false,
    this.readOnlyStatus,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceContainer.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ValueListenableBuilder<String>(
          valueListenable: student.statusNotifier,
          builder: (context, currentStatus, _) {
            final displayStatus = isReadOnly
                ? (readOnlyStatus ?? 'UNSET')
                : currentStatus;

            return Row(
              children: [
                Text(
                  "${index + 1}.",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.darkTextSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    student.fullName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.darkTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 6),

                // VAR BUTONU (PRESENT)
                _buildChip(
                  icon: Icons.check_rounded,
                  isSelected: displayStatus == 'PRESENT',
                  activeColor: AppColors.greenPresent,
                  onTap: () => student.status = 'PRESENT',
                ),
                const SizedBox(width: 6),

                // YOK BUTONU (ABSENT)
                _buildChip(
                  icon: Icons.close_rounded,
                  isSelected: displayStatus == 'ABSENT',
                  activeColor: AppColors.redAbsent,
                  onTap: () => student.status = 'ABSENT',
                ),
                const SizedBox(width: 6),

                // İZİNLİ BUTONU (EXCUSED)
                _buildChip(
                  icon: Icons.circle_outlined,
                  isSelected: displayStatus == 'EXCUSED',
                  activeColor: AppColors.amberExcused,
                  onTap: () => student.status = 'EXCUSED',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChip({
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: isReadOnly
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap();
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 30,
        width: 36, // Sabit genişlik ile daha düzenli durur
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.9)
              : activeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : activeColor,
        ),
      ),
    );
  }
}
