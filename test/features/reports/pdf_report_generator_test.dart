import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/service_calculator.dart';
import 'package:motocare/core/vehicle_components.dart';
import 'package:motocare/features/reports/data/pdf_report_generator.dart';
import 'package:motocare/features/service/data/models/service_record_model.dart';
import 'package:motocare/features/vehicles/data/models/vehicle_model.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('PdfReportGenerator', () {
    const generator = PdfReportGenerator();
    final vehicle = Vehicle(
      id: 'v1',
      name: 'Vario 160',
      brand: 'Honda',
      model: 'Vario 160',
      plate: 'B 1234 CD',
      currentKm: 14280,
      createdAt: DateTime(2025, 1, 1),
    );

    test('menghasilkan bytes PDF yang valid untuk laporan dengan catatan servis', () async {
      final records = [
        ServiceRecord(
          id: 'rec1',
          vehicleId: 'v1',
          items: const [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.engineOil,
              action: ServiceItemAction.replaced,
              brand: 'SPX2',
            ),
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.vBelt,
              action: ServiceItemAction.cleaned,
            ),
          ],
          date: DateTime(2025, 9, 15),
          km: 12500,
          price: 145000,
          location: 'AHASS Mitra Jaya',
        ),
        ServiceRecord(
          id: 'rec2',
          vehicleId: 'v1',
          items: const [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.gearOil,
              action: ServiceItemAction.replaced,
              brand: 'AHM Gear Oil',
            ),
          ],
          date: DateTime(2025, 9, 20),
          km: 12500,
          price: 35000,
          location: 'AHASS Mitra Jaya',
        ),
      ];

      final bytes = await generator.generateMonthlyReportPdf(
        vehicle: vehicle,
        targetMonth: DateTime(2025, 9, 1),
        records: records,
        userEmail: 'user@example.com',
      );

      expect(bytes, isNotEmpty);
      // Header file PDF selalu dimulai dengan '%PDF-'
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });

    test('menghasilkan bytes PDF yang valid bahkan saat records kosong', () async {
      final bytes = await generator.generateMonthlyReportPdf(
        vehicle: vehicle,
        targetMonth: DateTime(2025, 8, 1),
        records: [],
      );

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    });
  });
}
