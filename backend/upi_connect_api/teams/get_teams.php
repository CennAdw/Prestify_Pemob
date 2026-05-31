<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$db = get_db();
$stmt = $db->query(
    "SELECT
        t.id,
        t.team_name,
        t.description,
        t.required_skills,
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
     ORDER BY t.id ASC"
);

send_success($stmt->fetchAll(), 'Data tim berhasil diambil.');
