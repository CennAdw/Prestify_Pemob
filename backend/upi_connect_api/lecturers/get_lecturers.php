<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$db = get_db();
$stmt = $db->query(
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
     ORDER BY l.id ASC"
);

send_success($stmt->fetchAll(), 'Data dosen berhasil diambil.');
