<?php
require_once __DIR__ . '/../helpers/response.php';

function get_db()
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $host = 'localhost';
    $database = 'upi_connect_db';
    $username = 'root';
    $password = '';

    try {
        $pdo = new PDO(
            "mysql:host={$host};dbname={$database};charset=utf8mb4",
            $username,
            $password,
            [
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            ]
        );
        return $pdo;
    } catch (PDOException $exception) {
        send_error('Database connection failed: ' . $exception->getMessage(), 500);
    }
}
