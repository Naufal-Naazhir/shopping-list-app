### Software Requirements Specification (SRS) - Aplikasi Daftar Belanjaku

**Nama Tim:** Naufal Naazhir Arkaan,  M. Arya Pratama
**Versi:** 1.0
**Tanggal:** 16 september 2025

---

### 1. Pendahuluan

**1.1 Tujuan**
Dokumen ini menyediakan spesifikasi persyaratan perangkat lunak yang detail untuk aplikasi mobile "BelanjaPraktis" versi 1.0. Tujuannya adalah untuk memberikan pemahaman yang jelas dan tidak ambigu tentang fungsionalitas dan batasan sistem kepada tim pengembang, tim pengujian (QA), dan pemangku kepentingan lainnya.

**1.2 Ruang Lingkup Produk (DIUBAH)**
Aplikasi "BelanjaPraktis" adalah sebuah aplikasi mandiri (*standalone*) untuk platform iOS dan Android yang berfungsi sebagai asisten belanja pribadi dan manajer inventaris rumah. Versi 1.0 telah mengimplementasikan **sistem autentikasi pengguna yang lengkap**, fungsionalitas inti pengelolaan daftar belanja, dan fitur pembeda yaitu **manajemen pantry cerdas** dengan pelacak kedaluwarsa otomatis, didukung oleh **Appwrite Backend-as-a-Service (BaaS)**.

**Ruang lingkup versi 1.0 TIDAK mencakup:**
*   Sinkronisasi data antar perangkat (Cloud Sync).
*   Fitur berbagi daftar belanja dengan pengguna lain.
*   Fitur *drag-and-drop ordering* (ditunda).

**1.3 Definisi, Akronim, dan Singkatan**
*   **SRS:** Software Requirements Specification
*   **PRD:** Product Requirement Document
*   **UI/UX:** User Interface/User Experience
*   **FAB:** Floating Action Button
*   **CRUD:** Create, Read, Update, Delete
*   **Daftar:** Kumpulan dari beberapa Item Belanja.
*   **Item:** Satu entitas barang yang akan dibeli.
*   **Pantry:** Inventaris virtual untuk item yang sudah dibeli dan disimpan di rumah.
*   **Preset:** Kumpulan item default untuk membuat daftar baru.

**1.4 Referensi**
*   Product Requirement Document (PRD) - BelanjaPraktis v2.0

**1.5 Ikhtisar Dokumen**
Dokumen ini terbagi menjadi beberapa bagian. Bagian 1 memberikan pendahuluan. Bagian 2 memberikan deskripsi umum tentang produk. Bagian 3 merinci persyaratan fungsional dan non-fungsional.

---

### 2. Deskripsi Umum

**2.1 Perspektif Produk (DIUBAH)**
Aplikasi ini adalah produk perangkat lunak baru yang dikembangkan dari awal menggunakan framework Flutter. Aplikasi ini akan berinteraksi dengan **Appwrite Backend-as-a-Service (BaaS)** untuk persistensi data dan autentikasi pengguna. Aplikasi juga terintegrasi dengan SDK iklan.

**2.2 Fungsi Produk (DIUBAH)**
Fungsi utama dari aplikasi ini adalah sebagai berikut:
1.  **Autentikasi Pengguna:** Membuat akun, login, dan logout.
2.  Membuat, melihat, mengedit, dan menghapus daftar belanja.
3.  Menambah, mengedit, menghapus, dan menandai item dalam daftar.
4.  Menghitung total harga belanja secara otomatis.
5.  **Memindahkan item yang sudah dibeli ke dalam Pantry secara otomatis saat daftar dihapus, dengan saran tanggal kedaluwarsa otomatis.**
6.  **Mengelola item di Pantry, termasuk melacak tanggal kedaluwarsa dan mengembalikan item ke daftar asal.**
7.  **Menyediakan fitur pengaturan (tema, hapus iklan, rating, feedback, translate).**
8.  **Memberikan notifikasi lokal untuk item yang akan kedaluwarsa (DITUNDA).**
9.  Menyediakan pembuatan daftar dari resep (AI).
10. Menampilkan iklan (pada versi gratis) dan menyediakan **versi Premium** untuk menghapus iklan dan batasan jumlah daftar.

**2.3 Karakteristik Pengguna**
Target pengguna adalah individu atau keluarga yang membutuhkan alat bantu digital untuk mengatur belanja dan mengurangi pemborosan makanan di rumah.

**2.4 Batasan Umum (DIUBAH)**
*   Aplikasi dikembangkan menggunakan Flutter, BLoC, Equatable, GoRouter, GetIt, dan **Appwrite** sebagai backend.
*   Semua data pengguna akan disimpan di **Appwrite BaaS**.
*   Aplikasi harus mendukung orientasi potret (*portrait mode*) saja.

**2.5 Asumsi dan Ketergantungan**
*   Pengguna memiliki koneksi internet untuk menampilkan iklan.
*   Sistem operasi perangkat mendukung pengiriman notifikasi lokal.

---

### 3. Persyaratan Spesifik

**3.1 Persyaratan Fungsional**

**3.1.1 Autentikasi Pengguna**
*   **FUNC-AUTH-001:** Sistem harus menyediakan fungsi untuk registrasi pengguna baru.
*   **FUNC-AUTH-002:** Sistem harus menyediakan fungsi untuk login pengguna.
*   **FUNC-AUTH-003:** Sistem harus menyediakan fungsi untuk logout pengguna.

**3.1.2 Pengelolaan Daftar Belanja (List Management)**
*   **FUNC-LM-001:** Sistem harus menyediakan fungsi untuk membuat daftar belanja baru.
*   **FUNC-LM-002:** Sistem harus menampilkan semua daftar belanja yang ada di layar utama.
*   **FUNC-LM-003:** Sistem harus mengizinkan pengguna untuk mengubah nama daftar belanja.
*   **FUNC-LM-004:** Sistem harus menyediakan fungsi untuk menghapus daftar belanja.
*   **FUNC-LM-005 (DITUNDA):** Pengurutan manual daftar belanja ditunda.

**3.1.3 Pengelolaan Item Belanja (Item Management)**
*   **FUNC-IM-001:** Sistem harus mengizinkan pengguna menambahkan item baru ke daftar belanja.
*   **FUNC-IM-002:** Sistem harus menampilkan semua item dalam sebuah daftar.
*   **FUNC-IM-003:** Pengguna harus dapat menandai item sebagai "sudah dibeli".
*   **FUNC-IM-004:** Sistem harus mengizinkan pengguna untuk mengedit detail item.
*   **FUNC-IM-005:** Sistem harus mengizinkan pengguna untuk menghapus item.
*   **FUNC-IM-006 (DITUNDA):** Pengurutan manual item belanja ditunda.

**3.1.4 Kalkulasi Total Belanja**
*   **FUNC-CALC-001:** Sistem harus secara otomatis menghitung dan menampilkan total harga dari item yang ada di daftar belanja.
*   **FUNC-CALC-002:** Total harus diperbarui secara *real-time* saat ada perubahan pada item.

**3.1.5 Pembuatan Daftar Cerdas (AI)**
*   **FUNC-PRES-001 (DIHAPUS - Diganti oleh AI):** Sistem harus menawarkan opsi untuk memilih dari template.
*   **FUNC-PRES-002 (DIHAPUS - Diganti oleh AI):** Jika template dipilih, sistem harus mengisi daftar baru dengan item default.
*   **FUNC-PRES-003:** Sistem harus menyediakan opsi untuk membuat daftar dari resep via AI.

**3.1.6 Pengelolaan Pantry (Pantry Management) - DIUBAH**
*   **FUNC-PAN-001:** Ketika sebuah daftar belanja dihapus, sistem harus secara otomatis memindahkan semua item yang bertanda `isBought` ke Pantry, dengan **saran tanggal kedaluwarsa otomatis**.
*   **FUNC-PAN-002:** Sistem harus memiliki layar "Pantry" yang menampilkan semua item yang tersimpan.
*   **FUNC-PAN-003:** Setiap item di Pantry harus menampilkan nama, tanggal pembelian, dan **tanggal kedaluwarsa (jika ada)**.
*   **FUNC-PAN-004:** Sistem harus mengizinkan pengguna untuk menghapus item dari Pantry.
*   **FUNC-PAN-005 (BARU):** Sistem harus mengizinkan pengguna untuk mengembalikan item dari Pantry ke daftar belanja asalnya.

**3.1.7 Notifikasi (Notifications)**
*   **FUNC-NOTIF-001:** Sistem harus dapat mengirimkan notifikasi lokal ke perangkat pengguna.
*   **FUNC-NOTIF-002:** Sistem harus mengirimkan notifikasi jika ada item di Pantry yang akan kedaluwarsa dalam periode waktu yang ditentukan (misal, H-3).

**3.1.8 Monetisasi (DIUBAH)**
*   **FUNC-MON-001:** Sistem harus menampilkan iklan *banner* pada versi gratis.
*   **FUNC-MON-002:** Versi gratis dibatasi hingga **5 daftar belanja**.
*   **FUNC-MON-003:** Sistem harus menyediakan **versi Premium** yang menghapus batasan jumlah daftar dan menghilangkan iklan.

**3.2 Persyaratan Non-Fungsional**
(Tidak ada perubahan signifikan, tetap berlaku)

**3.3 Persyaratan Antarmuka Eksternal**

**3.3.1 Antarmuka Pengguna (GUI) - DIUBAH**
*   **GUI-001:** **Layar Autentikasi:** Layar untuk Login dan Registrasi.
*   **GUI-002:** **Layar Daftar Belanja:** Menampilkan daftar belanja pengguna.
*   **GUI-003:** **Layar Detail Daftar:** Menampilkan item-item dari sebuah daftar.
*   **GUI-004:** **Layar Pantry:** Menampilkan semua item dari `pantry_items`.
*   **GUI-005:** **Layar Profil:** Berisi informasi pengguna dan opsi-opsi aplikasi.
*   **GUI-006:** **Layar Pengaturan:** Berisi opsi pengaturan aplikasi (tema, kebijakan privasi, dll.).
*   **GUI-007:** **Navigasi:** Menggunakan `BottomNavigationBar` untuk navigasi utama.

**3.4 Persyaratan Database (DIUBAH)**
*   **DB-001:** Aplikasi harus menggunakan **Appwrite Backend-as-a-Service (BaaS)** untuk persistensi data.
*   **DB-002:** Data akan disimpan dalam koleksi berbasis dokumen di Appwrite.