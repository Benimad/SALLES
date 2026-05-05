const admin = require('firebase-admin');
const serviceAccount = require("./salles-7274b-firebase-adminsdk-fbsvc-9fb835fc8d.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const salles = [
  {
    "nom": "Salle de Réunion A",
    "capacite": 10,
    "etage": 1,
    "localisation": "Aile Ouest",
    "equipements": "Projecteur, Tableau blanc, Wifi, Climatisation",
    "disponible": true,
    "description": "Salle idéale pour réunions de petits groupes",
  },
  {
    "nom": "Salle de Conférence B",
    "capacite": 50,
    "etage": 2,
    "localisation": "Aile Est",
    "equipements": "Projecteur HD, Système audio, Wifi, Climatisation, Visioconférence",
    "disponible": true,
    "description": "Grande salle de conférence avec équipement complet",
  },
  {
    "nom": "Salle de Formation C",
    "capacite": 20,
    "etage": 3,
    "localisation": "Aile Nord",
    "equipements": "Ordinateurs, Projecteur, Wifi, Tableau blanc",
    "disponible": true,
    "description": "Salle informatique avec 15 postes de travail",
  },
  {
    "nom": "Salle de Réunion D",
    "capacite": 8,
    "etage": 1,
    "localisation": "Aile Sud",
    "equipements": "Écran TV, Wifi, Tableau blanc",
    "disponible": true,
    "description": "Salle intime pour réunions confidentielles",
  }
];

async function initialize() {
  console.log("🚀 Initializing Al Omrane Admin System...");
  
  const adminEmail = "admin@alomrane.gov.ma";
  const adminPassword = "admin1234";

  try {
    // 1. Create User in Firebase Auth
    let userRecord;
    try {
      userRecord = await admin.auth().getUserByEmail(adminEmail);
      console.log(`✅ Admin user already exists in Auth: ${adminEmail}`);
    } catch (e) {
      userRecord = await admin.auth().createUser({
        email: adminEmail,
        password: adminPassword,
        displayName: "Administrateur Al Omrane",
      });
      console.log(`✨ Successfully created new Admin user: ${adminEmail}`);
    }

    // 2. Initialize Firestore
    const batch = db.batch();

    // Create Admin Document
    const userRef = db.collection('users').doc(userRecord.uid);
    batch.set(userRef, {
      email: adminEmail,
      nom: "Administrateur",
      prenom: "Al Omrane",
      role: "admin",
      created_at: admin.firestore.FieldValue.serverTimestamp()
    });

    // Add Salles
    for (const s of salles) {
      const ref = db.collection('salles').doc();
      batch.set(ref, {
        ...s,
        created_at: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    await batch.commit();
    console.log("✅ Firestore initialized with Admin privileges and Room data.");
    console.log(`\n🔑 LOGIN CREDENTIALS:`);
    console.log(`📧 Email: ${adminEmail}`);
    console.log(`🔒 Password: ${adminPassword}`);
    
  } catch (err) {
    console.error("❌ Setup failed:", err.message);
  }
  
  process.exit(0);
}

initialize().catch(console.error);
