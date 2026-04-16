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
    fcm_token VARCHAR(255),
    phone VARCHAR(20),
    department VARCHAR(100),
    status ENUM('active', 'inactive') DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_role (role),
    INDEX idx_status (status)
);

-- Table des salles
CREATE TABLE IF NOT EXISTS salles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nom VARCHAR(100) NOT NULL,
    capacite INT NOT NULL,
    etage INT,
    localisation VARCHAR(100),
    equipements TEXT,
    disponible BOOLEAN DEFAULT TRUE,
    description TEXT,
    contact_responsable VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_disponible (disponible),
    INDEX idx_capacite (capacite)
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
    description TEXT,
    participants_externes INT DEFAULT 0,
    statut ENUM('en_attente', 'approuvee', 'rejetee') DEFAULT 'en_attente',
    raison_rejet TEXT,
    approuve_par INT,
    approuve_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (salle_id) REFERENCES salles(id) ON DELETE CASCADE,
    FOREIGN KEY (approuve_par) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_user_statut (user_id, statut),
    INDEX idx_date_range (date_debut, date_fin, salle_id),
    INDEX idx_user_id (user_id),
    INDEX idx_salle_id (salle_id),
    INDEX idx_statut (statut),
    INDEX idx_date_debut (date_debut),
    INDEX idx_date_fin (date_fin)
);

-- Table des attachements
CREATE TABLE IF NOT EXISTS attachments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    demande_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    filepath VARCHAR(500) NOT NULL,
    file_type VARCHAR(50),
    file_size INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (demande_id) REFERENCES demandes(id) ON DELETE CASCADE,
    INDEX idx_demande_id (demande_id)
);

-- Table des notifications/logs
CREATE TABLE IF NOT EXISTS notifications (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    demande_id INT,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type ENUM('info', 'warning', 'success', 'error') DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (demande_id) REFERENCES demandes(id) ON DELETE CASCADE,
    INDEX idx_user_id (user_id),
    INDEX idx_is_read (is_read)
);

-- Mise à jour de la table users si elle existe déjà (colonnes manquantes)
ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token VARCHAR(255);
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS department VARCHAR(100);
ALTER TABLE users ADD COLUMN IF NOT EXISTS status ENUM('active', 'inactive') DEFAULT 'active';

-- Mise à jour de la table salles si elle existe déjà (colonnes manquantes)
ALTER TABLE salles ADD COLUMN IF NOT EXISTS etage INT;
ALTER TABLE salles ADD COLUMN IF NOT EXISTS localisation VARCHAR(100);
ALTER TABLE salles ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE salles ADD COLUMN IF NOT EXISTS contact_responsable VARCHAR(100);

-- Insertion d'un utilisateur admin par défaut
INSERT IGNORE INTO users (nom, prenom, email, password, role, department) 
VALUES ('Admin', 'Système', 'admin@alomrane.ma', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin', 'Administration');
-- Mot de passe: password

-- Insertion de quelques salles
INSERT IGNORE INTO salles (nom, capacite, etage, localisation, equipements, description) VALUES
('Salle de Réunion A', 10, 1, 'Aile Ouest', 'Projecteur, Tableau blanc, Wifi, Climatisation', 'Salle idéale pour réunions de petits groupes'),
('Salle de Conférence B', 50, 2, 'Aile Est', 'Projecteur HD, Système audio, Wifi, Climatisation, Visioconférence', 'Grande salle de conférence avec équipement complet'),
('Salle de Formation C', 20, 3, 'Aile Nord', 'Ordinateurs, Projecteur, Wifi, Tableau blanc', 'Salle informatique avec 15 postes de travail'),
('Salle de Réunion D', 8, 1, 'Aile Sud', 'Écran TV, Wifi, Tableau blanc', 'Salle intime pour réunions confidentielles');
