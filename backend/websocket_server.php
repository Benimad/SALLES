<?php
require __DIR__ . '/vendor/autoload.php';

use Ratchet\Server\IoServer;
use Ratchet\Http\HttpServer;
use Ratchet\WebSocket\WsServer;
use Ratchet\MessageComponentInterface;
use Ratchet\ConnectionInterface;

class SallesWebSocket implements MessageComponentInterface {
    protected $clients;
    protected $users;

    public function __construct() {
        $this->clients = new \SplObjectStorage;
        $this->users = [];
    }

    public function onOpen(ConnectionInterface $conn) {
        $this->clients->attach($conn);
        echo "New connection: {$conn->resourceId}\n";
    }

    public function onMessage(ConnectionInterface $from, $msg) {
        $data = json_decode($msg, true);
        
        if (!$data) return;

        switch ($data['type']) {
            case 'auth':
                $this->users[$from->resourceId] = $data['userId'];
                echo "User {$data['userId']} authenticated\n";
                break;

            case 'new_demande':
                $this->broadcastToAdmins($data);
                break;

            case 'demande_update':
                $this->broadcastToUser($data);
                break;
        }
    }

    public function onClose(ConnectionInterface $conn) {
        $this->clients->detach($conn);
        unset($this->users[$conn->resourceId]);
        echo "Connection {$conn->resourceId} closed\n";
    }

    public function onError(ConnectionInterface $conn, \Exception $e) {
        echo "Error: {$e->getMessage()}\n";
        $conn->close();
    }

    private function broadcastToAdmins($data) {
        foreach ($this->clients as $client) {
            if (isset($this->users[$client->resourceId])) {
                $client->send(json_encode($data));
            }
        }
    }

    private function broadcastToUser($data) {
        foreach ($this->clients as $client) {
            if (isset($this->users[$client->resourceId])) {
                $client->send(json_encode($data));
            }
        }
    }
}

$server = IoServer::factory(
    new HttpServer(
        new WsServer(
            new SallesWebSocket()
        )
    ),
    8080
);

echo "WebSocket server started on port 8080\n";
$server->run();
