import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/app_bottom_nav_bar.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../widgets/app_progress_bar.dart';
import '../widgets/app_status_badge.dart';
import '../widgets/app_text_field.dart';

/// Layar uji sementara untuk memeriksa seluruh komponen visual MotoCare di HP
class ComponentPreviewScreen extends StatefulWidget {
  const ComponentPreviewScreen({super.key});

  @override
  State<ComponentPreviewScreen> createState() => _ComponentPreviewScreenState();
}

class _ComponentPreviewScreenState extends State<ComponentPreviewScreen> {
  int _currentNavIndex = 0;
  final TextEditingController _odoController =
      TextEditingController(text: '14350');
  final TextEditingController _bengkelController =
      TextEditingController(text: 'Ahass Motor');

  @override
  void dispose() {
    _odoController.dispose();
    _bengkelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MotoCare UI Preview',
              style: AppTypography.headlineSm(),
            ),
            Text(
              'Pratinjau Komponen Fondasi Visual',
              style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.margin,
          vertical: AppSpacing.md,
        ),
        children: [
          // Section: Typografi & Palette Ringkas
          _buildSectionHeader('1. IDENTITAS & TIPOGRAFI'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display LG (48px)', style: AppTypography.displayLg()),
                const SizedBox(height: AppSpacing.xs),
                Text('Headline MD (22px)', style: AppTypography.headlineMd()),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('14.280', style: AppTypography.metricVal()),
                    const SizedBox(width: AppSpacing.xs),
                    Text('KM', style: AppTypography.headlineSm(color: AppColors.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Body Large: Teks deskripsi menggunakan font Inter dengan keterbacaan tinggi.',
                  style: AppTypography.bodyLg(),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section: Badge Status
          _buildSectionHeader('2. BADGE STATUS KOMPONEN'),
          AppCard(
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppStatusBadge.safe(),
                AppStatusBadge.warning(),
                AppStatusBadge.critical(),
                AppStatusBadge.safe(label: 'Masih Bagus'),
                AppStatusBadge.critical(label: 'Siapkan Ganti'),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section: Tombol (Buttons)
          _buildSectionHeader('3. TOMBOL (APP BUTTON)'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppButton(
                  text: 'Update KM Hari Ini',
                  icon: const Icon(Symbols.add_circle, size: 20, color: AppColors.onPrimary),
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  text: 'Tombol Sekunder (Outline)',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {},
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        text: 'Batal',
                        variant: AppButtonVariant.tonal,
                        height: 44,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        text: 'Simpan',
                        variant: AppButtonVariant.primary,
                        height: 44,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                const AppButton(
                  text: 'Sedang Memuat...',
                  isLoading: true,
                  onPressed: null,
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section: Kolom Input (Text Fields)
          _buildSectionHeader('4. KOLOM INPUT (APP TEXT FIELD)'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  controller: _odoController,
                  label: 'Angka Kilometer Baru (KM)',
                  suffix: Text(
                    'KM',
                    style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
                  ),
                  helperText: 'Tercatat sebelumnya: 14.280 KM',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: _bengkelController,
                  label: 'Nama Bengkel',
                  prefixIcon: const Icon(Symbols.store, color: AppColors.onSurfaceVariant),
                  hintText: 'Masukkan nama bengkel...',
                ),
                const SizedBox(height: AppSpacing.md),
                const AppTextField(
                  label: 'Kolom dengan Validasi Error',
                  hintText: 'Contoh input salah',
                  errorText: 'KM baru tidak boleh lebih kecil dari KM sebelumnya',
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section: Progress Bar & Kartu Komponen
          _buildSectionHeader('5. PROGRESS BAR & KARTU KOMPONEN'),
          _buildComponentCard(
            icon: Symbols.oil_barrel,
            title: 'Oli Mesin Matic (10W-30)',
            interval: 'Interval tiap 2.000 km',
            status: AppStatusType.critical,
            statusLabel: 'Siapkan Ganti',
            percentUsed: 0.85,
            leftText: '85% terpakai',
            rightText: 'Sisa 420 km',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildComponentCard(
            icon: Symbols.settings_slow_motion,
            title: 'Oli Transmisi / Gardan',
            interval: 'Interval tiap 8.000 km',
            status: AppStatusType.safe,
            statusLabel: 'Masih Bagus',
            percentUsed: 0.40,
            leftText: '40% terpakai',
            rightText: 'Sisa 3.720 km',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildComponentCard(
            icon: Symbols.sync,
            title: 'V-Belt Penggerak',
            interval: 'Interval tiap 20.000 km',
            status: AppStatusType.warning,
            statusLabel: 'Peringatan',
            percentUsed: 0.75,
            leftText: '75% terpakai',
            rightText: 'Sisa 5.000 km',
          ),

          const SizedBox(height: AppSpacing.lg),

          // Section: Alert Attention Banner
          _buildSectionHeader('6. BANNER PERINGATAN'),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: AppShapes.roundedDefault,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: AppColors.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.notification_important,
                    size: 20,
                    color: AppColors.onErrorContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERHATIAN SERVIS TERDEKAT',
                        style: AppTypography.labelCaps(
                          color: AppColors.onErrorContainer,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Ganti Oli Mesin dlm 420 km (~19 hari lagi)',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurface,
                        ).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs + 2),
      child: Text(
        title,
        style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
      ),
    );
  }

  Widget _buildComponentCard({
    required IconData icon,
    required String title,
    required String interval,
    required AppStatusType status,
    required String statusLabel,
    required double percentUsed,
    required String leftText,
    required String rightText,
  }) {
    Color iconBg;
    Color iconColor;

    switch (status) {
      case AppStatusType.safe:
        iconBg = AppColors.surfaceContainer;
        iconColor = AppColors.onSurfaceVariant;
        break;
      case AppStatusType.warning:
        iconBg = AppColors.statusWarningBg;
        iconColor = AppColors.statusWarningIndicator;
        break;
      case AppStatusType.critical:
        iconBg = AppColors.errorContainer;
        iconColor = AppColors.onErrorContainer;
        break;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 20,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTypography.labelMd().copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            interval,
                            style: AppTypography.bodySm(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              AppStatusBadge(
                status: status,
                customLabel: statusLabel,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppProgressBar(
            percentageUsed: percentUsed,
            status: status,
            leftLabel: leftText,
            rightLabel: rightText,
          ),
        ],
      ),
    );
  }
}
