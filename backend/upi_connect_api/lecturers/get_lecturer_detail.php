<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$lecturerId = $_GET['id'] ?? null;
if (!$lecturerId) {
    send_error('Parameter id wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "SELECT
        l.id,
        u.name,
        u.email,
        l.nidn,
        l.faculty,
        l.expertise,
        l.mentoring_status,
        l.mentoring_quota,
        l.current_mentoring_count,
        l.bio
     FROM lecturers l
     JOIN users u ON u.id = l.user_id
     WHERE l.id = ?"
);
$stmt->execute([$lecturerId]);
$lecturer = $stmt->fetch();

if (!$lecturer) {
    send_error('Dosen tidak ditemukan.', 404);
}

$lecturer['experiences'] = 'GEMASTIK XVI 2023 - Juara 1 Nasional, UI/UX Design Competition 2023 - Juara 2 Nasional';
if ((int) $lecturerId === 2) {
    $lecturer['experiences'] = 'Business Plan Competition 2024 - Best Innovation, KMI Expo 2023 - Finalis Nasional';
}
if ((int) $lecturerId === 3) {
    $lecturer['experiences'] = 'LIDM 2023 - Finalis Nasional, Inovasi Media Pembelajaran 2022 - Juara Favorit';
}

send_success($lecturer, 'Detail dosen berhasil diambil.');
