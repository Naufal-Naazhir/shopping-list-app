# Software Design Document (SDD) - Aplikasi BelanjaPraktis

**Versi:** 2.0
**Tanggal:** 10 Oktober 2025

---

### 1. Pendahuluan

#### 1.1 Tujuan
Dokumen ini merinci desain teknis tingkat tinggi dan tingkat rendah untuk aplikasi "BelanjaPraktis". Tujuannya adalah untuk menjadi panduan bagi tim pengembang dalam mengimplementasikan sistem sesuai dengan arsitektur yang telah disepakati. Dokumen ini merupakan terjemahan dari persyaratan yang tercantum dalam SRS (Software Requirements Specification) v.1.0 ke dalam spesifikasi desain teknis.

#### 1.2 Ruang Lingkup
Desain yang dijelaskan dalam dokumen ini mencakup struktur arsitektur, desain komponen, desain database, dan strategi penanganan error untuk versi 1.0 aplikasi. Ini mencakup semua fungsionalitas yang didefinisikan dalam SRS, termasuk pengelolaan daftar dan item, kalkulasi total, template, dan monetisasi.

#### 1.3 Referensi
*   Software Requirements Specification (SRS) - BelanjaPraktis v1.0
*   Product Requirement Document (PRD) - BelanjaPraktis v1.0
*   Dokumen Skema Database - BelanjaPraktis (Appwrite)

---

### 2. Desain Arsitektur

#### 2.1 Pola Arsitektur: Layered Architecture
Aplikasi ini akan mengadopsi pola **Layered Architecture** untuk memisahkan *concerns* dan meningkatkan *maintainability*, *scalability*, dan *testability*. Arsitektur ini akan dibagi menjadi tiga lapisan utama:

1.  **Presentation Layer (Lapisan Presentasi):**
    *   **Tanggung Jawab:** Menampilkan UI (Widgets) dan menangani input dari pengguna. Lapisan ini juga berisi komponen state management (BLoC) yang merespons interaksi pengguna dan pembaruan data.
    *   **Komponen:** Widgets (Screens), State Management (BLoC).
    *   **Teknologi:** Flutter, flutter_bloc.

2.  **Business Logic Layer (Lapisan Logika Bisnis):**
    *   **Tanggung Jawab:** Berisi logika bisnis inti aplikasi. Lapisan ini mendefinisikan "kontrak" untuk pengambilan data melalui *Repository Interfaces* dan berisi model data domain (*Entities*).
    *   **Komponen:** Entities, Repository Interfaces.
    *   **Teknologi:** Dart murni, Equatable.

3.  **Data Layer (Lapisan Data):**
    *   **Tanggung Jawab:** Mengelola pengambilan dan penyimpanan data dari **Appwrite Backend-as-a-Service (BaaS)**. Lapisan ini mengimplementasikan *interface* repository yang didefinisikan di Business Logic Layer.
    *   **Komponen:** Repository Implementations, Data Sources (Appwrite).
    *   **Teknologi:** Appwrite SDK.

**Aliran Ketergantungan:** `Presentation` → `Business Logic` ← `Data`. Lapisan Business Logic tidak bergantung pada lapisan lainnya.

#### 2.2 Diagram Komponen Tingkat Tinggi

```
[ Antarmuka Pengguna (UI Widgets) ]
     |           ^
(User Events)    | (State Updates)
     |           |
     V           |
[ BLoC (State Management) ]
     |
     | (Memanggil metode)
     V
[ Repository Interface (Business Logic) ]
     ^
     | (Implementasi)
     |
[ Repository Implementation (Data) ]
     |
     V
[ Appwrite BaaS (Collections & Documents) ]
```

---

### 3. Desain Rinci

#### 3.1 Presentation Layer
*   **Struktur UI (Views/Widgets):** UI akan dibangun menggunakan Flutter. Setiap layar (misalnya, `ShoppingListsScreen`, `ListDetailScreen`) akan menggunakan widget dari pustaka `flutter_bloc` seperti `BlocProvider`, `BlocBuilder`, dan `BlocListener` untuk terhubung dengan BLoC dan bereaksi terhadap perubahan *state*.
*   **Manajemen State (State Management):** **BLoC (Business Logic Component)** akan digunakan untuk mengelola state aplikasi. Pola ini memisahkan logika bisnis dari UI dengan jelas.
    *   **Event:** Kelas-kelas sederhana yang merepresentasikan aksi pengguna atau kejadian sistem (misalnya, `LoadShoppingLists`, `AddListRequested`). Event dikirim dari UI ke BLoC.
    *   **State:** Kelas *immutable* yang merepresentasikan kondisi UI pada satu waktu (misalnya, `ShoppingListLoading`, `ShoppingListLoaded`, `ShoppingListError`). UI akan me-*render* dirinya sendiri berdasarkan *state* saat ini.
    *   **Bloc:** Kelas utama yang menerima *Events*, memprosesnya (dengan bantuan *repositories*), dan mengeluarkan *States* baru. BLoC akan berisi logika untuk memetakan event ke state.

#### 3.2 Business Logic Layer
*   **Entities:** Entitas bisnis inti (misalnya, `ShoppingList`, `ShoppingItem`) akan didefinisikan sebagai kelas *immutable* menggunakan `Equatable` untuk perbandingan. Entitas ini mewakili objek bisnis murni.
*   **Repository Interfaces:** *Abstract class* akan mendefinisikan "kontrak" untuk operasi data (CRUD). BLoC akan bergantung pada interface ini, bukan pada implementasinya.

#### 3.3 Data Layer
*   **Data Sources:** Akan ada satu sumber data utama: **Appwrite BaaS**. Sumber data ini akan berinteraksi langsung dengan Appwrite SDK untuk operasi CRUD pada koleksi dokumen.
*   **Data Models (Appwrite Documents):** Data akan disimpan sebagai dokumen di koleksi Appwrite. Model data di aplikasi akan memetakan langsung ke struktur dokumen Appwrite.
*   **Repository Implementations:** Kelas ini akan mengimplementasikan *Repository Interfaces* dari Business Logic Layer. Tanggung jawabnya adalah:
    1.  Memanggil metode yang sesuai pada Appwrite SDK.
    2.  Mengambil data dari koleksi Appwrite.
    3.  Melakukan deserialisasi data dari dokumen Appwrite ke *Domain Entities*.
    4.  Menangani *exception* dari Appwrite SDK dan mengubahnya menjadi tipe *Failure* yang telah didefinisikan.
    *   **Catatan Teknis:** Implementasi saat ini menggunakan versi Appwrite SDK di mana beberapa fungsi (seperti `createDocument`, `listDocuments`) sekarang dianggap *deprecated*. Pembaruan ke API yang lebih baru (seperti `createRow`, `listRows`) direkomendasikan di masa mendatang.

#### 3.4 Penanganan Error (Error Handling)
*   Aplikasi akan menggunakan `try-catch` block untuk menangani error, terutama dari Appwrite SDK.
*   BLoC akan memetakan *exception* yang ditangkap ke `State` yang sesuai (misalnya, `ShoppingListError`).

---

### 4. Desain Database (Appwrite Collections)
Desain database akan menggunakan **Appwrite Collections** sebagai pengganti tabel database relasional. Setiap entitas akan direpresentasikan sebagai sebuah koleksi, dan setiap instance entitas akan menjadi sebuah dokumen dalam koleksi tersebut.

*   **Struktur Data:** Data disimpan sebagai dokumen JSON di dalam koleksi Appwrite.
*   **Relasi:** Relasi antar data (seperti `shopping_lists` dan `shopping_items`) diimplementasikan melalui atribut dokumen yang menyimpan ID dokumen terkait (misalnya, `listId` di dokumen `shopping_items` akan menyimpan `\$id` dari dokumen `shopping_lists`).
*   **Kepemilikan Pengguna:** Setiap dokumen akan memiliki atribut `userId` yang menyimpan `\$id` dari pengguna Appwrite yang membuatnya, memastikan data terisolasi per pengguna.
*   **Integritas Data:** Integritas data dijaga oleh logika bisnis di dalam BLoC dan Repositories, serta oleh aturan izin (permissions) di Appwrite.

**Koleksi Utama:**

1.  **`users` Collection:**
    *   Menyimpan data profil tambahan untuk pengguna (misalnya, `username`, `isPremium`).
    *   Atribut kunci: `\$id` (ID Dokumen), `username` (String), `isPremium` (Boolean).

2.  **`shopping_lists` Collection:**
    *   Menyimpan daftar belanja utama.
    *   Atribut kunci: `\$id` (ID Dokumen), `userId` (String), `name` (String), `createdAt` (DateTime), `lastUpdated` (DateTime, Nullable).

3.  **`shopping_items` Collection:**
    *   Menyimpan item-item spesifik dalam daftar belanja.
    *   Atribut kunci: `\$id` (ID Dokumen), `listId` (String, FK ke `shopping_lists`), `userId` (String), `name` (String), `price` (Double, Nullable), `quantity` (Integer), `isBought` (Boolean).

4.  **`pantry_items` Collection:**
    *   Menyimpan inventaris item yang sudah dibeli oleh pengguna.
    *   Atribut kunci: `\$id` (ID Dokumen), `userId` (String), `originalListId` (String, Nullable, FK ke `shopping_lists`), `name` (String), `quantity` (Double, Nullable), `unit` (String, Nullable), `purchaseDate` (DateTime), `expiryDate` (DateTime, Nullable).

---

### 5. Struktur Direktori Proyek

Struktur direktori akan diatur dengan pendekatan yang lebih sederhana dan mudah dikelola, memprioritaskan kejelasan dan mengurangi kompleksitas.

```
belanja_praktis/
├── lib/
│   ├── config/                 # Konfigurasi aplikasi (routing, theme, appwrite)
│   │   ├── app_router.dart       # Konfigurasi GoRouter
│   │   ├── app_theme.dart        # Tema aplikasi (warna, font)
│   │   ├── appwrite_config.dart  # Konfigurasi endpoint dan project Appwrite
│   │   └── appwrite_db.dart      # ID database dan koleksi Appwrite
│   │
│   ├── data/                   # Semua yang berhubungan dengan data
│   │   ├── models/               # Semua model data (menggunakan Equatable)
│   │   │   ├── user_model.dart
│   │   │   ├── shopping_list_model.dart
│   │   │   └── pantry_item.dart
│   │   └── repositories/         # Implementasi dan interface repository
│   │       ├── auth_repository.dart
│   │       ├── auth_repository_impl.dart
│   │       ├── shopping_list_repository.dart
│   │       ├── shopping_list_repository_impl.dart
│   │       ├── pantry_repository.dart
│   │       └── pantry_repository_impl.dart
│   │
│   ├── presentation/           # Semua yang berhubungan dengan tampilan (UI, state management)
│   │   ├── screens/              # Folder untuk setiap layar utama
│   │   │   ├── home_screen.dart
│   │   │   ├── list_detail_screen.dart
│   │   │   ├── pantry_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   └── register_screen.dart
│   │   │
│   │   ├── widgets/              # Widget yang dipakai di banyak layar
│   │   │   ├── shopping_item_card.dart
│   │   │   └── list_card.dart
│   │   │
│   │   └── bloc/                 # Semua file BLoC/State Management
│   │       ├── shopping_list_bloc.dart
│   │       ├── list_detail_bloc.dart
│   │       ├── pantry_bloc.dart
│   │       ├── auth_bloc.dart
│   │       ├── auth_event.dart
│   │       └── auth_state.dart
│   │
│   ├── services/                 # Layanan aplikasi (lokal, AI, notifikasi, tema)
│   │   ├── local_storage_service.dart
│   │   ├── ai_service.dart
│   │   ├── notification_service.dart
│   │   └── theme_service.dart
│   │
│   ├── utils/                    # Utilitas dan helper
│   │   ├── price_utils.dart
│   │   └── shelf_life_data.dart
│   │
│   └── main.dart               # Titik masuk aplikasi
│
├── test/                       # Folder untuk unit dan widget test
│   └── ...
│
└── pubspec.yaml
```
