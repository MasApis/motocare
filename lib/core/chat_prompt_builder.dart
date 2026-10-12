import 'component_health.dart';
import 'vehicle_components.dart';

/// Konteks status satu komponen untuk dimasukkan ke prompt chatbot
class ComponentContextSummary {
  const ComponentContextSummary({
    required this.type,
    required this.remainingKm,
    required this.healthPercent,
    required this.statusLabel,
  });

  final String type;
  final int remainingKm;
  final int healthPercent;
  final String statusLabel;

  /// Membuat ringkasan dari data kilometer komponen
  factory ComponentContextSummary.fromKm({
    required String type,
    required int intervalKm,
    required int lastServiceKm,
    required int currentKm,
  }) {
    final health = calculateComponentHealth(
      intervalKm: intervalKm,
      lastServiceKm: lastServiceKm,
      currentKm: currentKm,
    );

    return ComponentContextSummary(
      type: type,
      remainingKm: health.remainingKm,
      healthPercent: health.remainingPercentage.round(),
      statusLabel: health.statusLabel,
    );
  }
}

/// Builder fungsi murni untuk menyusun instruksi sistem dan konteks motor aktif
class ChatPromptBuilder {
  const ChatPromptBuilder._();

  /// Batas maksimal panjang pesan dari pengguna (dalam karakter)
  static const int maxMessageLength = 300;

  /// Disclaimer wajib yang harus selalu disertakan pada jawaban diagnosa
  static const String disclaimerText =
      'Catatan: Diagnosa ini merupakan dugaan awal. Untuk kepastian dan penanganan masalah serius, silakan periksa motor Anda langsung ke bengkel terpercaya.';

  /// Memvalidasi input pesan pengguna:
  /// Mengembalikan pesan error jika tidak valid, atau `null` jika valid.
  static String? validateUserMessage(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Pertanyaan tidak boleh kosong.';
    }
    if (input.trim().length > maxMessageLength) {
      return 'Pertanyaan maksimal $maxMessageLength karakter.';
    }
    return null;
  }

  /// Membangun instruksi sistem (system prompt) yang memberi peran mekanik matic
  /// dan menyertakan konteks motor aktif pengguna.
  static String buildSystemInstruction({
    required String vehicleName,
    required String brand,
    required String model,
    required int currentKm,
    required List<ComponentContextSummary> components,
  }) {
    final compSummaryBuffer = StringBuffer();
    for (final c in components) {
      final label = ComponentType.getLabel(c.type);
      compSummaryBuffer.writeln(
        '- $label: sisa ${c.remainingKm} km (${c.healthPercent}%, status: ${c.statusLabel})',
      );
    }

    return '''
Kamu adalah MotoAI, asisten mekanik ahli khusus sepeda motor matic di Indonesia yang ramah, solutif, dan jelas.

TUGAS DAN PERAN:
1. Membantu pengguna mendiagnosa keluhan motor matic (suara aneh, tarikan berat/gredek pada CVT, rem, aki, oli, ban, dsb).
2. Memberikan dugaan penyebab yang paling mungkin secara ringkas dan langkah awal pemeriksaan yang aman.
3. Selalu bersikap jujur dan sertakan pengingat bahwa saran ini adalah dugaan awal dan perlu dicek langsung di bengkel.

KONTEKS MOTOR PENGGUNA SAAT INI:
- Motor: $vehicleName ($brand $model)
- Odometer saat ini: $currentKm km
- Status Komponen Kritis:
$compSummaryBuffer
BATASAN KETAT (GUARDRAILS):
1. HANYA jawab pertanyaan seputar sepeda motor matic, perawatan motor, mekanikal, dan keselamatan berkendara.
2. Jika pengguna menanyakan topik di luar sepeda motor (seperti masakan, politik, coding, kesehatan manusia, obrolan umum di luar otomotif), TOLAK DENGAN RAMAH DAN SOPAN:
   "Maaf, saya MotoAI, asisten khusus perawatan dan diagnosa motor matic. Saya hanya dapat membantu pertanyaan dan kendala seputar sepeda motor."
3. Gunakan bahasa Indonesia yang mudah dimengerti, ringkas, dan praktis.
'''.trim();
  }
}
