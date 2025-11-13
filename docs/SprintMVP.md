### Checklist Timeline Sprint untuk MVP "Aplikasi Daftar Belanjaku"

**Versi:** 2.0 (Dengan Fitur Pantry)

#### Sprint 0: Fondasi & Penyiapan Proyek (Minggu 1-2)
*Tujuan: Menyiapkan seluruh kerangka kerja, arsitektur, dan alat yang dibutuhkan.*
**Status: SELESAI**

-   [x] Inisialisasi Proyek (Flutter, Git).
-   [x] Manajemen Dependensi (`pubspec.yaml`).
-   [x] Struktur Proyek (Sederhana).
-   [x] Konfigurasi Database Awal (Appwrite Collections & Documents).
-   [x] Konfigurasi Dasar Aplikasi (`main.dart`, `GoRouter`, `AppTheme`).

---

#### Sprint 1: Fungsionalitas Inti Daftar Belanja (CRUD Lists) (Minggu 3-4)
*Tujuan: Pengguna dapat membuat, melihat, mengedit, dan menghapus daftar belanja.*
**Status: SELESAI**

-   [x] Business & Data Layer untuk `ShoppingList`.
-   [x] Presentation Layer (`ShoppingListsScreen`, `ShoppingListBloc`).
-   [x] Fungsionalitas UI untuk menambah, mengedit, dan menghapus daftar.

---

#### Sprint 2: Fungsionalitas Inti Item Belanja & Finalisasi (Minggu 5-6)
*Tujuan: Pengguna dapat mengelola item dalam daftar dan navigasi aplikasi berfungsi penuh.*
**Status: SEBAGIAN BESAR SELESAI**

-   [x] Business & Data Layer untuk `ShoppingItem`.
-   [x] Presentation Layer (`ListDetailScreen`, `ListDetailBloc`).
-   [x] Logika untuk menambah, mengedit, menghapus, dan menandai item.
-   [x] Logika kalkulasi total belanja.
-   [x] **Tugas Prioritas:** Selesaikan navigasi dari `ShoppingListsScreen` ke `ListDetailScreen`.

---

#### **(BARU)** Sprint 3: Fitur Pantry Cerdas (Bagian 1 - Data & Logika) (Minggu 7-8)
*Tujuan: Membangun seluruh fondasi data dan logika bisnis untuk fitur Pantry.*
**Status: SELESAI**

-   [x] **Database:**
    -   [x] Definisikan dan implementasikan koleksi `pantry_items` di Appwrite (id, name, quantity, unit, purchase_date, expiry_date, userId, originalListId).
-   [x] **Business Logic Layer:**
    -   [x] Buat kelas Dart biasa untuk `PantryItem`.
    -   [x] Definisikan *interface* `PantryRepository`.
-   [x] **Data Layer:**
    -   [x] Buat `PantryRepositoryImpl` yang berinteraksi dengan Appwrite.
-   [x] **Logika Lintas Fitur:**
    -   [x] Perbarui `ShoppingListRepository` dengan metode untuk "memindahkan" item ke pantry.

---

#### **(BARU)** Sprint 4: Fitur Pantry Cerdas (Bagian 2 - UI & Interaksi) (Minggu 9-10)
*Tujuan: Menghadirkan fitur Pantry kepada pengguna dan memastikan alur kerja yang mulus.*
**Status: SELESAI**

-   [x] **Navigasi Utama:**
    -   [x] Implementasikan `BottomNavigationBar` untuk beralih antara "Daftar Belanja", "Pantry", "Food Facts", dan "Profil".
    -   [x] Perbarui konfigurasi `GoRouter` untuk mendukung navigasi berbasis tab.
-   [x] **Presentation Layer (Pantry):**
    -   [x] Buat `PantryScreen` untuk menampilkan semua item di pantry.
    -   [x] Buat `PantryBloc` beserta `Event` dan `State`.
    -   [x] Implementasikan UI untuk menampilkan item pantry, termasuk status kedaluwarsa (dengan kode warna).
    -   [x] Implementasikan fungsionalitas untuk menghapus item dari pantry.
    -   [x] Implementasikan fungsionalitas untuk mengembalikan item dari pantry ke daftar asal.
-   [x] **Integrasi Antar Fitur:**
    -   [x] Tambahkan tombol/logika di `ListDetailScreen` untuk memicu proses "Pindahkan ke Pantry" dengan saran tanggal kedaluwarsa otomatis.

---

#### **(BARU)** Sprint 5: Fitur Premium (Analisis Pantry), Pengaturan & Notifikasi (Minggu 11-12)
*Tujuan: Menyelesaikan fitur premium, fitur pendukung, dan notifikasi cerdas.*
**Status: SEBAGIAN BESAR SELESAI**

-   [ ] **Fitur Premium (Analisis & Laporan Pantry):**
    -   [ ] Implementasikan logika untuk mengumpulkan data yang dibutuhkan untuk analisis pantry.
    -   [ ] Buat UI untuk dashboard "Laporan" yang menampilkan analisis pengeluaran dan pemborosan.
    -   [ ] Integrasikan IAP untuk membuka fitur premium ini.
-   [x] **Integrasi Iklan:**
    -   [x] Integrasikan SDK Google AdMob untuk menampilkan iklan *banner* pada versi gratis.
    -   [x] Implementasikan pop-up informasi premium untuk fitur "Hapus Iklan".
-   [ ] **Fitur Notifikasi:**
    -   [ ] Integrasikan *package* notifikasi lokal (misal: `flutter_local_notifications`).
    -   [ ] Buat logika untuk memeriksa item yang akan kedaluwarsa dan mengirim notifikasi.
-   [x] **Layar Pengaturan:**
    -   [x] Buat `SettingsScreen` dengan semua tautan yang diperlukan (Kebijakan Privasi, Syarat & Ketentuan, Versi Aplikasi).
    -   [x] Implementasikan fungsionalitas untuk Rating, Umpan Balik, dan Bantuan Terjemahan.
    -   [x] Implementasikan fungsionalitas pemilihan Tema (Light/Dark/System).

---

#### **(BARU)** Sprint 6: Pengujian Akhir, Bug Fixing & Persiapan Rilis (Minggu 13-14)
*Tujuan: Memastikan aplikasi stabil, bebas dari bug kritis, dan siap untuk diluncurkan.*

-   [ ] **Quality Assurance (QA):**
    -   [ ] Lakukan pengujian *end-to-end* pada semua fitur, termasuk alur Pantry dan notifikasi.
-   [ ] **Bug Fixing:**
    -   [ ] Prioritaskan dan perbaiki semua *bug* yang ditemukan.
-   [ ] **Persiapan Rilis:**
    -   [ ] Siapkan aset visual (App Icon, Splash Screen, Screenshot).
    -   [ ] Finalisasi deskripsi aplikasi, catatan rilis, dan kebijakan privasi.
-   [ ] **Build & Submit:**
    -   [ ] Hasilkan *build* rilis dan kirim ke Google Play Store & Apple App Store.