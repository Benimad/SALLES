<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents('php://input'), true);

    if (empty($input['user_id']) || empty($input['nom']) || empty($input['prenom'])) {
        echo ApiResponse::validation(['message' => 'Champs requis manquants']);
        exit();
    }

    $userId = intval($input['user_id']);
    $nom = trim($input['nom']);
    $prenom = trim($input['prenom']);
    $phone = isset($input['phone']) ? trim($input['phone']) : null;
    $department = isset($input['department']) ? trim($input['department']) : null;

    $stmt = $db->prepare("UPDATE users SET nom = :nom, prenom = :prenom, phone = :phone, department = :department WHERE id = :id");
    $stmt->bindParam(':nom', $nom);
    $stmt->bindParam(':prenom', $prenom);
    $stmt->bindParam(':phone', $phone);
    $stmt->bindParam(':department', $department);
    $stmt->bindParam(':id', $userId, PDO::PARAM_INT);
    $stmt->execute();

    $userStmt = $db->prepare("SELECT id, nom, prenom, email, role, phone, department FROM users WHERE id = :id");
    $userStmt->bindParam(':id', $userId, PDO::PARAM_INT);
    $userStmt->execute();
    $user = $userStmt->fetch(PDO::FETCH_ASSOC);

    echo json_encode(['success' => true, 'message' => 'Profil mis à jour', 'user' => $user]);

} catch (PDOException $e) {
    error_log('Update Profile Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur lors de la mise à jour du profil', 500);
}
?>
