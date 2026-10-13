# SPEC: MotoCare v2

| | |
|---|---|
| **Nama Proyek** | MotoCare |
| **Jenis** | Aplikasi mobile Android (Flutter) |
| **Mata kuliah** | Pemrograman Perangkat Bergerak |
| **Versi SPEC** | 2.3 |
| **Penulis** | Abdul |

Dokumen ini adalah sumber kebenaran pengembangan. Jika kode dan SPEC berbeda, SPEC dianggap benar sampai diubah secara sengaja.

---

## 1. Ringkasan

MotoCare membantu pemilik **motor matic** memantau sisa usia pakai komponen (oli mesin, oli gardan, V-belt), mencatat servis, diingatkan sebelum komponen habis, dan bertanya keluhan motor ke asisten AI.

### 1.1 Tujuan
- Pemilik motor tahu kapan harus servis tanpa menghafal jadwal.
- Riwayat servis dan pengeluaran tercatat rapi per motor.
- Aplikasi siap dipakai banyak orang (rilis publik) setelah tugas kuliah.

### 1.2 Target Pengguna
Pemilik motor matic harian: mahasiswa, pekerja, pengemudi ojek online.

### 1.3 Ruang Lingkup
- **Termasuk:** F1 sampai F8 (bagian 5).
- **Tidak termasuk:** motor non-matic (bebek/sport), iOS, pembayaran, marketplace bengkel, sensor odometer otomatis (OBD/GPS).

---

## 2. Keputusan Teknis

| Hal | Keputusan |
|-----|-----------|
| Framework | Flutter (Dart), Android saja |
| State management | **Riverpod** (`flutter_riverpod`) |
| Backend | **Firebase**: Authentication (email + password) dan Cloud Firestore (offline persistence aktif) |
| Navigasi | `go_router` |
| AI | LLM via **Groq Cloud API** (`llama-3.1-8b-instant`) gratis tanpa kartu kredit (fallback/opsi Firebase AI Logic tersedia); kunci API diinjeksi via `--dart-define=GROQ_API_KEY` saat menjalankan aplikasi. **Kunci API tidak disimpan di kode aplikasi maupun repositori.** Cloud Functions dan Vertex AI/Agent Platform berbayar **tidak dipakai** |
| Notifikasi | `flutter_local_notifications`, notifikasi dijadwalkan pada tanggal tertentu (tanpa background service) |
| PDF | `pdf` + `printing` (atau `share_plus`) |
| UI/UX | Desain dari **Google Stitch** (export zip) di `docs/design/` (tiap layar: `screen.png` + `code.html`); peta layar ke fitur di `docs/design/SCREENS.md`; aturan visual di `docs/DESIGN.md` (MotoSense Design System). `code.html` hanya acuan nilai dan tata letak, bukan kode yang disalin ke Flutter |
| Test | `flutter_test`; paket test tambahan hanya dengan persetujuan |
| Lint | `flutter_lints` + `flutter analyze` |

Versi paket dicek terbaru saat scaffolding, lalu dikunci di `pubspec.yaml`.

### 2.1 Aturan Inti Perhitungan
Semua aturan ini ditulis sebagai **fungsi murni di `lib/core/`** dengan unit test, tanpa bergantung pada Firebase atau UI.

**Komponen** (tiap motor punya tiga): `engine_oil` (oli mesin), `gear_oil` (oli gardan), `v_belt`.

**Interval default** (asumsi awal, **verifikasi dengan buku manual motor**, dapat diubah pengguna per motor):

| Komponen | Interval default |
|----------|------------------|
| Oli mesin | 2.000 km |
| Oli gardan | 8.000 km |
| V-belt | 20.000 km |

**Rumus:**
- `km_terpakai = km_sekarang - km_servis_terakhir`
- `sisa_km = interval - km_terpakai`
- `persen = clamp(sisa_km / interval, 0, 1) × 100`

**Warna indikator** (asumsi, konstanta di satu tempat):

| Persen | Warna |
|--------|-------|
| > 30% | Hijau (Aman) |
| 10% sampai 30% | Kuning (Peringatan) |
| < 10% | Merah (Batas habis) |

**Rata-rata KM harian:** dari catatan odometer 30 hari terakhir: `(km terbaru - km tertua) / selisih hari`. Dibutuhkan minimal dua catatan dengan selisih ≥ 3 hari; jika tidak, pakai nilai awal **20 km/hari** (asumsi).

**Tanggal masuk zona merah:** `hari ini + ((sisa_km - 10% × interval) / rata2_harian)` hari. Jika sudah merah, dianggap hari ini.

**Validasi odometer:** KM baru tidak boleh lebih kecil dari KM terakhir.

**Nilai awal komponen:** saat motor dibuat, `lastServiceKm` tiap komponen = KM saat ini (dianggap baru diservis), sehingga semua mulai 100%. Pengguna memperbaikinya dengan mencatat servis di F5. Nilai ini juga disimpan sebagai `baselineKm` komponen.

**Aturan servis (F5), DITUNDA sampai Tahap 7b; kode F5 saat ini belum mengikutinya:**
- Satu catatan servis = satu kunjungan ke bengkel, berisi satu atau lebih **item**.
- Item bertipe **komponen** (oli mesin, oli gardan, V-belt) atau **part lain** (bebas, mis. roller, kampas ganda, busi, filter udara, kampas rem).
- Oli mesin dan oli gardan hanya bisa **diganti**. V-belt (CVT) bisa **diganti** atau **dibersihkan**. Part lain selalu dianggap diganti.
- Hanya komponen yang **diganti** yang mereset kartunya: `lastServiceKm` = KM servis. **Dibersihkan** tidak mereset, tetapi tetap tercatat di riwayat.
- Part lain tidak memengaruhi kartu mana pun; hanya tercatat di riwayat.
- "Servis CVT" di MotoCare = item V-belt (diganti atau dibersihkan) ditambah part lain yang diganti, jika ada.
- Saat catatan dihapus, `lastServiceKm` tiap komponen dihitung ulang: KM dari catatan "diganti" untuk komponen itu dengan KM tertinggi yang tersisa; jika tidak ada, kembali ke `baselineKm`.

---

## 3. Arsitektur

```
UI (widget) → Provider (Riverpod) → Repository → Firestore / Firebase Auth
                      ↓
              core/ (fungsi murni perhitungan)
```

```
motocare/
├── lib/
│   ├── core/            # perhitungan, konstanta (interval, warna), util format
│   ├── features/
│   │   ├── auth/        # data/, providers/, ui/
│   │   ├── vehicles/
│   │   ├── dashboard/
│   │   ├── odometer/
│   │   ├── service/     # input servis + riwayat
│   │   ├── notifications/
│   │   ├── chatbot/
│   │   └── reports/
│   ├── shared/          # tema, widget bersama
│   └── main.dart
├── test/
├── docs/{SPEC.md, DESIGN.md}
└── AGENTS.md
```

Aturan: widget tidak memanggil Firestore langsung; semua lewat provider dan repository.

---

## 4. Desain Data (Firestore)

```
users/{uid}
  └─ vehicles/{vehicleId}:  name, brand, model, plate (opsional), currentKm, createdAt
       ├─ components/{type}:   type, intervalKm, lastServiceKm, baselineKm (KM saat motor dibuat)
       ├─ odometerLogs/{id}:   km, date
       └─ serviceRecords/{id}: date, km, location, price (rupiah, integer; total satu kunjungan), note, items[]
            items[] = { kind: "component" | "part", componentType (jika kind = component: engine_oil | gear_oil | v_belt),
                        action: "replaced" | "cleaned", name (wajib jika kind = part), brand (opsional) }
```

> Skema `serviceRecords` dan `baselineKm` di atas telah aktif dan diimplementasikan pada revisi F5.

- Semua data berada di bawah `users/{uid}`; **security rules** hanya mengizinkan pemilik `uid` yang login membaca dan menulis datanya.
- `price` disimpan sebagai bilangan bulat rupiah.
- Menghapus kendaraan menghapus seluruh sub-koleksinya.

---

## 5. Fitur dan Kriteria Selesai

Fitur dianggap **selesai** jika semua kriterianya terpenuhi, test terkait lulus, `flutter analyze` bersih, dan sudah dicek di HP.

#### F1. Autentikasi
**Kriteria selesai:**
- Pengguna bisa daftar dan masuk dengan email + password; pesan error ramah (email dipakai, password lemah, password salah).
- Sesi bertahan setelah aplikasi ditutup dan dibuka lagi.
- Ada tombol Keluar.
- Layar utama hanya bisa dibuka setelah masuk.
- Security rules Firestore terpasang dan diuji: pengguna lain tidak bisa membaca data kita.

#### F2. Multi-Kendaraan dan Carousel
**Kriteria selesai:**
- Pengguna bisa menambah, mengubah, menghapus motor (hapus dengan konfirmasi). Pilihan model matic tersedia sebagai preset dan bisa diketik manual.
- Dashboard menampilkan carousel kartu yang bisa digeser kiri/kanan; berganti motor mengganti seluruh data dashboard.
- Saat motor dibuat, tiga komponen dibuat otomatis dengan interval default.
- Interval tiap komponen bisa diubah per motor.
- Kondisi tanpa motor menampilkan empty state yang mengajak menambah motor.

#### F3. Dashboard Motor Health Card
**Kriteria selesai:**
- Tiga kartu (oli mesin, oli gardan, V-belt) tampil dengan progress bar (sesuai desain), persen, dan sisa KM.
- Warna dinamis sesuai aturan bagian 2.1; penanda tidak hanya warna (ada teks status: Aman / Peringatan / Batas habis).
- Perhitungan memakai fungsi di `core/` dengan unit test (termasuk batas 30%, 10%, 0%, dan KM melebihi interval).
- Tampilan mengikuti layar beranda di `docs/design/` dan `docs/DESIGN.md`.

#### F4. Hybrid Odometer
**Kriteria selesai:**
- Pengguna bisa memasukkan KM terbaru dengan form singkat (tanggal default hari ini).
- Validasi: KM tidak boleh turun; input non-angka ditolak dengan pesan jelas.
- Setelah disimpan, dashboard langsung diperbarui.
- Rata-rata KM harian dihitung sesuai bagian 2.1 dan terlihat di layar (mis. "± 25 km/hari"), ada unit test untuk kasus data kurang.

#### F5. Interactive Service Input dan Riwayat
> **Status:** Revisi F5 telah selesai diimplementasikan (multi-item per kunjungan servis, aksi diganti/dibersihkan, part lain, dan baselineKm).

**Kriteria selesai:**
- Menekan kartu komponen (atau tab Catat) membuka form catat servis; komponen dari kartu yang ditekan sudah terpilih. Isian: KM (default KM sekarang), tanggal, nama bengkel, total biaya, catatan opsional.
- Pengguna bisa memilih **satu atau lebih komponen** (oli mesin, oli gardan, V-belt/CVT). Oli selalu "diganti"; V-belt memilih "Diganti" atau "Dibersihkan". Komponen yang diganti punya merek opsional.
- Ada bagian **"Part lain yang diganti"**: nol atau lebih baris (nama part wajib, merek opsional) dengan tombol tambah dan hapus baris.
- Validasi: minimal satu item; harga tidak boleh negatif (0 diperbolehkan untuk servis gratis); input tidak valid ditolak dengan pesan jelas.
- Setelah disimpan: satu catatan masuk "Riwayat Servis"; hanya komponen yang **diganti** yang `lastServiceKm`-nya terisi dan kartunya kembali 100%. Komponen yang **dibersihkan** dan part lain tidak mengubah kartu (aturan servis, bagian 2.1).
- Tiap catatan di riwayat menampilkan daftar item dengan label "diganti" atau "dibersihkan", total biaya, dan bengkel.
- Test untuk aturan reset: komponen diganti vs dibersihkan, beberapa komponen sekaligus, hanya part lain, hapus catatan, dan kembali ke `baselineKm`.
- Riwayat Servis menampilkan daftar terbaru dulu, bisa difilter per motor, dengan format rupiah dan tanggal Indonesia.
- Catatan servis bisa dihapus (dengan konfirmasi); kartu komponen kembali menghitung dari servis sebelumnya.

#### F6. Smart Push Notification (Lokal)
**Kriteria selesai:**
- Setiap odometer baru atau servis baru memicu perhitungan ulang tanggal masuk zona merah tiap komponen, dan notifikasi lama dibatalkan lalu dijadwalkan ulang.
- Notifikasi muncul pada tanggal tersebut pukul 08:00 waktu lokal, tanpa membuka aplikasi, menyebut nama motor dan komponen.
- Jika komponen sudah merah saat KM diinput, notifikasi muncul langsung (sekali per komponen sampai di-reset).
- Izin notifikasi diminta dengan sopan; jika ditolak, aplikasi tetap jalan dan menjelaskan dampaknya.
- Logika penjadwalan (hitung tanggal) punya unit test.

#### F7. Chatbot Diagnosa (AI Assistant)
**Kriteria selesai:**
- Tampilan seperti chat bubble; pengguna mengetik keluhan, AI membalas dugaan penyebab dan saran.
- AI diberi peran ahli mekanik motor matic dan konteks motor aktif (model, KM sekarang, status komponen).
- Setiap jawaban disertai pengingat singkat bahwa ini dugaan dan perlu dicek bengkel untuk masalah serius; pertanyaan di luar topik motor ditolak dengan sopan.
- Ada status mengetik/loading, pesan gagal yang ramah saat offline atau API error, dan batas panjang pesan.
- **Kunci API tidak ada di kode aplikasi maupun repositori** (dioper via `--dart-define=GROQ_API_KEY`).
- Berjalan 100% gratis tanpa kartu kredit: tidak ada layanan yang membutuhkan Blaze atau langganan berbayar.
- Hemat kuota gratis: batas panjang pesan (300 karakter), hanya beberapa pesan terakhir (10 pesan) yang dikirim sebagai konteks, tombol kirim nonaktif saat menunggu jawaban.
- Saat kuota atau batas laju tercapai, tampil pesan ramah ("coba lagi nanti"), bukan error teknis.
- Riwayat chat cukup di memori sesi (tidak disimpan permanen pada versi ini).

#### F8. Laporan Bulanan PDF
**Kriteria selesai:**
- Halaman Laporan menampilkan total pengeluaran servis bulan terpilih (mis. "Pengeluaran September: Rp 150.000") dan bisa berganti bulan.
- Tombol "Unduh Laporan PDF" membuat PDF berisi tabel riwayat satu baris per kunjungan (tanggal, ringkasan item seperti "Oli Mesin (diganti), V-Belt (dibersihkan), Roller (diganti)", bengkel, total biaya) dan total bulan.
- File bisa dibuka atau dibagikan dari HP (cara simpan mengikuti aturan penyimpanan Android, diputuskan di rencana).
- Bulan tanpa data menampilkan pesan yang jelas, bukan PDF kosong.
- Perhitungan total punya unit test.

### 5.1 Layar
Tata letak layar mengikuti `docs/design/` (10 layar; lihat `docs/design/SCREENS.md` untuk peta layar ke fitur dan daftar elemen yang belum ada di SPEC). Tampilan meniru desain, tetapi fitur hanya yang ada di SPEC ini: elemen desain tanpa fitur di SPEC **dihilangkan dari layar** (bukan tombol mati atau placeholder).

---

## 6. Kebutuhan Non-Fungsional

- **Performa:** dashboard tampil kurang dari 2 detik; gulir dan carousel lancar di HP kelas menengah.
- **Offline:** dashboard, odometer, dan riwayat tetap bisa dipakai tanpa internet (Firestore offline persistence); chatbot butuh internet.
- **Keamanan:** security rules, tidak ada rahasia di repositori, validasi semua input.
- **Aksesibilitas:** kontras memadai, teks mengikuti ukuran font sistem, target sentuh ≥ 48dp.
- **Lokalisasi:** seluruh teks bahasa Indonesia; format rupiah dan tanggal `id_ID`.

## 7. Strategi Pengujian

- **Unit test:** seluruh fungsi di `core/` (persen, warna, rata-rata harian, tanggal zona merah, total laporan).
- **Widget test:** kartu kesehatan (warna dan teks per kondisi), form servis (validasi).
- **Uji manual di HP asli:** tiap fitur sesuai daftar cek di PANDUAN.

## 8. Risiko dan Mitigasi

| Risiko | Mitigasi |
|--------|----------|
| Kunci Gemini bocor | Jangan di kode aplikasi; lewat Firebase AI Logic (tanpa kunci di aplikasi) + App Check |
| Kuota gratis Gemini habis atau berubah | Batasi panjang pesan dan konteks, pesan ramah saat limit; opsi paket berbayar nanti jika pengguna bertambah |
| Interval komponen tidak akurat | Bisa diubah pengguna; tampilkan catatan "sesuaikan dengan buku manual" |
| Notifikasi tidak muncul (penghemat baterai HP tertentu) | Beri panduan di aplikasi; uji di HP asli |
| Scope terlalu besar | Satu fitur per tahap; selesai F1 sampai F5 dulu sebagai inti |
| Aturan penyimpanan file Android berubah-ubah | Putuskan di rencana, uji di HP asli |

## 9. Kriteria Keberhasilan

- F1 sampai F8 berjalan di HP asli tanpa crash.
- Pengguna baru bisa menambah motor dan melihat dashboard dalam kurang dari 2 menit.
- Cakupan test pada fungsi di `core/` minimal 80%.
- Tidak ada rahasia di repositori.

## 10. Urutan Pengerjaan

Scaffolding + Firebase → Tema dari desain → F1 → F2 → F3 → F4 → F5 → F6 → F7 → F8 → Verifikasi akhir → Persiapan rilis (opsional).

## 11. Keputusan Terbuka

- Interval default dan ambang warna (bagian 2.1) masih asumsi; verifikasi dengan buku manual motor.
- Rilis publik: App Check produksi (di Android memakai Play Integrity) dan apakah kuota gratis Gemini cukup; mungkin perlu paket berbayar. Cek ketentuan penggunaan data pada tier gratis sebelum rilis.
- Apakah rilis publik butuh fitur tambahan (hapus akun, kebijakan privasi); lihat Tahap 12 di panduan.