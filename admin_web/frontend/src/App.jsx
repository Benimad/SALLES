import React, { useState, useEffect } from 'react';
import { auth, db } from './firebase';
import { onAuthStateChanged, signOut } from 'firebase/auth';
import { 
  LayoutDashboard, 
  Building2, 
  Users, 
  Settings, 
  LogOut, 
  Bell, 
  Search, 
  FileDown, 
  CheckCircle2, 
  XCircle, 
  Clock, 
  MoreHorizontal,
  ChevronRight,
  TrendingUp,
  ArrowUpRight,
  User,
  Calendar
} from 'lucide-react';
import { Toaster, toast } from 'react-hot-toast';
import { useDemandes } from './hooks/useDemandes';
import { generateAdminReport } from './services/pdfService';
import { collection, onSnapshot, updateDoc, doc, Timestamp } from 'firebase/firestore';
import LoginPage from './pages/LoginPage';
import ManageSalles from './components/ManageSalles';
import PlanningCalendar from './components/PlanningCalendar';

// --- SHARED COMPONENTS ---

const AL_OMRANE_LOGO = "/omrane-log0.png";

const SidebarItem = ({ icon: Icon, label, active = false, onClick }) => (
  <li 
    className={`nav-item ${active ? 'active' : ''}`}
    onClick={onClick}
  >
    <Icon className="nav-icon" />
    <span>{label}</span>
  </li>
);

const EnterpriseStatCard = ({ label, value, icon: Icon, color, trend }) => (
  <div className="enterprise-stat animate-fade-in">
    <div className="stat-top">
      <div className="stat-icon-box" style={{ background: `${color}15`, color }}>
        <Icon size={24} />
      </div>
      {trend && (
        <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.75rem', color: '#10b981', fontWeight: '700', background: '#f0fdf4', padding: '4px 8px', borderRadius: '20px' }}>
          <TrendingUp size={12} /> {trend}
        </div>
      )}
    </div>
    <div style={{ marginTop: '4px' }}>
      <div className="stat-value">{value}</div>
      <div className="stat-label">{label}</div>
    </div>
  </div>
);

// --- MAIN DASHBOARD CONTENT ---

const DashboardContent = () => {
  const { demandes, loading } = useDemandes();
  const [salles, setSalles] = useState([]);
  const [view, setView] = useState('dashboard');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    return onSnapshot(collection(db, 'salles'), (snap) => {
      setSalles(snap.docs.map(d => ({ id: d.id, ...d.data() })));
    });
  }, []);

  const stats = {
    total: demandes.length,
    pending: demandes.filter(d => d.statut === 'en_attente').length,
    approved: demandes.filter(d => d.statut === 'approuvee').length,
  };

  const filteredDemandes = demandes.filter(d => 
    d.user_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.salle_name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
    d.motif?.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const handleStatus = async (id, status) => {
    const reason = status === 'rejetee' ? prompt("Raison du refus ?") : null;
    if (status === 'rejetee' && !reason) return;
    
    try {
      await updateDoc(doc(db, 'demandes', id), {
        statut: status,
        raison_rejet: reason,
        updated_at: Timestamp.now()
      });
      toast.success(`Demande ${status === 'approuvee' ? 'approuvée' : 'rejetée'} avec succès`);
    } catch (e) { 
      console.error(e);
      toast.error("Une erreur est survenue");
    }
  };

  if (loading) return (
    <div style={{ display: 'flex', height: '100vh', alignItems: 'center', justifyContent: 'center', background: 'white' }}>
      <div style={{ textAlign: 'center' }}>
        <img src={AL_OMRANE_LOGO} alt="Logo" style={{ width: '80px', marginBottom: '20px' }} className="animate-pulse" />
        <div style={{ fontWeight: '600', color: '#1e5c3b' }}>Système Al Omrane...</div>
      </div>
    </div>
  );

  return (
    <div className="dashboard-layout">
      {/* SIDEBAR */}
      <aside className="sidebar">
        <div className="logo-container">
          <img src={AL_OMRANE_LOGO} alt="Al Omrane" className="logo-img" />
          <div style={{ display: 'flex', flexDirection: 'column' }}>
            <span style={{ fontWeight: '800', fontSize: '1.2rem', letterSpacing: '-0.5px' }}>AL OMRANE</span>
            <span style={{ fontSize: '0.65rem', opacity: 0.6, letterSpacing: '1.5px', fontWeight: '600' }}>CONSOLE ADMIN</span>
          </div>
        </div>

        <nav style={{ flex: 1 }}>
          <ul className="nav-list">
            <SidebarItem icon={LayoutDashboard} label="Tableau de bord" active={view === 'dashboard'} onClick={() => setView('dashboard')} />
            <SidebarItem icon={Building2} label="Gestion Salles" active={view === 'salles'} onClick={() => setView('salles')} />
            <SidebarItem icon={Users} label="Collaborateurs" />
            <SidebarItem icon={Calendar} label="Planning" active={view === 'planning'} onClick={() => setView('planning')} />
          </ul>

          <div style={{ marginTop: '3rem' }}>
            <div style={{ fontSize: '0.7rem', color: 'rgba(255,255,255,0.4)', fontWeight: '700', paddingLeft: '1rem', marginBottom: '1rem', textTransform: 'uppercase' }}>Système</div>
            <ul className="nav-list">
              <SidebarItem icon={Settings} label="Paramètres" />
            </ul>
          </div>
        </nav>

        <button 
          onClick={() => signOut(auth)} 
          className="nav-item" 
          style={{ marginTop: 'auto', border: 'none', background: 'none', width: '100%', cursor: 'pointer' }}
        >
          <LogOut className="nav-icon" />
          <span>Déconnexion</span>
        </button>
      </aside>

      {/* MAIN WRAPPER */}
      <div className="main-wrapper">
        <header className="top-bar">
          <div style={{ display: 'flex', alignItems: 'center', gap: '1rem', background: '#f8fafc', padding: '8px 16px', borderRadius: '12px', width: '300px' }}>
            <Search size={18} color="#94a3b8" />
            <input 
              type="text" 
              placeholder="Rechercher une demande..." 
              style={{ border: 'none', background: 'transparent', outline: 'none', fontSize: '0.9rem', width: '100%' }}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
          </div>

          <div style={{ display: 'flex', alignItems: 'center', gap: '20px' }}>
            <button className="btn-icon btn-ghost" style={{ position: 'relative' }}>
              <Bell size={20} />
              <span style={{ position: 'absolute', top: '4px', right: '4px', width: '8px', height: '8px', background: '#ef4444', borderRadius: '50%', border: '2px solid white' }}></span>
            </button>
            
            <div style={{ height: '24px', width: '1px', background: '#e2e8f0' }}></div>
            
            <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
              <div style={{ textAlign: 'right' }}>
                <div style={{ fontSize: '0.85rem', fontWeight: '700' }}>Admin Al Omrane</div>
                <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Super Administrateur</div>
              </div>
              <div className="avatar-circle" style={{ width: '40px', height: '40px' }}>
                <User size={20} />
              </div>
            </div>
          </div>
        </header>

        <div className="page-content animate-fade-in">
          {view === 'dashboard' ? (
            <>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: '2.5rem' }}>
                <div>
                  <h2 style={{ fontSize: '2.2rem', fontWeight: '900', color: '#0f172a', letterSpacing: '-1px' }}>Bonjour, Administrateur</h2>
                  <p style={{ color: '#64748b', fontWeight: '500' }}>Voici l'état actuel de votre parc immobilier et des réservations.</p>
                </div>
                <button className="btn btn-primary" onClick={() => generateAdminReport(demandes)}>
                  <FileDown size={18} />
                  <span>Générer Rapport PDF</span>
                </button>
              </div>

              {/* STATS */}
              <div className="stat-grid">
                <EnterpriseStatCard label="Total Réservations" value={stats.total} icon={LayoutDashboard} color="#1e5c3b" trend="+12.5%" />
                <EnterpriseStatCard label="En Attente" value={stats.pending} icon={Clock} color="#f59e0b" />
                <EnterpriseStatCard label="Salles Occupées" value={salles.length} icon={Building2} color="#2563eb" />
                <EnterpriseStatCard label="Taux d'occupation" value="78%" icon={TrendingUp} color="#10b981" />
              </div>

              <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '2rem' }}>
                {/* RECENT DEMANDS */}
                <div className="table-wrapper">
                  <div style={{ padding: '1.5rem', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <h3 style={{ fontSize: '1.1rem', fontWeight: '800' }}>Flux des Réservations</h3>
                    <div style={{ fontSize: '0.75rem', fontWeight: '700', color: '#1e5c3b', background: '#f0fdf4', padding: '4px 12px', borderRadius: '20px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <span style={{ width: '6px', height: '6px', background: '#10b981', borderRadius: '50%' }}></span> LIVE FEED
                    </div>
                  </div>
                  <table className="enterprise-table">
                    <thead>
                      <tr>
                        <th>Salle & Info</th>
                        <th>Collaborateur</th>
                        <th>Date & Heure</th>
                        <th>Statut</th>
                        <th>Actions</th>
                      </tr>
                    </thead>
                    <tbody>
                      {filteredDemandes.length > 0 ? filteredDemandes.map(d => (
                        <tr key={d.id}>
                          <td>
                            <div style={{ fontWeight: '700', color: '#0f172a' }}>{d.salle_name}</div>
                            <div style={{ fontSize: '0.7rem', color: '#94a3b8' }}>ID: {d.id.substring(0, 8).toUpperCase()}</div>
                          </td>
                          <td>
                            <div className="user-info-cell">
                              <div className="avatar-circle">{d.user_name?.charAt(0).toUpperCase()}</div>
                              <div>
                                <div style={{ fontWeight: '600', fontSize: '0.85rem' }}>{d.user_name}</div>
                                <div style={{ fontSize: '0.75rem', color: '#64748b' }}>{d.motif}</div>
                              </div>
                            </div>
                          </td>
                          <td>
                            <div style={{ fontWeight: '600' }}>{d.date_debut}</div>
                            <div style={{ fontSize: '0.8rem', color: '#64748b' }}>{d.heure_debut} - {d.heure_fin}</div>
                          </td>
                          <td>
                            <span className={`status-pill status-${d.statut === 'en_attente' ? 'pending' : d.statut === 'approuvee' ? 'approved' : 'rejected'}`}>
                              {d.statut === 'en_attente' ? 'En attente' : d.statut === 'approuvee' ? 'Approuvée' : 'Rejetée'}
                            </span>
                          </td>
                          <td>
                            {d.statut === 'en_attente' ? (
                              <div style={{ display: 'flex', gap: '8px' }}>
                                <button className="btn btn-icon btn-primary" title="Approuver" onClick={() => handleStatus(d.id, 'approuvee')}>
                                  <CheckCircle2 size={16} />
                                </button>
                                <button className="btn btn-icon" title="Rejeter" style={{ background: '#fee2e2', color: '#ef4444' }} onClick={() => handleStatus(d.id, 'rejetee')}>
                                  <XCircle size={16} />
                                </button>
                              </div>
                            ) : (
                              <div style={{ color: '#94a3b8', fontSize: '0.8rem', fontStyle: 'italic', display: 'flex', alignItems: 'center', gap: '4px' }}>
                                <CheckCircle2 size={14} /> Traité
                              </div>
                            )}
                          </td>
                        </tr>
                      )) : (
                        <tr>
                          <td colSpan="5" style={{ textAlign: 'center', padding: '40px', color: '#94a3b8' }}>
                            Aucune réservation trouvée
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {/* ROOM STATUS */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>
                  <div className="card" style={{ padding: '1.5rem' }}>
                    <div className="card-header">
                      <h3 style={{ fontSize: '1.1rem', fontWeight: '800' }}>État des Salles</h3>
                      <button className="btn-icon btn-ghost"><MoreHorizontal size={18} /></button>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                      {salles.map(s => {
                        const now = new Date();
                        const todayStr = now.toISOString().split('T')[0];
                        const currentTime = `${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}`;
                        
                        const activeParticipants = demandes
                          .filter(d => 
                            d.salle_id === s.id && 
                            d.statut === 'approuvee' && 
                            d.date_debut === todayStr &&
                            currentTime >= d.heure_debut && 
                            currentTime <= d.heure_fin
                          )
                          .reduce((sum, d) => sum + (parseInt(d.participants_externes) || 1), 0);

                        const remaining = s.capacite - activeParticipants;
                        const percentage = (activeParticipants / s.capacite) * 100;
                        const isFull = remaining <= 0;

                        return (
                          <div key={s.id} style={{ paddingBottom: '16px', borderBottom: '1px solid #f1f5f9' }}>
                            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '10px' }}>
                              <div>
                                <div style={{ fontWeight: '700', fontSize: '0.95rem' }}>{s.nom}</div>
                                <div style={{ fontSize: '0.75rem', color: '#64748b' }}>Capacité: {s.capacite} personnes</div>
                              </div>
                              <span style={{ fontSize: '0.85rem', fontWeight: '700', color: isFull ? '#ef4444' : '#10b981' }}>
                                {isFull ? 'Saturé' : `${remaining} libres`}
                              </span>
                            </div>
                            <div style={{ height: '8px', width: '100%', background: '#f1f5f9', borderRadius: '4px', overflow: 'hidden' }}>
                              <div style={{ 
                                height: '100%', 
                                width: `${percentage}%`, 
                                background: isFull ? '#ef4444' : 'var(--primary)',
                                transition: 'width 0.5s ease'
                              }}></div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                    <button className="btn btn-ghost" style={{ width: '100%', marginTop: '1rem', border: '1px solid #e2e8f0' }} onClick={() => setView('salles')}>
                      Gérer les salles <ChevronRight size={16} />
                    </button>
                  </div>

                  {/* QUICK ACTIONS */}
                  <div className="card" style={{ background: 'var(--primary)', color: 'white', border: 'none' }}>
                    <h3 style={{ fontSize: '1.1rem', fontWeight: '800', marginBottom: '0.5rem' }}>Action Rapide</h3>
                    <p style={{ fontSize: '0.85rem', opacity: 0.8, marginBottom: '1.5rem' }}>Ajoutez une nouvelle salle ou gérez les utilisateurs en un clic.</p>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>
                      <button className="btn" style={{ background: 'white', color: 'var(--primary)', width: '100%' }} onClick={() => setView('salles')}>
                        <Building2 size={16} /> Ajouter une salle
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </>
          ) : view === 'planning' ? (
            <PlanningCalendar salles={salles} />
          ) : (
            <div className="animate-fade-in">
              <div style={{ marginBottom: '2rem', display: 'flex', alignItems: 'center', gap: '12px' }}>
                <button className="btn btn-icon btn-ghost" onClick={() => setView('dashboard')}><ChevronRight size={20} style={{ transform: 'rotate(180deg)' }} /></button>
                <h2 style={{ fontSize: '2rem', fontWeight: '900' }}>Gestion des Salles</h2>
              </div>
              <ManageSalles />
            </div>
          )}
        </div>
      </div>
      <Toaster position="top-right" />
    </div>
  );
};

// --- ROOT AUTHENTICATION ROUTER ---

function App() {
  const [user, setUser] = useState(null);
  const [authLoading, setAuthLoading] = useState(true);

  useEffect(() => {
    return onAuthStateChanged(auth, (u) => {
      setUser(u);
      setAuthLoading(false);
    });
  }, []);

  if (authLoading) {
    return (
      <div style={{ height: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f4f7f6' }}>
        <div style={{ textAlign: 'center' }}>
          <img src={AL_OMRANE_LOGO} alt="Al Omrane" style={{ width: '100px', marginBottom: '20px' }} />
          <div style={{ fontWeight: '700', fontSize: '1.2rem', color: '#1e5c3b' }}>Chargement du portail Al Omrane...</div>
        </div>
      </div>
    );
  }

  return user ? <DashboardContent /> : <LoginPage onLogin={setUser} />;
}

export default App;
