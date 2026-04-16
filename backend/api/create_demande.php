<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents("php://input"), true);

    // Validation
    $errors = [];
    if (empty($input['user_id'])) $errors['user_id'] = 'User ID requis';
    if (empty($input['salle_id'])) $errors['salle_id'] = 'Salle requise';
    if (empty($input['date_debut'])) $errors['date_debut'] = 'Date de début requise';
    if (empty($input['date_fin'])) $errors['date_fin'] = 'Date de fin requise';
    if (empty($input['heure_debut'])) $errors['heure_debut'] = 'Heure de début requise';
    if (empty($input['heure_fin'])) $errors['heure_fin'] = 'Heure de fin requise';
    if (empty($input['motif'])) $errors['motif'] = 'Motif requis';

    if (!empty($errors)) {
        echo ApiResponse::validation($errors);
        exit();
    }

    $user_id = intval($input['user_id']);
    $salle_id = intval($input['salle_id']);
    $date_debut = $input['date_debut'];
    $date_fin = $input['date_fin'];
    $heure_debut = $input['heure_debut'];
    $heure_fin = $input['heure_fin'];
    $motif = $input['motif'];

    // Date validation
    if (strtotime($date_debut) < strtotime(date('Y-m-d'))) {
        echo ApiResponse::error('La date de début doit être dans le futur');
        exit();
    }

    if (strtotime($date_fin) < strtotime($date_debut)) {
        echo ApiResponse::error('La date de fin doit être après la date de début');
        exit();
    }

    // Time validation
    if ($date_debut === $date_fin && strtotime($heure_fin) <= strtotime($heure_debut)) {
        echo ApiResponse::error('L\'heure de fin doit être après l\'heure de début');
        exit();
    }

    // Check for conflicts with better logic
    $conflictQuery = "SELECT COUNT(*) as conflict_count FROM demandes 
                     WHERE salle_id = :salle_id 
                     AND statut IN ('en_attente', 'approuvee')
                     AND (
                         (date_debut <= :date_fin AND date_fin >= :date_debut)
                         OR (date_debut = :date_debut AND heure_fin > :heure_debut AND heure_debut < :heure_fin)
                     )";

    $conflictStmt = $db->prepare($conflictQuery);
    $conflictStmt->bindParam(':salle_id', $salle_id, PDO::PARAM_INT);
    $conflictStmt->bindParam(':date_debut', $date_debut);
    $conflictStmt->bindParam(':date_fin', $date_fin);
    $conflictStmt->bindParam(':heure_debut', $heure_debut);
    $conflictStmt->bindParam(':heure_fin', $heure_fin);
    $conflictStmt->execute();

    $result = $conflictStmt->fetch(PDO::FETCH_ASSOC);
    if ($result['conflict_count'] > 0) {
        echo ApiResponse::error('Cette salle est déjà réservée pour cette période');
        exit();
    }

    // Insert new request
    $insertQuery = "INSERT INTO demandes (user_id, salle_id, date_debut, date_fin, heure_debut, heure_fin, motif, description) 
                    VALUES (:user_id, :salle_id, :date_debut, :date_fin, :heure_debut, :heure_fin, :motif, :description)";
    $insertStmt = $db->prepare($insertQuery);

    $description = $input['description'] ?? '';
    $insertStmt->bindParam(':user_id', $user_id, PDO::PARAM_INT);
    $insertStmt->bindParam(':salle_id', $salle_id, PDO::PARAM_INT);
    $insertStmt->bindParam(':date_debut', $date_debut);
    $insertStmt->bindParam(':date_fin', $date_fin);
    $insertStmt->bindParam(':heure_debut', $heure_debut);
    $insertStmt->bindParam(':heure_fin', $heure_fin);
    $insertStmt->bindParam(':motif', $motif);
    $insertStmt->bindParam(':description', $description);

    $insertStmt->execute();
    $demandeId = $db->lastInsertId();

    // Get the created request details
    $getQuery = "SELECT d.id, d.user_id, d.salle_id, s.nom as salle_nom, u.prenom, u.nom,
                        d.date_debut, d.date_fin, d.heure_debut, d.heure_fin, d.motif, d.statut, d.created_at
                 FROM demandes d
                 JOIN users u ON d.user_id = u.id
                 JOIN salles s ON d.salle_id = s.id
                 WHERE d.id = :id";
    $getStmt = $db->prepare($getQuery);
    $getStmt->bindParam(':id', $demandeId, PDO::PARAM_INT);
    $getStmt->execute();
    $createdDemande = $getStmt->fetch(PDO::FETCH_ASSOC);

    echo ApiResponse::success($createdDemande, 'Demande créée avec succès');

} catch (PDOException $e) {
    error_log('Error creating demande: ' . $e->getMessage());
    echo ApiResponse::error('Erreur lors de la création de la demande', 500);
}
?>

