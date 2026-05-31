<?php
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(204);
    exit;
}

function send_success($data = null, $message = 'success', $status = 200)
{
    http_response_code($status);
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data,
    ]);
    exit;
}

function send_error($message = 'error', $status = 400, $data = null)
{
    http_response_code($status);
    echo json_encode([
        'success' => false,
        'message' => $message,
        'data' => $data,
    ]);
    exit;
}

function get_json_input()
{
    $raw = file_get_contents('php://input');
    if (!$raw) {
        return $_POST;
    }

    $decoded = json_decode($raw, true);
    if (json_last_error() !== JSON_ERROR_NONE) {
        send_error('Invalid JSON body.', 422);
    }

    return $decoded ?: [];
}

function require_method($method)
{
    if ($_SERVER['REQUEST_METHOD'] !== $method) {
        send_error('Method not allowed.', 405);
    }
}
