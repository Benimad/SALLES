<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

// Créer le dossier uploads s'il n'existe pas
$uploadDir = '../uploads/';
if (!file_exists($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

if (isset($_FILES['file']) && isset($_POST['demande_id'])) {
    $demandeId = $_POST['demande_id'];
    $file = $_FILES['file'];
    
    // Vérifier les erreurs
    if ($file['error'] !== UPLOAD_ERR_OK) {
        echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'upload']);
        exit;
    }
    
    // Vérifier la taille (max 10MB)
    if ($file['size'] > 10 * 1024 * 1024) {
        echo json_encode(['success' => false, 'message' => 'Fichier trop volumineux (max 10MB)']);
        exit;
    }
    
    // Extensions autorisées
    $allowedExtensions = ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'];
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    
    if (!in_array($fileExtension, $allowedExtensions)) {
        echo json_encode(['success' => false, 'message' => 'Type de fichier non autorisé']);
        exit;
    }
    
    // Générer un nom unique
    $fileName = uniqid() . '_' . basename($file['name']);
    $filePath = $uploadDir . $fileName;
    
    // Déplacer le fichier
    if (move_uploaded_file($file['tmp_name'], $filePath)) {
        // Enregistrer dans la base de données
        $query = "INSERT INTO attachments (demande_id, file_name, file_path, file_type, file_size) 
                  VALUES (:demande_id, :file_name, :file_path, :file_type, :file_size)";
        $stmt = $db->prepare($query);
        
        $originalName = $file['name'];
        $fileType = $file['type'];
        $fileSize = $file['size'];
        
        $stmt->bindParam(':demande_id', $demandeId);
        $stmt->bindParam(':file_name', $originalName);
        $stmt->bindParam(':file_path', $fileName);
        $stmt->bindParam(':file_type', $fileType);
        $stmt->bindParam(':file_size', $fileSize);
        
        if ($stmt->execute()) {
            echo json_encode([
                'success' => true, 
                'message' => 'Fichier uploadé avec succès',
                'file_id' => $db->lastInsertId(),
                'file_name' => $originalName,
                'file_path' => $fileName
            ]);
        } else {
            unlink($filePath); // Supprimer le fichier si l'insertion échoue
            echo json_encode(['success' => false, 'message' => 'Erreur lors de l\'enregistrement']);
        }
    } else {
        echo json_encode(['success' => false, 'message' => 'Erreur lors du déplacement du fichier']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Fichier ou ID de demande manquant']);
}
?>
