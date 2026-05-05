import { initializeApp, getApps, getApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// Al Omrane Production Configuration
const firebaseConfig = {
  apiKey: "AIzaSyDpq6EgBuQSS1mXwowzLAkUll1vMe_2Suo",
  authDomain: "salles-7274b.firebaseapp.com",
  projectId: "salles-7274b",
  storageBucket: "salles-7274b.firebasestorage.app",
  messagingSenderId: "905030593731",
  appId: "1:905030593731:web:982f1a45e91e9c59e58676",
  measurementId: "G-1FL72HT6MK"
};

// Initialize Firebase only if not already initialized
const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
export const auth = getAuth(app);
export const db = getFirestore(app);
export default app;
