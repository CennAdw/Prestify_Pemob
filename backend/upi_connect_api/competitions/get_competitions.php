<?php
require_once __DIR__ . '/../config/database.php';

require_method('GET');

$db = get_db();
$stmt = $db->query(
    "SELECT
        id,
        title,
        organizer,
        category,
        level,
        deadline,
        description,
        registration_link,
        verification_status,
        CASE id
            WHEN 1 THEN 98
            WHEN 2 THEN 74
            WHEN 3 THEN 62
            WHEN 4 THEN 86
            ELSE 40
        END AS interest_count
     FROM competitions
     WHERE verification_status = 'Terverifikasi'
     ORDER BY deadline ASC"
);

send_success($stmt->fetchAll(), 'Data lomba berhasil diambil.');
