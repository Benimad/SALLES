<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->id)) {
    // Vérifier s'il y a des demandes liées à cette salle
    $checkQuery = "SELECT COUNT(*) as count FROM demandes WHERE salle_id = :id AND statut != 'rejetee'";
    $checkStmt = $db->prepare($checkQuery);
    $checkStmt->bindParam(':id', $data->id);
    $checkStmt->execute();
    $result = $checkStmt->fetch(PDO::FETCH_ASSOC);

    if ($result['count'] > 0) {
        echo json_encode([
            'success' => false, 
            'message' => 'Impossible de supprimer cette salle car elle a des réservations actives'
        ]);
    } else {
        $query = "DELETE FROM salles WHERE id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $data->id);

        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Salle supprimée avec succès']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Erreur lors de la suppression']);
        }
    }
} else {
    echo json_encode(['success' => false, 'message' => 'ID de salle requis']);
}
?>
