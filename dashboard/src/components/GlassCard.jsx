import './GlassCard.css';

export default function GlassCard({ children, className = '', hoverable = true, ...props }) {
  return (
    <div className={`glass-card ${hoverable ? 'glass-card--hoverable' : ''} ${className}`} {...props}>
      {children}
    </div>
  );
}
