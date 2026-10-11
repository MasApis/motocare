import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

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
/// Mengacu pada docs/design/riwayat_servis_keseluruhan/ dan docs/SPEC.md (F5)
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
          'Catatan servis ${record.componentLabel} (${record.formattedDate}) pada $vehicleName akan dihapus. Kartu komponen akan kembali menghitung sisa masa pakai dari servis sebelumnya.',
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
            componentType: record.componentType,
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
    final selectedFilterId = ref.watch(serviceFilterVehicleIdProvider);
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
              'Log pemeliharaan armada terbaru',
              style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Filter per motor (SPEC F5: "bisa difilter per motor")
            if (vehicles.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Opsi: Semua Motor
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          selected: selectedFilterId == null,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(serviceFilterVehicleIdProvider.notifier).select(null);
                            }
                          },
                          label: const Text('Semua Motor'),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surfaceContainerLow,
                          labelStyle: TextStyle(
                            color: selectedFilterId == null
                                ? AppColors.onPrimary
                                : AppColors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppShapes.roundedFull,
                          ),
                        ),
                      ),
                      // Opsi per motor
                      ...vehicles.map((v) {
                        final isSelected = selectedFilterId == v.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.xs),
                          child: ChoiceChip(
                            selected: isSelected,
                            onSelected: (selected) {
                              ref.read(serviceFilterVehicleIdProvider.notifier).select(
                                    selected ? v.id : null,
                                  );
                            },
                            label: Text(v.displayName),
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.surfaceContainerLow,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            shape: const RoundedRectangleBorder(
                              borderRadius: AppShapes.roundedFull,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            const Divider(height: 1, color: AppColors.borderSlate),

            // Daftar Linimasa Riwayat Servis
            Expanded(
              child: recordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return _buildEmptyState(context, vehicles);
                  }
                  return _buildTimelineList(context, ref, records, vehicles);
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      'Gagal memuat riwayat servis: $err',
                      style: AppTypography.bodyMd(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, List<Vehicle> vehicles) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Symbols.history,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum Ada Riwayat Servis',
              style: AppTypography.headlineSm(),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Catat servis berkala seperti ganti oli mesin, oli gardan, atau servis CVT untuk memantau kesehatan motor.',
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            if (vehicles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                text: 'Catat Servis Baru',
                icon: const Icon(Symbols.build, size: 20, color: AppColors.onPrimary),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ServiceFormScreen(),
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineList(
    BuildContext context,
    WidgetRef ref,
    List<ServiceRecord> records,
    List<Vehicle> vehicles,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.xl,
      ),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final vehicle = vehicles.where((v) => v.id == record.vehicleId).firstOrNull;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Garis Linimasa & Node Bulat di Sisi Kiri
              SizedBox(
                width: 24,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    // Garis Penghubung Vertikal
                    Positioned(
                      top: 14,
                      bottom: index == records.length - 1 ? null : 0,
                      height: index == records.length - 1 ? 40 : null,
                      child: Container(
                        width: 2,
                        color: AppColors.surfaceContainerHighest,
                      ),
                    ),
                    // Node Bulat
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary,
                          width: 3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.xs),

              // Kartu Detail Servis
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
                        color: Color(0x0A0F172A),
                        blurRadius: 4,
                        offset: Offset(0, 1),
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

                      // Nama Servis / Komponen & Merek
                      Text(
                        '${record.componentLabel} • ${record.brand}',
                        style: AppTypography.labelMd().copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),

                      const SizedBox(height: 4),

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
      },
    );
  }
}
