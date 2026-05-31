<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$db = get_db();

$totalStudents = (int) $db->query('SELECT COUNT(*) FROM students')->fetchColumn();
$totalTeams = (int) $db->query('SELECT COUNT(*) FROM teams')->fetchColumn();
$totalCompetitions = (int) $db->query('SELECT COUNT(*) FROM competitions')->fetchColumn();
$totalLecturers = (int) $db->query('SELECT COUNT(*) FROM lecturers')->fetchColumn();

$categoryStmt = $db->query(
    "SELECT category, COUNT(*) AS total
     FROM competitions
     GROUP BY category
     ORDER BY total DESC"
);
$categoryStats = [];
foreach ($categoryStmt->fetchAll() as $row) {
    $categoryStats[$row['category']] = (int) $row['total'];
}

$pendingStmt = $db->query(
    "SELECT
        id,
        title,
        organizer,
        category,
        level,
        deadline,
        description,
        registration_link,
        verification_status,
        0 AS interest_count
     FROM competitions
     WHERE verification_status = 'Menunggu Verifikasi'
     ORDER BY created_at DESC"
);

send_success([
    'total_students' => $totalStudents,
    'total_teams' => $totalTeams,
    'total_competitions' => $totalCompetitions,
    'total_lecturers' => $totalLecturers,
    'category_stats' => $categoryStats,
    'pending_competitions' => $pendingStmt->fetchAll(),
], 'Dashboard admin berhasil diambil.');
