<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->id) && !empty($data->nom) && !empty($data->capacite) && !empty($data->equipements)) {
    $query = "UPDATE salles 
              SET nom = :nom, capacite = :capacite, equipements = :equipements, disponible = :disponible 
              WHERE id = :id";
    $stmt = $db->prepare($query);
    
    $disponible = isset($data->disponible) ? $data->disponible : 1;
    
    $stmt->bindParam(':id', $data->id);
    $stmt->bindParam(':nom', $data->nom);
    $stmt->bindParam(':capacite', $data->capacite);
    $stmt->bindParam(':equipements', $data->equipements);
    $stmt->bindParam(':disponible', $disponible);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Salle modifiée avec succès']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la modification']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Tous les champs sont requis']);
}
?>
