import GlassCard from '../components/GlassCard';
import Button from '../components/Button';
import './QuickActions.css';

export default function QuickActions({ onRefresh, onTestMemory }) {
  return (
    <GlassCard hoverable={false}>
      <div className="panel-header">
        <h2 className="panel-title"><span>⚡</span> Quick Actions</h2>
      </div>
      <div className="panel-body">
        <div className="quick-grid">
          <Button onClick={onRefresh}>🔄 Refresh Status</Button>
          <Button as="a" href="http://localhost:20128/dashboard" target="_blank" rel="noopener noreferrer">🔀 9Router</Button>
          <Button as="a" href="http://localhost:3000" target="_blank" rel="noopener noreferrer">📊 Langfuse</Button>
          <Button as="a" href="http://localhost:3002" target="_blank" rel="noopener noreferrer">🟢 Uptime Kuma</Button>
          <Button as="a" href="http://localhost:3001" target="_blank" rel="noopener noreferrer">🐾 OpenClaw</Button>
          <Button onClick={onTestMemory}>🧠 Test Memory</Button>
        </div>
      </div>
    </GlassCard>
  );
}
