# Prestify

Flutter app untuk mencari tim lomba, mengajukan bergabung ke tim, mencari dosen pembimbing, dan mengelola portofolio mahasiswa.

## Supabase Setup

1. Buat project Supabase.
2. Buka SQL Editor.
3. Jalankan file `supabase/schema.sql`.
4. Buka `lib/core/constants/supabase_config.dart`.
5. Isi URL dan anon key project Supabase.
6. Aktifkan Google di Authentication > Providers.
7. Tambahkan redirect URL ini di Authentication > URL Configuration:

```text
id.upi.connect.upi_connect_plus://login-callback/
```

Database tidak diisi seed account. Semua data dibuat oleh user asli setelah login Google.

## Jalankan App

```powershell
flutter pub get
flutter run
```

Catatan: role admin, backend PHP Native, dan MySQL sudah dihapus dari versi ini.
