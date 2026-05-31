// Isi dua nilai ini dari Project Settings > API di dashboard Supabase.
// Jika masih placeholder atau salah, request akan gagal dan detail error
// muncul di debug console Flutter.
const String supabaseUrl = 'https://byfuvpemgmczdhnvbjgf.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZnV2cGVtZ21jemRobnZiamdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMTE2MTYsImV4cCI6MjA5NTc4NzYxNn0.AX89Qyta63uR7OLpDuyFopUWbYk9lg0E4ZctnCymBuY';

// Tambahkan URL ini di Supabase Dashboard > Authentication > URL Configuration
// > Redirect URLs, lalu aktifkan Google provider di Authentication > Providers.
final String googleOAuthRedirectUrl = Uri.base.origin;

bool get isSupabaseConfigured =>
    supabaseUrl.startsWith('https://') &&
    !supabaseUrl.contains('YOUR_PROJECT_ID') &&
    supabaseAnonKey.isNotEmpty &&
    !supabaseAnonKey.contains('YOUR_SUPABASE_ANON_KEY');
