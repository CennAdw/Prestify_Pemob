<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$title = trim($input['title'] ?? '');
$organizer = trim($input['organizer'] ?? '');
$category = trim($input['category'] ?? '');
$level = trim($input['level'] ?? '');
$deadline = trim($input['deadline'] ?? '');
$description = trim($input['description'] ?? '');
$registrationLink = trim($input['registration_link'] ?? '');

if ($title === '' || $deadline === '') {
    send_error('title dan deadline wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "INSERT INTO competitions
        (title, organizer, category, level, deadline, description, registration_link, verification_status)
     VALUES (?, ?, ?, ?, ?, ?, ?, 'Menunggu Verifikasi')"
);
$stmt->execute([$title, $organizer, $category, $level, $deadline, $description, $registrationLink]);

send_success(['competition_id' => $db->lastInsertId()], 'Lomba berhasil diajukan.', 201);
