import 'package:intl/intl.dart';

/// Fungsi-fungsi murni untuk perhitungan servis dan riwayat
/// sesuai dengan docs/SPEC.md bagian 5 (F5) dan Bagian 2.1.
abstract final class ServiceCalculator {
  /// Menentukan lastServiceKm baru setelah servis dilakukan pada [serviceKm].
  /// Kartu komponen akan menghitung pemakaian dari KM ini,
  /// sehingga jika servis dilakukan pada KM saat ini, kartu kembali 100%.
  static int calculateNewLastServiceKm({
    required int serviceKm,
  }) {
    return serviceKm < 0 ? 0 : serviceKm;
  }

  /// Menghitung lastServiceKm komponen setelah sebuah catatan servis dihapus.
  /// 
  /// Aturan docs/SPEC.md F5:
  /// "Catatan servis bisa dihapus (dengan konfirmasi); kartu komponen kembali
  /// menghitung dari servis sebelumnya."
  /// 
  /// Parameter:
  /// - [initialKm]: KM awal kendaraan saat pertama kali didaftarkan (baseline jika tidak ada servis tersisa).
  /// - [remainingServiceKms]: Daftar KM dari seluruh catatan servis yang MASIH TERSISA
  ///   untuk tipe komponen tersebut pada motor ini.
  /// 
  /// Mengembalikan:
  /// - Jika masih ada catatan servis tersisa: KM servis terbaru (nilai KM maksimum).
  /// - Jika seluruh catatan servis telah dihapus (kosong): kembali ke [initialKm].
  static int calculateLastServiceKmAfterDelete({
    required int initialKm,
    required List<int> remainingServiceKms,
  }) {
    if (remainingServiceKms.isEmpty) {
      return initialKm < 0 ? 0 : initialKm;
    }

    // Ambil KM servis terbesar di antara catatan yang tersisa
    int maxKm = remainingServiceKms.first;
    for (final km in remainingServiceKms) {
      if (km > maxKm) {
        maxKm = km;
      }
    }
    return maxKm;
  }

  /// Memformat angka harga rupiah ke string mata uang Indonesia (id_ID),
  /// contoh: 145000 -> "Rp 145.000"
  static String formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Memformat tanggal ke format ramah Indonesia (id_ID),
  /// contoh: DateTime(2025, 3, 15) -> "15 Mar 2025"
  static String formatDate(DateTime date) {
    try {
      final formatter = DateFormat('d MMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (_) {
      // Fallback format jika locale id_ID belum terinisialisasi
      final formatter = DateFormat('d MMM yyyy');
      return formatter.format(date);
    }
  }

  /// Memformat tanggal lengkap dalam bahasa Indonesia (id_ID),
  /// contoh: DateTime(2025, 3, 15) -> "15 Maret 2025"
  static String formatFullDate(DateTime date) {
    try {
      final formatter = DateFormat('d MMMM yyyy', 'id_ID');
      return formatter.format(date);
    } catch (_) {
      final formatter = DateFormat('d MMMM yyyy');
      return formatter.format(date);
    }
  }

  /// Mengurai string input biaya (misal "145.000" atau "Rp 145.000") menjadi bilangan bulat integer rupiah.
  /// Mengembalikan null jika input kosong atau tidak valid.
  static int? parseRupiahInput(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final cleaned = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  /// Memformat angka kilometer dengan pemisah ribuan titik (id_ID),
  /// contoh: 14280 -> "14.280"
  static String formatKm(int km) {
    final formatter = NumberFormat.decimalPattern('id_ID');
    return formatter.format(km);
  }
}
