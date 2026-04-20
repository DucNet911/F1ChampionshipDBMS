import React, { useState, useEffect } from 'react';
import { Save, AlertCircle, CheckCircle } from 'lucide-react';

export default function UpdateResults({ champCode }) {
  const [stages, setStages] = useState([]);
  const [selectedStage, setSelectedStage] = useState('');
  const [stageInfo, setStageInfo] = useState(null);

  const [entries, setEntries] = useState([]);
  const [results, setResults] = useState({});
  const [errors, setErrors] = useState({});

  const [message, setMessage] = useState(null);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const url = champCode
      ? `http://localhost:5000/api/races?champ_code=${champCode}`
      : 'http://localhost:5000/api/races';
    fetch(url).then(r => r.json()).then(data => {
      setStages(Array.isArray(data) ? data : []);
      setSelectedStage('');
    });
  }, [champCode]);

  useEffect(() => {
    if (selectedStage) {
      const stage = stages.find(s => s.race_code === selectedStage);
      setStageInfo(stage || null);

      fetch(`http://localhost:5000/api/races/${selectedStage}/entries`)
        .then(r => r.json())
        .then(data => {
          setEntries(data);
          const initResults = {};
          data.forEach(e => {
            initResults[e.entry_id] = { end_time: '', laps_completed: '', status: 'Finished' };
          });
          setResults(initResults);
          setErrors({});
          setMessage(null);
        });
    } else {
      setEntries([]);
      setResults({});
      setErrors({});
      setStageInfo(null);
    }
  }, [selectedStage, stages]);

  const handleChange = (entryId, field, value) => {
    setResults(prev => ({
      ...prev,
      [entryId]: {
        ...prev[entryId],
        [field]: value,
        // Reset end_time when switching away from Finished
        ...(field === 'status' && value !== 'Finished' ? { end_time: '' } : {})
      }
    }));
    // Clear error for this row when user edits
    setErrors(prev => ({ ...prev, [entryId]: null }));
  };

  // Validate all rows, return true if OK
  const validate = () => {
    const newErrors = {};
    let valid = true;

    entries.forEach(e => {
      const r = results[e.entry_id];
      if (!r) return;

      if (!r.laps_completed || parseInt(r.laps_completed) < 0) {
        newErrors[e.entry_id] = 'Số vòng đua phải được nhập và không âm.';
        valid = false;
        return;
      }

      if (r.status === 'Finished') {
        if (!r.end_time) {
          newErrors[e.entry_id] = 'Thời gian kết thúc là bắt buộc khi trạng thái là Finished.';
          valid = false;
          return;
        }
        // Validate end_time > start_time (frontend pre-check)
        if (stageInfo?.start_time) {
          const startMs = new Date(stageInfo.start_time).getTime();
          const endMs = new Date(r.end_time).getTime();
          if (endMs <= startMs) {
            newErrors[e.entry_id] = `Thời gian kết thúc phải sau ${stageInfo.start_time.replace('T', ' ').substring(0, 19)}.`;
            valid = false;
            return;
          }
        }
      }
    });

    setErrors(newErrors);
    return valid;
  };

  const handleSave = async () => {
    if (!validate()) {
      setMessage({ type: 'error', text: 'Vui lòng kiểm tra lại dữ liệu nhập. Có một số ô chưa hợp lệ!' });
      return;
    }

    setLoading(true);
    const payload = Object.keys(results).map(id => ({
      entry_id: parseInt(id),
      ...results[id],
      end_time: results[id].status === 'Finished'
        ? (results[id].end_time ? results[id].end_time.replace('T', ' ') : null)
        : null
    }));

    try {
      const res = await fetch(`http://localhost:5000/api/races/results`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ results: payload })
      });
      if (res.ok) {
        setMessage({ type: 'success', text: '✅ Results saved & points recalculated successfully!' });
      } else {
        const data = await res.json().catch(() => ({}));
        setMessage({ type: 'error', text: data.error || 'Error saving results' });
      }
    } catch (err) {
      setMessage({ type: 'error', text: 'Network error — backend unreachable.' });
    }
    setLoading(false);
  };

  const handleClearResult = async (entryId) => {
    if (!window.confirm('Do you want to clear the result for this entry?')) return;

    setLoading(true);
    try {
      const res = await fetch(`http://localhost:5000/api/results/${entryId}`, { method: 'DELETE' });
      if (res.ok) {
        setMessage({ type: 'success', text: 'Result cleared successfully!' });
        setResults(prev => ({
          ...prev,
          [entryId]: { end_time: '', laps_completed: '', status: 'Finished' }
        }));
        setErrors(prev => ({ ...prev, [entryId]: null }));
      } else {
        setMessage({ type: 'error', text: 'Error clearing result' });
      }
    } catch (err) {
      setMessage({ type: 'error', text: 'Network error' });
    }
    setLoading(false);
  };

  // Completion summary
  const filledCount = entries.filter(e => {
    const r = results[e.entry_id];
    if (!r) return false;
    if (r.status !== 'Finished') return !!r.laps_completed;
    return !!r.end_time && !!r.laps_completed;
  }).length;
  const allFilled = filledCount === entries.length && entries.length > 0;

  return (
    <div className="page-container">
      <div className="page-header">
        <h1 className="page-title">Update Race Results</h1>
        <p className="page-subtitle">Enter finishing time and laps for all competing racers.</p>
      </div>

      <div className="glass-panel" style={{ marginBottom: '2rem' }}>
        <div className="form-group" style={{ margin: 0, maxWidth: '400px' }}>
          <label className="form-label">Target Stage</label>
          <select className="form-control" value={selectedStage} onChange={e => setSelectedStage(e.target.value)}>
            <option value="">-- View Registered Racers --</option>
            {stages.map(s => <option key={s.race_code} value={s.race_code}>{s.name}</option>)}
          </select>
        </div>
        {stageInfo && (
          <p style={{ marginTop: '0.75rem', color: 'var(--text-muted)', fontSize: '0.9rem' }}>
            🏁 Race start time: <strong style={{ color: 'var(--text-main)' }}>
              {new Date(stageInfo.start_time).toLocaleString()}
            </strong>
            &nbsp;— End time must be <strong style={{ color: 'var(--primary-color)' }}>after</strong> this.
          </p>
        )}
      </div>

      {message && (
        <div className={`alert alert-${message.type}`}>{message.text}</div>
      )}

      {selectedStage && entries.length > 0 && (
        <div className="glass-panel">
          {/* Progress bar */}
          <div style={{ marginBottom: '1.5rem' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
              <span style={{ fontSize: '0.9rem', color: 'var(--text-muted)', fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>
                Entry Completion
              </span>
              <span style={{
                fontWeight: 700,
                color: allFilled ? 'var(--success)' : 'var(--primary-color)',
                display: 'flex', alignItems: 'center', gap: '0.4rem'
              }}>
                {allFilled
                  ? <><CheckCircle size={16} /> All entries filled</>
                  : <><AlertCircle size={16} /> {filledCount} / {entries.length} filled</>
                }
              </span>
            </div>
            <div style={{ height: '6px', borderRadius: '3px', background: 'rgba(255,255,255,0.1)', overflow: 'hidden' }}>
              <div style={{
                height: '100%',
                borderRadius: '3px',
                width: `${entries.length ? (filledCount / entries.length) * 100 : 0}%`,
                background: allFilled ? 'var(--success)' : 'var(--primary-gradient, var(--primary-color))',
                transition: 'width 0.4s ease'
              }} />
            </div>
          </div>

          <div className="table-responsive">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Racer</th>
                  <th>Team</th>
                  <th>Status</th>
                  <th>End Time</th>
                  <th>Laps</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {entries.map(e => {
                  const r = results[e.entry_id] || {};
                  const rowError = errors[e.entry_id];
                  return (
                    <React.Fragment key={e.entry_id}>
                      <tr style={{ borderLeft: rowError ? '3px solid var(--primary-color)' : '3px solid transparent' }}>
                        <td style={{ fontWeight: 600 }}>{e.driver_name}</td>
                        <td style={{ color: 'var(--text-muted)' }}>{e.team_name}</td>
                        <td>
                          <select
                            className="form-control" style={{ padding: '0.5rem' }}
                            value={r.status || 'Finished'}
                            onChange={ev => handleChange(e.entry_id, 'status', ev.target.value)}
                          >
                            <option value="Finished">✅ Finished</option>
                            <option value="DNF">🚫 DNF</option>
                            <option value="Accident">💥 Accident</option>
                          </select>
                        </td>
                        <td>
                          <input
                            type="datetime-local" step="0.001"
                            className="form-control"
                            style={{
                              padding: '0.5rem',
                              borderColor: rowError && r.status === 'Finished' && !r.end_time ? 'var(--primary-color)' : undefined
                            }}
                            value={r.end_time || ''}
                            onChange={ev => handleChange(e.entry_id, 'end_time', ev.target.value)}
                            disabled={r.status !== 'Finished'}
                            min={stageInfo?.start_time}
                          />
                        </td>
                        <td>
                          <input
                            type="number" min="0"
                            className="form-control"
                            style={{
                              padding: '0.5rem', width: '90px',
                              borderColor: rowError && !r.laps_completed ? 'var(--primary-color)' : undefined
                            }}
                            value={r.laps_completed || ''}
                            onChange={ev => handleChange(e.entry_id, 'laps_completed', ev.target.value)}
                            placeholder="0"
                          />
                        </td>
                        <td>
                          <button
                            className="btn"
                            style={{ padding: '0.5rem 1rem', background: 'rgba(225, 6, 0, 0.2)', color: 'var(--primary-color)', borderRadius: '20px' }}
                            onClick={() => handleClearResult(e.entry_id)}
                            disabled={loading}
                          >
                            Clear
                          </button>
                        </td>
                      </tr>
                      {rowError && (
                        <tr>
                          <td colSpan="6" style={{ padding: '0.25rem 1rem 0.75rem', paddingTop: 0 }}>
                            <div style={{
                              display: 'flex', alignItems: 'center', gap: '0.5rem',
                              color: 'var(--primary-color)', fontSize: '0.85rem', fontWeight: 600
                            }}>
                              <AlertCircle size={14} /> {rowError}
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>

          <div style={{ marginTop: '2rem', textAlign: 'right' }}>
            <button
              className="btn btn-primary"
              onClick={handleSave}
              disabled={loading}
              title={!allFilled ? 'Please fill in all required fields first' : ''}
            >
              <Save size={18} /> {loading ? 'Saving...' : 'Save All Results'}
            </button>
          </div>
        </div>
      )}

      {selectedStage && entries.length === 0 && (
        <div className="glass-panel" style={{ textAlign: 'center', color: 'var(--text-muted)' }}>
          No entries found for this stage yet. Please register racers first.
        </div>
      )}
    </div>
  );
}
