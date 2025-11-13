## Product Requirement Document (PRD) - Aplikasi Daftar Belanjaku

**1. Pendahuluan**

*   **Nama Produk:** BelanjaPraktis
*   **Versi:** 1.0.0
*   **Tanggal Dokumen:** 16 September 2025
*   **Penulis:** [M. Arya Pratama, Naufal Naazhir Arkaan]

**1.1 Tujuan**
Dokumen ini bertujuan untuk menjelaskan secara detail fungsionalitas, persyaratan, dan ruang lingkup aplikasi "BelanjaPraktis". Aplikasi ini akan menjadi alat bantu bagi pengguna untuk membuat, mengelola, dan melacak daftar belanja mereka dengan mudah, cepat, dan efisien. Fokus utama adalah kesederhanaan, keringanan, dan pengalaman pengguna yang intuitif.

**1.2 Visi Produk**
Menjadi asisten belanja dan manajemen pantry pribadi yang cerdas, membantu pengguna tidak hanya merencanakan belanjaan tetapi juga mengelola stok barang di rumah untuk mengurangi pemborosan.

**1.3 Audiens Target**
Individu atau keluarga yang ingin mengelola daftar belanja dan inventaris rumah secara digital, dengan prioritas pada kemudahan penggunaan, fungsionalitas inti, dan fitur cerdas untuk menghemat uang dan mengurangi limbah.

---

**2. Lingkup Fungsionalitas**

Berikut adalah daftar fitur utama yang akan diimplementasikan pada versi 1.0.0.

**2.1 Fitur Inti Aplikasi**

*   **2.1.1 Pengelolaan Daftar Belanja:**
    *   **FR-1.1.1:** Pengguna dapat membuat daftar belanja baru.
    *   **FR-1.1.2:** Pengguna dapat memberi nama daftar belanja.
    *   **FR-1.1.3:** Pengguna dapat melihat semua daftar belanja yang telah dibuat di halaman utama.
    *   **FR-1.1.4:** Pengguna dapat mengedit nama daftar belanja.
    *   **FR-1.1.5:** Pengguna dapat menghapus daftar belanja.
    *   **FR-1.1.6 (DITUNDA):** Pengguna dapat mengurutkan daftar belanja secara manual (drag-and-drop).

*   **2.1.2 Pengelolaan Item Belanja:**
    *   **FR-1.2.1:** Pengguna dapat menambahkan item baru ke dalam daftar belanja.
    *   **FR-1.2.2:** Untuk setiap item, pengguna dapat memasukkan nama (wajib), harga (opsional), dan kuantitas (opsional).
    *   **FR-1.2.3:** Pengguna dapat menandai item sebagai "sudah dibeli".
    *   **FR-1.2.4:** Pengguna dapat mengedit detail item yang sudah ada.
    *   **FR-1.2.5:** Pengguna dapat menghapus item dari daftar belanja.
    *   **FR-1.2.6 (DITUNDA):** Pengguna dapat mengurutkan item dalam daftar belanja secara manual (drag-and-drop).

*   **2.1.3 Kalkulasi Total Belanja:**
    *   **FR-1.3.1:** Aplikasi akan menampilkan total harga dari semua item yang belum dan sudah dibeli.
    *   **FR-1.3.2:** Total kalkulasi akan diperbarui secara real-time.

*   **2.1.4 Manajemen Pengguna (Autentikasi):**
    *   **FR-1.4.1:** Pengguna dapat membuat akun baru dengan gmail dan password .
    *   **FR-1.4.2:** Pengguna dapat masuk (login) ke akun yang sudah ada.
    *   **FR-1.4.3:** Pengguna dapat keluar (logout) dari akun mereka.
    *   **FR-1.4.4 (DITUNDA):** Terdapat akun "admin" untuk tujuan demonstrasi atau pengelolaan.

*   **2.1.5 Kategori Preset & Pembuatan Daftar Cerdas:**
    *   **FR-1.5.1 (DIHAPUS - Diganti oleh AI):** Pengguna dapat memilih dari template kategori preset.
    *   **FR-1.5.2 (DIHAPUS - Diganti oleh AI):** Jika template dipilih, daftar belanja akan otomatis terisi dengan item-item default.
    *   **FR-1.5.3:** Pengguna dapat membuat daftar belanja secara otomatis dengan memasukkan resep,belanja bulanan,dll (menggunakan pemrosesan AI).

*   **2.1.6 Pengelolaan Pantry (Pantry Cerdas):**
    *   **FR-1.6.1 (DIUBAH):** Ketika pengguna menghapus sebuah daftar belanja, semua item yang telah ditandai "sudah dibeli" (`isBought`) secara otomatis ditambahkan ke "Pantry".
    *   **FR-1.6.2:** Saat memindahkan, aplikasi akan secara otomatis menyarankan tanggal kedaluwarsa berdasarkan jenis item.
    *   **FR-1.6.3:** Terdapat halaman "Pantry" untuk melihat semua item yang tersimpan di rumah.
    *   **FR-1.6.4:** Item di pantry akan menampilkan status kedaluwarsa (misal: segar, akan kedaluwarsa, sudah kedaluwarsa).
    *   **FR-1.6.5:** Pengguna dapat menghapus item dari pantry (misal: saat sudah habis digunakan).
    *   **FR-1.6.6 (DITUNDA):** Aplikasi akan memberikan notifikasi lokal saat ada item yang mendekati tanggal kedaluwarsa.

**2.2 Antarmuka Pengguna (UI) & Pengalaman Pengguna (UX)**

*   **FR-2.2.1:** Desain antarmuka harus minimalis, bersih, dan intuitif.
*   **FR-2.2.2:** Navigasi utama menggunakan `BottomNavigationBar` untuk beralih antara "Daftar Belanja", "Pantry", "Food Facts", dan "Profil".
*   **FR-2.2.3:** Penggunaan `Floating Action Button (FAB)` untuk aksi utama (menambah daftar).
*   **FR-2.2.4:** Dukungan untuk *Light Mode* dan *Dark Mode* yang mengikuti pengaturan sistem operasi (Sudah diimplementasikan).

**2.3 Fitur Pengaturan (Disimplifikasi)**

*   **FR-2.3.1:** Halaman pengaturan sederhana yang dapat diakses dari halaman Profil, mencakup:
    *   Pemilihan Tema (Light/Dark/System).
    *   Informasi Hapus Iklan (Pop-up untuk pengguna premium).
    *   Link ke Rating Aplikasi.
    *   Link untuk mengirim Umpan Balik.
    *   Link untuk membantu Terjemahan.
    *   Link ke Kebijakan Privasi, Syarat & Ketentuan, Versi Aplikasi.

**2.4 Monetisasi & Model Premium**

*   **FR-2.4.1:** Aplikasi akan menampilkan iklan *banner* di lokasi yang tidak mengganggu pada versi gratis.
*   **FR-2.4.2 (DIUBAH):** Versi gratis aplikasi memiliki batasan fungsional:
    *   Pengguna dapat membuat dan mengelola maksimal **5 daftar belanja**.
*   **FR-2.4.3 (DIUBAH):** Pengguna dapat upgrade ke **Versi Premium** untuk membuka batasan tersebut, mendapatkan:
    *   **Daftar belanja tanpa batas (unlimited).**
    *   Bebas dari iklan.
*   **FR-2.4.4 (MASA DEPAN):** Fitur premium di masa depan dapat mencakup **"Analisis & Laporan Pantry"**, yang akan memberikan insight pengeluaran dan pemborosan.

---

**3. Lingkup Non-Fungsional**

*   **3.1 Kinerja:**
    *   **NFR-3.1.1:** Waktu muat aplikasi harus cepat (< 2 detik).
    *   **NFR-3.1.2:** Responsivitas UI harus lancar tanpa *lag*.
    *   **NFR-3.1.3:** Penggunaan memori dan baterai harus minimal.

*   **3.2 Skalabilitas:**
    *   **NFR-3.2.1:** Arsitektur harus dirancang agar mudah ditambahkan fitur-fitur baru di masa depan.

*   **3.3 Keamanan:**
    *   **NFR-3.3.1:** Data pengguna harus disimpan secara lokal dan aman di perangkat.

*   **3.4 Kompatibilitas:**
    *   **NFR-3.4.1:** Aplikasi harus kompatibel dengan Android 7.0+ dan iOS 13.0+.

*   **3.5 Pemeliharaan:**
    *   **NFR-3.5.1:** Kode harus ditulis dengan standar *clean code*, teruji, dan mudah dipelihara.

---

**4. Teknologi yang Digunakan (DIUBAH)**

*   **Database/Backend:** Appwrite Backend-as-a-Service (BaaS)
*   **State Management:** BLoC / flutter_bloc
*   **Immutable Data Models:** Equatable (untuk perbandingan objek)
*   **Navigasi:** GoRouter
*   **Layanan (Service Locator):** GetIt
*   **Notifikasi Lokal:** flutter_local_notifications
*   **Logging:** Logger
*   **Lingkungan:** flutter_dotenv (untuk manajemen variabel lingkungan)
*   **Peluncur URL:** url_launcher
*   **Internasionalisasi:** intl (untuk format tanggal/waktu)

---

**5. Alur Pengguna (User Flow)**

**5.1 Alur Umum Penggunaan Aplikasi (DIUBAH):**

1.  **Autentikasi:** Pengguna membuka aplikasi, melakukan Registrasi atau Login.
2.  **Mulai Aplikasi:** Pengguna masuk ke halaman utama "Daftar Belanja".
3.  **Buat Daftar Baru:** Pengguna mengetuk `+` untuk membuat daftar baru (bisa dari template, resep AI, atau kosong).
4.  **Halaman Detail Daftar:** Pengguna menambahkan item ke dalam daftar.
5.  **Belanja:** Pengguna menandai item saat dibeli.
6.  **Hapus Daftar & Pindahkan ke Pantry:** Setelah selesai, pengguna menghapus daftar belanja dari halaman utama. Semua item yang sudah dibeli secara otomatis masuk ke Pantry dengan tanggal kedaluwarsa yang disarankan secara otomatis.
7.  **Navigasi ke Pantry:** Pengguna mengetuk tab "Pantry" di `BottomNavigationBar`.
8.  **Lihat Stok:** Pengguna melihat semua item yang mereka miliki di rumah beserta status kedaluwarsanya.
9.  **Dapat Notifikasi:** Pengguna menerima notifikasi jika ada item yang akan kedaluwarsa.
10. **Gunakan Item:** Pengguna menghapus item dari pantry saat sudah habis.
11. **Logout:** Pengguna keluar dari akun melalui tombol di halaman utama.

---

**6. Model Data (Gambaran Awal)**

*   **ShoppingList:**
    ```dart
    class ShoppingList extends Equatable {
      final String id;
      final String userId;
      final String name;
      final DateTime createdAt;
      final DateTime? lastUpdated;

      const ShoppingList({
        required this.id,
        required this.userId,
        required this.name,
        required this.createdAt,
        this.lastUpdated,
      });

      @override
      List<Object?> get props => [id, userId, name, createdAt, lastUpdated];
    }
    ```

*   **ShoppingItem:**
    ```dart
    class ShoppingItem extends Equatable {
      final String id;
      final String name;
      final int quantity;
      final double price;
      final bool isBought;

      const ShoppingItem({
        required this.id,
        required this.name,
        required this.quantity,
        required this.price,
        this.isBought = false,
      });

      @override
      List<Object> get props => [id, name, quantity, price, isBought];
    }
    ```

*   **PantryItem:**
    ```dart
    // Note: Assuming PantryItem also uses Equatable and its model needs correction.
    // This is a placeholder based on the other models and schema.
    class PantryItem extends Equatable {
      final String id;
      final String userId;
      final String? originalListId;
      final String name;
      final double? quantity;
      final String? unit; // This seems to exist in pantry but not shopping items
      final DateTime purchaseDate;
      final DateTime? expiryDate;

      const PantryItem({
        required this.id,
        required this.userId,
        this.originalListId,
        required this.name,
        this.quantity,
        this.unit,
        required this.purchaseDate,
        this.expiryDate,
      });

      @override
      List<Object?> get props => [id, userId, originalListId, name, quantity, unit, purchaseDate, expiryDate];
    }
    ```

---

**7. Lampiran (Opsional)**

*   Sketsa Desain UI/UX (yang sudah kamu berikan, atau gambar tambahan).
*   Daftar Item Default untuk setiap Kategori Preset.

---

Dokumen PRD ini seharusnya sudah cukup untuk memulai proses pengembangan.