// Base URL untuk Android Emulator bawaan Android Studio.
// Emulator mengakses localhost laptop melalui IP khusus 10.0.2.2.
const String baseUrl = 'http://10.0.2.2/upi_connect_api';

// Untuk HP Android asli, ganti nilai baseUrl di atas menjadi IP laptop:
// const String baseUrl = 'http://192.168.1.8/upi_connect_api';
//
// Pastikan HP dan laptop tersambung ke Wi-Fi yang sama, Apache XAMPP menyala,
// dan firewall laptop mengizinkan akses ke port 80.
