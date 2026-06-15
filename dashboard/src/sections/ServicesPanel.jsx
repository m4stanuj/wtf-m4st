import GlassCard from '../components/GlassCard';
import StatusDot from '../components/StatusDot';
import Badge from '../components/Badge';
import { SERVICES } from '../config';
import './ServicesPanel.css';

export default function ServicesPanel({ services }) {
  const badgeVariant = !services ? 'muted' : Object.values(services).every(s => s === 'healthy') ? 'default' : 'warn';
  const badgeText = !services ? 'CHECKING' : Object.values(services).every(s => s === 'healthy') ? 'ALL HEALTHY' : 'DEGRADED';

  return (
    <GlassCard hoverable={false}>
      <div className="panel-header">
        <h2 className="panel-title"><span>📡</span> Service Health</h2>
        <Badge text={badgeText} variant={badgeVariant} />
      </div>
      <div className="panel-body">
        <div className="service-grid">
          {SERVICES.map(svc => {
            const status = services?.[svc.key] || 'unknown';
            return (
              <div className="service-item" key={svc.id} title={svc.description}>
                <StatusDot status={status} />
                <div className="service-info">
                  <div className="service-name">{svc.name}</div>
                  <div className="service-port">:{svc.port}</div>
                </div>
                <span className={`service-status-label service-status-label--${status}`}>
                  {status.toUpperCase()}
                </span>
                {svc.url && (
                  <a className="service-link" href={svc.url} target="_blank" rel="noopener noreferrer" title={`Open ${svc.name}`}>↗</a>
                )}
              </div>
            );
          })}
        </div>
      </div>
    </GlassCard>
  );
}
