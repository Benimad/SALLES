import { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, query, orderBy } from 'firebase/firestore';
import toast from 'react-hot-toast';

export const useDemandes = () => {
  const [demandes, setDemandes] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const q = query(collection(db, 'demandes'), orderBy('created_at', 'desc'));
    
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const data = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      
      // Check for new requests to show notification
      if (!loading && data.length > demandes.length) {
        const newRequest = data[0];
        if (newRequest.statut === 'en_attente') {
          toast.success(`Nouvelle demande de ${newRequest.user_name || 'Utilisateur'}`, {
            icon: '🔔',
            duration: 5000,
          });
        }
      }
      
      setDemandes(data);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [loading, demandes.length]);

  return { demandes, loading };
};
