import GlassCard from '../components/GlassCard';
import Badge from '../components/Badge';
import { CREWS } from '../config';
import './CrewPanel.css';

export default function CrewPanel() {
  return (
    <GlassCard hoverable={false}>
      <div className="panel-header">
        <h2 className="panel-title"><span>🤖</span> Crew Reference</h2>
        <Badge text="READ ONLY" variant="default" />
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
            </div>
          ))}
        </div>
      </div>
    </GlassCard>
  );
}
