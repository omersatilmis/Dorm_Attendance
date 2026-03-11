import 'package:flutter/material.dart';
import 'package:yurt_yoklama/core/theme/app_colors.dart';

/// Modern seçim alanı widget'ı.
/// Tıklanınca alttan açılan liste (bottom sheet) gösterir.
class SelectField<T> extends StatelessWidget {
  final String label;
  final String? selectedText;
  final IconData prefixIcon;
  final List<SelectFieldItem<T>> items;
  final ValueChanged<T> onSelected;

  const SelectField({
    super.key,
    required this.label,
    required this.prefixIcon,
    required this.items,
    required this.onSelected,
    this.selectedText,
  });

  void _showSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.45,
        ),
        decoration: const BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkTextSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Icon(prefixIcon, color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.darkTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.darkSurfaceContainer),
            // Items
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = item.label == selectedText;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onSelected(item.value);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : Colors.transparent,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.label,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.darkTextPrimary,
                                fontSize: 15,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSelectionSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.darkSurfaceContainer,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selectedText != null
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              prefixIcon,
              color: selectedText != null
                  ? AppColors.primary
                  : AppColors.darkTextSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedText ?? label,
                style: TextStyle(
                  color: selectedText != null
                      ? AppColors.darkTextPrimary
                      : AppColors.darkTextSecondary,
                  fontSize: 15,
                ),
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.darkTextSecondary.withValues(alpha: 0.6),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class SelectFieldItem<T> {
  final T value;
  final String label;

  const SelectFieldItem({required this.value, required this.label});
}
