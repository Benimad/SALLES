<?php
require_once 'config.php';

$db = getDB();

try {
    $date = $_GET['date'] ?? date('Y-m-d');
    $sortBy = $_GET['sort'] ?? 'nom';

    $query = "SELECT id, nom, capacite, etage, localisation, equipements, disponible, description, contact_responsable, created_at
              FROM salles
              ORDER BY nom ASC";
    
    $stmt = $db->prepare($query);
    $stmt->execute();

    $salles = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        // Get bookings for this room on the specified date
        $bookingsQuery = "SELECT COUNT(*) as bookingCount FROM demandes 
                         WHERE salle_id = :salle_id AND date_debut <= :date AND date_fin >= :date 
                         AND statut IN ('en_attente', 'approuvee')";
        $bookingsStmt = $db->prepare($bookingsQuery);
        $bookingsStmt->bindParam(':salle_id', $row['id'], PDO::PARAM_INT);
        $bookingsStmt->bindParam(':date', $date);
        $bookingsStmt->execute();
        $bookings = $bookingsStmt->fetch(PDO::FETCH_ASSOC);

        $salles[] = [
            'id' => (int)$row['id'],
            'nom' => $row['nom'],
            'capacite' => (int)$row['capacite'],
            'etage' => $row['etage'],
            'localisation' => $row['localisation'],
            'equipements' => $row['equipements'] ?? '',
            'disponible' => (bool)$row['disponible'],
            'description' => $row['description'],
            'contact_responsable' => $row['contact_responsable'],
        ];
    }

    echo json_encode(['success' => true, 'salles' => $salles]);

} catch (PDOException $e) {
    error_log('Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur serveur', 500);
}
?>
