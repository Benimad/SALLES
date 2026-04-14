<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->user_id) && !empty($data->fcm_token)) {
    $query = "UPDATE users SET fcm_token = :fcm_token WHERE id = :user_id";
    $stmt = $db->prepare($query);
    
    $stmt->bindParam(':fcm_token', $data->fcm_token);
    $stmt->bindParam(':user_id', $data->user_id);

    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Token FCM mis à jour']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de la mise à jour']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'User ID et token requis']);
}
?>
