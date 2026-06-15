import StatusDot from '../components/StatusDot';
import Badge from '../components/Badge';
import './Header.css';

export default function Header({ status, isConnected, isLive }) {
  const statusLabel = isLive
    ? (status === 'healthy' ? 'All Systems Operational' : 'Degraded')
    : (isConnected ? 'Preview Mode' : 'Backend Offline');
  const dotStatus = isLive && status === 'healthy' ? 'healthy' : 'unhealthy';
  const badgeVariant = isLive ? 'default' : 'warn';
  const badgeText = isLive ? 'LIVE' : 'OFFLINE';

  return (
    <header className="header">
      <div className="header-brand">
        <span className="header-logo">M4ST</span>
        <div>
          <h1 className="header-title">M4ST COMMAND CENTER</h1>
          <p className="header-subtitle">Solo | Zero Budget | Full Control</p>
        </div>
      </div>
      <div className="header-meta">
        <Badge text="v8.2-local" variant="muted" />
        <Badge text={badgeText} variant={badgeVariant} />
        <div className="header-status">
          <StatusDot status={dotStatus} size={8} />
          <span className={`header-status-text header-status-text--${dotStatus}`}>{statusLabel}</span>
        </div>
      </div>
    </header>
  );
}
