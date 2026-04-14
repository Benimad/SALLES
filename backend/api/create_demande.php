<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->salle_id) && !empty($data->date_debut) && 
    !empty($data->date_fin) && !empty($data->heure_debut) && !empty($data->heure_fin) && 
    !empty($data->motif)) {
    
    // Vérifier les conflits de réservation
    $query = "SELECT * FROM demandes 
              WHERE salle_id = :salle_id 
              AND statut != 'rejetee'
              AND (
                  (date_debut <= :date_fin AND date_fin >= :date_debut)
              )";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':salle_id', $data->salle_id);
    $stmt->bindParam(':date_debut', $data->date_debut);
    $stmt->bindParam(':date_fin', $data->date_fin);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => false, 'message' => 'Cette salle est déjà réservée pour cette période']);
    } else {
        $query = "INSERT INTO demandes (user_id, salle_id, date_debut, date_fin, heure_debut, heure_fin, motif) 
                  VALUES (:user_id, :salle_id, :date_debut, :date_fin, :heure_debut, :heure_fin, :motif)";
        $stmt = $db->prepare($query);
        
        $stmt->bindParam(':user_id', $data->user_id);
        $stmt->bindParam(':salle_id', $data->salle_id);
        $stmt->bindParam(':date_debut', $data->date_debut);
        $stmt->bindParam(':date_fin', $data->date_fin);
        $stmt->bindParam(':heure_debut', $data->heure_debut);
        $stmt->bindParam(':heure_fin', $data->heure_fin);
        $stmt->bindParam(':motif', $data->motif);

        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Demande créée avec succès']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la création de la demande']);
        }
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Tous les champs sont requis']);
}
?>
