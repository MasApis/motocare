import 'dart:async';

/// Batas tunggu konfirmasi server sebelum penyimpanan dianggap masuk antrean.
///
/// Saat offline, Firestore langsung menyimpan tulisan ke disk, tetapi Future
/// `commit()` / `update()` baru selesai setelah server menerima — bisa tidak
/// pernah. Lewat batas ini data dianggap "queued"; Firestore tetap mengirim
/// sendiri saat internet kembali.
const Duration saveAckTimeout = Duration(seconds: 5);

/// Status penyimpanan setelah aplikasi menunggu konfirmasi server.
enum SaveStatus {
  /// Server sudah menerima data.
  synced,

  /// Data tersimpan di HP dan akan dikirim otomatis saat internet tersedia.
  queued,
}

/// Hasil penyimpanan: nilai balik operasi beserta status pengirimannya.
typedef SaveResult<T> = ({T value, SaveStatus status});

/// Menunggu [write] sampai server mengonfirmasi, paling lama [timeout].
///
/// Error asli (mis. izin ditolak) tetap dilempar. Hanya batas waktu yang
/// diubah menjadi [SaveStatus.queued].
Future<SaveStatus> awaitServerAck(
  Future<void> write, {
  Duration timeout = saveAckTimeout,
}) async {
  try {
    await write.timeout(timeout);
    return SaveStatus.synced;
  } on TimeoutException {
    return SaveStatus.queued;
  }
}
