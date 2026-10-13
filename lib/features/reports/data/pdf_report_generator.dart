import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../core/report_calculator.dart';
import '../../../../core/service_calculator.dart';
import '../../service/data/models/service_record_model.dart';
import '../../vehicles/data/models/vehicle_model.dart';

/// Generator dokumen PDF Laporan Bulanan MotoCare (F8)
class PdfReportGenerator {
  const PdfReportGenerator();

  /// Menghasilkan byte dokumen PDF laporan servis bulanan
  Future<Uint8List> generateMonthlyReportPdf({
    required Vehicle vehicle,
    required DateTime targetMonth,
    required List<ServiceRecord> records,
    String? userEmail,
  }) async {
    final pdf = pw.Document(
      title: 'Laporan Servis MotoCare - ${vehicle.displayName}',
      author: 'MotoCare',
    );

    final monthStr = ReportCalculator.formatMonthYear(targetMonth);
    final totalExpense = ReportCalculator.calculateTotalExpense(records);
    final formattedTotal = ServiceCalculator.formatRupiah(totalExpense);

    // Filter catatan agar dipastikan hanya bulan terkait dan diurutkan berdasarkan tanggal
    final sortedRecords = List<ServiceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            // Header Dokumen
            _buildHeader(vehicle, monthStr),
            pw.SizedBox(height: 16),

            // Kartu Ringkasan Informasi Kendaraan & Pengeluaran
            _buildSummaryCard(vehicle, monthStr, sortedRecords.length, formattedTotal),
            pw.SizedBox(height: 20),

            // Judul Tabel
            pw.Text(
              'Rincian Catatan Servis ($monthStr)',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.SizedBox(height: 8),

            // Tabel Riwayat Servis
            _buildRecordsTable(sortedRecords),
            pw.SizedBox(height: 16),

            // Baris Total Pengeluaran Akhir
            _buildTotalSection(formattedTotal),
            pw.SizedBox(height: 32),

            // Footer
            _buildFooter(userEmail),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Vehicle vehicle, String monthStr) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'MotoCare',
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Laporan Bulanan Perawatan & Pengeluaran Servis',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Text(
              monthStr,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryCard(
    Vehicle vehicle,
    String monthStr,
    int recordCount,
    String formattedTotal,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'KENDARAAN',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                vehicle.displayName,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
              if (vehicle.plate != null && vehicle.plate!.trim().isNotEmpty) ...[
                pw.SizedBox(height: 1),
                pw.Text(
                  vehicle.plate!.trim(),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'TOTAL TRANSAKSI',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '$recordCount Catatan',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'TOTAL PENGELUARAN',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                formattedTotal,
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRecordsTable(List<ServiceRecord> records) {
    if (records.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(16),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'Tidak ada riwayat servis pada periode bulan ini.',
          style: const pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey600,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
    }

    const headers = ['No', 'Tanggal', 'KM', 'Rincian Servis / Suku Cadang', 'Bengkel', 'Total Biaya'];

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FixedColumnWidth(22),
        1: pw.FlexColumnWidth(1.4),
        2: pw.FlexColumnWidth(1.2),
        3: pw.FlexColumnWidth(3.4),
        4: pw.FlexColumnWidth(2.0),
        5: pw.FlexColumnWidth(1.8),
      },
      children: [
        // Table Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blueGrey100),
          children: headers.map((header) {
            return pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blueGrey900,
                ),
                textAlign: (header == 'Total Biaya' || header == 'KM')
                    ? pw.TextAlign.right
                    : (header == 'No' ? pw.TextAlign.center : pw.TextAlign.left),
              ),
            );
          }).toList(),
        ),
        // Table Data Rows
        ...records.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final r = entry.value;
          final isEven = index % 2 == 0;

          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isEven ? PdfColors.grey50 : PdfColors.white,
            ),
            children: [
              _tableCell(index.toString(), align: pw.TextAlign.center),
              _tableCell(r.formattedDate),
              _tableCell(ServiceCalculator.formatKm(r.km), align: pw.TextAlign.right),
              _tableCell(r.itemsSummary),
              _tableCell(r.location.isNotEmpty ? r.location : '-'),
              _tableCell(r.formattedPrice, align: pw.TextAlign.right, isBold: true),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget _tableCell(String text, {pw.TextAlign align = pw.TextAlign.left, bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.blueGrey900,
        ),
        textAlign: align,
      ),
    );
  }

  pw.Widget _buildTotalSection(String formattedTotal) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          border: pw.Border.all(color: PdfColors.blue200, width: 1),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Text(
              'Total Pengeluaran Bulan Ini: ',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blueGrey900,
              ),
            ),
            pw.Text(
              formattedTotal,
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildFooter(String? userEmail) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Dicetak otomatis oleh Aplikasi MotoCare',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          if (userEmail != null && userEmail.isNotEmpty)
            pw.Text(
              'Akun: $userEmail',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
            ),
        ],
      ),
    );
  }
}
