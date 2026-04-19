import React, { useState, useEffect } from 'react';
import { Routes, Route, NavLink } from 'react-router-dom';
import { Flag, Timer, Trophy, Users, Sun, Moon, Monitor } from 'lucide-react';
import RegisterRacing from './pages/RegisterRacing';
import UpdateResults from './pages/UpdateResults';
import DriverStandings from './pages/DriverStandings';
import TeamStandings from './pages/TeamStandings';

function App() {
  const [theme, setTheme] = useState(localStorage.getItem('f1-theme') || 'default');

  useEffect(() => {
    document.documentElement.setAttribute('data-theme', theme);
    localStorage.setItem('f1-theme', theme);
  }, [theme]);
  return (
    <div className="app-container">
      {/* Sidebar Navigation */}
      <aside className="sidebar">
        <div className="brand brand-font">
          <Flag className="highlight" size={28} />
          <span>F1<span className="highlight">2026</span></span>
        </div>
        
        <nav className="nav-links">
          <NavLink to="/register" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
            <Users size={20} /> Register Team
          </NavLink>
          <NavLink to="/results" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
            <Timer size={20} /> Update Results
          </NavLink>
          <NavLink to="/standings/driver" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
            <Trophy size={20} /> Driver Standings
          </NavLink>
          <NavLink to="/standings/team" className={({isActive}) => `nav-link ${isActive ? 'active' : ''}`}>
            <Trophy size={20} /> Team Standings
          </NavLink>
        </nav>

        {/* Theme Switcher */}
        <div className="theme-switcher">
          <div className="theme-switcher-title">Theme Mode</div>
          <button className={`theme-btn ${theme === 'default' ? 'active' : ''}`} onClick={() => setTheme('default')}>
            <Monitor size={16} /> Default
          </button>
          <button className={`theme-btn ${theme === 'light' ? 'active' : ''}`} onClick={() => setTheme('light')}>
            <Sun size={16} /> Light
          </button>
          <button className={`theme-btn ${theme === 'dark' ? 'active' : ''}`} onClick={() => setTheme('dark')}>
            <Moon size={16} /> Dark
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="main-content">
        <Routes>
          <Route path="/" element={<DriverStandings />} />
          <Route path="/register" element={<RegisterRacing />} />
          <Route path="/results" element={<UpdateResults />} />
          <Route path="/standings/driver" element={<DriverStandings />} />
          <Route path="/standings/team" element={<TeamStandings />} />
        </Routes>
      </main>
    </div>
  );
}

export default App;
