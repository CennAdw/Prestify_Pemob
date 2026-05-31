<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$selectedRole = trim($input['role'] ?? '');

if ($email === '' || $password === '') {
    send_error('Email dan password wajib diisi.', 422);
}

$db = get_db();
$stmt = $db->prepare(
    "SELECT
        u.id AS user_id,
        u.name,
        u.email,
        u.password,
        u.role,
        s.id AS student_id,
        s.study_program,
        s.batch_year,
        s.skills,
        l.id AS lecturer_id
     FROM users u
     LEFT JOIN students s ON s.user_id = u.id
     LEFT JOIN lecturers l ON l.user_id = u.id
     WHERE u.email = ?
     LIMIT 1"
);
$stmt->execute([$email]);
$user = $stmt->fetch();

if (!$user) {
    send_error('Akun tidak ditemukan.', 401);
}

$storedPassword = $user['password'];
$isPasswordHashValid = password_verify($password, $storedPassword);
$isShaFallbackValid = hash_equals($storedPassword, hash('sha256', $password));

if (!$isPasswordHashValid && !$isShaFallbackValid) {
    send_error('Password salah.', 401);
}

if ($selectedRole !== '' && $selectedRole !== $user['role']) {
    send_error('Role akun tidak sesuai dengan pilihan login.', 403);
}

$profileId = $user['user_id'];
if ($user['role'] === 'student' && $user['student_id']) {
    $profileId = $user['student_id'];
}
if ($user['role'] === 'lecturer' && $user['lecturer_id']) {
    $profileId = $user['lecturer_id'];
}

send_success([
    'user' => [
        'id' => $profileId,
        'user_id' => $user['user_id'],
        'student_id' => $user['student_id'],
        'lecturer_id' => $user['lecturer_id'],
        'name' => $user['name'],
        'email' => $user['email'],
        'role' => $user['role'],
        'study_program' => $user['study_program'],
        'batch_year' => $user['batch_year'],
        'skills' => $user['skills'],
    ],
], 'Login berhasil.');
