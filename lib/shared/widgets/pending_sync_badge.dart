import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_typography.dart';

/// Penanda bahwa data sudah tersimpan di HP tetapi belum terkirim ke server.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key, this.label = 'Menunggu dikirim'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.statusWarningBg,
        borderRadius: AppShapes.roundedFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Symbols.cloud_upload,
            size: 12,
            color: AppColors.statusWarningText,
          ),
          const SizedBox(width: 4),
          // Flexible agar badge tidak meluber bila ruangnya sempit
          Flexible(
            child: Text(
              label,
              style: AppTypography.labelCaps(
                color: AppColors.statusWarningText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
