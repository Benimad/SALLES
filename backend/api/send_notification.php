<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->title) && !empty($data->body)) {
    // Récupérer le token FCM de l'utilisateur
    $query = "SELECT fcm_token FROM users WHERE id = :user_id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':user_id', $data->user_id);
    $stmt->execute();
    
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($user && !empty($user['fcm_token'])) {
        $fcmToken = $user['fcm_token'];
        
        // Configuration Firebase Cloud Messaging
        $serverKey = 'YOUR_FIREBASE_SERVER_KEY'; // À remplacer par votre clé serveur Firebase
        
        $notification = [
            'title' => $data->title,
            'body' => $data->body,
            'sound' => 'default',
            'badge' => '1'
        ];
        
        $dataPayload = [
            'type' => isset($data->type) ? $data->type : 'general',
            'demande_id' => isset($data->demande_id) ? $data->demande_id : null
        ];
        
        $fields = [
            'to' => $fcmToken,
            'notification' => $notification,
            'data' => $dataPayload,
            'priority' => 'high'
        ];
        
        $headers = [
            'Authorization: key=' . $serverKey,
            'Content-Type: application/json'
        ];
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'https://fcm.googleapis.com/fcm/send');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($fields));
        
        $result = curl_exec($ch);
        curl_close($ch);
        
        // Enregistrer la notification dans la base de données
        $insertQuery = "INSERT INTO notifications (user_id, title, body, type, is_read) 
                       VALUES (:user_id, :title, :body, :type, 0)";
        $insertStmt = $db->prepare($insertQuery);
        $type = isset($data->type) ? $data->type : 'general';
        $insertStmt->bindParam(':user_id', $data->user_id);
        $insertStmt->bindParam(':title', $data->title);
        $insertStmt->bindParam(':body', $data->body);
        $insertStmt->bindParam(':type', $type);
        $insertStmt->execute();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Notification envoyée',
            'fcm_response' => json_decode($result)
        ]);
    } else {
        echo json_encode(['success' => false, 'message' => 'Token FCM non trouvé pour cet utilisateur']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Données manquantes']);
}
?>
