<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$user_id = isset($_GET['user_id']) ? $_GET['user_id'] : null;

if ($user_id) {
    $query = "SELECT d.*, s.nom as salle_name, CONCAT(u.prenom, ' ', u.nom) as user_name
              FROM demandes d
              JOIN salles s ON d.salle_id = s.id
              JOIN users u ON d.user_id = u.id
              WHERE d.user_id = :user_id
              ORDER BY d.created_at DESC";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':user_id', $user_id);
} else {
    $query = "SELECT d.*, s.nom as salle_name, CONCAT(u.prenom, ' ', u.nom) as user_name
              FROM demandes d
              JOIN salles s ON d.salle_id = s.id
              JOIN users u ON d.user_id = u.id
              ORDER BY d.created_at DESC";
    $stmt = $db->prepare($query);
}

$stmt->execute();

$demandes = [];
while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
    $demandes[] = [
        'id' => $row['id'],
        'user_id' => $row['user_id'],
        'salle_id' => $row['salle_id'],
        'date_debut' => $row['date_debut'],
        'date_fin' => $row['date_fin'],
        'heure_debut' => $row['heure_debut'],
        'heure_fin' => $row['heure_fin'],
        'motif' => $row['motif'],
        'statut' => $row['statut'],
        'salle_name' => $row['salle_name'],
        'user_name' => $row['user_name']
    ];
}

echo json_encode(['success' => true, 'demandes' => $demandes]);
?>
