<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$studentId = $input['student_id'] ?? $input['id'] ?? null;

if (!$studentId) {
    send_error('student_id wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "UPDATE students
     SET faculty = ?, study_program = ?, batch_year = ?, skills = ?, interests = ?, portfolio_link = ?, bio = ?
     WHERE id = ?"
);
$stmt->execute([
    $input['faculty'] ?? '',
    $input['study_program'] ?? '',
    $input['batch_year'] ?? null,
    $input['skills'] ?? '',
    $input['interests'] ?? '',
    $input['portfolio_link'] ?? '',
    $input['bio'] ?? '',
    $studentId,
]);

send_success(null, 'Profil mahasiswa berhasil diperbarui.');
