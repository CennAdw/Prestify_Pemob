<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$userId = $_GET['user_id'] ?? null;
$studentId = $_GET['student_id'] ?? null;

$db = get_db();
if ($studentId) {
    $stmt = $db->prepare(
        "SELECT s.*, u.name, u.email, u.role
         FROM students s
         JOIN users u ON u.id = s.user_id
         WHERE s.id = ?"
    );
    $stmt->execute([$studentId]);
} else {
    $stmt = $db->prepare(
        "SELECT s.*, u.name, u.email, u.role
         FROM students s
         JOIN users u ON u.id = s.user_id
         WHERE s.user_id = ?"
    );
    $stmt->execute([$userId]);
}

$profile = $stmt->fetch();
if (!$profile) {
    send_error('Profil mahasiswa tidak ditemukan.', 404);
}

send_success($profile, 'Profil mahasiswa berhasil diambil.');
