<?php
require_once 'config.php';

$database = new Database();
$db = $database->getConnection();

$demande_id = isset($_GET['demande_id']) ? $_GET['demande_id'] : null;

if ($demande_id) {
    $query = "SELECT * FROM attachments WHERE demande_id = :demande_id ORDER BY uploaded_at DESC";
    $stmt = $db->prepare($query);
    $stmt->bindParam(':demande_id', $demande_id);
    $stmt->execute();

    $attachments = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $attachments[] = [
            'id' => $row['id'],
            'demande_id' => $row['demande_id'],
            'file_name' => $row['file_name'],
            'file_path' => $row['file_path'],
            'file_type' => $row['file_type'],
            'file_size' => $row['file_size'],
            'uploaded_at' => $row['uploaded_at']
        ];
    }

    echo json_encode(['success' => true, 'attachments' => $attachments]);
} else {
    echo json_encode(['success' => false, 'message' => 'ID de demande requis']);
}
?>
