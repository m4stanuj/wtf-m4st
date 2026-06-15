import './Button.css';

export default function Button({
  children,
  variant = 'default',
  size = 'md',
  loading = false,
  disabled = false,
  fullWidth = false,
  as: Tag = 'button',
  ...props
}) {
  return (
    <Tag
      className={`btn btn--${variant} btn--${size} ${fullWidth ? 'btn--full' : ''}`}
      disabled={disabled || loading}
      {...props}
    >
      {loading && <span className="btn-spinner" />}
      {children}
    </Tag>
  );
}
