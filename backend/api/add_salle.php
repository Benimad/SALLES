<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->nom) && !empty($data->capacite) && !empty($data->equipements)) {
    $query = "INSERT INTO salles (nom, capacite, equipements, disponible) 
              VALUES (:nom, :capacite, :equipements, :disponible)";
    $stmt = $db->prepare($query);
    
    $disponible = isset($data->disponible) ? $data->disponible : 1;
    
    $stmt->bindParam(':nom', $data->nom);
    $stmt->bindParam(':capacite', $data->capacite);
    $stmt->bindParam(':equipements', $data->equipements);
    $stmt->bindParam(':disponible', $disponible);

    if ($stmt->execute()) {
        $salle_id = $db->lastInsertId();
        echo json_encode([
            'success' => true, 
            'message' => 'Salle ajoutée avec succès',
            'salle_id' => $salle_id
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'ajout de la salle']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Tous les champs sont requis']);
}
?>
