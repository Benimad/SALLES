import React from 'react';
import { Clock, CheckCircle2, ChevronLeft, ChevronRight, Filter } from 'lucide-react';
import { useDemandes } from '../hooks/useDemandes';

const PlanningCalendar = ({ salles }) => {
  const { demandes, loading } = useDemandes();
  
  // Use today's date for this daily planner
  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];
  
  // Only show approved requests for today
  const todaysReservations = demandes.filter(d => 
    d.statut === 'approuvee' && d.date_debut === todayStr
  );

  const hours = [8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];

  const calculatePositionAndWidth = (heureDebut, heureFin) => {
    // Expected format "HH:MM"
    const startHour = parseInt(heureDebut.split(':')[0]);
    const startMin = parseInt(heureDebut.split(':')[1]);
    const endHour = parseInt(heureFin.split(':')[0]);
    const endMin = parseInt(heureFin.split(':')[1]);

    const startOffset = (startHour - 8) * 60 + startMin; // minutes since 8:00
    const duration = (endHour - startHour) * 60 + (endMin - startMin); // duration in minutes

    // Assuming total grid is from 8:00 to 18:00 (10 hours = 600 minutes)
    // The width of the container is 100%, so 1 minute = 100/600 %
    const leftPercentage = (startOffset / 600) * 100;
    const widthPercentage = (duration / 600) * 100;

    return { 
      left: `${Math.max(0, leftPercentage)}%`, 
      width: `${Math.min(100 - Math.max(0, leftPercentage), widthPercentage)}%` 
    };
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'approuvee': return { bg: '#d1fae5', text: '#059669', border: '#10b981' };
      case 'en_attente': return { bg: '#fef3c7', text: '#d97706', border: '#f59e0b' };
      default: return { bg: '#f1f5f9', text: '#475569', border: '#94a3b8' };
    }
  };

  return (
    <div className="animate-fade-in" style={{ padding: '0' }}>
      
      {/* Header controls */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '2rem' }}>
        <div>
          <h2 style={{ fontSize: '2rem', fontWeight: '900', color: '#0f172a' }}>Planning du Jour</h2>
          <p style={{ color: '#64748b', fontWeight: '500' }}>Vue chronologique des occupations de salles.</p>
        </div>
        
        <div style={{ display: 'flex', gap: '1rem' }}>
          <div style={{ display: 'flex', background: 'white', border: '1px solid #e2e8f0', borderRadius: '12px', padding: '4px' }}>
            <button className="btn btn-ghost" style={{ padding: '8px', border: 'none' }}><ChevronLeft size={18} /></button>
            <div style={{ padding: '8px 16px', fontWeight: '700', color: '#1e5c3b', display: 'flex', alignItems: 'center' }}>
              {new Date().toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' })}
            </div>
            <button className="btn btn-ghost" style={{ padding: '8px', border: 'none' }}><ChevronRight size={18} /></button>
          </div>
          <button className="btn" style={{ background: 'white', border: '1px solid #e2e8f0' }}>
            <Filter size={18} /> Filtres
          </button>
        </div>
      </div>

      <div className="card" style={{ padding: '0', overflowX: 'auto', border: '1px solid #e2e8f0', boxShadow: '0 10px 30px -10px rgba(0,0,0,0.05)' }}>
        
        {/* Timeline Header (Hours) */}
        <div style={{ display: 'flex', background: '#f8fafc', borderBottom: '1px solid #e2e8f0', paddingLeft: '200px', position: 'relative' }}>
          {hours.map(hour => (
            <div key={hour} style={{ flex: 1, minWidth: '80px', padding: '16px 8px', borderLeft: '1px solid #e2e8f0', textAlign: 'center', fontSize: '0.85rem', fontWeight: '700', color: '#64748b' }}>
              {hour.toString().padStart(2, '0')}:00
            </div>
          ))}
        </div>

        {/* Rooms Rows */}
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          {salles.length === 0 ? (
            <div style={{ padding: '40px', textAlign: 'center', color: '#94a3b8' }}>Chargement des salles...</div>
          ) : (
            salles.map(salle => {
              const reservationsForSalle = todaysReservations.filter(d => d.salle_id === salle.id);

              return (
                <div key={salle.id} style={{ display: 'flex', borderBottom: '1px solid #e2e8f0', minHeight: '80px' }}>
                  {/* Room Info Sidebar */}
                  <div style={{ width: '200px', flexShrink: 0, padding: '16px', background: '#fff', borderRight: '1px solid #e2e8f0', display: 'flex', flexDirection: 'column', justifyContent: 'center' }}>
                    <div style={{ fontWeight: '800', fontSize: '0.95rem', color: '#0f172a' }}>{salle.nom}</div>
                    <div style={{ fontSize: '0.75rem', color: '#64748b', marginTop: '4px' }}>Capacité: {salle.capacite}</div>
                  </div>

                  {/* Timeline Grid for this room */}
                  <div style={{ flex: 1, position: 'relative', background: '#fafafa', display: 'flex' }}>
                    {/* Vertical grid lines */}
                    {hours.map((hour, idx) => (
                      <div key={`grid-${idx}`} style={{ flex: 1, minWidth: '80px', borderLeft: idx === 0 ? 'none' : '1px dashed #e2e8f0' }}></div>
                    ))}

                    {/* Reservation Blocks */}
                    {reservationsForSalle.map(res => {
                      const pos = calculatePositionAndWidth(res.heure_debut, res.heure_fin);
                      const colors = getStatusColor(res.statut);
                      
                      return (
                        <div 
                          key={res.id} 
                          style={{
                            position: 'absolute',
                            top: '12px',
                            bottom: '12px',
                            left: pos.left,
                            width: pos.width,
                            padding: '0 4px',
                            zIndex: 10
                          }}
                        >
                          <div style={{
                            width: '100%',
                            height: '100%',
                            background: colors.bg,
                            border: `1px solid ${colors.border}`,
                            borderRadius: '8px',
                            padding: '6px',
                            display: 'flex',
                            flexDirection: 'column',
                            overflow: 'hidden',
                            boxShadow: '0 2px 4px rgba(0,0,0,0.02)',
                            cursor: 'pointer'
                          }} title={`${res.user_name} - ${res.motif}`}>
                            <div style={{ display: 'flex', alignItems: 'center', gap: '4px', fontSize: '0.7rem', fontWeight: '800', color: colors.text }}>
                              <CheckCircle2 size={10} /> {res.heure_debut} - {res.heure_fin}
                            </div>
                            <div style={{ fontSize: '0.75rem', fontWeight: '600', color: '#0f172a', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis', marginTop: '2px' }}>
                              {res.user_name}
                            </div>
                            <div style={{ fontSize: '0.65rem', color: '#64748b', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>
                              {res.motif}
                            </div>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              );
            })
          )}
        </div>
        
      </div>
      
      {/* Legend */}
      <div style={{ display: 'flex', gap: '1.5rem', marginTop: '1.5rem', padding: '0 1rem' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '8px', fontSize: '0.8rem', fontWeight: '600', color: '#64748b' }}>
          <span style={{ width: '12px', height: '12px', background: '#d1fae5', border: '1px solid #10b981', borderRadius: '4px' }}></span> Réservé (Approuvé)
        </div>
      </div>
    </div>
  );
};

export default PlanningCalendar;
