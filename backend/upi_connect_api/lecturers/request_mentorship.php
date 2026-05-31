<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$teamId = $input['team_id'] ?? null;
$lecturerId = $input['lecturer_id'] ?? null;
$proposalTitle = trim($input['proposal_title'] ?? '');
$proposalSummary = trim($input['proposal_summary'] ?? '');
$proposalLink = trim($input['proposal_link'] ?? '');

if (!$teamId || !$lecturerId || $proposalTitle === '') {
    send_error('team_id, lecturer_id, dan proposal_title wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "INSERT INTO mentorship_requests
        (team_id, lecturer_id, proposal_title, proposal_summary, proposal_link, status)
     VALUES (?, ?, ?, ?, ?, 'pending')"
);
$stmt->execute([$teamId, $lecturerId, $proposalTitle, $proposalSummary, $proposalLink]);

send_success(['request_id' => $db->lastInsertId()], 'Request bimbingan berhasil dikirim.', 201);
