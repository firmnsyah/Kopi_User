# Panduan Penggunaan Aplikasi Kopi User

Aplikasi kasir dan manajemen bisnis untuk kedai kopi. Mencatat transaksi pemasukan & pengeluaran, memantau performa bisnis lewat dashboard analitik, dan mengelola data karyawan.

---

## Daftar Isi

1. [Persyaratan](#persyaratan)
2. [Login ke Aplikasi](#login-ke-aplikasi)
3. [Dashboard (Beranda)](#dashboard-beranda)
4. [Mencatat Transaksi](#mencatat-transaksi)
5. [Riwayat Transaksi](#riwayat-transaksi)
6. [Manajemen Karyawan (Admin)](#manajemen-karyawan-admin)
7. [Ekspor PDF](#ekspor-pdf)
8. [Peran Pengguna](#peran-pengguna)
9. [Cara Menjalankan Aplikasi (Developer)](#cara-menjalankan-aplikasi-developer)

---

## Persyaratan

- Smartphone Android atau PC Windows
- Koneksi internet aktif (untuk sinkronisasi data ke Supabase)
- Akun karyawan yang sudah didaftarkan oleh Admin

---

## Login ke Aplikasi

1. Buka aplikasi **Kopi User**.
2. Masukkan **ID Karyawan** pada kolom yang tersedia.
3. Masukkan **PIN 4 digit** milik kamu.
4. Tekan tombol **Masuk**.

> Jika PIN salah, tampilan akan bergetar sebagai tanda peringatan. Hubungi Admin jika lupa PIN atau akun belum terdaftar.

---

## Dashboard (Beranda)

Setelah login, kamu akan langsung masuk ke halaman **Dashboard** yang menampilkan ringkasan bisnis.

### Filter Waktu

Gunakan chip filter di bagian atas untuk memilih rentang data:

| Filter | Keterangan |
|---|---|
| **Hari Ini** | Data transaksi hari ini saja |
| **Bulan Ini** | Data sepanjang bulan berjalan |
| **Keseluruhan** | Semua data sejak awal |

### Kartu Ringkasan

- **Pemasukan** — Total pendapatan dari penjualan
- **Pengeluaran** — Total biaya operasional
- **Profit / Rugi** — Selisih pemasukan dikurangi pengeluaran (hijau = untung, merah = rugi)

### Grafik & Visualisasi

- **Distribusi Transaksi** — Grafik distribusi transaksi berdasarkan waktu
- **Peringkat Produk** — Produk terlaris berdasarkan jumlah terjual
- **Volume Pembayaran** — Perbandingan metode bayar: QRIS, Tunai, Transfer
- **Kategori Pengeluaran** — Rincian pengeluaran per kategori (Bahan Baku, Gaji, dll.)

### Transaksi Terbaru

Daftar transaksi paling baru ditampilkan di bagian bawah. Ketuk salah satu untuk melihat detailnya.

### Tombol Tambah Transaksi

Tekan tombol **+** (hijau, pojok kanan bawah) untuk langsung membuka form input transaksi baru.

---

## Mencatat Transaksi

Tekan tombol **+** di beranda atau navigasi ke menu **Input** untuk mencatat transaksi baru.

### Jenis Transaksi

Pilih jenis transaksi menggunakan toggle di bagian atas:

| Jenis | Keterangan |
|---|---|
| **Pemasukan** | Penjualan produk ke pelanggan |
| **Pengeluaran** | Pembelian bahan baku, biaya operasional, dll. |

---

### Mencatat Pemasukan (Penjualan)

1. Pilih toggle **Pemasukan**.
2. Tambah produk yang terjual dengan menekan **+** di sebelah nama produk:
   - Kopi Susu
   - Kopi Gula Aren
   - Coklat Susu
3. Atur **jumlah** setiap produk dengan tombol `+` / `-`.
4. Pilih **metode pembayaran**:
   - **QRIS**
   - **Tunai**
   - **Transfer**
5. *(Opsional)* Unggah **foto struk/bukti** via kamera atau galeri.
6. *(Opsional)* Tambahkan **catatan** tambahan.
7. Tekan **Simpan**.

> Total harga akan dihitung otomatis berdasarkan produk dan jumlah yang dipilih.

---

### Mencatat Pengeluaran

1. Pilih toggle **Pengeluaran**.
2. Masukkan **jumlah nominal** pengeluaran.
3. Pilih **kategori pengeluaran**:

   | Kategori | Contoh |
   |---|---|
   | Bahan Baku | Kopi, susu, gula |
   | Operasional | Listrik, gas, air |
   | Gaji Staff | Upah karyawan |
   | Perlengkapan | Gelas, sedotan, kemasan |
   | Lain-lain | Keperluan di luar kategori |

4. Pilih **metode pembayaran**.
5. *(Opsional)* Unggah foto bukti pengeluaran.
6. *(Opsional)* Tambahkan catatan.
7. Tekan **Simpan**.

---

### Mengedit Transaksi

1. Buka **Riwayat** atau ketuk transaksi di beranda.
2. Buka **Detail Transaksi**.
3. Tekan ikon **edit** (pensil).
4. Ubah data yang diperlukan, lalu tekan **Simpan**.

---

## Riwayat Transaksi

Buka menu **Riwayat** untuk melihat semua transaksi yang sudah dicatat.

### Filter Riwayat

- **Filter waktu**: Hari Ini / Bulan Ini / Keseluruhan / Rentang Tanggal Kustom
- **Filter jenis**: Semua / Pemasukan / Pengeluaran

### Rentang Tanggal Kustom

1. Pilih opsi **Kustom** pada filter waktu.
2. Pilih tanggal mulai dan tanggal akhir.
3. Data akan otomatis difilter sesuai rentang yang dipilih.

### Detail Transaksi

Ketuk transaksi mana saja untuk melihat informasi lengkap:
- Tanggal & waktu
- Jenis & kategori
- Nominal
- Metode pembayaran
- Foto struk (jika ada)
- Catatan

---

## Ekspor PDF

Dari halaman **Riwayat**, kamu bisa mengekspor laporan transaksi ke format PDF:

1. Atur filter waktu dan jenis transaksi sesuai kebutuhan.
2. Tekan ikon **PDF / Ekspor** di bagian atas.
3. File PDF akan dibuat dan bisa langsung dicetak atau dibagikan.

> PDF akan mencakup semua transaksi yang saat ini tampil sesuai filter aktif.

---

## Manajemen Karyawan (Admin)

Fitur ini hanya tersedia untuk akun dengan peran **Admin**.

Akses dari beranda: tekan ikon **Karyawan** di pojok kanan atas.

### Melihat Daftar Karyawan

Semua karyawan aktif dan nonaktif ditampilkan dalam daftar beserta status masing-masing.

### Menambah Karyawan Baru

1. Tekan tombol **+** atau **Tambah Karyawan**.
2. Isi data:
   - Nama lengkap
   - ID Karyawan
   - PIN (4 digit)
   - Peran: **Staff** atau **Admin**
3. Tekan **Simpan**.

### Mengedit Data Karyawan

1. Ketuk nama karyawan di daftar.
2. Tekan ikon **edit**.
3. Ubah data yang diperlukan, lalu simpan.

### Menonaktifkan / Mengaktifkan Karyawan

- Toggle status pada kartu karyawan untuk mengubah status aktif/nonaktif.
- Karyawan nonaktif tidak bisa login ke aplikasi.

---

## Peran Pengguna

| Fitur | Staff | Admin |
|---|:---:|:---:|
| Login | ✓ | ✓ |
| Lihat Dashboard | ✓ | ✓ |
| Catat Transaksi | ✓ | ✓ |
| Lihat Riwayat | ✓ | ✓ |
| Ekspor PDF | ✓ | ✓ |
| Lihat data semua karyawan | — | ✓ |
| Kelola Karyawan | — | ✓ |

> Staff hanya dapat melihat transaksi yang dicatatnya sendiri. Admin dapat melihat seluruh data transaksi semua karyawan.

---

## Cara Menjalankan Aplikasi (Developer)

### Prasyarat

- Flutter SDK 3.19.0+
- Dart 3.3.0+
- Android Studio / VS Code dengan ekstensi Flutter

### Instalasi

```bash
cd mobile
flutter pub get
flutter run
```

### Build APK (Android)

```bash
flutter build apk --release
```

### Build Windows

```bash
flutter build windows --release
```

### Konfigurasi Supabase

Edit konstanta di [mobile/lib/main.dart](mobile/lib/main.dart):

```dart
const kSupabaseUrl = 'YOUR_SUPABASE_URL';
const kSupabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

Untuk pengembangan lokal tanpa backend, set:

```dart
const kUseMock = true; // gunakan data dummy
```

### Setup Database

Jalankan skrip migrasi Supabase:

```bash
supabase db reset
# atau jalankan manual:
# supabase/fix_and_seed.sql
```

---

## Struktur Proyek

```
Kopi User/
├── mobile/
│   ├── lib/
│   │   ├── main.dart           # Entry point & konfigurasi
│   │   ├── data/               # Repository (Supabase & Mock)
│   │   ├── models/             # Model data (Transaction, Employee, Product)
│   │   ├── screens/            # Halaman UI
│   │   ├── state/              # Manajemen state (Provider)
│   │   ├── theme/              # Warna & tipografi
│   │   ├── utils/              # Formatter & PDF export
│   │   └── widgets/            # Komponen UI reusable
│   └── pubspec.yaml
└── supabase/
    └── migrations/             # SQL migrasi database
```

---

*Dibuat dengan Flutter & Supabase — untuk manajemen kedai kopi yang lebih mudah.*
