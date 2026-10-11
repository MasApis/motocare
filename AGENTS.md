# AGENTS.md: MotoCare

Sebelum mengerjakan fitur, baca `docs/SPEC.md` (fitur), `docs/DESIGN.md` (aturan visual), dan `docs/design/SCREENS.md` (peta layar). Jangan mengerjakan di luar SPEC.

Aplikasi Flutter perawatan motor matic. `docs/SPEC.md` adalah sumber kebenaran fitur; `docs/DESIGN.md` adalah aturan visual. Baca bagian yang relevan sebelum mengerjakan apa pun.

## Tentang Pengguna
Pemula. Jelaskan dengan bahasa Indonesia sederhana, singkat, tanpa istilah yang tidak dijelaskan. Sistem pengguna: Linux Mint, dites di HP Android asli lewat kabel USB (bukan emulator).

## Aturan Kerja
1. **Satu fitur per sesi.** Kerjakan hanya fitur yang diminta di prompt.
2. **Jangan menambah fitur di luar `docs/SPEC.md`.** Jika ragu atau ada ide, tanya dulu.
3. **Rencanakan dulu** untuk perubahan besar (struktur folder, paket baru, skema Firestore, fitur baru): tampilkan rencana singkat dan tunggu persetujuan.
4. **Langkah kecil.** Ubah sedikit, jalankan, lanjut.
5. **Sebelum menyatakan selesai**, jalankan `flutter analyze` dan `flutter test`, lalu laporkan hasilnya apa adanya. Jangan bilang berhasil jika belum dijalankan atau gagal.
6. **Cek setiap kriteria selesai** fitur di SPEC dan laporkan satu per satu: terpenuhi atau belum.
7. **Tulis test** untuk logika di `lib/core/` dan untuk perilaku penting widget.
8. **Jangan menjalankan `git commit`, `git push`, atau perintah yang menghapus data.** Pengguna yang commit sendiri. Cukup berikan saja pesan commit.
9. **Jangan memasang paket baru** di luar daftar SPEC tanpa menjelaskan alasannya dan meminta persetujuan.
10. Jika perintah gagal, tunjukkan pesan error, jelaskan penyebabnya dengan sederhana, lalu perbaiki. Jangan menyembunyikan error.
11. Jika mengubah skema data atau aturan perhitungan, perbarui `docs/SPEC.md` dan sebutkan di ringkasan.
12. Setelah selesai, tulis ringkasan: file yang diubah, perintah yang perlu dijalankan pengguna, dan apa yang perlu dicek di HP.

## UI/UX (desain dari Stitch, ada di folder `docs/design/`)
- Tiap layar punya folder berisi `screen.png` (tampilan) dan `code.html` (HTML + Tailwind, memuat warna, ukuran, teks, dan susunan persisnya). Baca **keduanya** sebelum membuat sebuah layar; kalau tidak bisa melihat gambar, andalkan `code.html`.
- **HTML tidak disalin ke Flutter.** Terjemahkan ke widget Flutter: kelas Tailwind (mis. `rounded-full`, `p-4`) menjadi nilai yang setara di tema; nilai warna dan font diambil dari `docs/DESIGN.md`.
- Warna, font, bentuk, dan jarak didefinisikan **sekali** di `lib/shared/` (tema), bukan ditulis ulang di tiap widget.
- Data contoh di desain (nama motor, angka, nama bengkel, "Rp 145.000", dll.) hanyalah contoh. **Jangan di-hardcode**; ambil dari data sebenarnya.
- Peta layar ke fitur ada di `docs/design/SCREENS.md` (apa yang dipertahankan dan dibuang per layar). Tampilan meniru desain, tetapi fitur hanya yang ada di SPEC: elemen desain tanpa fitur di SPEC **dihilangkan dari layar** (bukan tombol mati atau placeholder), lalu susunan dirapikan agar tetap seimbang.
- Klaim pemasaran di desain yang tidak benar untuk aplikasi ini (mis. "terkoneksi ke OBD-II", enkripsi/standar teknis, garansi, "naikkan harga jual 15%") **jangan ditampilkan**.
- Jika layar yang diminta tidak ada di `docs/design/`, atau desain berbeda dengan SPEC, berhenti, laporkan perbedaannya, dan tanya mana yang dipakai. Jangan menebak desain.

## Tech Stack
Flutter (Dart), Android. Riverpod, go_router, Firebase Auth + Cloud Firestore, flutter_local_notifications, pdf + printing, Gemini (tanpa kunci di aplikasi).

## Struktur
```
lib/core/      # fungsi murni perhitungan + konstanta (wajib punya unit test)
lib/features/<fitur>/{data,providers,ui}
lib/shared/    # tema, widget bersama
test/
```
Widget tidak memanggil Firestore langsung; selalu lewat provider dan repository.

## Konvensi Kode
- Dart null-safe, hindari `dynamic`. Patuhi `flutter_lints`.
- Nama kode dalam bahasa Inggris; teks antarmuka dan komentar singkat dalam bahasa Indonesia.
- Format rupiah dan tanggal memakai locale `id_ID`; harga disimpan sebagai integer rupiah.
- Aturan perhitungan (persen, warna, rata-rata harian, tanggal zona merah) hanya ada di `lib/core/`; jangan menduplikasinya di widget.
- Provider Riverpod per fitur; hindari state global yang tidak perlu.
- Aksesibilitas: target sentuh ≥ 48dp, status tidak hanya dengan warna, dukung ukuran font sistem.

## Perintah
| Perintah | Fungsi |
|----------|--------|
| `flutter pub get` | Ambil paket |
| `flutter analyze` | Periksa kode |
| `flutter test` | Jalankan test |
| `flutter devices` | Lihat perangkat tersambung |
| `flutter run` | Jalankan di HP (tekan `r` untuk hot reload, `q` untuk berhenti) |
| `flutter build apk --debug` | Bangun APK uji |

## Keamanan (wajib)
- **Jangan pernah menaruh kunci API (Gemini dll.) di kode, aset, atau repositori.**
- Jangan membaca, mencetak, atau meng-commit file rahasia (`.env`, keystore, `key.properties`).
- Security rules Firestore: hanya pemilik `uid` yang bisa membaca dan menulis datanya.
- Validasi semua input pengguna.

## Definisi Selesai
Fitur selesai jika: semua kriteria di SPEC terpenuhi, `flutter analyze` bersih, `flutter test` lulus, dan pengguna sudah mengecek di HP.
