import GlassCard from '../components/GlassCard';
import Badge from '../components/Badge';
import { ARCH_LAYERS } from '../config';
import './ArchitecturePanel.css';

export default function ArchitecturePanel() {
  return (
    <GlassCard hoverable={false}>
      <div className="panel-header">
        <h2 className="panel-title"><span>🏗️</span> Architecture</h2>
        <Badge text="v8.2-local" variant="default" />
      </div>
      <div className="panel-body">
        <div className="arch-flow">
          {ARCH_LAYERS.map((layer, i) => (
            <div key={layer.label}>
              <div className="arch-layer">
                <div className="arch-layer-label">{layer.icon} {layer.label}</div>
                <div className="arch-layer-nodes">
                  {layer.nodes.map(node => (
                    <span className="arch-node" key={node}>{node}</span>
                  ))}
                </div>
              </div>
              {i < ARCH_LAYERS.length - 1 && <div className="arch-arrow">↓</div>}
            </div>
          ))}
        </div>
      </div>
    </GlassCard>
  );
}
