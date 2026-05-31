<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$studentId = $_GET['student_id'] ?? null;
if (!$studentId) {
    send_error('student_id wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "SELECT *
     FROM achievements
     WHERE student_id = ?
     ORDER BY year DESC, id DESC"
);
$stmt->execute([$studentId]);

send_success($stmt->fetchAll(), 'Data prestasi berhasil diambil.');
