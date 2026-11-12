// =====================================================================
// CONTOH SAJA — JANGAN DIPAKAI LANGSUNG.
//
// File asli `lib/firebase_options.dart` sengaja TIDAK disimpan di repo
// karena berisi kunci project Firebase.
//
// Cara membuat file asli (pilih salah satu):
//
//   1. Cara otomatis (disarankan):
//        flutterfire configure
//      Perintah ini membaca `firebase.json` di root repo dan langsung
//      membuat `lib/firebase_options.dart` yang benar.
//
//   2. Cara manual:
//      Salin file ini menjadi `lib/firebase_options.dart`, lalu ganti
//      semua tulisan GANTI_... dengan nilai dari Firebase Console:
//      Project Settings -> General -> Your apps -> SDK setup and configuration.
//
// Untuk penjelasan lengkap, baca bagian "Konfigurasi Firebase" di README.md
// atau "Tiga file rahasia" di CONTRIBUTING.md.
// =====================================================================

// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Nilai [FirebaseOptions] untuk tiap platform.
///
/// Sesuaikan dengan hasil `flutterfire configure` di project Anda sendiri.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Platform web belum dikonfigurasi untuk proyek ini.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'MotoCare hanya dikonfigurasi untuk Android. '
          'Jalankan `flutterfire configure` jika ingin menambah platform lain.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'GANTI_DENGAN_API_KEY_ANDA',
    appId: 'GANTI_DENGAN_APP_ID_ANDA',
    messagingSenderId: 'GANTI_DENGAN_SENDER_ID_ANDA',
    projectId: 'GANTI_DENGAN_PROJECT_ID_ANDA',
    storageBucket: 'GANTI_DENGAN_STORAGE_BUCKET_ANDA',
  );
}
