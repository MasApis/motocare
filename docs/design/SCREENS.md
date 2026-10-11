# Peta Layar Desain MotoSense ke Fitur MotoCare

Folder ini berasal dari export **Google Stitch**. Tiap layar punya `screen.png` (tampilan) dan `code.html` (HTML + Tailwind, memuat nilai persisnya). Warna, font, dan bentuk ada di `docs/DESIGN.md`.

## Aturan utama
1. **Tampilan meniru desain**: susunan, gaya kartu, warna, font, bentuk, dan jarak. 
2. **Fitur hanya yang ada di `docs/SPEC.md`.** Elemen desain yang fiturnya tidak ada di SPEC **dihilangkan dari layar** (bukan tombol mati, bukan placeholder). Rapikan susunan agar layar tetap seimbang.
3. Data contoh di desain (Honda Vario 160, 14.280 km, Rp 145.000, nama bengkel, dst.) hanya contoh; jangan di-hardcode.
4. Klaim pemasaran yang tidak benar untuk MotoCare tidak ditampilkan: terkoneksi OBD-II/telemetri IoT, enkripsi atau standar teknis (TLS 256-bit, ISO-14229), garansi dan kupon, sinkron dengan riwayat resmi pabrikan, "menaikkan harga jual 15%".
5. Teks status komponen mengikuti SPEC (Aman / Peringatan / Batas habis), bukan teks contoh di desain.

## Navigasi bawah (5 tab, seperti `beranda_status_motor_2`)
| Tab | Layar acuan | Fitur |
|-----|-------------|-------|
| Beranda | `beranda_status_motor_2` | F2, F3, F4 |
| Catat | `form_pencatatan_mandiri_motor` | F5 |
| Buku Servis | `buku_servis_pengeluaran` | F8 |
| Chat AI | `chat_bot_ai_asisten_motor` | F7 |
| Riwayat | `riwayat_servis_keseluruhan` | F5 |

Layar di luar tab: `login_registrasi_motosense` (F1) dan `setup_pertama_kali_motor_motosense` (F2, tambah motor).

## Dipertahankan dan dibuang per layar

**`login_registrasi_motosense` (F1)**
- Pertahankan: logo, judul sambutan, tab Masuk/Daftar, kolom email dan kata sandi (ikon tampil/sembunyi), "Ingat Saya" hanya jika sesi memang memakainya, tombol utama, tautan Ketentuan/Privasi hanya jika halamannya ada.
- Buang: nomor WhatsApp, PIN 6 digit, "Pendaftaran Instan", Google, Apple ID, "Coba Demo", semua teks OBD-II/IoT/enkripsi. "Lupa Kata Sandi" hanya jika SPEC memintanya (saat ini tidak, jadi buang).

**`setup_pertama_kali_motor_motosense` (F2, tambah motor)**
- Pertahankan: kartu bagian Merek, Model (pilihan preset matic + ketik manual), Nomor Polisi (opsional), KM speedometer saat ini; tombol simpan.
- Buang: indikator "Langkah 1 dari 2", tahun produksi, kapasitas mesin, nama panggilan, estimasi jarak harian, baseline oli terakhir, kartu "Prediksi Pintar/MotoAI", tombol "Nanti Saja", tautan "Bantuan".

**`beranda_status_motor_2` (F2, F3, F4)**
- Pertahankan: header (logo, nama motor aktif, ikon pengaturan yang membuka menu berisi Keluar), kartu motor (nama, plat, odometer, "x hari lalu", rata-rata km/hari, tombol "Update KM Hari Ini"), kartu peringatan servis terdekat (dihitung dari SPEC bagian 2.1), tiga kartu komponen dengan progress bar, persen terpakai, sisa km, badge status, bottom navigation. Tambahkan carousel geser antar motor sesuai SPEC (tidak digambar di desain).
- Buang: avatar foto, Skor Kesehatan Mesin, grid "Pencatatan Mandiri" (Isi Bensin, Pajak STNK), "Est. km hari ini", kartu Kampas Rem dan Filter Udara, "Lihat Semua", kartu Pajak STNK.

**`form_pencatatan_mandiri_motor` (F5)**
- Pertahankan: kartu motor aktif, KM saat servis (tombol "gunakan KM terkini"), tanggal, pilihan komponen berbentuk chip (hanya Oli Mesin, Oli Gardan, V-Belt; satu catatan = satu komponen), nama bengkel, total biaya, catatan, tombol simpan.
- Tambahkan: kolom **merek** (mis. merek oli) sesuai SPEC F5; desain belum punya.
- Buang: tab Isi Bensin/Pajak STNK, pilihan Filter Udara & Busi / Lainnya, foto struk, "Reset Formulir", "Pintasan Form Lainnya", kartu "Buku Servis Terverifikasi".

**`buku_servis_pengeluaran` (F8)**
- Pertahankan: kartu "Pengeluaran Bulan Ini" (total) dengan pemilih bulan, daftar riwayat servis bulan itu, tombol Unduh PDF.
- Buang: pemisahan Bensin/Perawatan, tombol "Catat Pengeluaran Baru", kartu "Jadwal Servis Terdekat" beserta estimasi biaya dan item disarankan, filter Bensin/Sparepart, Ekspor/Excel, kartu "Buku Servis Terverifikasi".

**`riwayat_servis_keseluruhan` (F5)**
- Pertahankan: linimasa servis terbaru dulu (tanggal, KM, jenis, bengkel, harga), gaya kartu dan garis waktu, hapus catatan dengan konfirmasi (SPEC).
- Buang: ringkasan (kunjungan, total biaya, odometer), "Laporan Buku Servis" (PDF ada di tab Buku Servis), badge Struk/Garansi/Kupon/Garansi Pabrik, "Lihat Struk", filter chip, catatan sinkron/terenkripsi.

**`chat_bot_ai_asisten_motor` (F7)**
- Pertahankan: header MotoAI, chat bubble, waktu, kolom ketik dan tombol kirim, loading. Judul mengikuti motor aktif (bukan selalu "Vario 160").
- Buang: chip pertanyaan cepat, tombol "Jadwalkan Servis" dan estimasi harga di jawaban, ikon lampirkan gambar, lencana "AI Expert". Tambahkan pengingat singkat "ini dugaan" sesuai SPEC.

**Tidak dipakai:** `beranda_status_motor_1` (duplikat beranda, navigasi berbeda), `buku_servis_riwayat_perawatan` (duplikat; boleh jadi rujukan gaya item riwayat), `panduan_cek_fisik_mandiri` (fitur tidak ada di SPEC), `image.png_1`, `image.png_2` (potongan gambar beranda).

## Cara menerjemahkan layar ke Flutter
- Buka `code.html` layar itu untuk melihat teks, warna, ukuran, susunan; cocokkan dengan `screen.png`.
- Kelas Tailwind diterjemahkan ke nilai di tema (`lib/shared/`), bukan disalin satu-satu ke tiap widget.
- Font Plus Jakarta Sans dan Inter, serta ikon Material Symbols Outlined, dimuat dari internet di HTML; di Flutter pasang lewat aset lokal atau paket (minta persetujuan sebelum menambah paket).
- Progress bar menampilkan "% terpakai" = 100 dikurangi persen sisa; warna dan status mengikuti ambang di SPEC bagian 2.1.
- Bandingkan hasil di HP dengan `screen.png` sambil hot reload.
