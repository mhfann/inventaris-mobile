KONTEKS PROYEK: inventaris_mobile

Aplikasi inventaris sekolah berbasis Flutter, backend Laravel (https://inventaris.mhfann.my.id/api).
Lokasi project: C:\flutter\inventaris-mobile. Saya menjalankannya di Windows desktop saat development.
State management: provider. HTTP: dio. Ikon: phosphoricons_flutter. Font: google_fonts (Plus Jakarta Sans).
Shorebird terpasang (App ID 7c03f4fb-7d03-4090-b54c-9bfbb5b6f4e7), rilis terakhir 1.0.0+2.
Saya lampirkan zip project terbaru. Cek dulu apakah zip benar-benar ada di unggahan; kalau tidak ada, katakan dan minta saya mengirim file satu per satu.

ATURAN KERJA
- Jawab dalam bahasa Indonesia, singkat, langsung bisa dipakai.
- JANGAN mengubah tampilan/gaya visual tanpa diminta. Perbaikan hanya logika.
- Saya mengirim file satu per satu untuk dicek. Untuk tiap file: sebut ada bug atau tidak, jelaskan singkat, dan kalau ada perbaikan, berikan ISI FILE LENGKAP (bukan potongan) supaya saya tinggal menimpa.
- Kalau perbaikan menyentuh lebih dari satu file, sebutkan semua file yang harus dipasang bersamaan.
- Kalau ada error, minta saya mengirim output lengkapnya.
- Katakan terus terang kalau sesuatu belum diuji atau penyebabnya belum pasti. Jangan menebak nama endpoint, getter, atau format respons; minta file/contohnya.

GAYA VISUAL (acuan, jangan diubah)
- Tema terang, kartu putih berborder tipis, sudut membulat besar.
- Aksen indigo kebiruan (~#3F4780), latar pill/ikon lavender muda (~#E8E9F8).
- Oranye hanya untuk peringatan (stok menipis). Ikon outline berujung bulat.
- Navigasi bawah: Dashboard, Barang, Master (hanya admin), Transaksi, Profil.

STATUS IKON APLIKASI
- Ikon Android (termasuk adaptive, latar #E8E9F8) dan iOS sudah ter-generate. Ikon Windows BELUM (blok `windows:` di pubspec belum diaktifkan).
- Hasil generate ikon belum di-commit.
- Belum dilakukan: naikkan versi ke 1.0.0+3 lalu `shorebird release android` (ikon = perubahan native, tidak bisa lewat `shorebird patch`).

CATATAN PENTING
Agent sebelumnya tidak bisa menjalankan Flutter, jadi SEMUA perbaikan di bawah berasal dari pembacaan kode dan BELUM DIUJI. Cek di zip apakah tiap perubahan sudah terpasang; kalau saya bilang belum, anggap belum.

FILE YANG SUDAH DIPERBAIKI (isi lengkap sudah dikirim)
Sesi 1:
1. providers/item_provider.dart (dashboardLoading terpisah, nomor permintaan loadItems, referencesLoading/referencesError, loadDashboard tidak menulis _error)
2. screens/home/dashboard_screen.dart
3. widgets/transaction_filter_bar.dart (BELUM TUNTAS: chip tanggal "dari–sampai" dilaporkan tidak bisa ditutup, penyebab belum ditemukan)
4. core/api/api_client.dart
5. core/widgets/custom_snackbar.dart
6. models/report.dart
7. providers/transaction_provider.dart (status muat/error/hasMore terpisah masuk & keluar, loadIncoming/loadOutgoing(refresh: ...), getter lama loading/error dipertahankan)
8. screens/auth/login_screen.dart
9. screens/categories/categories_screen.dart (butuh item_provider.dart baru)
10. screens/errors/maintenance_screen.dart

Sesi 2 (ISI LENGKAP SUDAH DIKIRIM, belum tentu saya pasang):
11. screens/items/item_form_screen.dart: nilai awal dropdown dijaga (cegah assertion), loadReferences bila kosong, key dropdown, scroll ke error, input angka saja.
12. screens/items/items_screen.dart: loadItems tidak lagi dipanggil di dalam itemBuilder (postFrame + penjaga), hasSearch benar, reset juga mematikan filter stok menipis, onEdit hanya jika canEdit.
13. screens/profile/profile_screen.dart: jadi StatefulWidget, penjaga logout ganda, error logout ditangkap.
14. screens/profile/change_password_screen.dart: validasi huruf besar/kecil/angka sesuai teks bantuan, validator konfirmasi sendiri, snackbar sebelum pop.
15. screens/reports/report_screen.dart: nomor permintaan, snackbar bila refresh gagal saat data ada, penjaga mounted.
16. screens/rooms/rooms_screen.dart: pakai referencesLoading/referencesError, trim payload (butuh item_provider.dart baru).
17. screens/transactions/incoming_screen.dart dan outgoing_screen.dart: pakai getter per daftar (incomingLoading/incomingError/incomingHasMore, outgoing*), muat halaman berikutnya, refresh: true (butuh transaction_provider.dart baru).
18. screens/transactions/transaction_form_screen.dart: "Stok saat ini" tanpa "null", tujuan disimpan sebagai id ruangan (bukan objek Room), loadReferences terpisah dari fetchAllItems, scroll ke error.
19. screens/users/user_management_screen.dart: error simpan tampil di dalam bottom sheet, tidak bisa hapus akun sendiri, validasi password saat edit, regex email, snackbar bila refresh gagal.
20. services/auth_service.dart: import diperbaiki, login menolak respons tanpa token/user, logout tidak melempar error setelah sesi lokal dibersihkan.
21. services/item_service.dart: import diperbaiki, hasMore membaca meta atau level atas (fallback jumlah item == perPage), parameter kosong tidak dikirim, unwrap aman.
22. services/category_service.dart: import diperbaiki, tipe Response dari dio, unwrap aman.

Dicek, TIDAK ADA bug: screens/master/master_screen.dart, screens/transactions/transactions_screen.dart.

PASANGAN YANG HARUS DIPASANG BERSAMA
- item_provider.dart (baru) + categories_screen + rooms_screen + item_form_screen
- transaction_provider.dart (baru) + incoming_screen + outgoing_screen
- profile_screen disarankan bersama perubahan auth_provider.logout() (saran, lihat bawah)

SARAN OPSIONAL SEBELUMNYA (kode sudah diberikan di chat, belum tentu saya pasang)
api_exception.dart (toString semua pesan validasi); app_config.dart (applyStatus, low_stock_threshold); app_constants.dart (baseUrl String.fromEnvironment); token_storage.dart (_safeRead); models/dashboard.dart (_toInt/_toIntList); models/room.dart (== dan hashCode berdasarkan id); models/transaction_filter.dart (activeCount rentang tanggal = 1); providers/auth_provider.dart (logout set unauthenticated dulu); screens/items/item_detail_screen.dart (_orDash).

PROGRES PENGECEKAN FILE SATU PER SATU
Sudah dicek: semua lib/core, semua lib/models, semua lib/providers, semua lib/screens, widgets/transaction_filter_bar, dan services: auth_service, item_service, category_service.
BELUM dicek: sisa lib/services (room_service dan lainnya; minta saya menyebut daftar file di folder itu), widget: error_view, icon_badge, loading_widget, master_form_sheet, search_field, search_select_field, section_header, stat_card; lib/main.dart; folder test.
Aturan untuk semua file di lib/services: import ditulis '../../models/...', harus '../models/...'.

BUG/PEKERJAAN YANG MASIH TERBUKA
- master_form_sheet.dart: form ditutup sebelum data dikirim, isian hilang kalau server menolak (perbaiki saat file ini dicek).
- search_select_field.dart: pastikan `value` yang tidak ada di `items` ditangani aman (dipakai di form barang keluar).
- Izin/peran user tidak diambil ulang setelah login (restoreSession hanya membaca salinan tersimpan). Butuh nama endpoint profil (/user atau /me) dan bentuk responsnya: minta saya menjalankan `php artisan route:list` bagian auth/user, jangan menebak.
- Data provider (barang, transaksi, user, filter) tidak dikosongkan saat logout.
- items_screen: teks kotak pencarian tidak sinkron dengan setLowStockOnly() dan setelah logout (butuh item_provider.dart terpasang). canEdit = update || create terlihat janggal, tanya saya dulu.
- report_service: cek parameter fetch(...) dan format tanggal yang dikirim.
- category_service.all() hanya satu halaman; kalau backend memaginasi /categories, kategori ke-16 dan seterusnya tidak muncul. Minta contoh respons GET /categories.
- item_service: low_stock dikirim sebagai true; kalau tidak jalan di Laravel, ganti 1.
- Pastikan createRoom/updateRoom/deleteRoom/createUser/updateUser memperbarui daftar di provider, dan UserProvider.roles terisi oleh loadUsers (belum terlihat). Tipe User.id harus sama dengan auth.user.id (dipakai penjaga hapus diri sendiri).
- Admin bisa mencabut peran admin dari dirinya sendiri lewat edit user (belum diputuskan).
- Rilis Android: android/app/build.gradle.kts masih menandatangani release dengan debug key; android:usesCleartextTraffic="true" di AndroidManifest tidak diperlukan.
- Font Plus Jakarta Sans diunduh saat runtime (belum dibundel sebagai aset); MaterialApp tanpa themeMode sehingga ikut mode gelap perangkat.
- Menunggu keputusan saya: ikon mata password terbalik antara login dan ganti password; ejaan "Silahkan" di layar maintenance; "Inventaris Sekolah v1.0" ditulis manual di profil; email tampil dobel di profil; kontras teks putih di atas oranye/hijau.

LANGKAH SELANJUTNYA
1. Saya menempelkan file dari lib/services satu per satu (berikutnya room_service.dart), lalu widget, lalu lib/main.dart dan test.
2. Setelah semua beres: `flutter analyze` dan `flutter test`, perbaiki yang muncul (kirim output lengkapnya).
3. Naikkan versi ke 1.0.0+3, lalu `shorebird release android`.

Saya sampai di: services/category_service.dart (sudah dicek). Berikutnya: room_service.dart.