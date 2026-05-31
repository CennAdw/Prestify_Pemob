<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$studentId = $input['student_id'] ?? null;
$competitionName = trim($input['competition_name'] ?? '');
$award = trim($input['award'] ?? '');
$category = trim($input['category'] ?? '');
$level = trim($input['level'] ?? '');
$year = trim($input['year'] ?? date('Y'));
$description = trim($input['description'] ?? '');

if (!$studentId || $competitionName === '') {
    send_error('student_id dan competition_name wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "INSERT INTO achievements
        (student_id, team_id, competition_name, award, category, level, year, certificate_link, verification_status, description)
     VALUES (?, NULL, ?, ?, ?, ?, ?, '', 'Menunggu Verifikasi', ?)"
);
$stmt->execute([$studentId, $competitionName, $award, $category, $level, $year, $description]);

send_success(['achievement_id' => $db->lastInsertId()], 'Prestasi berhasil ditambahkan.', 201);
