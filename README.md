# 🛵 MotoCare

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Spark%20Plan-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![State Management](https://img.shields.io/badge/State-Riverpod%20v3-00599C)](https://riverpod.dev)
[![Tests](https://img.shields.io/badge/Tests-197%20Passed-brightgreen)](https://github.com)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

**MotoCare** adalah aplikasi mobile Android berbasis Flutter yang dirancang khusus untuk membantu pemilik **sepeda motor matic** memantau kesehatan komponen kendaraan (oli mesin, oli gardan, V-belt), mencatat riwayat servis berkala, menjadwalkan pengingat servis otomatis, serta berkonsultasi seputar kendala motor dengan asisten cerdas berbasis AI (**MotoAI**).

---

## 🌟 Fitur Utama

- 🔄 **Multi-Kendaraan & Carousel**
  - Kelola lebih dari satu motor matic dalam satu akun.
  - Tampilan *carousel* interaktif untuk berpindah kendaraan dengan cepat.
  - Preset motor matic populer (Beat, Vario, Scoopy, NMAX, Aerox, PCX, dll) serta opsi kustom.
  - Pengaturan interval kilometer per komponen yang dapat disesuaikan dengan buku manual motor.

- 📊 **Visual Motor Health Card**
  - Pemantauan real-time sisa usia pakai 3 komponen kritis: **Oli Mesin**, **Oli Gardan**, dan **V-Belt**.
  - Indikator status visual berbasis warna dan teks:
    - 🟢 **Aman** (> 30%)
    - 🟡 **Peringatan** (10% – 30%)
    - 🔴 **Batas Habis** (< 10% atau melebihi interval).
  - Tampilan sisa kilometer dan estimasi kondisi suku cadang.

- ⏱️ **Pencatatan Odometer & Rata-rata Harian**
  - Pembaruan kilometer motor secara berkala dengan validasi angka (KM tidak boleh mundur).
  - Perhitungan otomatis rata-rata jarak tempuh harian (km/hari) berdasarkan riwayat odometer 30 hari terakhir.

- 🛠️ **Pencatatan Servis Multi-Item & Riwayat**
  - Catat servis dengan banyak item sekaligus dalam satu kunjungan bengkel.
  - Mendukung aksi fleksibel: komponen **Diganti** (mereset sisa KM ke 100%) atau **Dibersihkan** (hanya dicatat tanpa reset).
  - Tambah suku cadang tambahan (*spare part lain*, misal: kampas rem, busi, filter udara, roller CVT).
  - Riwayat servis lengkap dengan format tanggal Indonesia dan mata uang Rupiah (`id_ID`).
  - Hapus catatan servis dengan fitur pemulihan status komponen otomatis (*rollback* ke servis sebelumnya atau baseline).

- 📶 **Tetap Bisa Dipakai Tanpa Internet**
  - Dashboard, riwayat, dan odometer tetap terbuka tanpa sinyal.
  - Menyimpan servis atau KM saat offline tetap berhasil, lalu dikirim otomatis saat internet kembali.
  - Catatan yang belum terkirim ditandai **Menunggu dikirim**.
  - Batasnya: login pertama dan Chat AI tetap butuh internet.

- 🔔 **Smart Push Notification (Lokal)**
  - Pengingat otomatis saat komponen memasuki *zona merah* (sisa < 10%).
  - Menggunakan perhitungan estimasi tanggal berdasarkan rata-rata km harian motor.
  - Dijadwalkan otomatis pada pukul 08:00 pagi tanpa memerlukan background server berbayar.

- 🤖 **MotoAI (Mekanik Virtual Motor Matic)**
  - Konsultasi gejala atau keluhan motor langsung ke asisten AI interaktif.
  - Dilengkapi konteks spesifik motor yang sedang aktif (tipe motor, km saat ini, status oli dan CVT).
  - Rekomendasi ramah dengan *disclaimer* keselamatan berkendara.
  - Berjalan cepat dan hemat kuota menggunakan LLM API (Groq Cloud).

- 📄 **Laporan Pengeluaran & Cetak PDF**
  - Ringkasan total biaya perawatan dan servis bulanan.
  - Generator laporan formal dalam format dokumen **PDF** berisi rincian kunjungan bengkel.
  - Pratinjau langsung, cetak (*print*), dan bagikan (*share*) berkas PDF dari ponsel.

---

## 🏗️ Arsitektur & Teknologi

MotoCare dibangun dengan memisahkan logika murni, state management, dan antarmuka:

```
UI (Widgets & Pages) ──► Providers (Riverpod) ──► Repositories ──► Cloud Firestore / Auth / Groq API
                                 │
                                 ▼
                     lib/core/ (Fungsi Murni & Kalkulasi)
```

### Tech Stack
| Bagian | Teknologi / Library |
|---|---|
| **Framework** | Flutter (Dart SDK ^3.13) |
| **State Management** | `flutter_riverpod` |
| **Routing / Navigasi** | `go_router` |
| **Backend & Database** | Firebase Authentication & Cloud Firestore (Offline Persistence) |
| **AI Engine** | Groq Cloud API (`openai/gpt-oss-120b`); kunci diisi pengguna di aplikasi, disimpan dengan `flutter_secure_storage` |
| **Notifikasi** | `flutter_local_notifications` + `timezone` |
| **Laporan & Dokumen** | `pdf` + `printing` |
| **Ikon & Font** | `google_fonts` (Plus Jakarta Sans) & `material_symbols_icons` |
| **Pengujian** | `flutter_test` (197 Unit & Widget Tests) |

---

## 📁 Struktur Direktori

```text
motocare/
├── lib/
│   ├── core/                  # Kalkulasi murni, rumus KM/hari, formula kesehatan, format IDR
│   ├── features/              # Fitur modular (data, providers, ui)
│   │   ├── auth/              # Login, register, auth state
│   │   ├── chatbot/           # Konsultasi AI mekanik motor
│   │   ├── dashboard/         # Health card komponen, hero banner, odometer
│   │   ├── notifications/     # Jadwal notifikasi lokal zona merah
│   │   ├── odometer/          # Dialog & histori KM
│   │   ├── reports/           # Laporan bulanan & PDF generator
│   │   ├── service/           # Form servis multi-item & riwayat
│   │   └── vehicles/          # Tambah, kelola, & ganti kendaraan
│   ├── shared/                # Tema warna, tipografi, komponen bersama
│   └── main.dart              # Entrypoint aplikasi
├── test/                      # 197 Unit & Widget test
├── docs/                      # Spesifikasi & desain
│   ├── SPEC.md                #   daftar fitur resmi (sumber kebenaran)
│   ├── DESIGN.md              #   aturan visual (warna, font, ukuran)
│   ├── ERD.md                 #   struktur data Firestore
│   ├── FIRESTORE_RULES_SETUP.md  # cara memasang rules keamanan
│   └── design/SCREENS.md      #   peta layar desain ke fitur
├── CONTRIBUTING.md            # Panduan untuk kontributor
└── README.md
```

---

## 📥 Unduh & Pasang (tanpa membangun sendiri)

Rilis siap pakai tersedia di halaman **Releases** repositori ini.

1. Unduh `app-arm64-v8a-release.apk` (HP modern, hampir semua HP keluaran 2018 ke atas).
   Kalau HP Anda lama/32-bit, pakai `app-armeabi-v7a-release.apk`.
2. Buka file yang terunduh → Android akan bertanya soal **izin sumber tidak dikenal** → izinkan untuk aplikasi browser/file manager Anda.
3. Pasang, lalu buka **MotoCare** dan daftar akun.

> APK dari GitHub **tidak diperbarui otomatis**. Untuk versi baru, unduh lagi dan pasang menimpa versi lama — data Anda tidak hilang karena tersimpan di akun, bukan di HP.

### Mengaktifkan Chat AI (sekali saja, gratis)

APK publik **tidak berisi kunci API apa pun**. Chat AI memakai kunci Groq milik Anda sendiri, supaya kuota gratis Anda yang terpakai dan pembuat aplikasi tidak menanggung biaya siapa pun.

1. Buka [console.groq.com/keys](https://console.groq.com/keys) di browser, masuk dengan akun Google. Gratis, tanpa kartu kredit.
2. Tekan **Create API Key**, beri nama bebas, lalu **salin** kuncinya (hanya ditampilkan sekali).
3. Di aplikasi: buka tab **Chat AI** → tekan **Atur Kunci API** → tempel → **Simpan**.

Kunci disimpan terenkripsi di HP Anda (Android Keystore) dan hanya dikirim ke Groq saat chat dipakai. Tidak pernah dikirim ke pembuat aplikasi. Tombol **Hapus kunci** ada di dialog yang sama.

Tanpa kunci, semua fitur lain tetap berjalan normal: dashboard, odometer, catatan servis, notifikasi, dan laporan PDF.

---

## 🚀 Panduan Memulai & Instalasi

### 1. Prasyarat
Pastikan lingkungan pengembangan Anda sudah terpasang:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi stable terbaru)
- Android Studio / Android SDK (Java 17 / 21)
- Ponsel Android fisik dengan mode *USB Debugging* aktif (atau Android Emulator)
- Git

### 2. Kloning Repositori
```bash
git clone https://github.com/MasApis/motocare.git
cd motocare
```

### 3. Ambil Dependensi
```bash
flutter pub get
```

### 4. Konfigurasi Firebase
Repo ini **sengaja tidak menyimpan** dua berkas konfigurasi Firebase, karena isinya kunci project:

```text
android/app/google-services.json
lib/firebase_options.dart
```

Tanpa keduanya, aplikasi **gagal di-build** — bukan sekadar kehilangan sebagian fitur. Kabar baiknya, keduanya bisa dibuat otomatis dalam satu perintah:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Pilih project `motocare-d902e`, lalu platform **Android** saja. Perintah ini membaca `firebase.json` di repo dan membuat kedua berkas dengan isi yang benar.

Kalau `flutterfire configure` tidak bisa dipakai, salin contoh yang sudah disiapkan lalu isi manual:

```bash
cp lib/firebase_options.example.dart lib/firebase_options.dart
```

Nilai yang perlu diisi didapat dari **Firebase Console → Project Settings → General → Your apps**. Untuk `google-services.json`, unduh dari halaman yang sama.

> **Punya project Firebase sendiri?** Langkah lengkapnya ada di [Lampiran A pada CONTRIBUTING.md](CONTRIBUTING.md#lampiran-a-memakai-project-firebase-sendiri). Cukup paket **Spark** (gratis, tanpa kartu kredit).

### 5. Pasang Firestore Security Rules
Jangan biarkan database dalam *test mode* (terbuka untuk siapa saja). Rules yang benar sudah ada di `firestore.rules`:

```bash
firebase login
firebase deploy --only firestore:rules
```

Alternatif tanpa CLI: **Firestore Database → Rules →** tempel isi `firestore.rules` **→ Publish**.

### 6. Jalankan Aplikasi
Untuk mengaktifkan fitur asisten **MotoAI**, Anda perlu API Key dari [Groq Console](https://console.groq.com/keys) (gratis, tanpa kartu kredit).

Buat file `dart_defines.json` di root proyek (cukup **sekali**), isinya:

```json
{
  "GROQ_API_KEY": "gsk_kunci_asli_anda_disini"
}
```

Cara tercepat, salin contohnya:

```bash
cp dart_defines.example.json dart_defines.json
```

Lalu isi kunci asli Anda di file itu. Setelah itu jalankan:

```bash
flutter run --dart-define-from-file=dart_defines.json
```

> **File `dart_defines.json` sudah masuk `.gitignore`**, jadi kunci Anda tidak akan ikut ter-commit. Jangan hapus baris itu dari `.gitignore`.

> **Untuk build yang dibagikan ke orang lain, jangan sertakan flag ini.** Kunci dari `--dart-define` **ditempel ke dalam APK saat build**, jadi siapa pun yang memegang APK bisa mengambilnya. Build publik dibuat tanpa kunci; pengguna mengisi kuncinya sendiri di layar Chat AI.
>
> Tanpa kunci, seluruh fitur pemantauan motor, servis, odometer, notifikasi, dan PDF tetap berfungsi normal. Hanya fitur chatbot yang menampilkan panduan konfigurasi.

Saat pertama kali dijalankan, **dashboard kemungkinan masih kosong**. Itu wajar — lanjut ke langkah 7.

### 7. Daftarkan Token App Check
MotoCare memakai **Firebase App Check**. Pada mode debug, aplikasi membuat *debug token* sendiri yang **harus didaftarkan** dulu. Selama belum terdaftar, semua permintaan ke Firestore ditolak dan dashboard tampak kosong tanpa pesan error.

1. Dengan aplikasi masih berjalan, buka terminal kedua dan lihat log:

   ```bash
   adb logcat -s com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider
   ```

   Jika kosong, nyalakan log detailnya lebih dulu:
   ```bash
   adb shell setprop log.tag.com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider VERBOSE
   ```
   Tutup-buka aplikasi, salin token yang tercetak, lalu matikan lagi:
   ```bash
   adb shell setprop log.tag.com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider 0
   ```

2. Buka [Firebase Console → App Check → Apps](https://console.firebase.google.com/project/motocare-d902e/appcheck/apps)
3. Kartu `com.hdp.motocare` → **⋮** → **Manage debug tokens** → **Add debug token**
4. Tempel token tadi, beri nama bebas, **Save**
5. Tutup dan jalankan ulang aplikasi — dashboard sekarang terisi.

> Token ini berubah kalau aplikasi di-uninstall atau data aplikasi dibersihkan. Kalau suatu saat dashboard kosong lagi, ulangi langkah ini.
>
> Perintah `firebase appcheck:debugtokens:create` **tidak bisa** dipakai untuk mendaftarkan token pilihan Anda — perintah itu membuat token acak baru. Gunakan halaman web di atas.

### 8. Build APK Rilis (opsional)
Build rilis memerlukan berkas `android/key.properties` berisi lokasi keystore. Tanpa berkas itu build **akan gagal** dengan pesan yang jelas — bukan diam-diam memakai kunci debug.

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/jalur/lengkap/ke/keystore.jks
```

Untuk build yang dibagikan (tanpa kunci API di dalamnya):

```bash
flutter build apk --release --split-per-abi
```

Untuk build pribadi yang ingin langsung memakai kunci Anda:

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=dart_defines.json
```

> **Jangan bagikan APK hasil perintah kedua.** Kuncinya ikut tercetak di dalam APK.

> **Peringatan:** build rilis memakai **Play Integrity**, bukan debug token. APK rilis yang dipasang manual (sideload, bukan lewat Play Store) umumnya **gagal** pemeriksaan App Check.
>
> **Apakah itu masalah?** Saat ini **tidak**, karena enforcement App Check untuk Firestore dan Auth masih **UNENFORCED** (mati). Selama belum dinyalakan, APK rilis tetap bisa dipakai dan dibagikan.
>
> Yang berubah kalau enforcement dinyalakan: APK rilis sideload akan tampak rusak (dashboard kosong) padahal kodenya benar. Jangan nyalakan enforcement kecuali aplikasi didistribusikan lewat Play Store.

### 9. Ukuran APK

Build debug memang besar. Angka terukur langsung di proyek ini:

| Hasil build | Ukuran file |
|---|---|
| `flutter build apk --debug` | 200 MB (terpasang di HP **± 386 MB**) |
| `flutter build apk --release` | 59 MB |
| `--release --split-per-abi` | arm64 **23 MB** · armeabi-v7a 21 MB · x86_64 25 MB |

Penyebab utamanya `kernel_blob.bin` (134 MB): kode Dart bentuk mentah yang hanya dibutuhkan mode debug. Selain itu APK debug membawa `libflutter.so` untuk **tiga** arsitektur prosesor sekaligus (arm64 37 MB + x86_64 38 MB + armeabi-v7a 32 MB), padahal satu HP hanya memakai satu.

Maka:

- **Untuk testing harian di HP sendiri**, batasi ke arsitektur HP Anda. Hemat ± 70 MB dan tetap bisa dibaca lognya:

  ```bash
  flutter run --target-platform android-arm64 \
    --dart-define-from-file=dart_defines.json
  ```

- **Untuk dibagikan ke orang lain**, pisahkan APK per arsitektur:

  ```bash
  flutter build apk --release --split-per-abi
  ```

  Menghasilkan tiga APK kecil (arm64 23 MB, armeabi-v7a 21 MB, x86_64 25 MB). Bagikan yang **arm64-v8a** — itu yang dipakai hampir semua HP sekarang.

  Untuk keperluan membagikan APK (demo, penguji), ikuti panduan lengkap di [CONTRIBUTING bagian 9b](CONTRIBUTING.md#9b-membagikan-aplikasi-untuk-demo) — termasuk cara memakai kunci khusus demo yang bisa dicabut.

Untuk cek arsitektur HP yang tersambung:

```bash
adb shell getprop ro.product.cpu.abi
```

---

## 🤝 Ingin Berkontribusi?

Baca **[CONTRIBUTING.md](CONTRIBUTING.md)**. Isinya: quickstart, penanganan berkas rahasia, langkah App Check yang detail, aturan kerja, konvensi kode, tabel error umum, dan checklist PR.

Ikhtisar singkat: satu fitur per PR, `flutter analyze` harus bersih, `flutter test` harus lulus semua, dan fitur yang dikerjakan harus ada di [`docs/SPEC.md`](docs/SPEC.md).

---

## 📱 Panduan Penggunaan Aplikasi

1. **Pendaftaran / Masuk:**
   - Buka aplikasi dan daftarkan akun baru menggunakan email dan password.
2. **Tambah Motor Pertama:**
   - Masukkan nama panggilan motor (contoh: *Vario Hitam*), pilih merek dan model matic, nomor plat (opsional), serta kilometer odometer saat ini.
3. **Pantau Kesehatan Komponen:**
   - Di halaman utama (*Dashboard*), perhatikan persentase kartu oli mesin, oli gardan, dan V-belt.
   - Ketuk kartu mana saja untuk langsung mencatat penggantian komponen tersebut.
4. **Perbarui Kilometer (Odometer):**
   - Tekan tombol **Update KM** di kartu motor untuk mencatat angka kilometer terkini setelah bepergian.
5. **Catat Servis Bengkel:**
   - Buka tab **Catat**.
   - Masukkan tanggal, bengkel, pilih komponen yang diganti atau dibersihkan, serta tambahkan part lain jika ada (misal: kampas rem). Simpan untuk memperbarui status kesehatan motor secara otomatis.
6. **Konsultasi dengan MotoAI:**
   - Buka tab **Chat AI** untuk menanyakan indikasi kerusakan, bunyi asing di bagian CVT, atau rekomendasi perawatan motor matic Anda.
7. **Unduh Laporan Biaya Servis:**
   - Buka tab **Buku Servis**, pilih bulan yang diinginkan, dan tekan tombol unduh laporan PDF untuk melihat rincian serta mencetak bukti servis.

---

## 🧪 Pengujian & Analisis Kode

Proyek ini dilengkapi dengan cakupan pengujian komprehensif pada fungsi inti (*core logic*) dan perilaku widget:

```bash
# Menjalankan analisis statis kode
flutter analyze

# Menjalankan seluruh pengujian (197 test cases)
flutter test
```

---

## 🔒 Keamanan & Kebijakan Privasi

- Kunci API tidak disimpan di dalam repositori **maupun di dalam APK publik**. Kunci Groq diisi pengguna di layar Chat AI dan disimpan terenkripsi di perangkat (`flutter_secure_storage`). Saat pengembangan, `dart_defines.json` (sudah di-`.gitignore`) masih bisa dipakai lewat `--dart-define-from-file`.
- Data pengguna diisolasi pada tingkat sub-koleksi Firestore (`users/{uid}/vehicles/...`) sehingga tiap pengguna hanya dapat membaca dan menulis data miliknya sendiri. Aturannya ada di `firestore.rules` — lihat [langkah 5](#5-pasang-firestore-security-rules).
- **Firebase App Check** memastikan permintaan ke Firestore hanya datang dari aplikasi asli, bukan dari skrip pihak lain.
- Berkas berisi kunci (`google-services.json`, `firebase_options.dart`, `key.properties`, `dart_defines.json`, `*.jks`) tidak disimpan di repo. Daftar lengkapnya ada di [CONTRIBUTING.md](CONTRIBUTING.md#lampiran-b-daftar-berkas-rahasia).

> **Yang perlu diketahui:** kalau Anda menjalankan `flutter build` **dengan** `--dart-define-from-file`, kunci Groq Anda **tertanam di dalam APK** dan bisa diambil siapa pun yang memegang file itu. Untuk dibagikan, build **tanpa** flag tersebut. Penjelasan lengkap ada di [CONTRIBUTING.md bagian 3b](CONTRIBUTING.md#3b-kunci-groq-tidak-tersimpan-di-aplikasi).

---

## 📄 Lisensi

Proyek ini didistribusikan di bawah lisensi **MIT License**. Silakan lihat berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.
