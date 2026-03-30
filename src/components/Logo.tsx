export function FlashXpressLogo({ className = "h-8 w-8" }: { className?: string }) {
  return (
    <svg viewBox="0 0 64 64" fill="none" className={className}>
      <defs><linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#3b82f6" /><stop offset="100%" stopColor="#06b6d4" /></linearGradient></defs>
      <circle cx="32" cy="32" r="30" stroke="url(#bg)" strokeWidth="2.5" fill="none" />
      <path d="M36 8L18 34h12l-4 22 20-26H34l4-22z" fill="url(#bg)" />
    </svg>
  );
}
export function FlashXpressLogoDark({ className = "h-8 w-8" }: { className?: string }) {
  return (
    <svg viewBox="0 0 64 64" fill="none" className={className}>
      <defs><linearGradient id="bgd" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" stopColor="#60a5fa" /><stop offset="100%" stopColor="#22d3ee" /></linearGradient></defs>
      <circle cx="32" cy="32" r="30" stroke="url(#bgd)" strokeWidth="2" fill="none" opacity=".6" />
      <path d="M36 8L18 34h12l-4 22 20-26H34l4-22z" fill="url(#bgd)" />
    </svg>
  );
}
