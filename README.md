# 🛵 MotoCare

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Spark%20Plan-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![State Management](https://img.shields.io/badge/State-Riverpod%20v3-00599C)](https://riverpod.dev)
[![Tests](https://img.shields.io/badge/Tests-174%20Passed-brightgreen)](https://github.com)
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
| **AI Engine** | Groq Cloud API (`llama-3.1-8b-instant`) |
| **Notifikasi** | `flutter_local_notifications` + `timezone` |
| **Laporan & Dokumen** | `pdf` + `printing` |
| **Ikon & Font** | `google_fonts` (Plus Jakarta Sans) & `material_symbols_icons` |
| **Pengujian** | `flutter_test` (174 Unit & Widget Tests) |

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
├── test/                      # 174 Unit & Widget test
├── docs/                      # Spesifikasi teknis (SPEC.md) & Desain visual (DESIGN.md)
└── README.md
```

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
git clone https://github.com/USERNAME/motocare.git
cd motocare
```

### 3. Konfigurasi Firebase
Aplikasi ini memerlukan Firebase Authentication dan Cloud Firestore:
1. Buat proyek baru di [Firebase Console](https://console.firebase.google.com/) (Gunakan paket gratis **Spark**).
2. Aktifkan **Email/Password** pada menu **Authentication**.
3. Buat database **Cloud Firestore** dalam mode pengujian (*test mode*).
4. Daftarkan aplikasi Android:
   - Unduh file `google-services.json` dan letakkan di:
     ```text
     android/app/google-services.json
     ```
   - Buat file konfigurasi `lib/firebase_options.dart` menggunakan FlutterFire CLI:
     ```bash
     flutterfire configure
     ```

### 4. Ambil Dependensi
```bash
flutter pub get
```

### 5. Jalankan Aplikasi
Untuk mengaktifkan fitur asisten **MotoAI**, Anda dapat menyertakan API Key dari [Groq Console](https://console.groq.com/keys) (gratis):

```bash
flutter run --dart-define=GROQ_API_KEY="gsk_kunci_groq_anda_disini"
```

> **Catatan:** Jika dijalankan tanpa parameter `--dart-define=GROQ_API_KEY`, seluruh fitur pemantauan motor, servis, odometer, notifikasi, dan PDF tetap berfungsi normal, namun fitur chatbot akan menampilkan panduan konfigurasi API key.

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
   - Buka menu **Servis** > **Catat Servis**.
   - Masukkan tanggal, bengkel, pilih komponen yang diganti atau dibersihkan, serta tambahkan part lain jika ada (misal: kampas rem). Simpan untuk memperbarui status kesehatan motor secara otomatis.
6. **Konsultasi dengan MotoAI:**
   - Buka tab **Chatbot** untuk menanyakan indikasi kerusakan, bunyi asing di bagian CVT, atau rekomendasi perawatan motor matic Anda.
7. **Unduh Laporan Biaya Servis:**
   - Buka tab **Laporan**, pilih bulan yang diinginkan, dan tekan **Unduh Laporan PDF** untuk melihat rincian serta mencetak bukti servis.

---

## 🧪 Pengujian & Analisis Kode

Proyek ini dilengkapi dengan cakupan pengujian komprehensif pada fungsi inti (*core logic*) dan perilaku widget:

```bash
# Menjalankan analisis statis kode
flutter analyze

# Menjalankan seluruh pengujian (174 test cases)
flutter test
```

---

## 🔒 Keamanan & Kebijakan Privasi

- Kunci API rahasia tidak pernah disimpan di dalam repositori kode (diinjeksi aman melalui runtime compilation `--dart-define`).
- Data pengguna diisolasi pada tingkat sub-koleksi Firestore (`users/{uid}/vehicles/...`) sehingga tiap pengguna hanya dapat membaca dan menulis data miliknya sendiri.

---

## 📄 Lisensi

Proyek ini didistribusikan di bawah lisensi **MIT License**. Silakan lihat berkas [LICENSE](LICENSE) untuk informasi lebih lanjut.
