<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents("php://input"), true);

    if (empty($input['user_id']) || empty($input['fcm_token'])) {
        echo ApiResponse::validation(['message' => 'User ID et token FCM requis']);
        exit();
    }

    $userId = intval($input['user_id']);
    $fcmToken = trim($input['fcm_token']);

    // Validate token format (Firebase FCM tokens have typical length)
    if (strlen($fcmToken) < 50) {
        echo ApiResponse::error('Token FCM invalide');
        exit();
    }

    $query = "UPDATE users SET fcm_token = :fcm_token WHERE id = :user_id";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':fcm_token', $fcmToken);
    $stmt->bindParam(':user_id', $userId, PDO::PARAM_INT);

    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        echo ApiResponse::error('Utilisateur non trouvé', 404);
        exit();
    }

    echo ApiResponse::success(['user_id' => $userId], 'Token FCM mis à jour');

} catch (PDOException $e) {
    error_log('Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur serveur', 500);
}
?>
