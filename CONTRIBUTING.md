# Panduan Kontribusi MotoCare

Dokumen ini untuk dua jenis orang:

- **Anda yang baru clone repo ini** dan ingin aplikasinya jalan di HP.
- **Anda yang ingin menyumbang kode** (memperbaiki bug, menambah fitur).

Ikuti dari atas ke bawah. Semua perintah diketik di terminal, dijalankan dari folder `motocare`.

---

## 1. Yang harus terpasang dulu

| Perangkat lunak | Cara cek | Catatan |
|---|---|---|
| Flutter SDK | `flutter --version` | Proyek ini dibuat dengan Flutter 3.47.x (stable) |
| Android SDK | `flutter doctor` | Ikuti saran yang muncul sampai hijau |
| Git | `git --version` | |
| HP Android asli | `flutter devices` | USB debugging harus aktif |

Proyek ini **tidak butuh emulator**. Justru lebih baik pakai HP asli, karena notifikasi dan penyimpanan offline hanya bisa diuji dengan benar di perangkat nyata.

Belum punya Flutter? Ikuti [panduan resmi](https://docs.flutter.dev/get-started/install/linux) untuk Linux.

---

## 2. Quickstart (5 menit)

Kalau Anda sudah punya akses ke project Firebase `motocare-d902e`:

```bash
git clone https://github.com/MasApis/motocare.git
cd motocare
flutter pub get
flutterfire configure          # membuat 2 file rahasia (lihat bagian 3)
flutter run --dart-define=GROQ_API_KEY="gsk_..."
```

Setelah aplikasi terbuka, **dashboard kemungkinan masih kosong**. Itu bukan bug: token App Check Anda belum didaftarkan. Kerjakan [bagian 4](#4-app-check-sekali-pasang-tidak-dipikir-lagi) sekali saja, lalu jalankan ulang aplikasinya.

Kalau muncul error di salah satu langkah, lompat ke [tabel error](#10-error-yang-sering-muncul). Hampir semua masalah awal berasal dari bagian 3 dan 4 di bawah.

> **Tidak punya akses ke project `motocare-d902e`?** Anda harus punya project Firebase sendiri. Lihat [Lampiran A](#lampiran-a-memakai-project-firebase-sendiri).

---

## 3. Tiga file rahasia (paling sering bikin gagal)

Repo ini **sengaja tidak menyimpan** tiga file ini. Tanpa ketiganya, aplikasi gagal jalan.

| File | Untuk apa | Didapat dari |
|---|---|---|
| `android/app/google-services.json` | Menghubungkan aplikasi Android ke Firebase | `flutterfire configure` |
| `lib/firebase_options.dart` | Alamat & kunci project untuk kode Dart | `flutterfire configure` |
| `android/key.properties` | Tanda tangan APK rilis | Dibuat sendiri (hanya perlu saat build rilis) |

Kabar baiknya: **dua yang pertama dibuat otomatis.** File `firebase.json` di repo sudah menyimpan daftar project dan app ID, jadi cukup satu perintah:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Perintah itu akan menanyakan project mana yang dipakai. Pilih `motocare-d902e`, lalu platform **Android** saja.

Setelah selesai, pastikan kedua file benar-benar ada:

```bash
ls android/app/google-services.json lib/firebase_options.dart
```

Kalau file-file itu tidak muncul, `flutter run` akan berhenti dengan pesan seperti:

```
Exception: Gradle build failed. File google-services.json is missing.
```

`flutterfire configure` **aman dijalankan berkali-kali.** Kalau ada yang rusak, jalankan lagi.

### Kalau tidak bisa pakai `flutterfire configure`

Salin contoh yang sudah disiapkan:

```bash
cp lib/firebase_options.example.dart lib/firebase_options.dart
```

Lalu isi semua tulisan `GANTI_...` dengan nilai dari **Firebase Console → Project Settings → General → Your apps**.

Untuk `google-services.json`, unduh dari halaman yang sama: **Project Settings → Your apps → pilih app Android → Download google-services.json**.

**Jangan pernah** men-commit ketiga file itu. Semuanya sudah masuk `.gitignore`, jadi Anda tidak perlu khawatir — cukup jangan paksa dengan `git add -f`.

---

## 4. App Check: sekali pasang, tidak dipikir lagi

MotoCare memakai **Firebase App Check**. Fungsinya memastikan permintaan ke Firestore datang dari aplikasi asli, bukan dari skrip orang lain.

Saat mode debug, App Check memakai **debug token**: kode acak yang dibuat otomatis oleh aplikasi di HP Anda. Token ini **harus didaftarkan** dulu di Firebase Console. Kalau belum, semua permintaan ke Firestore ditolak dan dashboard tampak kosong tanpa penjelasan.

### 4a. Lihat token Anda

1. Colok HP, pastikan terdeteksi:

   ```bash
   flutter devices
   ```

2. Jalankan aplikasi:

   ```bash
   flutter run --dart-define=GROQ_API_KEY="gsk_..."
   ```

3. Buka terminal kedua, lalu:

   ```bash
   adb logcat -s com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider
   ```

   Jika tidak muncul apa-apa, nyalakan dulu log detailnya:

   ```bash
   adb shell setprop log.tag.com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider VERBOSE
   ```

   Lalu tutup dan buka lagi aplikasinya. Anda akan melihat:

   ```
   D DebugAppCheckProvider: Firebase App Check debug token:
                              xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
   ```

   **Salin token itu.** Ini satu-satunya cara melihatnya.

4. Matikan lagi log detail supaya tidak berisik:

   ```bash
   adb shell setprop log.tag.com.google.firebase.appcheck.debug.internal.DebugAppCheckProvider 0
   ```

### 4b. Daftarkan tokennya

Lewat browser — **bukan lewat CLI**:

1. Buka [Firebase Console → App Check → Apps](https://console.firebase.google.com/project/motocare-d902e/appcheck/apps)
2. Cari kartu app `com.hdp.motocare`, klik menu **⋮** → **Manage debug tokens**
3. **Add debug token**
   - Name: nama bebas, misal `HP saya`
   - Token: tempel token dari langkah 4a
4. **Save**

> **Penting:** perintah `firebase appcheck:debugtokens:create` **tidak bisa** mendaftarkan token yang Anda tentukan. Perintah itu membuat token acak baru. Jadi jangan buang waktu di sana — pakai halaman web di atas.

### 4c. Kenapa token berubah

Token debug disimpan di dalam data aplikasi. Kalau aplikasi **di-uninstall** atau **data aplikasi dibersihkan**, tokennya hilang dan dibuat ulang. Artinya Anda harus mendaftarkannya lagi. Ini normal, bukan bug.

### 4d. Token debug tidak berlaku untuk APK rilis

Build rilis memakai **Play Integrity**, bukan debug token. APK rilis yang dipasang manual (sideload) biasanya **gagal** pemeriksaan ini, sehingga aplikasi tampak rusak padahal kodenya benar.

Kalau App Check enforcement sedang aktif dan Anda membagikan APK rilis ke orang lain, pastikan APK itu dipasang lewat **Google Play Store**. Untuk pengujian lokal, gunakan `flutter run` (mode debug).

---

## 5. Aturan keamanan Firestore

Rules yang dipakai proyek ini sudah ada di `firestore.rules`: hanya pemilik `uid` yang bisa membaca dan menulis datanya.

**Jangan sekali-kali** memakai *test mode* Firebase (yang membuka database untuk siapa saja). Kalau database Anda masih test mode, pasang rules ini sekarang:

```bash
firebase login
firebase deploy --only firestore:rules
```

Atau lewat Console: **Firestore Database → Rules →** tempel isi `firestore.rules` **→ Publish**.

Detail tambahan ada di [`docs/FIRESTORE_RULES_SETUP.md`](docs/FIRESTORE_RULES_SETUP.md).

---

## 6. Aturan kerja (wajib dibaca sebelum kirim PR)

1. **Satu fitur per PR.** Jangan campur perbaikan bug dengan fitur baru. PR kecil lebih cepat ditinjau.
2. **Jangan menambah fitur di luar `docs/SPEC.md`.** Kalau punya ide, buka *issue* dulu. Ini bukan untuk membatasi — tapi supaya aplikasi tetap fokus pada satu masalah.
3. **`flutter analyze` harus bersih.** Nol peringatan, bukan "hanya satu-dua".
4. **`flutter test` harus lulus semua** (177 test saat dokumen ini ditulis).
5. **Tulis test** untuk logika baru di `lib/core/`, dan untuk perilaku widget yang penting.
6. **Ubah dulu, jalankan, baru lanjut.** Langkah kecil lebih mudah diperbaiki daripada satu perubahan besar.

Sebelum menyatakan selesai, jalankan:

```bash
flutter analyze
flutter test
```

Tempel hasil aslinya di deskripsi PR. Kalau ada yang gagal, katakan gagal.

---

## 7. Di mana "kebenaran" proyek ini disimpan

Kalau ragu tentang apa yang boleh dikerjakan, baca empat berkas ini. Ini sumber acuan, bukan saran.

| Berkas | Isinya | Kapan dibaca |
|---|---|---|
| [`docs/SPEC.md`](docs/SPEC.md) | Daftar fitur resmi, kriteria selesai | Sebelum mengerjakan fitur apa pun |
| [`docs/DESIGN.md`](docs/DESIGN.md) | Warna, font, ukuran, bentuk | Sebelum membuat atau mengubah tampilan |
| [`docs/design/SCREENS.md`](docs/design/SCREENS.md) | Peta layar desain → fitur | Sebelum membuat sebuah layar |
| [`docs/ERD.md`](docs/ERD.md) | Struktur data Firestore | Sebelum mengubah model atau skema |

Tampilan meniru desain di `docs/design/`, tapi **hanya fiturnya yang ada di SPEC**. Elemen desain yang fiturnya tidak ada di SPEC dihilangkan, bukan dijadikan tombol mati.

Data di desain (`Honda Vario 160`, `14.280 km`, `Rp 145.000`) hanya contoh. **Jangan di-hardcode.**

Kalau sebuah layar tidak ada di `docs/design/`, atau desainnya bertentangan dengan SPEC — berhenti dan tanya. Jangan menebak.

---

## 8. Konvensi kode

**Bahasa**
- Nama variabel, kelas, dan fungsi: bahasa Inggris.
- Teks di layar dan komentar: bahasa Indonesia.

**Struktur**

```
lib/core/                  fungsi murni + perhitungan (wajib punya unit test)
lib/features/<fitur>/data       repository & model
lib/features/<fitur>/providers  provider Riverpod
lib/features/<fitur>/ui         widget & halaman
lib/shared/                tema dan widget bersama
```

**Aturan yang paling sering dilanggar**

- **Widget tidak boleh memanggil Firestore langsung.** Selalu lewat provider → repository.
- **Rumus perhitungan hanya di `lib/core/`.** Persen, warna status, rata-rata km/hari, tanggal zona merah. Jangan disalin ke widget.
- **Warna dan ukuran hanya di `lib/shared/`.** Jangan tulis `Color(0xFF...)` di dalam widget.
- **Uang disimpan sebagai integer rupiah**, bukan `double`, bukan string.
- **Format rupiah dan tanggal pakai locale `id_ID`.**
- **Hindari `dynamic`.** Pakai tipe yang jelas.
- **Target sentuh minimal 48dp.** Status jangan dibedakan hanya dengan warna — sertakan teks atau ikon.

Detail lengkap ada di [`AGENTS.md`](AGENTS.md).

---

## 9. Perintah sehari-hari

| Perintah | Gunanya |
|---|---|
| `flutter pub get` | Ambil paket setelah `pubspec.yaml` berubah |
| `flutter analyze` | Cek kode sebelum kirim PR |
| `flutter test` | Jalankan semua test |
| `flutter test test/core/` | Jalankan test satu folder saja |
| `flutter devices` | Lihat HP yang tersambung |
| `flutter run` | Jalankan di HP (`r` = hot reload, `R` = restart, `q` = keluar) |
| `flutter build apk --debug` | Bikin APK uji |
| `adb logcat -s flutter` | Lihat log aplikasi |

> **Catatan:** output `flutter run` sering tertahan di terminal. Kalau butuh log, jalankan `adb logcat` di terminal terpisah.

### Build rilis (hanya kalau perlu)

Butuh `android/key.properties` berisi lokasi keystore:

```properties
storePassword=...
keyPassword=...
keyAlias=...
storeFile=/jalur/lengkap/ke/keystore.jks
```

Lalu:

```bash
flutter build apk --release --dart-define=GROQ_API_KEY="gsk_..."
```

File `key.properties` dan `*.jks` **tidak boleh** masuk repo. Keduanya sudah di-`.gitignore`.

### Kenapa APK debug besar

APK debug ± 200 MB (terpasang ± 386 MB) karena membawa `kernel_blob.bin` (134 MB) — kode Dart mentah yang hanya dipakai mode debug — plus `libflutter.so` untuk tiga arsitektur prosesor (arm64, x86_64, armeabi-v7a), padahal HP Anda hanya memakai satu.

Hemat ± 70 MB saat testing:

```bash
flutter run --target-platform android-arm64
```

Atau untuk APK bersama:

```bash
flutter build apk --release --split-per-abi
```

Hasilnya 21–25 MB per APK, tergantung arsitektur. Bagikan yang `arm64-v8a`.

Cek arsitektur HP: `adb shell getprop ro.product.cpu.abi`.

Rincian angka dan peringatan Play Integrity ada di [README bagian 9](README.md#9-ukuran-apk).

---

## 10. Error yang sering muncul

| Gejala | Penyebab | Solusi |
|---|---|---|
| Dashboard kosong, log ada `403` atau `PERMISSION_DENIED` | Token App Check belum didaftarkan | Ulangi [bagian 4](#4-app-check-sekali-pasang-tidak-dipikir-lagi) |
| `File google-services.json is missing` | `flutterfire configure` belum dijalankan | Bagian 3 |
| `firebase_options.dart` tidak ditemukan | Sama seperti di atas | Bagian 3 |
| Tanggal muncul `November 12, 2026` (bahasa Inggris) | `initializeDateFormatting('id_ID')` tidak dijalankan | Pastikan `main()` masih memanggilnya; jangan dihapus |
| `Helvetica has no Unicode support` saat buat PDF | Ada karakter non-Latin di teks yang dicetak | Pakai `rupiah()` dari `lib/core/`; jangan pakai simbol aneh di nama bengkel |
| Notifikasi pukul 08:00 tidak muncul | Izin "Alarm & pengingat" belum diizinkan | Pengaturan HP → Aplikasi → MotoCare → izin Alarm & pengingat |
| Notifikasi tidak muncul sama sekali | Izin notifikasi ditolak | Pengaturan HP → Aplikasi → MotoCare → Notifikasi |
| "KM baru tidak boleh lebih kecil dari KM terakhir" | Memang validasi, bukan bug | Isi odometer ≥ angka terakhir |
| Chat AI bilang kunci API belum dikonfigurasi | `--dart-define=GROQ_API_KEY` tidak disertakan | Jalankan dengan parameter itu |
| Chat AI bilang kunci tidak valid | Kunci Groq salah atau sudah dicabut | Buat kunci baru di [console.groq.com/keys](https://console.groq.com/keys) |
| Perubahan di `docs/` tidak ikut ter-commit | `.gitignore` memuat `docs/*` | `git add -f docs/nama_file.md` |
| `flutter analyze` bersih tapi `flutter test` gagal | Test lama menyesuaikan perilaku lama | Perbaiki kodenya, bukan testnya — kecuali memang perilakunya sengaja diubah |

---

## 11. Checklist sebelum kirim PR

- [ ] `flutter analyze` — **No issues found!**
- [ ] `flutter test` — **All tests passed!**
- [ ] Sudah dicoba di HP Android asli, bukan hanya di emulator
- [ ] Tidak ada kunci API, password, atau isi `google-services.json` di diff
- [ ] Fitur yang dikerjakan ada di `docs/SPEC.md`
- [ ] Kalau mengubah tampilan: nilai warna/ukuran diambil dari `lib/shared/`, tidak ditulis di widget
- [ ] Kalau mengubah skema data atau rumus: `docs/SPEC.md` ikut diperbarui
- [ ] Tidak ada file sementara, `print()` debug, atau kode mati yang tertinggal
- [ ] Pesan commit jelas: `fix: ...`, `feat: ...`, atau `docs: ...`

Cek cepat kalau curiga ada rahasia yang ikut:

```bash
git diff --cached | grep -iE "AIza|gsk_|password|secret|api[_-]?key"
```

Kalau ada hasil, **jangan commit**. Hapus dulu.

---

## Lampiran A: memakai project Firebase sendiri

Kalau Anda tidak punya akses ke `motocare-d902e`:

1. Buat project baru di [Firebase Console](https://console.firebase.google.com/) — pakai paket **Spark** (gratis, tanpa kartu kredit).
2. **Authentication → Sign-in method →** aktifkan **Email/Password**.
3. **Firestore Database → Create database**. Pilih mode produksi (bukan test mode).
4. **Project Settings → General → Your apps → Add app → Android**. Isi package name sesuai `applicationId` di `android/app/build.gradle.kts` (saat ini `com.hdp.motocare`). Kalau Anda menggantinya, ganti juga di file itu.
5. Jalankan `flutterfire configure` dan pilih project baru Anda.
6. Deploy rules: `firebase deploy --only firestore:rules`
7. Daftarkan debug token App Check ([bagian 4](#4-app-check-sekali-pasang-tidak-dipikir-lagi)).

Paket Spark cukup untuk semua fitur di proyek ini. Kalau ada langkah di Console yang meminta upgrade ke Blaze atau kartu kredit, **berhenti** — proyek ini tidak membutuhkannya.

---

## Lampiran B: daftar berkas rahasia

Agar tidak ragu, ini daftar lengkap yang **tidak boleh** masuk repo:

```
android/app/google-services.json
android/key.properties
lib/firebase_options.dart
*.jks
*.keystore
.env
```

Semuanya sudah tercantum di `.gitignore`. Kalau Anda membuat berkas rahasia dengan nama lain, tambahkan sendiri ke `.gitignore`.
