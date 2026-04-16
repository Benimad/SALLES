<?php
require_once 'config.php';

$db = getDB();

try {
    $userId = $_GET['user_id'] ?? null;
    $status = $_GET['status'] ?? null;
    $adminView = isset($_GET['admin']) && $_GET['admin'] === '1';
    $limit = intval($_GET['limit'] ?? 50);
    $offset = intval($_GET['offset'] ?? 0);

    $query = "SELECT d.id, d.user_id, d.salle_id,
                     CONCAT(u.prenom, ' ', u.nom) as user_name,
                     s.nom as salle_name,
                     d.date_debut, d.date_fin, d.heure_debut, d.heure_fin, 
                     d.motif, d.description, d.participants_externes,
                     d.statut, d.raison_rejet, d.created_at
              FROM demandes d
              JOIN users u ON d.user_id = u.id
              JOIN salles s ON d.salle_id = s.id
              WHERE 1=1";

    if ($userId && !$adminView) {
        $query .= " AND d.user_id = :user_id";
    }

    if ($status) {
        $query .= " AND d.statut = :status";
    }

    $query .= " ORDER BY d.date_debut DESC LIMIT :limit OFFSET :offset";

    $stmt = $db->prepare($query);

    if ($userId && !$adminView) {
        $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);
    }
    if ($status) {
        $stmt->bindParam(':status', $status, PDO::PARAM_STR);
    }
    $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
    $stmt->bindParam(':offset', $offset, PDO::PARAM_INT);

    $stmt->execute();
    $demandes = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode(['success' => true, 'demandes' => $demandes, 'total' => count($demandes)]);

} catch (PDOException $e) {
    error_log('Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur serveur', 500);
}
?>
