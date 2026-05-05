const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

// Firebase Admin Setup
try {
    const serviceAccount = require("./salles-7274b-firebase-adminsdk-fbsvc-9fb835fc8d.json");
    admin.initializeApp({
        credential: admin.credential.cert(serviceAccount)
    });
    console.log("Firebase Admin Initialized");
} catch (e) {
    console.warn("⚠️ Service account file missing or invalid.");
}

const db = admin.firestore();

// MIDDLEWARE: Simple check for Admin Role (Optional, usually handled by Firebase Auth tokens)
const verifyAdmin = async (req, res, next) => {
    // In a real pro app, you'd verify the ID token from the Authorization header
    // const idToken = req.headers.authorization?.split('Bearer ')[1];
    next(); 
};

// --- ROUTES ---

// Health Check
app.get('/', (req, res) => res.json({ status: "AL OMRANE API RUNNING", timestamp: new Date() }));

// GET Stats
app.get('/api/stats', async (req, res) => {
    try {
        const salles = await db.collection('salles').count().get();
        const demandes = await db.collection('demandes').count().get();
        const pending = await db.collection('demandes').where('statut', '==', 'en_attente').count().get();
        
        res.json({
            total_salles: salles.data().count,
            total_demandes: demandes.data().count,
            pending_demandes: pending.data().count
        });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// GET Salles
app.get('/api/salles', async (req, res) => {
    try {
        const snapshot = await db.collection('salles').get();
        const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.json(data);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// GET Demandes
app.get('/api/demandes', async (req, res) => {
    try {
        const snapshot = await db.collection('demandes').orderBy('created_at', 'desc').get();
        const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.json(data);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// UPDATE Request Status
app.patch('/api/demandes/:id', async (req, res) => {
    const { id } = req.params;
    const { statut, raison_rejet } = req.body;
    try {
        await db.collection('demandes').doc(id).update({
            statut,
            raison_rejet: raison_rejet || null,
            updated_at: admin.firestore.FieldValue.serverTimestamp()
        });
        res.json({ success: true, message: `Demande ${statut}` });
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// USER MANAGEMENT
app.get('/api/users', async (req, res) => {
    try {
        const snapshot = await db.collection('users').get();
        const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        res.json(data);
    } catch (e) {
        res.status(500).json({ error: e.message });
    }
});

// ERROR HANDLER
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).send('Something broke!');
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server running on http://localhost:${PORT}`);
});
