import React, { useState, useEffect } from 'react';
import { Save } from 'lucide-react';

export default function RegisterRacing({ champCode }) {
  const [stages, setStages] = useState([]);
  const [teams, setTeams] = useState([]);
  
  const [selectedStage, setSelectedStage] = useState('');
  const [selectedTeam, setSelectedTeam] = useState('');
  
  const [racers, setRacers] = useState([]);
  const [selectedRacers, setSelectedRacers] = useState([]);
  
  const [message, setMessage] = useState({ text: '', type: '' });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const url = champCode
      ? `http://localhost:5000/api/races?champ_code=${champCode}`
      : 'http://localhost:5000/api/races';
    fetch(url).then(r => r.json()).then(data => {
      setStages(Array.isArray(data) ? data : []);
      setSelectedStage('');
    });
    fetch('http://localhost:5000/api/teams').then(r => r.json()).then(setTeams);
  }, [champCode]);

  useEffect(() => {
    if (selectedTeam) {
      fetch(`http://localhost:5000/api/teams/${selectedTeam}/drivers`)
        .then(r => r.json())
        .then(data => {
            setRacers(data);
        });
    } else {
      setRacers([]);
    }
  }, [selectedTeam]);

  useEffect(() => {
    if (selectedStage && selectedTeam) {
      fetch(`http://localhost:5000/api/races/${selectedStage}/teams/${selectedTeam}/entries`)
        .then(r => r.json())
        .then(data => setSelectedRacers(data));
    } else {
      setSelectedRacers([]);
    }
  }, [selectedStage, selectedTeam]);

  const handleCheckboxChange = (contract_id) => {
    setSelectedRacers(prev => {
      if (prev.includes(contract_id)) {
        return prev.filter(id => id !== contract_id);
      } else {
        if (prev.length >= 2) return prev; // Max 2
        return [...prev, contract_id];
      }
    });
  };

  const handleSave = async () => {
    if (!selectedStage || !selectedTeam || selectedRacers.length === 0) {
      setMessage({ text: 'Please select a stage, a team and at least 1 racer.', type: 'error' });
      return;
    }
    
    setLoading(true);
    try {
      const res = await fetch(`http://localhost:5000/api/races/${selectedStage}/teams/${selectedTeam}/entries`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ contract_ids: selectedRacers })
      });
      const data = await res.json();
      
      if (res.ok) {
        setMessage({ text: 'Racers updated successfully!', type: 'success' });
      } else {
        setMessage({ text: data.error || 'Server error', type: 'error' });
      }
    } catch (err) {
      setMessage({ text: 'Failed to connect to server.', type: 'error' });
    }
    setLoading(false);
  };

  return (
    <div className="page-container fadeIn">
      <div className="page-header">
        <h1 className="page-title">Register Racing Team</h1>
        <p className="page-subtitle">Select up to 2 racers to compete in an upcoming stage.</p>
      </div>

      {message.text && (
        <div className={`alert ${message.type === 'error' ? 'alert-error' : 'alert-success'}`}>
          {message.text}
        </div>
      )}

      <div className="glass-panel">
        <div className="grid-2">
          <div className="form-group">
            <label className="form-label">Race Stage</label>
            <select className="form-control" value={selectedStage} onChange={e => setSelectedStage(e.target.value)}>
              <option value="">-- Select Stage --</option>
              {stages.map(s => <option key={s.race_code} value={s.race_code}>{s.name} ({s.location})</option>)}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label">Racing Team</label>
            <select className="form-control" value={selectedTeam} onChange={e => setSelectedTeam(e.target.value)}>
              <option value="">-- Select Team --</option>
              {teams.map(t => <option key={t.team_code} value={t.team_code}>{t.name}</option>)}
            </select>
          </div>
        </div>

        {racers.length > 0 && selectedStage && (
          <div className="form-group" style={{ marginTop: '2rem' }}>
            <label className="form-label">Select Racers (Max 2)</label>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: '1rem', marginTop: '1rem' }}>
              {racers.map(r => (
                <label key={r.contract_id} className="checkbox-container">
                  {r.name} ({r.nationality})
                  <input 
                    type="checkbox" 
                    checked={selectedRacers.includes(r.contract_id)} 
                    onChange={() => handleCheckboxChange(r.contract_id)}
                    disabled={!selectedRacers.includes(r.contract_id) && selectedRacers.length >= 2}
                  />
                  <span className="checkmark"></span>
                </label>
              ))}
            </div>
            
            <div style={{ marginTop: '2.5rem', textAlign: 'right' }}>
              <button className="btn btn-primary" onClick={handleSave} disabled={loading}>
                <Save size={18} /> {loading ? 'Saving...' : 'Sync Registration'}
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
