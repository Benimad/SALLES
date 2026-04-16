<?php
require_once 'config.php';

$db = getDB();

try {
    $input = json_decode(file_get_contents("php://input"), true);

    // Validation
    $errors = [];
    if (empty($input['nom'])) $errors['nom'] = 'Nom requis';
    if (empty($input['prenom'])) $errors['prenom'] = 'Prénom requis';
    if (empty($input['email'])) $errors['email'] = 'Email requis';
    else if (!filter_var($input['email'], FILTER_VALIDATE_EMAIL)) $errors['email'] = 'Email invalide';
    if (empty($input['password'])) $errors['password'] = 'Mot de passe requis';
    else if (strlen($input['password']) < 6) $errors['password'] = 'Mot de passe doit avoir au moins 6 caractères';

    if (!empty($errors)) {
        echo ApiResponse::validation($errors);
        exit();
    }

    $email = filter_var($input['email'], FILTER_SANITIZE_EMAIL);

    // Check if email exists
    $checkQuery = "SELECT id FROM users WHERE email = :email LIMIT 1";
    $checkStmt = $db->prepare($checkQuery);
    $checkStmt->bindParam(':email', $email);
    $checkStmt->execute();

    if ($checkStmt->rowCount() > 0) {
        echo ApiResponse::error('Cet email est déjà utilisé');
        exit();
    }

    // Insert new user
    $insertQuery = "INSERT INTO users (nom, prenom, email, password, role, status) 
                    VALUES (:nom, :prenom, :email, :password, 'employe', 'active')";
    $insertStmt = $db->prepare($insertQuery);

    $hashedPassword = password_hash($input['password'], PASSWORD_DEFAULT);
    
    $insertStmt->bindParam(':nom', $input['nom']);
    $insertStmt->bindParam(':prenom', $input['prenom']);
    $insertStmt->bindParam(':email', $email);
    $insertStmt->bindParam(':password', $hashedPassword);

    $insertStmt->execute();
    $userId = $db->lastInsertId();

    $user = [
        'id' => (int)$userId,
        'nom' => $input['nom'],
        'prenom' => $input['prenom'],
        'email' => $email,
        'role' => 'employe'
    ];

    echo ApiResponse::success($user, 'Inscription réussie');

} catch (PDOException $e) {
    error_log('Registration Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur lors de l\'inscription', 500);
}
?>
