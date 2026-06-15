import './RamBar.css';

export default function RamBar({ used, total }) {
  const pct = total > 0 ? Math.round((used / total) * 100) : 0;
  const level = pct > 85 ? 'danger' : pct > 65 ? 'warning' : 'normal';

  return (
    <div className="ram-bar-wrap">
      <div className="ram-track">
        <div className={`ram-fill ram-fill--${level}`} style={{ width: `${pct}%` }} />
      </div>
      <div className="ram-labels">
        <span>{used.toFixed(1)} GB{pct > 0 ? '' : ' (est.)'}</span>
        <span>{total} GB</span>
      </div>
    </div>
  );
}
