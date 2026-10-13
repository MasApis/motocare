import 'package:flutter_test/flutter_test.dart';
import 'package:motocare/core/chat_prompt_builder.dart';
import 'package:motocare/core/vehicle_components.dart';

void main() {
  group('ChatPromptBuilder', () {
    test('validateUserMessage menolak pesan kosong atau hanya spasi', () {
      expect(ChatPromptBuilder.validateUserMessage(null), isNotNull);
      expect(ChatPromptBuilder.validateUserMessage(''), isNotNull);
      expect(ChatPromptBuilder.validateUserMessage('   '), isNotNull);
    });

    test('validateUserMessage menolak pesan melebihi batas 300 karakter', () {
      final validMessage = 'A' * 300;
      final tooLongMessage = 'A' * 301;

      expect(ChatPromptBuilder.validateUserMessage(validMessage), isNull);
      expect(ChatPromptBuilder.validateUserMessage(tooLongMessage), contains('300'));
    });

    test('validateUserMessage menerima pesan valid', () {
      expect(
        ChatPromptBuilder.validateUserMessage('Motor saya gredek saat tarikan awal.'),
        isNull,
      );
    });

    test('ComponentContextSummary.fromKm menghitung status dengan benar', () {
      final summary = ComponentContextSummary.fromKm(
        type: ComponentType.engineOil,
        intervalKm: 2000,
        lastServiceKm: 1000,
        currentKm: 1500,
      );

      expect(summary.remainingKm, 1500);
      expect(summary.healthPercent, 75);
      expect(summary.statusLabel, 'Aman');
    });

    test('buildSystemInstruction memuat peran mekanik matic, data motor, dan guardrail', () {
      final components = [
        ComponentContextSummary.fromKm(
          type: ComponentType.engineOil,
          intervalKm: 2000,
          lastServiceKm: 0,
          currentKm: 1200,
        ),
        ComponentContextSummary.fromKm(
          type: ComponentType.gearOil,
          intervalKm: 8000,
          lastServiceKm: 0,
          currentKm: 1200,
        ),
        ComponentContextSummary.fromKm(
          type: ComponentType.vBelt,
          intervalKm: 20000,
          lastServiceKm: 0,
          currentKm: 19000,
        ),
      ];

      final instruction = ChatPromptBuilder.buildSystemInstruction(
        vehicleName: 'Vario Harian',
        brand: 'Honda',
        model: 'Vario 160',
        currentKm: 1200,
        components: components,
      );

      // Verifikasi peran & prinsip matic
      expect(instruction, contains('MotoAI'));
      expect(instruction, contains('mekanik ahli khusus sepeda motor matic'));
      expect(instruction, contains('CVT (Continuous Variable Transmission)'));
      expect(instruction, contains('TIDAK MEMILIKI: rantai roda'));

      // Verifikasi data motor aktif
      expect(instruction, contains('Vario Harian (Honda Vario 160)'));
      expect(instruction, contains('1200 km'));
      expect(instruction, contains('Oli Mesin'));
      expect(instruction, contains('Oli Gardan'));
      expect(instruction, contains('V-Belt'));

      // Verifikasi struktur diagnosa dan guardrail
      expect(instruction, contains('Dugaan Penyebab'));
      expect(instruction, contains('Solusi / Cek Mandiri'));
      expect(instruction, contains('Saran Bengkel'));
      expect(instruction, contains('tolak dengan ramah dan sopan'));
    });

    test('trimHistory mempertahankan seluruh pesan jika panjang <= 10', () {
      final history = List.generate(5, (i) => 'Pesan $i');
      final trimmed = ChatPromptBuilder.trimHistory(history);

      expect(trimmed.length, 5);
      expect(trimmed, equals(history));
    });

    test('trimHistory hanya mengambil 10 pesan terakhir jika panjang > 10', () {
      final history = List.generate(20, (i) => 'Pesan $i');
      final trimmed = ChatPromptBuilder.trimHistory(history);

      expect(trimmed.length, 10);
      expect(trimmed.first, 'Pesan 10');
      expect(trimmed.last, 'Pesan 19');
    });

    test('cleanResponseText membersihkan simbol markdown tebal, miring, header, dan tabel', () {
      const rawText = '''
# Diagnosa Motor
**Penyebab Utama:**
* Roller peyang
* Kampas kopling tipis
| Komponen | Status |
|---|---|
| CVT | Kotor |
''';

      final cleaned = ChatPromptBuilder.cleanResponseText(rawText);

      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains('# ')));
      expect(cleaned, isNot(contains('|---|')));
      expect(cleaned, contains('Penyebab Utama:'));
      expect(cleaned, contains('Roller peyang'));
    });
  });
}
