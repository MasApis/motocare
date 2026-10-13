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

  /// Batas maksimal riwayat pesan sebelumnya yang dikirimkan ke model sebagai konteks (hemat kuota)
  static const int maxHistoryMessages = 10;

  /// Disclaimer wajib yang harus selalu disertakan pada jawaban diagnosa
  static const String disclaimerText =
      'Catatan: Diagnosa ini merupakan dugaan awal. Untuk kepastian dan penanganan masalah serius, silakan periksa motor Anda langsung ke bengkel terpercaya.';

  /// Memotong riwayat chat agar hanya mempertahankan maksimal [maxHistoryMessages] pesan terakhir
  static List<T> trimHistory<T>(List<T> history) {
    if (history.length <= maxHistoryMessages) {
      return history;
    }
    return history.sublist(history.length - maxHistoryMessages);
  }

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
Kamu adalah MotoAI, asisten mekanik spesialis sepeda motor matic di Indonesia yang ramah, berpengalaman, jujur, dan solutif.

PERAN & KARAKTER:
1. Berbicaralah seperti montir/mekanik bengkel matic profesional: ramah, praktis, to-the-point, dan mudah dipahami oleh pemilik motor awam.
2. Gunakan istilah umum bengkel motor matic di Indonesia (misal: kampas ganda, mangkok kopling, roller peang, per CVT, v-belt retak, oli gardan, rumah roller, tarikan gredek/loyo).
3. Jika pengguna menyapa (seperti "Halo", "Selamat pagi", "Hai MotoAI"), balas sapaan dengan ramah dan tanyakan kendala atau perawatan motor matic yang sedang dihadapi.

KONTEKS MOTOR PENGGUNA SAAT INI:
- Motor: $vehicleName ($brand $model)
- Odometer saat ini: $currentKm km
- Status Komponen Kritis:
$compSummaryBuffer
INSTRUKSI DIAGNOSA:
1. Hubungkan analisa dengan data motor dan sisa kilometer komponen di atas jika relevan dengan keluhan (misalnya mengaitkan getaran CVT dengan v-belt atau roller yang sudah mendekati jadwal servis).
2. Susun jawaban secara ringkas, to-the-point, dan nyaman dibaca di layar HP dengan struktur:
   • Dugaan Penyebab: 1-2 kemungkinan terbesar dengan penjelasan singkat.
   • Solusi / Cek Mandiri: Langkah mudah atau hal yang bisa diperhatikan saat berkendara.
   • Saran Bengkel: Tindakan yang sebaiknya diminta ke mekanik (misal: cukup bersihkan CVT, atau perlu ganti suku cadang).
3. Hindari paragraf yang terlalu panjang agar tidak melelahkan dibaca di HP. Gunakan poin (•) atau penomoran rapi.
4. Jangan menulis paragraf disclaimer panjang di akhir jawaban, karena aplikasi sudah otomatis menampilkan kartu disclaimer resmi di bawah pesan.

BATASAN KETAT (GUARDRAILS):
1. HANYA jawab pertanyaan seputar sepeda motor matic, teknis kendaraan, perawatan, dan keselamatan berkendara.
2. Jika pengguna menanyakan topik di luar sepeda motor (seperti masakan, politik, coding, kesehatan manusia, obrolan umum non-otomotif), TOLAK DENGAN RAMAH DAN SOPAN:
   "Maaf, saya MotoAI, asisten khusus perawatan dan kendala motor matic. Ada yang bisa saya bantu seputar motor Anda?"
3. JANGAN gunakan format markdown seperti pagar (#) atau garis tabel (|).
'''.trim();
  }

  /// Membersihkan sisa-sisa simbol markdown (*, **, #, |) dari respon AI agar tampilan chat rapi
  static String cleanResponseText(String text) {
    var cleaned = text;
    // Hapus format bold (**teks**)
    cleaned = cleaned.replaceAll('**', '');
    // Ubah bullet list (* poin atau - poin) menjadi simbol bullet rapi (• poin)
    cleaned = cleaned.replaceAll(RegExp(r'^\s*[\*\-]\s+', multiLine: true), '• ');
    // Hapus sisa tanda bintang tunggal
    cleaned = cleaned.replaceAll('*', '');
    // Hapus header markdown (# Judul)
    cleaned = cleaned.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    // Bersihkan pemisah baris tabel markdown (|---|)
    cleaned = cleaned.replaceAll(RegExp(r'\|[-:\s|]+\|'), '');
    // Ganti pemisah kolom tabel (|) dengan spasi
    cleaned = cleaned.replaceAll('|', ' ');
    // Rapikan jeda baris yang terlalu renggang
    cleaned = cleaned.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return cleaned.trim();
  }
}
