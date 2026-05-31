<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$competitionId = $input['competition_id'] ?? null;
$leaderId = $input['leader_id'] ?? null;
$teamName = trim($input['team_name'] ?? '');
$description = trim($input['description'] ?? '');
$requiredSkills = trim($input['required_skills'] ?? '');
$requiredRoles = trim($input['required_roles'] ?? '');

if (!$competitionId || !$leaderId || $teamName === '') {
    send_error('competition_id, leader_id, dan team_name wajib diisi.', 422);
}

$db = get_db();
$db->beginTransaction();

try {
    $stmt = $db->prepare(
        "INSERT INTO teams
            (competition_id, leader_id, team_name, description, required_roles, required_skills, recruitment_status, progress_status)
         VALUES (?, ?, ?, ?, ?, ?, 'Open Recruitment', 'Recruiting')"
    );
    $stmt->execute([$competitionId, $leaderId, $teamName, $description, $requiredRoles, $requiredSkills]);
    $teamId = $db->lastInsertId();

    $memberStmt = $db->prepare(
        "INSERT INTO team_members (team_id, student_id, role_in_team, status)
         VALUES (?, ?, 'Ketua Tim', 'active')"
    );
    $memberStmt->execute([$teamId, $leaderId]);

    $db->commit();
    send_success(['team_id' => $teamId], 'Tim berhasil dibuat.', 201);
} catch (Exception $exception) {
    $db->rollBack();
    send_error('Gagal membuat tim: ' . $exception->getMessage(), 500);
}
