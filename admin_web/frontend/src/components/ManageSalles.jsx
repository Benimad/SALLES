import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, onSnapshot, addDoc, updateDoc, deleteDoc, doc, Timestamp } from 'firebase/firestore';
import { Plus, Edit2, Trash2, X, Save, Layers, Users as UsersIcon, Tv } from 'lucide-react';
import toast from 'react-hot-toast';

const ManageSalles = () => {
  const [salles, setSalles] = useState([]);
  const [showModal, setShowModal] = useState(false);
  const [currentSalle, setCurrentSalle] = useState(null);
  const [formData, setFormData] = useState({ nom: '', capacite: '', etage: '', equipements: '', disponible: true });

  useEffect(() => {
    return onSnapshot(collection(db, 'salles'), (snap) => {
      setSalles(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    const data = { 
      ...formData, 
      capacite: parseInt(formData.capacite), 
      etage: parseInt(formData.etage) || 0, 
      updated_at: Timestamp.now() 
    };
    
    try {
      if (currentSalle) {
        await updateDoc(doc(db, 'salles', currentSalle.id), data);
        toast.success('Salle mise à jour');
      } else {
        await addDoc(collection(db, 'salles'), { ...data, created_at: Timestamp.now() });
        toast.success('Nouvelle salle ajoutée');
      }
      setShowModal(false);
      setCurrentSalle(null);
      setFormData({ nom: '', capacite: '', etage: '', equipements: '', disponible: true });
    } catch (e) { 
      toast.error(e.message); 
    }
  };

  const openEdit = (s) => {
    setCurrentSalle(s);
    setFormData({ 
      nom: s.nom, 
      capacite: s.capacite, 
      etage: s.etage || '', 
      equipements: s.equipements || '', 
      disponible: s.disponible 
    });
    setShowModal(true);
  };

  const deleteSalle = async (id) => {
    if (window.confirm("Êtes-vous sûr de vouloir supprimer cette salle ?")) {
      try {
        await deleteDoc(doc(db, 'salles', id));
        toast.success('Salle supprimée');
      } catch (e) {
        toast.error('Erreur lors de la suppression');
      }
    }
  };

  return (
    <div className="table-wrapper animate-fade-in">
      <div style={{ padding: '1.5rem', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <h3 style={{ fontSize: '1.1rem', fontWeight: '800' }}>Répertoire des Salles</h3>
        <button 
          className="btn btn-primary" 
          onClick={() => { setCurrentSalle(null); setFormData({ nom: '', capacite: '', etage: '', equipements: '', disponible: true }); setShowModal(true); }}
        >
          <Plus size={18} />
          <span>Ajouter une salle</span>
        </button>
      </div>

      <table className="enterprise-table">
        <thead>
          <tr>
            <th>Nom de la Salle</th>
            <th>Configuration</th>
            <th>Équipements</th>
            <th>État</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {salles.map(s => (
            <tr key={s.id}>
              <td>
                <div style={{ fontWeight: '700', color: '#0f172a' }}>{s.nom}</div>
                <div style={{ fontSize: '0.75rem', color: '#94a3b8' }}>ID: {s.id.substring(0, 8)}</div>
              </td>
              <td>
                <div style={{ display: 'flex', gap: '12px' }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.8rem', color: '#64748b' }}>
                    <UsersIcon size={14} /> {s.capacite}
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.8rem', color: '#64748b' }}>
                    <Layers size={14} /> Niv. {s.etage || '0'}
                  </div>
                </div>
              </td>
              <td style={{ maxWidth: '250px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: '6px', fontSize: '0.8rem', color: '#64748b' }}>
                  <Tv size={14} />
                  <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {s.equipements || 'Standard'}
                  </span>
                </div>
              </td>
              <td>
                <span className={`status-pill ${s.disponible ? 'status-approved' : 'status-rejected'}`}>
                  {s.disponible ? 'Opérationnelle' : 'Maintenance'}
                </span>
              </td>
              <td>
                <div style={{ display: 'flex', gap: '8px' }}>
                  <button className="btn btn-icon btn-ghost" onClick={() => openEdit(s)}>
                    <Edit2 size={16} />
                  </button>
                  <button className="btn btn-icon" style={{ color: '#ef4444' }} onClick={() => deleteSalle(s.id)}>
                    <Trash2 size={16} />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      {showModal && (
        <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', background: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div className="card animate-fade-in" style={{ width: '550px', padding: '2.5rem', boxShadow: '0 25px 50px -12px rgba(0,0,0,0.25)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
              <h2 style={{ fontSize: '1.5rem', fontWeight: '800' }}>{currentSalle ? 'Modifier la Salle' : 'Nouvelle Salle'}</h2>
              <button className="btn-icon btn-ghost" onClick={() => setShowModal(false)}><X size={20} /></button>
            </div>
            
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: '1.5rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: '700', color: '#64748b', marginBottom: '8px', textTransform: 'uppercase' }}>Nom de la salle</label>
                <input 
                  style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid #e2e8f0', outline: 'none', fontSize: '1rem' }} 
                  placeholder="Ex: Salle de Conférence A"
                  value={formData.nom} 
                  onChange={e => setFormData({...formData, nom: e.target.value})} 
                  required 
                />
              </div>
              
              <div style={{ display: 'flex', gap: '1.5rem', marginBottom: '1.5rem' }}>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: '700', color: '#64748b', marginBottom: '8px', textTransform: 'uppercase' }}>Capacité Max</label>
                  <input 
                    type="number" 
                    style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid #e2e8f0', outline: 'none', fontSize: '1rem' }} 
                    placeholder="20"
                    value={formData.capacite} 
                    onChange={e => setFormData({...formData, capacite: e.target.value})} 
                    required 
                  />
                </div>
                <div style={{ flex: 1 }}>
                  <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: '700', color: '#64748b', marginBottom: '8px', textTransform: 'uppercase' }}>Étage / Niveau</label>
                  <input 
                    type="number" 
                    style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid #e2e8f0', outline: 'none', fontSize: '1rem' }} 
                    placeholder="0"
                    value={formData.etage} 
                    onChange={e => setFormData({...formData, etage: e.target.value})} 
                  />
                </div>
              </div>
              
              <div style={{ marginBottom: '2rem' }}>
                <label style={{ display: 'block', fontSize: '0.8rem', fontWeight: '700', color: '#64748b', marginBottom: '8px', textTransform: 'uppercase' }}>Équipements & Ressources</label>
                <textarea 
                  style={{ width: '100%', padding: '12px 16px', borderRadius: '12px', border: '1px solid #e2e8f0', outline: 'none', fontSize: '1rem', minHeight: '100px', fontFamily: 'inherit' }} 
                  placeholder="Vidéoprojecteur, Tableau blanc, Fibre optique..."
                  value={formData.equipements} 
                  onChange={e => setFormData({...formData, equipements: e.target.value})} 
                />
              </div>
              
              <div style={{ display: 'flex', gap: '1rem' }}>
                <button type="button" className="btn btn-ghost" style={{ flex: 1 }} onClick={() => setShowModal(false)}>Annuler</button>
                <button type="submit" className="btn btn-primary" style={{ flex: 2 }}>
                  <Save size={18} />
                  <span>Enregistrer les modifications</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default ManageSalles;
