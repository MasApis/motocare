import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../../../core/service_calculator.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../data/models/service_record_model.dart';
import '../providers/service_providers.dart';
import 'service_form_screen.dart';

/// Layar Riwayat Servis Keseluruhan
/// Mengacu pada docs/design/riwayat_servis_keseluruhan/ dan docs/SPEC.md (F5 revisi v2.2)
class ServiceHistoryScreen extends ConsumerWidget {
  const ServiceHistoryScreen({super.key});

  Future<void> _confirmDeleteRecord(
    BuildContext context,
    WidgetRef ref,
    ServiceRecord record,
    List<Vehicle> vehicles,
  ) async {
    final vehicle = vehicles.where((v) => v.id == record.vehicleId).firstOrNull;
    final vehicleName = vehicle?.displayName ?? 'Motor';

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
            Expanded(child: Text('Hapus Catatan Servis?')),
          ],
        ),
        content: Text(
          'Catatan servis (${record.formattedDate} • ${record.itemsSummary}) pada $vehicleName akan dihapus. Kartu komponen akan kembali menghitung sisa masa pakai dari servis sebelumnya atau baseline awal.',
          style: AppTypography.bodyMd(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
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
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref
          .read(serviceControllerProvider.notifier)
          .deleteServiceRecord(
            vehicleId: record.vehicleId,
            recordId: record.id,
          );

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Catatan servis dihapus. Perhitungan kartu disesuaikan.'),
            ),
          );
        } else {
          final error = ref.read(serviceControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Gagal menghapus catatan.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesStreamProvider);
    final vehicles = vehiclesAsync.asData?.value ?? [];
    final selectedFilterVehicleId = ref.watch(serviceFilterVehicleIdProvider);
    final recordsAsync = ref.watch(filteredServiceRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riwayat Servis',
              style: AppTypography.headlineSm().copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'Log pemeliharaan & penggantian suku cadang',
              style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Chip Pilihan Motor
            if (vehicles.length > 1) ...[
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: FilterChip(
                        selected: selectedFilterVehicleId == null,
                        label: const Text('Semua Motor'),
                        onSelected: (_) {
                          ref.read(serviceFilterVehicleIdProvider.notifier).select(null);
                        },
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          color: selectedFilterVehicleId == null
                              ? AppColors.onPrimary
                              : AppColors.onSurface,
                          fontWeight: selectedFilterVehicleId == null
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                        backgroundColor: AppColors.surfaceContainerLow,
                        shape: AppShapes.shapePill,
                      ),
                    ),
                    ...vehicles.map((v) {
                      final isSelected = selectedFilterVehicleId == v.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(v.displayName),
                          onSelected: (_) {
                            ref.read(serviceFilterVehicleIdProvider.notifier).select(v.id);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          ),
                          backgroundColor: AppColors.surfaceContainerLow,
                          shape: AppShapes.shapePill,
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.borderSlate),
            ],

            // Konten Riwayat (Realtime Stream)
            Expanded(
              child: recordsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Symbols.error, size: 48, color: AppColors.error),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Gagal memuat riwayat servis',
                          style: AppTypography.headlineSm(),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          error.toString(),
                          style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return _buildEmptyState(context, ref, vehicles);
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(filteredServiceRecordsProvider);
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: records.length,
                      itemBuilder: (context, index) {
                        final record = records[index];
                        final isLast = index == records.length - 1;
                        final vehicle =
                            vehicles.where((v) => v.id == record.vehicleId).firstOrNull;

                        return _buildTimelineItem(
                          context: context,
                          ref: ref,
                          record: record,
                          vehicle: vehicle,
                          vehicles: vehicles,
                          isLast: isLast,
                        );
                      },
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

  Widget _buildEmptyState(
    BuildContext context,
    WidgetRef ref,
    List<Vehicle> vehicles,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.history,
                size: 36,
                color: AppColors.outline,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum Ada Riwayat Servis',
              style: AppTypography.headlineSm(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Catat servis berkala Anda agar pemakaian suku cadang dan total pengeluaran terpantau rapi.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            if (vehicles.isNotEmpty)
              AppButton(
                text: 'Catat Servis Sekarang',
                icon: const Icon(Symbols.add, size: 20, color: AppColors.onPrimary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (ctx) => const ServiceFormScreen(),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required WidgetRef ref,
    required ServiceRecord record,
    required Vehicle? vehicle,
    required List<Vehicle> vehicles,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Garis Linimasa & Node Bulat
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.surfaceContainerHighest,
                    ),
                  ),
              ],
            ),
          ),

          // Kartu Informasi Servis
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: AppShapes.roundedDefault,
                border: Border.all(color: AppColors.borderSlate),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x06000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Kartu: Tanggal + KM + Harga
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  record.formattedDate,
                                  style: AppTypography.labelCaps(
                                    color: AppColors.primary,
                                  ).copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                    color: AppColors.outlineVariant,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  record.formattedKm,
                                  style: AppTypography.labelCaps(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            if (vehicle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                vehicle.displayName,
                                style: AppTypography.labelCaps(
                                  color: AppColors.outline,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Text(
                        record.formattedPrice,
                        style: AppTypography.headlineSm().copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Daftar Items Servis (SPEC F5: label diganti / dibersihkan)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: record.items.map((item) {
                      final isCleaned = item.action == ServiceItemAction.cleaned;
                      final isComponent = item.kind == ServiceItemKind.component;

                      Color bgColor;
                      Color textColor;

                      if (isCleaned) {
                        bgColor = AppColors.tertiaryFixed.withValues(alpha: 0.5);
                        textColor = AppColors.tertiary;
                      } else if (isComponent) {
                        bgColor = AppColors.primaryFixed;
                        textColor = AppColors.primary;
                      } else {
                        bgColor = AppColors.surfaceContainerHigh;
                        textColor = AppColors.onSurface;
                      }

                      final brandText =
                          (item.brand != null && item.brand!.isNotEmpty) ? ' • ${item.brand}' : '';

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: AppShapes.roundedFull,
                        ),
                        child: Text(
                          '${item.displayName} (${item.actionLabel}$brandText)',
                          style: AppTypography.labelCaps(color: textColor).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 8),

                  // Lokasi / Bengkel
                  Row(
                    children: [
                      const Icon(
                        Symbols.storefront,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.location,
                          style: AppTypography.bodySm(
                            color: AppColors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Catatan Mekanik jika ada
                  if (record.note != null && record.note!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Symbols.notes,
                            size: 16,
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            record.note!,
                            style: AppTypography.bodySm(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xs),

                  // Tombol Aksi Hapus (SPEC F5: dengan konfirmasi)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _confirmDeleteRecord(
                        context,
                        ref,
                        record,
                        vehicles,
                      ),
                      icon: const Icon(Symbols.delete_outline, size: 16),
                      label: Text(
                        'Hapus',
                        style: AppTypography.bodySm(color: AppColors.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
