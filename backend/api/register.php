<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$data = json_decode(file_get_contents("php://input"));

if (!empty($data->nom) && !empty($data->prenom) && !empty($data->email) && !empty($data->password)) {
    $query = "SELECT id FROM users WHERE email = :email";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':email', $data->email);
    $stmt->execute();

    if ($stmt->rowCount() > 0) {
        echo json_encode(['success' => false, 'message' => 'Cet email est déjà utilisé']);
    } else {
        $query = "INSERT INTO users (nom, prenom, email, password) VALUES (:nom, :prenom, :email, :password)";
        $stmt = $db->prepare($query);
        
        $hashed_password = password_hash($data->password, PASSWORD_DEFAULT);
        
        $stmt->bindParam(':nom', $data->nom);
        $stmt->bindParam(':prenom', $data->prenom);
        $stmt->bindParam(':email', $data->email);
        $stmt->bindParam(':password', $hashed_password);

        if ($stmt->execute()) {
            echo json_encode(['success' => true, 'message' => 'Inscription réussie']);
        } else {
            echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'inscription']);
        }
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Tous les champs sont requis']);
}
?>
