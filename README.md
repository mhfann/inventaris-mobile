KONTEKS PROYEK: inventaris_mobile

Aplikasi inventaris sekolah berbasis Flutter, backend Laravel (https://inventaris.mhfann.my.id/api).
Lokasi project: C:\flutter\inventaris-mobile. Saya menjalankannya di Windows desktop saat development.
State management: provider. HTTP: dio. Ikon: phosphoricons_flutter. Font: google_fonts (Plus Jakarta Sans).
Shorebird terpasang (App ID 7c03f4fb-7d03-4090-b54c-9bfbb5b6f4e7), rilis terakhir 1.0.0+2.
Saya lampirkan zip project terbaru. Baca dulu sebelum menjawab.

ATURAN KERJA
- Jawab dalam bahasa Indonesia, singkat, langsung bisa dipakai.
- JANGAN mengubah tampilan/gaya visual tanpa diminta. Perbaikan hanya logika.
- Saya mengirim file satu per satu untuk dicek. Untuk tiap file: sebut ada bug atau tidak, jelaskan singkat, dan kalau ada perbaikan, berikan ISI FILE LENGKAP (bukan potongan) supaya saya tinggal menimpa.
- Kalau perbaikan menyentuh lebih dari satu file, sebutkan semua file yang harus dipasang bersamaan.
- Kalau ada error, minta saya mengirim output lengkapnya.
- Katakan terus terang kalau sesuatu belum diuji atau penyebabnya belum pasti.

GAYA VISUAL (acuan, jangan diubah)
- Tema terang, kartu putih berborder tipis, sudut membulat besar.
- Aksen indigo kebiruan (~#3F4780), latar pill/ikon lavender muda (~#E8E9F8).
- Oranye hanya untuk peringatan (stok menipis). Ikon outline berujung bulat.
- Navigasi bawah: Dashboard, Barang, Master (hanya admin), Transaksi, Profil.

STATUS IKON APLIKASI
- flutter_launcher_icons sudah di dev_dependencies; ikon Android (termasuk adaptive, latar #E8E9F8) dan iOS sudah ter-generate dengan benar.
- Ikon Windows BELUM di-generate (blok `windows:` di pubspec masih belum diaktifkan).
- Hasil generate ikon belum di-commit.
- Belum dilakukan: naikkan versi ke 1.0.0+3 lalu `shorebird release android` (ikon = perubahan native, tidak bisa lewat `shorebird patch`).

CATATAN PENTING: agent sebelumnya tidak bisa menjalankan Flutter, jadi SEMUA perbaikan di bawah berasal dari pembacaan kode dan BELUM DIUJI. Cek di zip apakah tiap perubahan sudah terpasang.

FILE YANG SUDAH DIPERBAIKI DAN DIKIRIM (isi lengkap)
1. lib/providers/item_provider.dart
   - Flag muat dashboard dipisah (`dashboardLoading`) supaya tidak menghalangi `loadItems()` (dulu tab Barang kosong saat pertama dibuka).
   - `loadItems()` memakai nomor permintaan (`_itemsRequest`): refresh/pencarian selalu jalan, hasil lama dibuang.
   - Gagal memuat halaman berikutnya -> `_hasMore = false` (mencegah percobaan ulang tanpa henti).
   - `loadDashboard()` tidak lagi menulis ke `_error`.
   - `loadReferences()` punya `referencesLoading` dan `referencesError` sendiri.
2. lib/screens/home/dashboard_screen.dart
   - Indeks tab dijaga agar tidak melewati jumlah tab (dulu RangeError saat admin logout).
   - Tombol "Coba lagi" dan tarik-untuk-refresh lewat `_loadDashboard()`; gagal refresh saat data ada -> snackbar.
   - Dashboard dimuat ulang saat tab Dashboard diketuk.
3. lib/widgets/transaction_filter_bar.dart
   - Form filter tidak bisa terbuka dobel; terbuka langsung jika daftar barang sudah ada.
   - Seluruh chip filter bisa diketuk untuk menghapus (bukan hanya ikon X).
   - BELUM TUNTAS: saya melaporkan chip tanggal "dari–sampai" tidak bisa ditutup. Penyebab pastinya belum ditemukan (logika X terbaca benar). Saya belum mengonfirmasi apakah perubahan ini menyelesaikannya.
4. lib/core/api/api_client.dart: try/catch saat baca token di interceptor, pesan ramah untuk status >= 500 (selain 503), `sendTimeout` ditangani, `message` dibaca dengan `?.toString()`.
5. lib/core/widgets/custom_snackbar.dart: pesan maksimal 3 baris, error tampil 5 detik, `duration` jadi opsional.
6. lib/models/report.dart: helper `_toInt` untuk `totals`, `stock`, `quantity`.
7. lib/providers/transaction_provider.dart: status muat/error/hasMore terpisah untuk masuk dan keluar, nomor permintaan, dukungan halaman berikutnya (`loadIncoming(refresh: false)`), error simpan tidak bocor ke daftar. Getter lama `loading`/`error` dipertahankan.
8. lib/screens/auth/login_screen.dart: cegah login ganda, Enter pindah kolom, autofill, tooltip tombol mata.
9. lib/screens/categories/categories_screen.dart: memakai `referencesLoading`/`referencesError` (harus bersama item_provider.dart di atas).
10. lib/screens/errors/maintenance_screen.dart: `restoreSession()` dipanggil sebelum ke Dashboard; cegah navigasi ganda ke login.

SARAN YANG DIBERIKAN SEBAGAI KODE DI CHAT, BELUM TENTU SAYA PASANG (opsional)
- api_exception.dart: `toString()` menampilkan semua pesan validasi.
- app_config.dart: `AppConfig.applyStatus()` untuk membaca `low_stock_threshold` (termasuk string angka), dipakai di main.dart dan maintenance_screen.dart.
- app_constants.dart: `baseUrl` disederhanakan (String.fromEnvironment), hapus cabang platform yang identik.
- token_storage.dart: pembacaan aman (`_safeRead`) agar startup tidak macet jika secure storage rusak.
- models/dashboard.dart: helper `_toInt`/`_toIntList`.
- models/room.dart: `==` dan `hashCode` berdasarkan id (mencegah error dropdown "Tujuan" di form barang keluar).
- models/transaction_filter.dart: `activeCount` menghitung rentang tanggal sebagai satu.
- providers/auth_provider.dart: di `logout()`, set status unauthenticated sebelum memanggil server.
- screens/items/item_detail_screen.dart: helper `_orDash` untuk nilai kosong.

BUG/PEKERJAAN YANG MASIH TERBUKA
- items_screen.dart: `provider.loadItems()` dipanggil di dalam `itemBuilder` (memicu notifyListeners saat build) -> bungkus dengan `WidgetsBinding.instance.addPostFrameCallback`. Juga: `hasSearch` di empty state diisi `provider.error == null` (selalu "Barang tidak ditemukan"); teks kotak pencarian tidak sinkron dengan `setLowStockOnly()` dan setelah logout.
- incoming_screen.dart dan outgoing_screen.dart: belum memakai getter per daftar (`incomingLoading`, `incomingError`, `incomingHasMore`, dst.) dan belum memuat halaman berikutnya, jadi daftar masih berhenti di 15 data.
- rooms_screen.dart: masih memakai `provider.loading`/`provider.error`; ganti ke `referencesLoading`/`referencesError` seperti categories_screen.dart.
- transaction_form_screen.dart: teks "Stok saat ini: 5 null" bila satuan kosong (baris ~293, tambahkan `?? ''`).
- master_form_sheet.dart: form ditutup sebelum data dikirim, isian hilang kalau server menolak.
- Izin/peran user tidak pernah diambil ulang setelah login (restoreSession hanya membaca salinan tersimpan).
- Data provider (barang, transaksi, user, filter) tidak dikosongkan saat logout.
- lib/services/*.dart: import ditulis `'../../models/...'`, seharusnya `'../models/...'`.
- Rilis Android: `android/app/build.gradle.kts` masih menandatangani release dengan debug key; `android:usesCleartextTraffic="true"` di AndroidManifest tidak diperlukan.
- Font Plus Jakarta Sans diunduh saat runtime (belum dibundel sebagai aset); `MaterialApp` tanpa `themeMode` sehingga ikut mode gelap perangkat.
- Hal kecil menyangkut teks/tampilan, menunggu keputusan saya: ikon mata password terbalik antara login dan ganti password; ejaan "Silahkan" di layar maintenance; "Inventaris Sekolah v1.0" ditulis manual di profil; kontras teks putih di atas oranye/hijau.

PROGRES PENGECEKAN FILE SATU PER SATU
Sudah dicek: semua di lib/core, semua di lib/models, semua di lib/providers, lalu screens: auth/login_screen, categories/categories_screen, errors/maintenance_screen, home/dashboard_screen, items/item_detail_screen; widget: transaction_filter_bar.
Belum dicek satu per satu: screens/items/item_form_screen, screens/items/items_screen, screens/master/master_screen, screens/profile/profile_screen, screens/profile/change_password_screen, screens/reports/report_screen, screens/rooms/rooms_screen, screens/transactions/(incoming_screen, outgoing_screen, transaction_form_screen, transactions_screen), screens/users/user_management_screen, semua lib/services, widget lainnya (error_view, icon_badge, loading_widget, master_form_sheet, search_field, search_select_field, section_header, stat_card), lib/main.dart, dan folder test.

LANGKAH SELANJUTNYA
1. Lanjutkan pengecekan dari screens/items/item_form_screen.dart, lalu items_screen.dart, dan seterusnya sesuai daftar "belum dicek".
2. Setelah semua beres: `flutter analyze` dan `flutter test`, perbaiki yang muncul.
3. Naikkan versi ke 1.0.0+3, lalu `shorebird release android`.


saya sampai di item_detail_screen.dart