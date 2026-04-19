import React, { useState, useEffect } from 'react';
import { Crown } from 'lucide-react';

const formatTime = (seconds) => {
  if (!seconds || seconds === 0) return '-';
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins > 0 ? mins + ':' : ''}${secs.toFixed(3)}`;
};

export default function DriverStandings() {
  const [stages, setStages] = useState([]);
  const [selectedStage, setSelectedStage] = useState('');
  
  const [standings, setStandings] = useState([]);
  const [selectedDriver, setSelectedDriver] = useState(null);
  const [driverDetails, setDriverDetails] = useState([]);

  useEffect(() => {
    fetch('http://localhost:5000/api/races').then(r => r.json()).then(data => {
      if (Array.isArray(data)) {
        setStages(data);
        if (data.length > 0) setSelectedStage(data[data.length - 1].race_code); // default to latest
      }
    }).catch(console.error);
  }, []);

  useEffect(() => {
    if (selectedStage !== '') {
      fetch(`http://localhost:5000/api/standings/drivers?stage=${selectedStage}`)
        .then(r => r.json())
        .then(data => setStandings(data));
      setSelectedDriver(null);
    }
  }, [selectedStage]);

  const handleRowClick = (driverCode) => {
    if (selectedDriver === driverCode) {
      setSelectedDriver(null);
      return;
    }
    setSelectedDriver(driverCode);
    fetch(`http://localhost:5000/api/drivers/${driverCode}/results`)
      .then(r => r.json())
      .then(data => setDriverDetails(data));
  };

  return (
    <div className="page-container fadeIn">
      <div className="page-header">
        <h1 className="page-title">Driver Standings</h1>
        <p className="page-subtitle">Current championship rankings based on total points.</p>
      </div>

      <div className="glass-panel" style={{ marginBottom: '2rem' }}>
         <div className="form-group" style={{ margin: 0, maxWidth: '400px' }}>
          <label className="form-label">Calculate standings up to stage (inclusive)</label>
          <select className="form-control" value={selectedStage} onChange={e => setSelectedStage(e.target.value)}>
            <option value="">-- All season so far --</option>
            {stages.map(s => <option key={s.race_code} value={s.race_code}>{s.name}</option>)}
          </select>
        </div>
      </div>

      <div className="glass-panel">
        <div className="table-responsive">
          <table className="data-table">
            <thead>
              <tr>
                <th style={{ width: '80px' }}>Rank</th>
                <th>Driver</th>
                <th>Nationality</th>
                <th>Team</th>
                <th>Total Score</th>
                <th>Total Time (s)</th>
              </tr>
            </thead>
            <tbody>
              {standings.map((s, index) => (
                <React.Fragment key={s.driver_code}>
                  <tr onClick={() => handleRowClick(s.driver_code)} style={{ background: selectedDriver === s.driver_code ? 'rgba(255,255,255,0.05)' : '' }}>
                    <td>
                      <span className={`rank-badge ${index < 3 ? 'rank-' + (index + 1) : ''}`}>
                        {index === 0 ? <Crown size={20} color="#000" fill="#000" /> : index + 1}
                      </span>
                    </td>
                    <td style={{ fontWeight: 600, fontSize: '1.1rem' }}>{s.name}</td>
                    <td style={{ color: 'var(--text-muted)' }}>{s.nationality}</td>
                    <td>{s.team_name}</td>
                    <td><span className="score-badge">{s.total_score} PTS</span></td>
                    <td style={{ fontFamily: 'monospace', fontSize: '1.1rem' }}>{formatTime(s.total_time)}</td>
                  </tr>
                  
                  {/* Driver Details Expansion */}
                  {selectedDriver === s.driver_code && (
                    <tr>
                      <td colSpan="6" style={{ padding: 0 }}>
                        <div className="details-panel">
                          <h4 style={{ marginBottom: '1rem', color: 'var(--text-muted)' }}>Race History for {s.name}</h4>
                          <table className="data-table" style={{ background: 'transparent' }}>
                            <thead>
                              <tr>
                                <th>Stage</th>
                                <th>Rank</th>
                                <th>Status</th>
                                <th>Score</th>
                                <th>Time</th>
                              </tr>
                            </thead>
                            <tbody>
                              {driverDetails.length === 0 && <tr><td colSpan="5">No race data yet</td></tr>}
                              {driverDetails.map((d, i) => (
                                <tr key={i} style={{ cursor: 'default' }}>
                                  <td style={{ fontWeight: 500 }}>{d.stage_name}</td>
                                  <td>{d.finish_rank || '-'}</td>
                                  <td className={`status-${d.status.toLowerCase()}`}>{d.status}</td>
                                  <td style={{ color: 'var(--primary-color)', fontWeight: 'bold' }}>{d.score}</td>
                                  <td style={{ fontFamily: 'monospace' }}>{formatTime(d.time_to_finish)}</td>
                                </tr>
                              ))}
                            </tbody>
                          </table>
                        </div>
                      </td>
                    </tr>
                  )}
                </React.Fragment>
              ))}
              {standings.length === 0 && (
                <tr><td colSpan="6" style={{ textAlign: 'center', padding: '2rem' }}>No data found</td></tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
