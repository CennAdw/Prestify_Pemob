// Isi dua nilai ini dari Project Settings > API di dashboard Supabase.
// Selama masih memakai placeholder, aplikasi otomatis memakai fallback dummy.
const String supabaseUrl = 'https://byfuvpemgmczdhnvbjgf.supabase.co';
const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZnV2cGVtZ21jemRobnZiamdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMTE2MTYsImV4cCI6MjA5NTc4NzYxNn0.AX89Qyta63uR7OLpDuyFopUWbYk9lg0E4ZctnCymBuY';

bool get isSupabaseConfigured =>
    !supabaseUrl.contains('https://byfuvpemgmczdhnvbjgf.supabase.co') &&
    !supabaseAnonKey.contains('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ5ZnV2cGVtZ21jemRobnZiamdmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAyMTE2MTYsImV4cCI6MjA5NTc4NzYxNn0.AX89Qyta63uR7OLpDuyFopUWbYk9lg0E4ZctnCymBuY');
