<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$teamId = $input['team_id'] ?? null;
$studentId = $input['student_id'] ?? null;
$appliedRole = trim($input['applied_role'] ?? 'Member');
$message = trim($input['message'] ?? '');

if (!$teamId || !$studentId) {
    send_error('team_id dan student_id wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "INSERT INTO join_requests (team_id, student_id, applied_role, message, matching_score, status)
     VALUES (?, ?, ?, ?, 82, 'pending')"
);
$stmt->execute([$teamId, $studentId, $appliedRole, $message]);

send_success(['request_id' => $db->lastInsertId()], 'Request bergabung berhasil dikirim.', 201);
