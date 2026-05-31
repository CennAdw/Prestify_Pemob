# UPI Connect+

Flutter MVP untuk mencari tim lomba, mengajukan bergabung ke tim, mencari dosen pembimbing, dan mengelola portofolio mahasiswa.

## Supabase Setup

1. Buat project Supabase baru.
2. Buka SQL Editor.
3. Jalankan file `supabase/schema.sql`.
4. Buka `lib/core/constants/supabase_config.dart`.
5. Isi:

```dart
const String supabaseUrl = 'https://PROJECT_ID.supabase.co';
const String supabaseAnonKey = 'SUPABASE_ANON_KEY';
```

Selama URL/key masih placeholder, aplikasi otomatis memakai fallback dummy.

## Akun Demo

- Mahasiswa: `candra@upi.edu` / `123456`
- Dosen: `dosen@upi.edu` / `123456`

## Jalankan App

```powershell
flutter pub get
flutter run
```

Catatan: role admin, backend PHP Native, dan MySQL sudah dihapus dari versi ini.
