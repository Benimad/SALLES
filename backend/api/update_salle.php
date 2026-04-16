<?php
require_once 'config.php';

$db = getDB();

$input = json_decode(file_get_contents("php://input"), true);

if (empty($input['id']) || empty($input['nom']) || empty($input['capacite'])) {
    echo json_encode(['success' => false, 'message' => 'ID, nom et capacité requis']);
    exit();
}

try {
    $query = "UPDATE salles 
              SET nom = :nom, capacite = :capacite, etage = :etage, localisation = :localisation,
                  equipements = :equipements, disponible = :disponible, description = :description,
                  contact_responsable = :contact_responsable
              WHERE id = :id";
    $stmt = $db->prepare($query);

    $id = intval($input['id']);
    $nom = trim($input['nom']);
    $capacite = intval($input['capacite']);
    $etage = isset($input['etage']) && $input['etage'] !== '' && $input['etage'] !== null ? intval($input['etage']) : null;
    $localisation = isset($input['localisation']) ? trim($input['localisation']) : null;
    $equipements = isset($input['equipements']) ? trim($input['equipements']) : '';
    $disponible = isset($input['disponible']) ? (intval($input['disponible']) ? 1 : 0) : 1;
    $description = isset($input['description']) ? trim($input['description']) : null;
    $contactResponsable = isset($input['contact_responsable']) ? trim($input['contact_responsable']) : null;

    $stmt->bindParam(':id', $id, PDO::PARAM_INT);
    $stmt->bindParam(':nom', $nom);
    $stmt->bindParam(':capacite', $capacite, PDO::PARAM_INT);
    $stmt->bindParam(':etage', $etage, PDO::PARAM_INT);
    $stmt->bindParam(':localisation', $localisation);
    $stmt->bindParam(':equipements', $equipements);
    $stmt->bindParam(':disponible', $disponible, PDO::PARAM_INT);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':contact_responsable', $contactResponsable);

    $stmt->execute();
    echo json_encode(['success' => true, 'message' => 'Salle modifiée avec succès']);
} catch (PDOException $e) {
    error_log('Update Salle Error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Erreur lors de la modification']);
}
?>
