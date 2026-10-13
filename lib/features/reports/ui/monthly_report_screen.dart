import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:printing/printing.dart';

import '../../../../core/report_calculator.dart';
import '../../../../core/service_calculator.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_shapes.dart';
import '../../../shared/theme/app_spacing.dart';
import '../../../shared/theme/app_typography.dart';
import '../../../shared/widgets/app_button.dart';
import '../../service/data/models/service_record_model.dart';
import '../../vehicles/data/models/vehicle_model.dart';
import '../../vehicles/providers/vehicle_providers.dart';
import '../providers/report_providers.dart';

/// Halaman Laporan Bulanan & Pengeluaran Servis (F8)
/// sesuai docs/SPEC.md bagian 5 (F8) dan docs/design/buku_servis_pengeluaran/
class MonthlyReportScreen extends ConsumerStatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  ConsumerState<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _handleDownloadPdf({
    required Vehicle vehicle,
    required DateTime targetMonth,
    required List<ServiceRecord> records,
    required bool isShareOnly,
  }) async {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tidak ada riwayat servis pada ${ReportCalculator.formatMonthYear(targetMonth)} untuk diekspor.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isGeneratingPdf = true);

    try {
      final generator = ref.read(pdfReportGeneratorProvider);
      final userEmail = FirebaseAuth.instance.currentUser?.email;

      final pdfBytes = await generator.generateMonthlyReportPdf(
        vehicle: vehicle,
        targetMonth: targetMonth,
        records: records,
        userEmail: userEmail,
      );

      final monthName = ReportCalculator.formatMonthName(targetMonth);
      final filename = 'Laporan-Servis-${vehicle.name}-$monthName-${targetMonth.year}.pdf'
          .replaceAll(' ', '_');

      if (!mounted) return;

      if (isShareOnly) {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: filename,
        );
      } else {
        await Printing.layoutPdf(
          name: filename,
          onLayout: (format) async => pdfBytes,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat laporan PDF: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  void _showMonthPicker(BuildContext context, DateTime currentMonth) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: currentMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'PILIH BULAN & TAHUN LAPORAN',
      cancelText: 'BATAL',
      confirmText: 'PILIH',
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      ref.read(selectedReportMonthProvider.notifier).setMonth(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(selectedVehicleProvider);
    final selectedMonth = ref.watch(selectedReportMonthProvider);
    final recordsAsync = ref.watch(monthlyReportRecordsProvider);
    final totalExpense = ref.watch(monthlyReportTotalProvider);

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
              'Laporan Bulanan',
              style: AppTypography.headlineSm().copyWith(fontWeight: FontWeight.w700),
            ),
            if (activeVehicle != null)
              Text(
                activeVehicle.displayName,
                style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
              ),
          ],
        ),
      ),
      body: activeVehicle == null
          ? _buildNoVehicleState()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Navigasi Pemilih Bulan
                  _buildMonthSelector(context, selectedMonth),
                  const SizedBox(height: AppSpacing.md),

                  // Kartu Pengeluaran Bulan Ini
                  _buildExpenseSummaryCard(
                    activeVehicle: activeVehicle,
                    targetMonth: selectedMonth,
                    totalExpense: totalExpense,
                    records: recordsAsync.asData?.value ?? [],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Daftar Catatan Servis Bulan Terpilih
                  _buildRecordsSection(
                    context,
                    recordsAsync,
                    selectedMonth,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNoVehicleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
                Symbols.two_wheeler,
                size: 36,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Belum Ada Motor Terpilih',
              style: AppTypography.headlineSm(),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Silakan tambahkan atau pilih motor terlebih dahulu di beranda untuk melihat laporan pengeluaran.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(BuildContext context, DateTime selectedMonth) {
    final monthYearStr = ReportCalculator.formatMonthYear(selectedMonth);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedFull,
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Symbols.chevron_left, color: AppColors.primary),
            tooltip: 'Bulan Sebelumnya',
            onPressed: () {
              ref.read(selectedReportMonthProvider.notifier).previousMonth();
            },
          ),
          InkWell(
            onTap: () => _showMonthPicker(context, selectedMonth),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Symbols.calendar_month, size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    monthYearStr,
                    style: AppTypography.labelMd(color: AppColors.onSurface).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Symbols.chevron_right, color: AppColors.primary),
            tooltip: 'Bulan Berikutnya',
            onPressed: () {
              ref.read(selectedReportMonthProvider.notifier).nextMonth();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseSummaryCard({
    required Vehicle activeVehicle,
    required DateTime targetMonth,
    required int totalExpense,
    required List<ServiceRecord> records,
  }) {
    final summaryTitle = ReportCalculator.formatMonthlyExpenseSummary(
      targetMonth,
      totalExpense,
    );
    final hasData = records.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedLg,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Kartu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PENGELUARAN BULAN INI',
                      style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ServiceCalculator.formatRupiah(totalExpense),
                      style: AppTypography.displayMd(color: AppColors.onSurface).copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      summaryTitle,
                      style: AppTypography.bodySm(color: AppColors.primary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.account_balance_wallet,
                  size: 26,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasData
                ? '${records.length} catatan servis pada bulan ini'
                : 'Belum ada transaksi servis tercatat',
            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 1, color: AppColors.outlineVariant),
          const SizedBox(height: AppSpacing.md),

          // Tombol Unduh Laporan PDF & Bagikan
          Row(
            children: [
              Expanded(
                flex: 3,
                child: AppButton(
                  text: 'Unduh Laporan PDF',
                  icon: const Icon(Symbols.picture_as_pdf, size: 20, color: AppColors.onPrimary),
                  isLoading: _isGeneratingPdf,
                  onPressed: hasData
                      ? () => _handleDownloadPdf(
                            vehicle: activeVehicle,
                            targetMonth: targetMonth,
                            records: records,
                            isShareOnly: false,
                          )
                      : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton.filledTonal(
                tooltip: 'Bagikan PDF',
                icon: const Icon(Symbols.share, color: AppColors.primary),
                onPressed: hasData && !_isGeneratingPdf
                    ? () => _handleDownloadPdf(
                          vehicle: activeVehicle,
                          targetMonth: targetMonth,
                          records: records,
                          isShareOnly: true,
                        )
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsSection(
    BuildContext context,
    AsyncValue<List<ServiceRecord>> recordsAsync,
    DateTime selectedMonth,
  ) {
    return recordsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.errorContainer.withValues(alpha: 0.3),
          borderRadius: AppShapes.roundedDefault,
        ),
        child: Text(
          'Gagal memuat catatan: $err',
          style: AppTypography.bodySm(color: AppColors.error),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          final monthYearStr = ReportCalculator.formatMonthYear(selectedMonth);
          return Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: AppShapes.roundedLg,
              border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Symbols.event_busy,
                    size: 28,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Belum Ada Catatan Servis',
                  style: AppTypography.headlineSm(),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Tidak ada catatan perawatan atau pengeluaran servis pada $monthYearStr.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rincian Servis',
                  style: AppTypography.headlineSm(),
                ),
                Text(
                  '${records.length} Log',
                  style: AppTypography.labelCaps(color: AppColors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...records.map((r) => _buildRecordCard(r)),
          ],
        );
      },
    );
  }

  Widget _buildRecordCard(ServiceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: AppShapes.roundedDefault,
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceContainer,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Symbols.construction,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.itemsSummary,
                      style: AppTypography.labelMd(color: AppColors.onSurface).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${record.formattedDate} • ${record.formattedKm}',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Text(
                record.formattedPrice,
                style: AppTypography.labelMd(color: AppColors.onSurface).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (record.location.isNotEmpty || (record.note != null && record.note!.isNotEmpty)) ...[
            const SizedBox(height: AppSpacing.xs),
            Padding(
              padding: const EdgeInsets.only(left: 38 + AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.location.isNotEmpty)
                    Row(
                      children: [
                        const Icon(Symbols.store, size: 14, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            record.location,
                            style: AppTypography.bodySm(color: AppColors.onSurface),
                          ),
                        ),
                      ],
                    ),
                  if (record.note != null && record.note!.isNotEmpty)
                    Text(
                      'Catatan: ${record.note}',
                      style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
