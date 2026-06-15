import GlassCard from '../components/GlassCard';
import Badge from '../components/Badge';
import Button from '../components/Button';
import { CREWS } from '../config';
import './CrewPanel.css';

export default function CrewPanel({ onRunCrew, onRunAll, runningCrews }) {
  return (
    <GlassCard hoverable={false}>
      <div className="panel-header">
        <h2 className="panel-title"><span>🤖</span> Crew Control</h2>
        <Badge text="READY" variant="default" />
      </div>
      <div className="panel-body">
        <div className="crew-list">
          {CREWS.map(crew => (
            <div className="crew-card" key={crew.id}>
              <div className="crew-card-info">
                <div className="crew-card-icon" style={{ background: crew.colorGlow }}>{crew.icon}</div>
                <div>
                  <div className="crew-card-name">{crew.name}</div>
                  <div className="crew-card-agents">
                    {crew.agents.map((a, i) => (
                      <span key={a.role}>
                        {i > 0 && <span className="crew-arrow">→</span>}
                        <span className={`crew-agent crew-agent--${a.llm}`}>{a.role}</span>
                      </span>
                    ))}
                  </div>
                  <div className="crew-card-schedule">⏰ {crew.schedule}</div>
                </div>
              </div>
              <div className="crew-card-actions">
                <Button
                  variant="primary" size="sm"
                  loading={runningCrews[crew.file]}
                  onClick={() => onRunCrew(crew.file, false)}
                >▶ Run</Button>
                <Button
                  size="sm"
                  loading={runningCrews[crew.file]}
                  onClick={() => onRunCrew(crew.file, true)}
                >🧪 Dry</Button>
              </div>
            </div>
          ))}
        </div>
        <Button variant="primary" fullWidth onClick={() => onRunAll(true)} style={{ marginTop: '1rem' }}>
          🧪 Dry Run All Crews
        </Button>
      </div>
    </GlassCard>
  );
}
