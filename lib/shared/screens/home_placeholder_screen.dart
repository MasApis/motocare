import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_button.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/providers/auth_providers.dart';

/// Layar utama sementara (placeholder) — hanya bisa dibuka setelah masuk.
/// Menampilkan pesan selamat datang dan tombol Keluar.
class HomePlaceholderScreen extends ConsumerWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final userEmail = authState.whenData((user) => user?.email).value;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo aplikasi
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/icons/app_logo.png',
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Selamat datang di MotoCare!',
                  style: AppTypography.headlineMd(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (userEmail != null)
                  Text(
                    'Masuk sebagai $userEmail',
                    style:
                        AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Layar beranda akan segera hadir.\nFitur lain sedang dikembangkan.',
                  style:
                      AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xl),
                // Tombol Keluar
                AppButton(
                  text: 'Keluar',
                  variant: AppButtonVariant.secondary,
                  icon: const Icon(
                    Symbols.logout,
                    size: 20,
                    color: AppColors.onSurface,
                  ),
                  isFullWidth: false,
                  onPressed: () async {
                    try {
                      await ref.read(authRepositoryProvider).signOut();
                    } on AuthException catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.message)),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
