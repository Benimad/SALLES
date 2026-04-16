<?php
require_once 'config.php';

$db = getDB();

$input = json_decode(file_get_contents("php://input"), true);

if (empty($input['nom']) || empty($input['capacite'])) {
    echo json_encode(['success' => false, 'message' => 'Nom et capacité requis']);
    exit();
}

try {
    $query = "INSERT INTO salles (nom, capacite, etage, localisation, equipements, disponible, description, contact_responsable) 
              VALUES (:nom, :capacite, :etage, :localisation, :equipements, :disponible, :description, :contact_responsable)";
    $stmt = $db->prepare($query);

    $nom = trim($input['nom']);
    $capacite = intval($input['capacite']);
    $etage = isset($input['etage']) && $input['etage'] !== '' && $input['etage'] !== null ? intval($input['etage']) : null;
    $localisation = isset($input['localisation']) ? trim($input['localisation']) : null;
    $equipements = isset($input['equipements']) ? trim($input['equipements']) : '';
    $disponible = isset($input['disponible']) ? (intval($input['disponible']) ? 1 : 0) : 1;
    $description = isset($input['description']) ? trim($input['description']) : null;
    $contactResponsable = isset($input['contact_responsable']) ? trim($input['contact_responsable']) : null;

    $stmt->bindParam(':nom', $nom);
    $stmt->bindParam(':capacite', $capacite, PDO::PARAM_INT);
    $stmt->bindParam(':etage', $etage, PDO::PARAM_INT);
    $stmt->bindParam(':localisation', $localisation);
    $stmt->bindParam(':equipements', $equipements);
    $stmt->bindParam(':disponible', $disponible, PDO::PARAM_INT);
    $stmt->bindParam(':description', $description);
    $stmt->bindParam(':contact_responsable', $contactResponsable);

    $stmt->execute();
    $salleId = $db->lastInsertId();

    echo json_encode([
        'success' => true,
        'message' => 'Salle ajoutée avec succès',
        'salle_id' => (int)$salleId
    ]);
} catch (PDOException $e) {
    error_log('Add Salle Error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'ajout de la salle']);
}
?>
