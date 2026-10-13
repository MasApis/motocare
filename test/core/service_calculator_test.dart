import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:motocare/core/service_calculator.dart';
import 'package:motocare/core/vehicle_components.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('ServiceCalculator - getComponentsToReset (Aturan Reset Servis Baru)', () {
    test('Hanya komponen yang diganti (replaced) yang di-reset', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.engineOil,
          action: ServiceItemAction.replaced,
          brand: 'SPX2',
        ),
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.vBelt,
          action: ServiceItemAction.cleaned,
        ),
      ];

      final toReset = ServiceCalculator.getComponentsToReset(items);

      expect(toReset.contains(ComponentType.engineOil), isTrue);
      expect(toReset.contains(ComponentType.vBelt), isFalse);
      expect(toReset.length, 1);
    });

    test('Beberapa komponen sekaligus diganti mereset semua kartu yang diganti', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.engineOil,
          action: ServiceItemAction.replaced,
        ),
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.gearOil,
          action: ServiceItemAction.replaced,
        ),
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.vBelt,
          action: ServiceItemAction.replaced,
        ),
      ];

      final toReset = ServiceCalculator.getComponentsToReset(items);

      expect(toReset.contains(ComponentType.engineOil), isTrue);
      expect(toReset.contains(ComponentType.gearOil), isTrue);
      expect(toReset.contains(ComponentType.vBelt), isTrue);
      expect(toReset.length, 3);
    });

    test('Part lain yang diganti tidak memengaruhi kartu komponen manapun', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.part,
          name: 'Roller Daytona',
          action: ServiceItemAction.replaced,
        ),
        const ServiceItem(
          kind: ServiceItemKind.part,
          name: 'Busi NGK',
          action: ServiceItemAction.replaced,
        ),
      ];

      final toReset = ServiceCalculator.getComponentsToReset(items);
      expect(toReset.isEmpty, isTrue);
    });

    test('Servis CVT (V-Belt dibersihkan + Roller diganti) tidak mereset kartu manapun', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.vBelt,
          action: ServiceItemAction.cleaned,
        ),
        const ServiceItem(
          kind: ServiceItemKind.part,
          name: 'Roller CVT',
          action: ServiceItemAction.replaced,
        ),
      ];

      final toReset = ServiceCalculator.getComponentsToReset(items);
      expect(toReset.isEmpty, isTrue);
    });
  });

  group('ServiceCalculator - calculateComponentLastServiceKmAfterDelete (Aturan Hapus Servis)', () {
    test('Kembali ke servis diganti sebelumnya dengan KM tertinggi saat catatan terbaru dihapus', () {
      const baselineKm = 10000;

      // Misal Servis 3 (KM 16.000) dihapus, catatan tersisa:
      // Servis 1 (KM 12.000, diganti) & Servis 2 (KM 14.000, diganti)
      final remainingRecords = [
        const ServiceRecordSummary(
          km: 12000,
          items: [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.engineOil,
              action: ServiceItemAction.replaced,
            ),
          ],
        ),
        const ServiceRecordSummary(
          km: 14000,
          items: [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.engineOil,
              action: ServiceItemAction.replaced,
            ),
          ],
        ),
      ];

      final lastKm = ServiceCalculator.calculateComponentLastServiceKmAfterDelete(
        componentType: ComponentType.engineOil,
        baselineKm: baselineKm,
        remainingRecords: remainingRecords,
      );

      expect(lastKm, 14000);
    });

    test('Mengabaikan catatan servis yang hanya dibersihkan (cleaned) saat mencari KM servis terakhir', () {
      const baselineKm = 8000;

      // Misal V-belt:
      // Servis 1 di KM 10.000: V-Belt diganti
      // Servis 2 di KM 13.000: V-Belt hanya dibersihkan
      // Servis 3 di KM 15.000: V-Belt diganti (ini yang dihapus)
      // Yang tersisa Servis 1 dan Servis 2. V-Belt harus kembali ke KM 10.000 (bukan 13.000)
      final remainingRecords = [
        const ServiceRecordSummary(
          km: 10000,
          items: [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.vBelt,
              action: ServiceItemAction.replaced,
            ),
          ],
        ),
        const ServiceRecordSummary(
          km: 13000,
          items: [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.vBelt,
              action: ServiceItemAction.cleaned,
            ),
          ],
        ),
      ];

      final lastKm = ServiceCalculator.calculateComponentLastServiceKmAfterDelete(
        componentType: ComponentType.vBelt,
        baselineKm: baselineKm,
        remainingRecords: remainingRecords,
      );

      expect(lastKm, 10000);
    });

    test('Kembali ke baselineKm jika seluruh catatan servis yang mengganti komponen tersebut dihapus', () {
      const baselineKm = 10000;

      // Hanya tersisa catatan yang berisi part lain atau komponen lain
      final remainingRecords = [
        const ServiceRecordSummary(
          km: 14000,
          items: [
            ServiceItem(
              kind: ServiceItemKind.component,
              componentType: ComponentType.gearOil,
              action: ServiceItemAction.replaced,
            ),
          ],
        ),
      ];

      final lastKm = ServiceCalculator.calculateComponentLastServiceKmAfterDelete(
        componentType: ComponentType.engineOil,
        baselineKm: baselineKm,
        remainingRecords: remainingRecords,
      );

      expect(lastKm, baselineKm);
    });

    test('Kembali ke baselineKm jika daftar remainingRecords kosong', () {
      const baselineKm = 12500;
      final lastKm = ServiceCalculator.calculateComponentLastServiceKmAfterDelete(
        componentType: ComponentType.engineOil,
        baselineKm: baselineKm,
        remainingRecords: [],
      );

      expect(lastKm, baselineKm);
    });

    test('Menjaga baselineKm non-negatif jika nilai baseline tidak valid', () {
      final lastKm = ServiceCalculator.calculateComponentLastServiceKmAfterDelete(
        componentType: ComponentType.engineOil,
        baselineKm: -500,
        remainingRecords: [],
      );

      expect(lastKm, 0);
    });
  });

  group('ServiceCalculator - formatItemsSummary', () {
    test('Memformat satu item dengan rapi', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.engineOil,
          action: ServiceItemAction.replaced,
        ),
      ];
      expect(ServiceCalculator.formatItemsSummary(items), 'Oli Mesin (diganti)');
    });

    test('Memformat multi-item dengan koma sesuai SPEC F8', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.engineOil,
          action: ServiceItemAction.replaced,
        ),
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.vBelt,
          action: ServiceItemAction.cleaned,
        ),
        const ServiceItem(
          kind: ServiceItemKind.part,
          name: 'Roller',
          action: ServiceItemAction.replaced,
        ),
      ];
      expect(
        ServiceCalculator.formatItemsSummary(items),
        'Oli Mesin (diganti), V-Belt (dibersihkan), Roller (diganti)',
      );
    });

    test('Mendukung penyertaan merek jika includeBrand true', () {
      final items = [
        const ServiceItem(
          kind: ServiceItemKind.component,
          componentType: ComponentType.engineOil,
          action: ServiceItemAction.replaced,
          brand: 'SPX2',
        ),
      ];
      expect(
        ServiceCalculator.formatItemsSummary(items, includeBrand: true),
        'Oli Mesin (diganti, SPX2)',
      );
    });
  });

  group('ServiceCalculator - Format & Parsing Rupiah / KM', () {
    test('formatRupiah memformat angka menjadi format mata uang Indonesia', () {
      expect(ServiceCalculator.formatRupiah(145000), 'Rp 145.000');
      expect(ServiceCalculator.formatRupiah(0), 'Rp 0');
      expect(ServiceCalculator.formatRupiah(2500000), 'Rp 2.500.000');
    });

    test('formatDate memformat tanggal sesuai singkatan bulan Indonesia', () {
      final date = DateTime(2025, 3, 15);
      final formatted = ServiceCalculator.formatDate(date);
      expect(formatted, contains('15'));
      expect(formatted, contains('2025'));
    });

    test('formatFullDate memformat tanggal lengkap Indonesia', () {
      final date = DateTime(2025, 3, 15);
      final formatted = ServiceCalculator.formatFullDate(date);
      expect(formatted, contains('15'));
      expect(formatted, contains('Maret'));
      expect(formatted, contains('2025'));
    });

    test('parseRupiahInput mengurai teks rupiah ke integer', () {
      expect(ServiceCalculator.parseRupiahInput('145.000'), 145000);
      expect(ServiceCalculator.parseRupiahInput('Rp 145.000'), 145000);
      expect(ServiceCalculator.parseRupiahInput('0'), 0);
      expect(ServiceCalculator.parseRupiahInput(''), isNull);
      expect(ServiceCalculator.parseRupiahInput('   '), isNull);
      expect(ServiceCalculator.parseRupiahInput(null), isNull);
    });

    test('formatKm memformat angka kilometer dengan titik pemisah ribuan', () {
      expect(ServiceCalculator.formatKm(14280), '14.280');
      expect(ServiceCalculator.formatKm(0), '0');
    });
  });

  group('ServiceCalculator - calculateNewLastServiceKm & legacy calculateLastServiceKmAfterDelete', () {
    test('calculateNewLastServiceKm mengembalikan serviceKm atau 0 jika negatif', () {
      expect(ServiceCalculator.calculateNewLastServiceKm(serviceKm: 15000), 15000);
      expect(ServiceCalculator.calculateNewLastServiceKm(serviceKm: -100), 0);
    });

    test('calculateLastServiceKmAfterDelete mengembalikan max KM atau initialKm jika kosong', () {
      expect(
        ServiceCalculator.calculateLastServiceKmAfterDelete(
          initialKm: 5000,
          remainingServiceKms: [6000, 8000, 7500],
        ),
        8000,
      );
      expect(
        ServiceCalculator.calculateLastServiceKmAfterDelete(
          initialKm: 5000,
          remainingServiceKms: [],
        ),
        5000,
      );
      expect(
        ServiceCalculator.calculateLastServiceKmAfterDelete(
          initialKm: -10,
          remainingServiceKms: [],
        ),
        0,
      );
    });

    test('formatItemsSummary mengembalikan "-" jika list kosong', () {
      expect(ServiceCalculator.formatItemsSummary([]), '-');
    });
  });

  group('ServiceItem - Serialization & Copy', () {
    test('toMap dan fromMap bekerja secara simetris untuk komponen dan part', () {
      const item1 = ServiceItem(
        kind: ServiceItemKind.component,
        componentType: ComponentType.engineOil,
        action: ServiceItemAction.replaced,
        brand: 'AHM Oil',
      );
      final map1 = item1.toMap();
      final revived1 = ServiceItem.fromMap(map1);
      expect(revived1.kind, item1.kind);
      expect(revived1.componentType, item1.componentType);
      expect(revived1.action, item1.action);
      expect(revived1.brand, item1.brand);

      const item2 = ServiceItem(
        kind: ServiceItemKind.part,
        name: 'Kampas Rem',
        action: ServiceItemAction.replaced,
      );
      final map2 = item2.toMap();
      final revived2 = ServiceItem.fromMap(map2);
      expect(revived2.kind, item2.kind);
      expect(revived2.name, item2.name);
      expect(revived2.action, item2.action);
    });

    test('displayName mengembalikan "Part Lain" jika nama part kosong', () {
      const emptyPart = ServiceItem(
        kind: ServiceItemKind.part,
        action: ServiceItemAction.replaced,
      );
      expect(emptyPart.displayName, 'Part Lain');
    });

    test('copyWith memperbarui properti yang ditentukan', () {
      const original = ServiceItem(
        kind: ServiceItemKind.component,
        componentType: ComponentType.engineOil,
        action: ServiceItemAction.replaced,
      );
      final copied = original.copyWith(action: ServiceItemAction.cleaned, brand: 'Shell');
      expect(copied.action, ServiceItemAction.cleaned);
      expect(copied.brand, 'Shell');
      expect(copied.componentType, ComponentType.engineOil);
    });
  });
}
