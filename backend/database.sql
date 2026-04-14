-- Base de données pour Gestion des Salles
CREATE DATABASE IF NOT EXISTS gestion_salles;
USE gestion_salles;

-- Table des utilisateurs
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    prenom VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    role ENUM('employe', 'admin') DEFAULT 'employe',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des salles
CREATE TABLE IF NOT EXISTS salles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    capacite INT NOT NULL,
    equipements TEXT,
    disponible BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des demandes
CREATE TABLE IF NOT EXISTS demandes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    salle_id INT NOT NULL,
    date_debut DATE NOT NULL,
    date_fin DATE NOT NULL,
    heure_debut TIME NOT NULL,
    heure_fin TIME NOT NULL,
    motif TEXT NOT NULL,
    statut ENUM('en_attente', 'approuvee', 'rejetee') DEFAULT 'en_attente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (salle_id) REFERENCES salles(id) ON DELETE CASCADE
);

-- Insertion d'un utilisateur admin par défaut
INSERT INTO users (nom, prenom, email, password, role) 
VALUES ('Admin', 'Système', 'admin@alomrane.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin');
-- Mot de passe: password

-- Insertion de quelques salles
INSERT INTO salles (nom, capacite, equipements) VALUES
('Salle de Réunion A', 10, 'Projecteur, Tableau blanc, Wifi'),
('Salle de Conférence B', 50, 'Projecteur, Système audio, Wifi, Climatisation'),
('Salle de Formation C', 20, 'Ordinateurs, Projecteur, Wifi'),
('Salle de Réunion D', 8, 'Écran TV, Wifi, Tableau blanc');
