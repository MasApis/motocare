import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../core/vehicle_components.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_bottom_nav_bar.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../auth/providers/auth_providers.dart';
import '../../vehicles/data/models/vehicle_component_model.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import 'widgets/component_health_card.dart';

/// Layar Dashboard utama dengan Carousel Kendaraan sesuai docs/SPEC.md (F2)
/// dan acuan visual docs/design/beranda_status_motor_2
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  int _currentNavIndex = 0;
  bool _isUserSwiping = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, List<Vehicle> vehicles) {
    _isUserSwiping = true;
    setState(() => _currentPageIndex = index);
    if (index >= 0 && index < vehicles.length) {
      ref.read(selectedVehicleIdProvider.notifier).select(vehicles[index].id);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _isUserSwiping = false;
    });
  }

  Future<void> _confirmDeleteVehicle(Vehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppShapes.roundedDefault,
        ),
        title: const Row(
          children: [
            Icon(Symbols.warning, color: AppColors.error),
            SizedBox(width: AppSpacing.sm),
            Expanded(child: Text('Hapus Motor?')),
          ],
        ),
        content: Text(
          'Apakah kamu yakin ingin menghapus motor "${vehicle.displayName}"? Seluruh data catatan servis dan odometer terkait akan dihapus secara permanen.',
          style: AppTypography.bodyMd(),
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(false),
            child: Text(
              'Batal',
              style: AppTypography.labelMd(color: AppColors.onSurfaceVariant),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onError,
              shape: AppShapes.shapePill,
            ),
            onPressed: () => ctx.pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(vehicleControllerProvider).deleteVehicle(vehicle.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Motor "${vehicle.displayName}" berhasil dihapus.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus motor: $e')),
        );
      }
    }
  }

  void _showSettingsMenu(BuildContext context, Vehicle? activeVehicle) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: const BoxDecoration(
                  color: AppColors.outlineVariant,
                  borderRadius: AppShapes.roundedFull,
                ),
              ),
              if (activeVehicle != null) ...[
                ListTile(
                  leading: const Icon(Symbols.edit, color: AppColors.primary),
                  title: Text(
                    'Ubah Data Motor (${activeVehicle.displayName})',
                    style: AppTypography.bodyMd(color: AppColors.onSurface),
                  ),
                  onTap: () {
                    ctx.pop();
                    context.push('/vehicles/edit/${activeVehicle.id}');
                  },
                ),
                ListTile(
                  leading: const Icon(Symbols.delete, color: AppColors.error),
                  title: Text(
                    'Hapus Motor Ini',
                    style: AppTypography.bodyMd(color: AppColors.error),
                  ),
                  onTap: () {
                    ctx.pop();
                    _confirmDeleteVehicle(activeVehicle);
                  },
                ),
                const Divider(),
              ],
              ListTile(
                leading: const Icon(Symbols.add_circle, color: AppColors.primary),
                title: Text(
                  'Tambah Motor Lain',
                  style: AppTypography.bodyMd(color: AppColors.onSurface),
                ),
                onTap: () {
                  ctx.pop();
                  context.push('/vehicles/add');
                },
              ),
              ListTile(
                leading: const Icon(Symbols.logout, color: AppColors.onSurfaceVariant),
                title: Text(
                  'Keluar dari Akun',
                  style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                ),
                onTap: () async {
                  ctx.pop();
                  try {
                    await ref.read(authRepositoryProvider).signOut();
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal keluar: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);
    final activeVehicle = ref.watch(selectedVehicleProvider);

    // Sinkronkan halaman PageView hanya jika motor dipilih secara eksternal (bukan saat user swipe)
    ref.listen<String?>(selectedVehicleIdProvider, (prev, next) {
      if (_isUserSwiping) return;
      if (next == null) return;
      final vehicles = vehiclesAsync.valueOrNull ?? [];
      final targetIndex = vehicles.indexWhere((v) => v.id == next);
      if (targetIndex != -1 &&
          targetIndex != _currentPageIndex &&
          _pageController.hasClients) {
        _pageController.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _currentPageIndex = targetIndex;
      }
    });

    return Scaffold(

      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryFixed,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.two_wheeler,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MotoCare',
                  style: AppTypography.headlineSm().copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (activeVehicle != null)
                  Text(
                    activeVehicle.displayName,
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.settings),
            tooltip: 'Pengaturan & Opsi Motor',
            onPressed: () => _showSettingsMenu(context, activeVehicle),
          ),
        ],
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return _buildEmptyState(context);
          }
          return _buildDashboardContent(context, vehicles, activeVehicle);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Gagal memuat data kendaraan: $err',
              style: AppTypography.bodyMd(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
        },
      ),
    );
  }

  /// Empty state ketika belum ada motor yang terdaftar
  Widget _buildEmptyState(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.two_wheeler,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Belum Ada Motor Terdaftar',
                style: AppTypography.headlineMd(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Daftarkan motor matik pertamamu untuk mulai memantau sisa usia oli mesin, oli gardan, dan V-belt dengan mudah.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Daftarkan Motor Pertama',
                icon: const Icon(
                  Symbols.add,
                  color: AppColors.onPrimary,
                  size: 20,
                ),
                onPressed: () => context.push('/vehicles/add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Konten Dashboard dengan Carousel Motor
  Widget _buildDashboardContent(
    BuildContext context,
    List<Vehicle> vehicles,
    Vehicle? activeVehicle,
  ) {
    return ListView(

      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        // Header Carousel & Indikator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kendaraan Kamu (${vehicles.length})',
                style: AppTypography.headlineSm(),
              ),
              TextButton.icon(
                onPressed: () => context.push('/vehicles/add'),
                icon: const Icon(Symbols.add, size: 18),
                label: const Text('Tambah Motor'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),

        // Carousel Kartu Motor (PageView)
        SizedBox(
          height: 230,
          child: PageView.builder(
            controller: _pageController,
            itemCount: vehicles.length,
            onPageChanged: (index) => _onPageChanged(index, vehicles),
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: _buildVehicleHeroCard(context, vehicle, index + 1, vehicles.length),
              );
            },
          ),
        ),

        // Dot Page Indicator
        if (vehicles.length > 1) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(vehicles.length, (idx) {
              final isSelected = idx == _currentPageIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isSelected ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.outlineVariant,
                  borderRadius: AppShapes.roundedFull,
                ),
              );
            }),
          ),
        ],

        const SizedBox(height: AppSpacing.lg),

        // Seksi Status Masa Pakai Komponen (docs/SPEC.md F3)
        if (activeVehicle != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildComponentHealthSection(context, activeVehicle),
          ),
          const SizedBox(height: AppSpacing.md),

          // Seksi DEBUG SEMENTARA: Pengubah KM untuk pengujian F3 (Akan dihapus di F4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildF3DebugKmSection(context, activeVehicle),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Section Petunjuk Fitur
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: AppCard(
            backgroundColor: AppColors.surfaceContainerLow,
            borderColor: AppColors.outlineVariant.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.swipe,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Geser Kartu Motor',
                        style: AppTypography.labelMd().copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Geser ke kiri atau kanan untuk beralih antar motor. Seluruh data dashboard akan berganti otomatis.',
                        style: AppTypography.bodySm(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Seksi tiga kartu status kesehatan komponen motor (F3)
  Widget _buildComponentHealthSection(
    BuildContext context,
    Vehicle activeVehicle,
  ) {
    final componentsAsync = ref.watch(selectedVehicleComponentsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Status Masa Pakai Komponen',
              style: AppTypography.headlineSm(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        componentsAsync.when(
          data: (components) {
            final orderedTypes = ComponentType.values; // [engine_oil, gear_oil, v_belt]
            return Column(
              children: orderedTypes.map((type) {
                final comp = components.firstWhere(
                  (c) => c.type == type,
                  orElse: () => VehicleComponent(
                    type: type,
                    intervalKm: DefaultIntervals.forType(type),
                    lastServiceKm: activeVehicle.currentKm,
                  ),
                );
                return ComponentHealthCard(
                  componentType: comp.type,
                  intervalKm: comp.intervalKm,
                  lastServiceKm: comp.lastServiceKm,
                  currentKm: activeVehicle.currentKm,
                );
              }).toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.md),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Gagal memuat status komponen: $err',
              style: AppTypography.bodySm(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }

  /// Kontrol debug sementara untuk menguji perubahan KM pada tahap F3.
  /// Membantu verifikasi status Aman, Peringatan, Batas habis, dan Lewat interval di HP asli.
  /// PERHATIAN: Bagian ini akan dihapus setelah fitur F4 (Hybrid Odometer) diimplementasikan.
  Widget _buildF3DebugKmSection(
    BuildContext context,
    Vehicle activeVehicle,
  ) {
    final componentsAsync = ref.watch(selectedVehicleComponentsProvider);
    final components = componentsAsync.value ?? [];
    final engineOil = components.where((c) => c.type == ComponentType.engineOil).firstOrNull;
    final baseKm = engineOil?.lastServiceKm ?? activeVehicle.currentKm;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryFixed,
                  borderRadius: AppShapes.roundedFull,
                ),
                child: Text(
                  'DEBUG SEMENTARA (F3)',
                  style: AppTypography.labelCaps(
                    color: AppColors.onPrimaryFixedVariant,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'KM: ${_formatKm(activeVehicle.currentKm)}',
                style: AppTypography.labelMd().copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Uji perubahan kartu kesehatan di HP (Aman / Peringatan / Batas habis / Lewat interval). Panel ini dihapus di tahap F4.',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              ActionChip(
                label: const Text('Reset 100%'),
                labelStyle: AppTypography.labelCaps(color: AppColors.primary),
                backgroundColor: AppColors.surfaceContainerLowest,
                onPressed: () => _setVehicleKm(activeVehicle, baseKm),
              ),
              ActionChip(
                label: const Text('+500 KM (Aman)'),
                labelStyle: AppTypography.labelCaps(color: AppColors.statusSafeText),
                backgroundColor: AppColors.statusSafeBg,
                onPressed: () => _setVehicleKm(activeVehicle, baseKm + 500),
              ),
              ActionChip(
                label: const Text('+1.500 KM (Kuning)'),
                labelStyle: AppTypography.labelCaps(color: AppColors.statusWarningText),
                backgroundColor: AppColors.statusWarningBg,
                onPressed: () => _setVehicleKm(activeVehicle, baseKm + 1500),
              ),
              ActionChip(
                label: const Text('+1.900 KM (Merah)'),
                labelStyle: AppTypography.labelCaps(color: AppColors.statusCriticalText),
                backgroundColor: AppColors.statusCriticalBg,
                onPressed: () => _setVehicleKm(activeVehicle, baseKm + 1900),
              ),
              ActionChip(
                label: const Text('+2.500 KM (Lewat)'),
                labelStyle: AppTypography.labelCaps(color: AppColors.statusCriticalText),
                backgroundColor: AppColors.statusCriticalBg,
                onPressed: () => _setVehicleKm(activeVehicle, baseKm + 2500),
              ),
              ActionChip(
                avatar: const Icon(Symbols.edit, size: 16, color: AppColors.primary),
                label: const Text('Ketik KM...'),
                labelStyle: AppTypography.labelCaps(color: AppColors.primary),
                backgroundColor: AppColors.surfaceContainerLowest,
                onPressed: () => _showDebugSetKmDialog(context, activeVehicle),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setVehicleKm(Vehicle vehicle, int newKm) async {
    try {
      await ref.read(vehicleControllerProvider).updateVehicle(
            vehicleId: vehicle.id,
            brand: vehicle.brand,
            model: vehicle.model,
            name: vehicle.name,
            plate: vehicle.plate,
            currentKm: newKm,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah KM: $e')),
        );
      }
    }
  }

  Future<void> _showDebugSetKmDialog(BuildContext context, Vehicle vehicle) async {
    final controller = TextEditingController(text: vehicle.currentKm.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppShapes.roundedDefault,
        ),
        title: const Text('Ubah KM Sementara (Debug F3)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Masukkan angka KM baru untuk motor "${vehicle.displayName}":',
              style: AppTypography.bodyMd(),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Kilometer',
                suffixText: 'KM',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => ctx.pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed >= 0) {
                ctx.pop(parsed);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (result != null) {
      await _setVehicleKm(vehicle, result);
    }
  }


  /// Kartu Hero Motor sesuai desain beranda_status_motor_2
  Widget _buildVehicleHeroCard(
    BuildContext context,
    Vehicle vehicle,
    int itemNumber,
    int totalItems,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: AppShapes.roundedDefault,
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Baris Atas: Label & Tombol Edit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'MOTOR $itemNumber DARI $totalItems',
                    style: AppTypography.labelCaps(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Symbols.edit,
                  size: 20,
                  color: AppColors.primary,
                ),
                tooltip: 'Ubah Data Motor',
                onPressed: () => context.push('/vehicles/edit/${vehicle.id}'),
              ),
            ],
          ),

          // Nama Motor & Plat
          Text(
            vehicle.displayName,
            style: AppTypography.headlineMd().copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            vehicle.plate != null && vehicle.plate!.isNotEmpty
                ? '${vehicle.brand} ${vehicle.model} • ${vehicle.plate}'
                : '${vehicle.brand} ${vehicle.model}',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const Spacer(),

          // Box Odometer Tercatat
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppShapes.roundedDefault,
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ODOMETER TERCATAT',
                      style: AppTypography.labelCaps(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatKm(vehicle.currentKm),
                          style: AppTypography.headlineLg().copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'KM',
                          style: AppTypography.labelMd(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryFixed,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.speed,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatKm(int km) {
    // Format sederhana ribuan menggunakan titik
    final str = km.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }
}
