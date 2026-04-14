<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$query = "SELECT * FROM salles ORDER BY nom ASC";
$stmt = $db->prepare($query);
$stmt->execute();

$salles = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $salles[] = [
        'id' => $row['id'],
        'nom' => $row['nom'],
        'capacite' => $row['capacite'],
        'equipements' => $row['equipements'],
        'disponible' => $row['disponible']
    ];
}

echo json_encode(['success' => true, 'salles' => $salles]);
?>
