<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents("php://input"), true);

    $salle_id = intval($input['salle_id'] ?? 0);
    $date_debut = $input['date_debut'] ?? '';
    $heure_debut = $input['heure_debut'] ?? '';
    $heure_fin = $input['heure_fin'] ?? '';

    if (!$salle_id || !$date_debut || !$heure_debut || !$heure_fin) {
        echo ApiResponse::validation(['message' => 'Paramètres manquants']);
        exit();
    }

    // Check for conflicts
    $query = "SELECT COUNT(*) as count FROM demandes 
              WHERE salle_id = :salle_id 
              AND date_debut = :date_debut
              AND statut IN ('en_attente', 'approuvee')
              AND (
                  (heure_debut < :heure_fin AND heure_fin > :heure_debut)
              )";

    $stmt = $db->prepare($query);
    $stmt->bindParam(':salle_id', $salle_id, PDO::PARAM_INT);
    $stmt->bindParam(':date_debut', $date_debut);
    $stmt->bindParam(':heure_debut', $heure_debut);
    $stmt->bindParam(':heure_fin', $heure_fin);
    $stmt->execute();

    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    $isAvailable = $result['count'] == 0;

    echo ApiResponse::success([
        'available' => $isAvailable,
        'conflicts' => $result['count']
    ], 'Disponibilité vérifiée');

} catch (PDOException $e) {
    error_log('Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur serveur', 500);
}
?>
