import React, { useState } from 'react';
import { auth, db } from '../firebase';
import { signInWithEmailAndPassword, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { Mail, Lock, ShieldCheck, ArrowRight, Loader2, AlertCircle } from 'lucide-react';

const AL_OMRANE_LOGO = "/omrane-log0.png";

const LoginPage = ({ onLogin }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      const userDoc = await getDoc(doc(db, 'users', userCredential.user.uid));
      
      if (userDoc.exists() && userDoc.data().role === 'admin') {
        onLogin(userCredential.user);
      } else {
        await signOut(auth);
        setError("Accès refusé. Privilèges administrateur requis.");
      }
    } catch (err) {
      setError("Identifiants incorrects ou problème de connexion.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ 
      height: '100vh', 
      display: 'flex', 
      alignItems: 'center', 
      justifyContent: 'center', 
      background: 'linear-gradient(135deg, #1e5c3b 0%, #0a1f14 100%)',
      overflow: 'hidden',
      position: 'relative'
    }}>
      {/* Decorative blobs */}
      <div style={{ position: 'absolute', top: '-10%', left: '-5%', width: '40%', height: '40%', background: 'rgba(255,255,255,0.05)', borderRadius: '50%', filter: 'blur(80px)' }}></div>
      <div style={{ position: 'absolute', bottom: '-10%', right: '-5%', width: '40%', height: '40%', background: 'rgba(255,255,255,0.05)', borderRadius: '50%', filter: 'blur(80px)' }}></div>

      <div className="card animate-fade-in" style={{ width: '450px', padding: '3.5rem', boxShadow: '0 50px 100px -20px rgba(0, 0, 0, 0.4)', borderRadius: '32px', border: '1px solid rgba(255,255,255,0.1)' }}>
        <div style={{textAlign: 'center', marginBottom: '3rem'}}>
          <img src={AL_OMRANE_LOGO} alt="Al Omrane" style={{ width: '100px', marginBottom: '24px', background: 'white', padding: '10px', borderRadius: '20px', boxShadow: '0 10px 25px rgba(0,0,0,0.1)' }} />
          <h2 style={{ fontSize: '2.2rem', fontWeight: '900', color: '#0f172a', letterSpacing: '-1.5px' }}>Portail Admin</h2>
          <p style={{color: '#64748B', fontSize: '0.95rem', marginTop: '8px', fontWeight: '500'}}>Groupe Al Omrane — Gestion Immobilière</p>
        </div>
        
        {error && (
          <div style={{ background: '#FEE2E2', color: '#991B1B', padding: '1rem', borderRadius: '14px', marginBottom: '1.5rem', fontSize: '0.85rem', border: '1px solid #FECACA', display: 'flex', alignItems: 'center', gap: '10px' }}>
            <AlertCircle size={18} /> {error}
          </div>
        )}
        
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: '1.5rem' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.8rem', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Adresse Email</label>
            <div style={{ position: 'relative' }}>
              <Mail style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} size={20} />
              <input 
                type="email" 
                style={{ width: '100%', padding: '14px 16px 14px 48px', borderRadius: '16px', border: '1px solid #E2E8F0', outline: 'none', fontSize: '1rem', transition: 'all 0.2s' }} 
                value={email} 
                onChange={(e) => setEmail(e.target.value)} 
                placeholder="admin@alomrane.gov.ma"
                required 
              />
            </div>
          </div>
          <div style={{ marginBottom: '2.5rem' }}>
            <label style={{ display: 'block', marginBottom: '8px', fontSize: '0.8rem', fontWeight: '700', color: '#64748b', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Mot de passe</label>
            <div style={{ position: 'relative' }}>
              <Lock style={{ position: 'absolute', left: '16px', top: '50%', transform: 'translateY(-50%)', color: '#94a3b8' }} size={20} />
              <input 
                type="password" 
                style={{ width: '100%', padding: '14px 16px 14px 48px', borderRadius: '16px', border: '1px solid #E2E8F0', outline: 'none', fontSize: '1rem', transition: 'all 0.2s' }} 
                value={password} 
                onChange={(e) => setPassword(e.target.value)} 
                placeholder="••••••••"
                required 
              />
            </div>
          </div>
          
          <button 
            type="submit" 
            className="btn btn-primary" 
            style={{ width: '100%', padding: '1rem', fontSize: '1.1rem', height: '56px', borderRadius: '16px' }} 
            disabled={loading}
          >
            {loading ? <Loader2 className="animate-spin" /> : (
              <>
                <ShieldCheck size={20} />
                <span>Accès Sécurisé</span>
                <ArrowRight size={18} style={{ marginLeft: 'auto' }} />
              </>
            )}
          </button>
        </form>

        <div style={{ marginTop: '2.5rem', textAlign: 'center' }}>
          <p style={{ fontSize: '0.8rem', color: '#94a3b8' }}>
            &copy; 2026 Al Omrane. Tous droits réservés.
          </p>
        </div>
      </div>
    </div>
  );
};

export default LoginPage;
