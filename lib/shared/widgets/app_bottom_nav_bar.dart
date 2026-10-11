import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Item navigasi untuk [AppBottomNavBar]
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.filledIcon,
  });

  final IconData icon;
  final String label;
  final IconData? filledIcon;
}

/// Navigasi bawah 5 tab sesuai docs/design/SCREENS.md dan docs/design/beranda_status_motor_2/
class AppBottomNavBar extends StatelessWidget {
  const AppBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<AppBottomNavItem> items;

  /// Daftar 5 tab standar sesuai peta layar SCREENS.md
  static const List<AppBottomNavItem> defaultItems = [
    AppBottomNavItem(
      icon: Symbols.home,
      label: 'Beranda',
    ),
    AppBottomNavItem(
      icon: Symbols.edit_note,
      label: 'Catat',
    ),
    AppBottomNavItem(
      icon: Symbols.menu_book,
      label: 'Servis',
    ),
    AppBottomNavItem(
      icon: Symbols.smart_toy,
      label: 'Chat AI',
    ),
    AppBottomNavItem(
      icon: Symbols.history,
      label: 'Riwayat',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.borderSlate,
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SizedBox(
        height: 68.0,
        child: Row(
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isSelected = index == currentIndex;
            final color = isSelected ? AppColors.primary : AppColors.onSurfaceVariant;

            return Expanded(
              child: InkWell(
                onTap: () => onTap(index),
                splashColor: AppColors.primaryFixed.withValues(alpha: 0.3),
                highlightColor: Colors.transparent,
                child: SizedBox(
                  height: double.infinity,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isSelected && item.filledIcon != null
                            ? item.filledIcon
                            : item.icon,
                        size: 24.0,
                        color: color,
                        fill: isSelected ? 1.0 : 0.0,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.label,
                        style: AppTypography.labelCaps(color: color).copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
