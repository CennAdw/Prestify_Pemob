# Prestify

Flutter app untuk mencari tim lomba, mengajukan bergabung ke tim, mencari dosen
pembimbing, dan mengelola portofolio mahasiswa UPI.akhirnya

## Sistem Autentikasi

- Hanya email dengan domain tepat `@upi.edu` yang diterima.
- Login tersedia melalui NIM/NIDN + password dan Google.
- Password disimpan dan di-hash oleh Supabase Auth, bukan tabel publik.
- Verifikasi email menggunakan built-in email confirmation dari Supabase.
- Akun Google `@upi.edu` dianggap terverifikasi oleh provider Google.
- Akun Google baru diarahkan ke halaman pendaftaran tanpa meminta email dan
  password lagi.
- Role dosen hanya diberikan kepada email aktif di
  `public.lecturer_allowlist`.

## Supabase Setup

1. Buat project Supabase.
2. Buka SQL Editor.
3. Untuk project baru, jalankan `supabase/schema.sql`.
4. Untuk database yang sudah dipakai, jalankan migration secara berurutan:

```text
supabase/migrations/20260603_secure_role_assignment.sql
supabase/migrations/20260603_resend_auth_nim.sql
```

`supabase/schema.sql` menghapus dan membuat ulang tabel aplikasi, jadi jangan
jalankan file tersebut pada database yang sudah berisi data produksi.

5. Isi URL dan anon key di `lib/core/constants/supabase_config.dart`.
6. Aktifkan Google di Authentication > Providers.
7. Di Authentication > Providers > Email, pastikan **Confirm email** diaktifkan
   (settings default). Supabase akan mengirim email verification secara otomatis.
8. Di Google Cloud Console, tambahkan callback Supabase sebagai **Authorized
   redirect URI**:

```text
https://PROJECT_REF.supabase.co/auth/v1/callback
```

9. Tambahkan redirect URL aplikasi berikut di Supabase Authentication > URL
   Configuration:

```text
id.upi.connect.upi_connect_plus://login-callback/
http://localhost:PORT
```

Gunakan origin web yang sesuai saat menjalankan Flutter Web.

5. Deploy Edge Functions:

```powershell
supabase functions deploy login-with-nim --no-verify-jwt
supabase functions deploy complete-registration
```

## Role Dosen Terverifikasi

Pengguna tidak memilih role dari aplikasi. Tambahkan dosen resmi melalui SQL
Editor sebelum dosen tersebut mendaftar. NIDN dosen diambil dari allowlist ini,
bukan dari input pengguna:

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
  '1234567890',
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

## Jalankan App

```powershell
flutter pub get
flutter run
```

Catatan: role admin, backend PHP Native, dan MySQL sudah dihapus dari versi ini.
