<?php

declare(strict_types=1);

$dsn = 'pgsql:host=' . getenv('DB_HOST') .
       ';port=' . getenv('DB_PORT') .
       ';dbname=' . getenv('DB_NAME');

$db = new PDO(
    $dsn,
    getenv('DB_USER'),
    getenv('DB_PASSWORD'),
    [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
    ]
);
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$db->exec('
    CREATE TABLE IF NOT EXISTS test (
        id BIGSERIAL PRIMARY KEY,
        value INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )
');

// Generate a random value for this refresh
$value = random_int(1, 100);

// Save the value
$stmt = $db->prepare('
    INSERT INTO test (value)
    VALUES (:value)
');

$stmt->execute([
    ':value' => $value
]);

// Get the value that was just saved
$stmt = $db->query('
    SELECT value, created_at
    FROM test
    ORDER BY id DESC
    LIMIT 1
');

$row = $stmt->fetch(PDO::FETCH_ASSOC);

// Count total page refreshes
$stmt = $db->query('SELECT COUNT(*) FROM test');

$totalRefreshes = (int) $stmt->fetchColumn();

?>
--------------------------------------------------------------------
PHP version: <?= htmlspecialchars(PHP_VERSION) ?>

Latest value: <?= htmlspecialchars((string) $row['value']) ?>

Saved at: <?= htmlspecialchars((string) $row['created_at']) ?>

Total refreshes: <?= $totalRefreshes ?>

--------------------------------------------------------------------
