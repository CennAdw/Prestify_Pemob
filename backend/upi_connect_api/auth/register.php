<?php
require_once __DIR__ . '/../config/database.php';

require_method('POST');

$input = get_json_input();
$name = trim($input['name'] ?? '');
$email = trim($input['email'] ?? '');
$password = $input['password'] ?? '';
$role = trim($input['role'] ?? 'student');

if ($name === '' || $email === '' || $password === '') {
    send_error('Nama, email, dan password wajib diisi.', 422);
}

if (!in_array($role, ['student', 'lecturer', 'admin'], true)) {
    send_error('Role tidak valid.', 422);
}

$db = get_db();
$stmt = $db->prepare('INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)');
$stmt->execute([$name, $email, password_hash($password, PASSWORD_DEFAULT), $role]);

send_success(['user_id' => $db->lastInsertId()], 'Registrasi berhasil.', 201);
