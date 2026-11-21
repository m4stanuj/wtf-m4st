import GlassCard from '../components/GlassCard';
import RamBar from '../components/RamBar';
import { SERVICES, CREWS } from '../config';
import './StatsRow.css';

export default function StatsRow({ healthyCount, ram, totalRuns }) {
  return (
    <div className="stats-row">
      <GlassCard className="stat-card stat-card--green">
        <div className="stat-icon">⚡</div>
        <div className="stat-value">{healthyCount}<span className="stat-unit">/{SERVICES.length}</span></div>
        <div className="stat-label">Services Online</div>
      </GlassCard>

      <GlassCard className="stat-card stat-card--amber">
        <div className="stat-icon">🧠</div>
        <div className="stat-value">{ram.offline ? '—' : <>{ram.usedGb.toFixed(1)}<span className="stat-unit">GB</span></>}</div>
        <div className="stat-label">RAM Usage</div>
        {!ram.offline && <RamBar used={ram.usedGb} total={ram.totalGb} />}
      </GlassCard>

      <GlassCard className="stat-card stat-card--blue">
        <div className="stat-icon">🤖</div>
        <div className="stat-value">{CREWS.length}</div>
        <div className="stat-label">Crews in Reference</div>
      </GlassCard>

      <GlassCard className="stat-card stat-card--purple">
        <div className="stat-icon">📊</div>
        <div className="stat-value">{totalRuns || '—'}</div>
        <div className="stat-label">Recent Log Entries</div>
      </GlassCard>
    </div>
  );
}
