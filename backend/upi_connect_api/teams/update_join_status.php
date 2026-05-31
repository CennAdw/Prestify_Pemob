<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$requestId = $input['request_id'] ?? null;
$status = $input['status'] ?? null;

if (!$requestId || !$status) {
    send_error('request_id dan status wajib diisi.', 422);
}

$allowed = ['pending', 'accepted', 'rejected', 'Menunggu', 'Diterima', 'Ditolak'];
if (!in_array($status, $allowed, true)) {
    send_error('Status tidak valid.', 422);
}

$db = get_db();
$stmt = $db->prepare('UPDATE join_requests SET status = ? WHERE id = ?');
$stmt->execute([$status, $requestId]);

send_success(null, 'Status request berhasil diperbarui.');
