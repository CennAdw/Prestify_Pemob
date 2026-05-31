# UPI Connect+

Flutter MVP untuk mencari tim lomba, mengajukan bergabung ke tim, mencari dosen pembimbing, dan mengelola portofolio mahasiswa.

## Supabase Setup

1. Buat project Supabase baru.
2. Buka SQL Editor.
3. Jalankan file `supabase/schema.sql`.
4. Buka `lib/core/constants/supabase_config.dart`.
5. Isi URL dan anon key project Supabase:

```dart
const String supabaseUrl = 'https://PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'SUPABASE_ANON_KEY';
```

Tidak ada fallback dummy. Kalau konfigurasi, policy, atau tabel Supabase bermasalah, aplikasi menampilkan pesan error dan detailnya dicetak ke debug console Flutter.

## Akun Demo

- Mahasiswa: `candra@upi.edu` / `123456`
- Dosen: `dosen@upi.edu` / `123456`

## Jalankan App

```powershell
flutter pub get
flutter run
```

Catatan: role admin, backend PHP Native, dan MySQL sudah dihapus dari versi ini.
