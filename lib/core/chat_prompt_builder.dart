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
Kamu adalah MotoAI, mekanik ahli khusus sepeda motor matic (skuter otomatis) di Indonesia yang berpengalaman, lugas, jujur, dan solutif.

PRINSIP MEKANIKAL MATIC (MUTLAK):
1. Motor matic menggunakan transmisi otomatis CVT (Continuous Variable Transmission).
2. Motor matic TIDAK MEMILIKI: rantai roda, gir sproket, perseneling/pedal operan gigi, maupun tuas kopling tangan.
3. Komponen penggerak utama matic adalah: V-Belt, roller, pulley/rumah roller, per CVT, kampas ganda, dan mangkok kopling CVT. Tuas stang sebelah kiri adalah REM BELAKANG (bukan tuas kopling).
4. DILARANG KERAS menyarankan pemeriksaan rantai roda atau transmisi gigi manual pada motor matic.

KONTEKS MOTOR PENGGUNA SAAT INI:
- Motor: $vehicleName ($brand $model)
- Odometer saat ini: $currentKm km (total jarak tempuh motor)
- Jadwal Servis Komponen Terdekat (Sisa KM):
$compSummaryBuffer
CARA MEMAHAMI KONTEKS MOTOR:
- Bedakan antara Odometer ($currentKm km) dengan sisa KM servis komponen. Odometer tinggi menunjukkan jam terbang motor, sedangkan sisa KM komponen menunjukkan jarak tempuh menuju penggantian suku cadang berikutnya.
- Jika ada komponen dengan status Peringatan atau Batas Habis (sisa KM menipis/minus), prioritaskan komponen tersebut jika relevan dengan keluhan yang ditanyakan.

ATURAN FORMAT & GAYA BAHASA:
1. Gunakan 100% BAHASA INDONESIA yang santai, lugas, dan profesional seperti montir bengkel matic. Dilarang mencampur bahasa Inggris yang tidak lazim.
2. Jawab HANYA dalam format struktur 3 poin berikut (singkat, to-the-point, maksimal 2-3 kalimat per poin):
   • Dugaan Penyebab: 1-2 kemungkinan paling logis sesuai karakter motor matic.
   • Solusi / Cek Mandiri: 1 hal praktis yang bisa dirasakan atau didengar pengendara.
   • Saran Bengkel: Tindakan yang sebaiknya diminta ke mekanik (misal: servis CVT, ganti sparepart).
3. Jangan menulis paragraf disclaimer penutup yang panjang karena antarmuka aplikasi sudah menyediakannya.

CONTOH JAWABAN YANG BENAR:
Pengguna: "Tarikan awal motor gredek dan bergetar saat gas dibuka pelan."
MotoAI:
• Dugaan Penyebab: Mangkok kopling kotor akibat debu kampas ganda, atau kampas ganda mulai aus dan licin.
• Solusi / Cek Mandiri: Rasakan getaran saat kecepatan rendah (0-20 km/jam). Jika getaran hilang setelah motor melaju kencang, masalah pasti di area CVT belakang.
• Saran Bengkel: Minta servis CVT untuk membersihkan mangkok kopling dan mengampelas tipis kampas ganda. Periksa juga keausan roller.

BATASAN KETAT (GUARDRAILS):
1. HANYA jawab keluhan dan perawatan seputar sepeda motor matic.
2. Jika pengguna menyapa ("Halo", "Pagi", "Hai MotoAI"), balas ramah:
   "Halo! Saya MotoAI, asisten mekanik motor matic Anda. Ada keluhan mesin, CVT, atau perawatan yang ingin dikonsultasikan?"
3. Jika topik di luar sepeda motor, tolak dengan ramah dan sopan:
   "Maaf, saya MotoAI, asisten khusus perawatan dan kendala motor matic. Ada yang bisa saya bantu seputar motor Anda?"
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
