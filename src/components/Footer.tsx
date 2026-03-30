import Link from "next/link";

const cols: Record<string, { label: string; href: string; ext?: boolean }[]> = {
  Product: [
    { label: "Home", href: "/" },
    { label: "Install", href: "/install" },
    { label: "Commands", href: "/commands" },
    { label: "Changelog", href: "/about#changelog" },
  ],
  Resources: [
    { label: "Docs", href: "/install" },
    { label: "CLI Reference", href: "/commands" },
    { label: "Troubleshoot", href: "/install#troubleshooting" },
    { label: "Support", href: "/support" },
  ],
  Community: [
    { label: "Buy Me a Coffee", href: "https://buymeacoffee.com/wasimb", ext: true },
    { label: "Website", href: "https://wp.flashxpress.cloud", ext: true },
  ],
};

export function Footer() {
  return (
    <footer className="mt-auto border-t border-zinc-800/50">
      <div className="max-w-5xl mx-auto px-5 sm:px-6 pt-16 pb-8">
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-8 lg:gap-8 mb-12">
          <div className="col-span-2">
            <Link href="/" className="inline-flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-md bg-indigo-600 flex items-center justify-center">
                <svg className="w-3.5 h-3.5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z"/></svg>
              </div>
              <span className="text-sm font-bold text-white">Flash<span className="grad">Xpress</span></span>
            </Link>
            <p className="text-sm text-zinc-600 leading-relaxed mb-4 max-w-xs">Lightning-fast WordPress stack installer. NGINX, MariaDB, PHP, Redis — one command.</p>
          </div>
          {Object.entries(cols).map(([cat, items]) => (
            <div key={cat}>
              <h4 className="text-[11px] font-semibold text-zinc-500 uppercase tracking-widest mb-4">{cat}</h4>
              <ul className="space-y-2.5">
                {items.map(link => (
                  <li key={link.label}>
                    {link.ext ? (
                      <a href={link.href} target="_blank" rel="noopener noreferrer" className="text-sm text-zinc-600 hover:text-zinc-300 transition-colors">{link.label}</a>
                    ) : (
                      <Link href={link.href} className="text-sm text-zinc-600 hover:text-zinc-300 transition-colors">{link.label}</Link>
                    )}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="pt-6 border-t border-zinc-800/50 flex flex-col sm:flex-row items-center justify-between gap-3">
          <p className="text-xs text-zinc-700">&copy; {new Date().getFullYear()} FlashXpress</p>
          <p className="text-xs text-zinc-700">Made with <span className="text-red-500/80">&#9829;</span> by <a href="https://buymeacoffee.com/wasimb" target="_blank" rel="noopener noreferrer" className="text-indigo-400 hover:text-indigo-300 transition-colors">Wasim Akram</a></p>
        </div>
      </div>
    </footer>
  );
}
