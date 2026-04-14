<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->demande_id) && !empty($data->statut)) {
    $query = "UPDATE demandes SET statut = :statut WHERE id = :demande_id";
    $stmt = $db->prepare($query);
    
    $stmt->bindParam(':statut', $data->statut);
    $stmt->bindParam(':demande_id', $data->demande_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Statut mis à jour avec succès']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'ID de demande et statut requis']);
}
?>
