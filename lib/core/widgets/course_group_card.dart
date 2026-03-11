import 'package:flutter/material.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';
import 'package:yurt_yoklama/core/widgets/student_card.dart';
import 'package:yurt_yoklama/features/attendance/presentation/models/attendance_models.dart';

class CourseGroupCard extends StatefulWidget {
  final GroupAttendanceModel groupData;
  final bool isReadOnly;
  final Map<String, String>? readOnlyStatusMap;

  const CourseGroupCard({
    super.key,
    required this.groupData,
    this.isReadOnly = false,
    this.readOnlyStatusMap,
  });

  @override
  State<CourseGroupCard> createState() => _CourseGroupCardState();
}

class _CourseGroupCardState extends State<CourseGroupCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animController;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animController.forward();
      } else {
        _animController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkSurfaceContainer),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — tıklanabilir
          InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.class_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.groupData.group.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.darkTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.groupData.group.teacher?.fullName ??
                              'Hoca Bilgisi Yok',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.darkTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Öğrenci sayısı badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.groupData.students.length} kişi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Expand/Collapse icon
                  RotationTransition(
                    turns: _rotationAnim,
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.darkTextSecondary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expandable student list
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: _isExpanded
                ? Column(
                    children: [
                      const Divider(
                        height: 1,
                        color: AppColors.darkSurfaceContainer,
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 400),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
                          itemCount: widget.groupData.students.length,
                          itemBuilder: (context, index) {
                            final studentModel =
                                widget.groupData.students[index];
                            final status =
                                widget.readOnlyStatusMap?[studentModel.id];
                            return StudentCard(
                              index: index,
                              student: studentModel,
                              isReadOnly: widget.isReadOnly,
                              readOnlyStatus: status,
                            );
                          },
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}
