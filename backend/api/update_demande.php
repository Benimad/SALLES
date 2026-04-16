<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents("php://input"), true);

    if (empty($input['demande_id']) || empty($input['statut'])) {
        echo ApiResponse::validation(['message' => 'ID de demande et statut requis']);
        exit();
    }

    $demandeId = intval($input['demande_id']);
    $statut = $input['statut'];
    $raisonRejet = $input['raison_rejet'] ?? null;
    $appouveParId = intval($input['approuve_par'] ?? 0);

    // Validate status
    $validStatus = ['en_attente', 'approuvee', 'rejetee'];
    if (!in_array($statut, $validStatus)) {
        echo ApiResponse::error('Statut invalide');
        exit();
    }

    // Update demande
    $updateQuery = "UPDATE demandes SET statut = :statut, raison_rejet = :raison_rejet, approuve_par = :approuve_par, approuve_date = NOW()
                    WHERE id = :demande_id";
    $updateStmt = $db->prepare($updateQuery);
    $updateStmt->bindParam(':statut', $statut);
    $updateStmt->bindParam(':raison_rejet', $raisonRejet);
    $updateStmt->bindParam(':approuve_par', $appouveParId, PDO::PARAM_INT);
    $updateStmt->bindParam(':demande_id', $demandeId, PDO::PARAM_INT);
    $updateStmt->execute();

    // Get user details for notification
    $userQuery = "SELECT u.id, u.email, u.prenom, u.nom, u.fcm_token, d.salle_id, s.nom as salle_nom
                  FROM demandes d
                  JOIN users u ON d.user_id = u.id
                  JOIN salles s ON d.salle_id = s.id
                  WHERE d.id = :demande_id";
    $userStmt = $db->prepare($userQuery);
    $userStmt->bindParam(':demande_id', $demandeId, PDO::PARAM_INT);
    $userStmt->execute();
    $demande = $userStmt->fetch(PDO::FETCH_ASSOC);

    // Create notification
    if ($demande) {
        $notifTitle = 'Demande ' . ($statut === 'approuvee' ? 'approuvée' : 'rejetée');
        $notifMessage = 'Votre demande pour ' . $demande['salle_nom'] . ' a été ' . 
                       ($statut === 'approuvee' ? 'approuvée' : 'rejetée');

        $notifQuery = "INSERT INTO notifications (user_id, demande_id, title, message, type)
                       VALUES (:user_id, :demande_id, :title, :message, :type)";
        $notifStmt = $db->prepare($notifQuery);
        $notifStmt->bindParam(':user_id', $demande['id'], PDO::PARAM_INT);
        $notifStmt->bindParam(':demande_id', $demandeId, PDO::PARAM_INT);
        $notifStmt->bindParam(':title', $notifTitle);
        $notifStmt->bindParam(':message', $notifMessage);
        $notifType = $statut === 'approuvee' ? 'success' : 'warning';
        $notifStmt->bindParam(':type', $notifType);
        $notifStmt->execute();

        // Send Firebase notification if token exists
        if (!empty($demande['fcm_token'])) {
            sendFirebaseNotification($demande['fcm_token'], $notifTitle, $notifMessage);
        }
    }

    echo ApiResponse::success(['id' => $demandeId], 'Statut mis à jour avec succès');

} catch (PDOException $e) {
    error_log('Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur lors de la mise à jour', 500);
}

function sendFirebaseNotification($token, $title, $message) {
    // Replace with your actual Firebase Server Key from Firebase Console
    $serverKey = 'YOUR_FIREBASE_SERVER_KEY';
    
    $notification = array(
        'title' => $title,
        'body' => $message,
        'sound' => 'default',
        'badge' => '1'
    );
    
    $payload = array(
        'to' => $token,
        'notification' => $notification,
        'priority' => 'high',
        'data' => array(
            'click_action' => 'FLUTTER_NOTIFICATION_CLICK',
            'type' => 'demande_status',
            'timestamp' => date('Y-m-d H:i:s')
        )
    );
    
    $headers = array(
        'Authorization: key=' . $serverKey,
        'Content-Type: application/json'
    );
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
    
    $result = curl_exec($ch);
    if ($result === FALSE) {
        error_log('FCM Send Error: ' . curl_error($ch));
    }
    curl_close($ch);
    
    return $result;
}
?>
