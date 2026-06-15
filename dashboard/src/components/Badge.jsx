import './Badge.css';

export default function Badge({ text, variant = 'default' }) {
  return <span className={`badge badge--${variant}`}>{text}</span>;
}
