<?php
require_once 'config.php';

$db = getDB();

try {
    // Total demandes and breakdown
    $totalStmt = $db->query("SELECT 
        COUNT(*) AS total_demandes,
        SUM(CASE WHEN statut = 'approuvee' THEN 1 ELSE 0 END) AS approuvees,
        SUM(CASE WHEN statut = 'rejetee' THEN 1 ELSE 0 END) AS rejetees,
        SUM(CASE WHEN statut = 'en_attente' THEN 1 ELSE 0 END) AS en_attente
        FROM demandes");
    $totals = $totalStmt->fetch(PDO::FETCH_ASSOC);

    // Salles
    $sallesStmt = $db->query("SELECT 
        COUNT(*) AS total_salles,
        SUM(CASE WHEN disponible = 1 THEN 1 ELSE 0 END) AS salles_disponibles
        FROM salles");
    $sallesData = $sallesStmt->fetch(PDO::FETCH_ASSOC);

    // Top salles
    $topStmt = $db->query("SELECT s.nom, COUNT(d.id) AS total
        FROM demandes d
        JOIN salles s ON d.salle_id = s.id
        GROUP BY s.id, s.nom
        ORDER BY total DESC
        LIMIT 5");
    $topSalles = $topStmt->fetchAll(PDO::FETCH_ASSOC);

    // Demandes par mois (6 derniers mois)
    $monthsStmt = $db->query("SELECT 
        DATE_FORMAT(created_at, '%b') AS mois,
        COUNT(*) AS total
        FROM demandes
        WHERE created_at >= DATE_SUB(NOW(), INTERVAL 6 MONTH)
        GROUP BY YEAR(created_at), MONTH(created_at)
        ORDER BY YEAR(created_at) ASC, MONTH(created_at) ASC
        LIMIT 6");
    $parMois = $monthsStmt->fetchAll(PDO::FETCH_ASSOC);

    $data = [
        'total_demandes'   => (int)$totals['total_demandes'],
        'approuvees'       => (int)$totals['approuvees'],
        'rejetees'         => (int)$totals['rejetees'],
        'en_attente'       => (int)$totals['en_attente'],
        'total_salles'     => (int)$sallesData['total_salles'],
        'salles_disponibles' => (int)$sallesData['salles_disponibles'],
        'top_salles'       => $topSalles,
        'par_mois'         => $parMois,
    ];

    echo json_encode(['success' => true, 'data' => $data]);

} catch (PDOException $e) {
    error_log('Statistics Error: ' . $e->getMessage());
    echo ApiResponse::error('Erreur lors du chargement des statistiques', 500);
}
?>
