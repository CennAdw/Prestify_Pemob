<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$competitionId = $input['competition_id'] ?? null;
$verificationStatus = $input['verification_status'] ?? 'Terverifikasi';

if (!$competitionId) {
    send_error('competition_id wajib diisi.', 422);
}

$allowed = ['Menunggu Verifikasi', 'Terverifikasi', 'Ditolak'];
if (!in_array($verificationStatus, $allowed, true)) {
    send_error('verification_status tidak valid.', 422);
}

$db = get_db();
$stmt = $db->prepare('UPDATE competitions SET verification_status = ? WHERE id = ?');
$stmt->execute([$verificationStatus, $competitionId]);

send_success(null, 'Status verifikasi lomba berhasil diperbarui.');
