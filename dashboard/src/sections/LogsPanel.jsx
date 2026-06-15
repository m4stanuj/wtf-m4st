import GlassCard from '../components/GlassCard';
import Button from '../components/Button';
import './LogsPanel.css';

const CREW_COLORS = { nightly: 'purple', content: 'info', bugfix: 'default' };

function formatTime(ts) {
  if (!ts) return '—';
  try {
    const d = new Date(ts);
    const now = new Date();
    const diffHrs = Math.floor((now - d) / 3600000);
    if (diffHrs < 1) return 'Just now';
    if (diffHrs < 24) return `${diffHrs}h ago`;
    const diffDays = Math.floor(diffHrs / 24);
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays}d ago`;
    return d.toLocaleDateString('en-IN', { day: '2-digit', month: 'short' });
  } catch { return ts; }
}

export default function LogsPanel({ logs, loading, onRefresh }) {
  const sorted = [...logs].reverse();

  return (
    <GlassCard hoverable={false}>
      <div className="panel-header">
        <h2 className="panel-title"><span>📋</span> Recent Logs</h2>
        <Button size="sm" onClick={onRefresh} loading={loading}>↻ Refresh</Button>
      </div>
      <div className="panel-body">
        {sorted.length === 0 ? (
          <div className="logs-empty">No logs yet — run a crew to generate logs.</div>
        ) : (
          <div className="logs-scroll">
            {sorted.map((log, i) => (
              <div className="log-row" key={i} style={{ animationDelay: `${i * 0.04}s` }}>
                <span className="log-time">{formatTime(log.timestamp)}</span>
                <span className={`log-crew log-crew--${CREW_COLORS[log.crew] || 'muted'}`}>{log.crew || '?'}</span>
                <span className={`log-mode ${log.mode === 'DRY RUN' ? 'log-mode--dry' : 'log-mode--live'}`}>{log.mode || ''}</span>
                <span className="log-result" title={log.result || log.output || ''}>
                  {(log.result || log.output || '—').substring(0, 120)}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>
    </GlassCard>
  );
}
