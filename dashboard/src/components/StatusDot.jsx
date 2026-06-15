import './StatusDot.css';

export default function StatusDot({ status = 'unknown', size = 10 }) {
  return (
    <span
      className={`status-dot status-dot--${status}`}
      style={{ width: size, height: size }}
      title={status}
    />
  );
}
