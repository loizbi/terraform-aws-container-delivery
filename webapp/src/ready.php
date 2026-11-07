<?php

declare(strict_types=1);

header('Content-Type: application/json');

try {
    $dsn = 'pgsql:host=' . getenv('DB_HOST') .
           ';port=' . getenv('DB_PORT') .
           ';dbname=' . getenv('DB_NAME');

    $db = new PDO(
        $dsn,
        getenv('DB_USER'),
        getenv('DB_PASSWORD'),
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_TIMEOUT => 2,
        ]
    );

    // Verify that the database is actually responding.
    $db->query('SELECT 1');

    http_response_code(200);

    echo json_encode([
        'status' => 'ready',
        'database' => 'ok',
    ]);

} catch (Throwable $e) {

    http_response_code(503);

    echo json_encode([
        'status' => 'not_ready',
        'database' => 'unavailable',
    ]);
}

?>