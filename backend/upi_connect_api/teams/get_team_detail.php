<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$teamId = $_GET['id'] ?? null;
if (!$teamId) {
    send_error('Parameter id wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "SELECT
        t.id,
        t.team_name,
        t.description,
        t.required_skills,
        t.required_roles,
        t.recruitment_status,
        t.progress_status,
        c.title AS competition_title,
        c.deadline,
        c.category,
        COALESCE(member_counts.total_members, 0) AS current_members,
        5 AS max_members,
        CASE t.id
            WHEN 1 THEN 82
            WHEN 2 THEN 68
            WHEN 3 THEN 54
            ELSE 60
        END AS matching_score
     FROM teams t
     JOIN competitions c ON c.id = t.competition_id
     LEFT JOIN (
        SELECT team_id, COUNT(*) AS total_members
        FROM team_members
        WHERE status = 'active'
        GROUP BY team_id
     ) member_counts ON member_counts.team_id = t.id
     WHERE t.id = ?"
);
$stmt->execute([$teamId]);
$team = $stmt->fetch();

if (!$team) {
    send_error('Tim tidak ditemukan.', 404);
}

$memberStmt = $db->prepare(
    "SELECT u.name, tm.role_in_team
     FROM team_members tm
     JOIN students s ON s.id = tm.student_id
     JOIN users u ON u.id = s.user_id
     WHERE tm.team_id = ? AND tm.status = 'active'
     ORDER BY tm.id ASC"
);
$memberStmt->execute([$teamId]);
$members = array_map(function ($member) {
    return [
        'name' => $member['name'],
        'role_in_team' => $member['role_in_team'],
    ];
}, $memberStmt->fetchAll());

send_success([
    'team' => $team,
    'members' => $members,
], 'Detail tim berhasil diambil.');
