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

## Role Dosen Terverifikasi

Pengguna tidak memilih role saat login. Supabase menetapkan role secara otomatis:

- Email aktif di `public.lecturer_allowlist` masuk sebagai dosen.
- Email lain masuk sebagai mahasiswa.
- Flutter tidak memiliki izin untuk mengubah kolom `users.role`.

Tambahkan dosen resmi melalui SQL Editor sebelum dosen tersebut login:

```sql
insert into public.lecturer_allowlist (
  email,
  name,
  nidn,
  faculty,
  expertise
) values (
  'nama.dosen@upi.edu',
  'Nama Dosen',
  'NIDN',
  'Fakultas',
  'Mobile Development, Sistem Informasi'
);
```

Gunakan email huruf kecil. Untuk menonaktifkan akses dosen:

```sql
update public.lecturer_allowlist
set is_active = false
where email = 'nama.dosen@upi.edu';
```

RLS langsung menghentikan akses dosen ketika `is_active` menjadi `false`.
Role profil akan disinkronkan menjadi mahasiswa saat pengguna login berikutnya.

Jika schema lama sudah pernah dijalankan, jalankan
`supabase/migrations/20260603_secure_role_assignment.sql`. Setelah email dosen
masuk ke allowlist, minta dosen logout lalu login kembali agar role disinkronkan.

## Jalankan App

```powershell
flutter pub get
flutter run
```

Catatan: role admin, backend PHP Native, dan MySQL sudah dihapus dari versi ini.
