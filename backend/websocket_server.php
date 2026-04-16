<?php
require __DIR__ . '/vendor/autoload.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

class SallesWebSocket implements MessageComponentInterface {
    protected $clients;
    protected $users;        // Map conexion ID to user info
    protected $adminConnections;  // Map of admin connections
    protected $employees;    // Map of employee connections

    public function __construct() {
        $this->clients = new \SplObjectStorage;
        $this->users = [];
        $this->adminConnections = [];
        $this->employees = [];
        echo "[" . date('Y-m-d H:i:s') . "] WebSocket Server initialized\n";
    }

    public function onOpen(ConnectionInterface $conn) {
        $this->clients->attach($conn);
        echo "[" . date('Y-m-d H:i:s') . "] New connection: {$conn->resourceId}\n";
    }

    public function onMessage(ConnectionInterface $from, $msg) {
        try {
            $data = json_decode($msg, true);
            
            if (!$data) {
                $this->sendError($from, "Invalid JSON");
                return;
            }

            echo "[" . date('Y-m-d H:i:s') . "] Message from {$from->resourceId}: " . json_encode($data) . "\n";

            switch ($data['type']) {
                case 'auth':
                    $this->handleAuth($from, $data);
                    break;

                case 'demande_update':
                    $this->broadcastDemandeUpdate($from, $data);
                    break;

                case 'new_demande':
                    $this->broadcastNewDemande($from, $data);
                    break;

                case 'ping':
                    $this->send($from, ['type' => 'pong', 'timestamp' => time()]);
                    break;

                default:
                    $this->sendError($from, "Unknown message type");
            }
        } catch (\Exception $e) {
            echo "[ERROR] " . $e->getMessage() . "\n";
            $this->sendError($from, $e->getMessage());
        }
    }

    public function onClose(ConnectionInterface $conn) {
        $this->clients->detach($conn);
        
        if (isset($this->users[$conn->resourceId])) {
            $user = $this->users[$conn->resourceId];
            echo "[" . date('Y-m-d H:i:s') . "] User {$user['id']} ({$user['role']}) disconnected\n";
            
            if ($user['role'] === 'admin') {
                unset($this->adminConnections[$conn->resourceId]);
            } else {
                unset($this->employees[$conn->resourceId]);
            }
            
            unset($this->users[$conn->resourceId]);
        } else {
            echo "[" . date('Y-m-d H:i:s') . "] Connection {$conn->resourceId} closed\n";
        }
    }

    public function onError(ConnectionInterface $conn, \Exception $e) {
        echo "[ERROR] Connection {$conn->resourceId}: {$e->getMessage()}\n";
        $conn->close();
    }

    private function handleAuth(ConnectionInterface $conn, $data) {
        if (empty($data['userId']) || empty($data['role'])) {
            $this->sendError($conn, "Missing userId or role");
            return;
        }

        $this->users[$conn->resourceId] = [
            'id' => $data['userId'],
            'role' => $data['role'],
            'connectedAt' => time()
        ];

        if ($data['role'] === 'admin') {
            $this->adminConnections[$conn->resourceId] = $conn;
            echo "[" . date('Y-m-d H:i:s') . "] Admin {$data['userId']} authenticated\n";
        } else {
            $this->employees[$conn->resourceId] = $conn;
            echo "[" . date('Y-m-d H:i:s') . "] Employee {$data['userId']} authenticated\n";
        }

        $this->send($conn, [
            'type' => 'auth_success',
            'message' => 'Authentification réussie',
            'role' => $data['role'],
            'adminsOnline' => count($this->adminConnections),
            'employeesOnline' => count($this->employees)
        ]);
    }

    private function broadcastNewDemande(ConnectionInterface $from, $data) {
        if (!isset($this->users[$from->resourceId])) {
            $this->sendError($from, "Not authenticated");
            return;
        }

        $demandeData = [
            'type' => 'new_demande',
            'demande' => $data['demande'] ?? [],
            'from_user_id' => $this->users[$from->resourceId]['id'],
            'timestamp' => time()
        ];

        // Send to all admins
        foreach ($this->adminConnections as $adminConn) {
            $this->send($adminConn, $demandeData);
        }

        echo "[" . date('Y-m-d H:i:s') . "] New demande broadcasted to " . count($this->adminConnections) . " admins\n";
    }

    private function broadcastDemandeUpdate(ConnectionInterface $from, $data) {
        if (!isset($this->users[$from->resourceId])) {
            $this->sendError($from, "Not authenticated");
            return;
        }

        if (empty($data['demandeId']) || empty($data['userId']) || empty($data['status'])) {
            $this->sendError($from, "Missing required fields");
            return;
        }

        $updateData = [
            'type' => 'demande_update',
            'demandeId' => $data['demandeId'],
            'status' => $data['status'],
            'message' => 'Demande ' . $data['status'],
            'timestamp' => time()
        ];

        // Send to the specific employee whose demande was updated
        $targetUserId = $data['userId'];
        foreach ($this->employees as $empConn) {
            if (isset($this->users[$empConn->resourceId]) && 
                $this->users[$empConn->resourceId]['id'] == $targetUserId) {
                $this->send($empConn, $updateData);
                echo "[" . date('Y-m-d H:i:s') . "] Demande update sent to user $targetUserId\n";
                break;
            }
        }

        // Also notify all admins
        foreach ($this->adminConnections as $adminConn) {
            $this->send($adminConn, $updateData);
        }
    }

    private function send(ConnectionInterface $conn, $data) {
        try {
            $conn->send(json_encode($data));
        } catch (\Exception $e) {
            echo "[ERROR] Failed to send message: " . $e->getMessage() . "\n";
        }
    }

    private function sendError(ConnectionInterface $conn, $message) {
        $this->send($conn, [
            'type' => 'error',
            'message' => $message,
            'timestamp' => time()
        ]);
    }
}

$port = 8080;
$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new SallesWebSocket()
        )
    ),
    $port
);

echo "===================================================\n";
echo "WebSocket Server started on port $port\n";
echo "Server started at: " . date('Y-m-d H:i:s') . "\n";
echo "===================================================\n";

$server->run();
?>
