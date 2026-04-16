<?php
require_once 'config.php';

$db = getDB();

try {
    $userId = $_GET['id'] ?? null;
    $email = $_GET['email'] ?? null;

    if (!$userId && !$email) {
        echo ApiResponse::error('ID ou email requis', 400);
        exit();
    }

    $query = "SELECT id, nom, prenom, email, role, department, phone, status, created_at FROM users WHERE ";
    
    if ($userId) {
        $query .= "id = :id";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':id', $userId, PDO::PARAM_INT);
    } else {
        $query .= "email = :email";
        $stmt = $db->prepare($query);
        $stmt->bindParam(':email', $email);
    }

    $stmt->execute();

    if ($stmt->rowCount() === 0) {
        echo ApiResponse::error('Utilisateur non trouvé', 404);
        exit();
    }

    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    echo ApiResponse::success($user, 'Utilisateur récupéré');

} catch (PDOException $e) {
    error_log('Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur serveur', 500);
}
?>
