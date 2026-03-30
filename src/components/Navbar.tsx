"use client";

import { useState } from "react";
import Link from "next/link";
import { Menu, X, Zap } from "lucide-react";

const nav = [
  { label: "Home", href: "/" },
  { label: "Install", href: "/install" },
  { label: "Commands", href: "/commands" },
  { label: "About", href: "/about" },
  { label: "Support", href: "/support" },
];

export function Navbar() {
  const [open, setOpen] = useState(false);
  return (
    <header className="fixed top-0 left-0 right-0 z-50 bg-black/80 backdrop-blur-xl border-b border-zinc-800/50">
      <div className="max-w-5xl mx-auto px-5 sm:px-6 flex items-center justify-between h-16">
        <Link href="/" className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center"><Zap className="w-4 h-4 text-white" strokeWidth={2.5} /></div>
          <span className="text-sm font-bold text-white">Flash<span className="grad">Xpress</span></span>
        </Link>

        <nav className="hidden md:flex items-center gap-1">
          {nav.map(l => (
            <Link key={l.href} href={l.href} className="px-3.5 py-2 text-[13px] font-medium text-zinc-500 hover:text-white rounded-lg hover:bg-zinc-800/40 transition-colors">{l.label}</Link>
          ))}
        </nav>

        <div className="hidden md:flex items-center gap-3">
          <a href="https://github.com" target="_blank" rel="noopener noreferrer" className="p-2 text-zinc-600 hover:text-zinc-300 rounded-lg hover:bg-zinc-800/40 transition-colors" aria-label="GitHub">
            <svg className="w-[18px] h-[18px]" viewBox="0 0 24 24" fill="currentColor"><path d="M12 0c-6.626 0-12 5.373-12 12 0 5.302 3.438 9.8 8.207 11.387.599.111.793-.261.793-.577v-2.234c-3.338.726-4.033-1.416-4.033-1.416-.546-1.387-1.333-1.756-1.333-1.756-1.089-.745.083-.729.083-.729 1.205.084 1.839 1.237 1.839 1.237 1.07 1.834 2.807 1.304 3.492.997.107-.775.418-1.305.762-1.604-2.665-.305-5.467-1.334-5.467-5.931 0-1.311.469-2.381 1.236-3.221-.124-.303-.535-1.524.117-3.176 0 0 1.008-.322 3.301 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.291-1.552 3.297-1.23 3.297-1.23.653 1.653.242 2.874.118 3.176.77.84 1.235 1.911 1.235 3.221 0 4.609-2.807 5.624-5.479 5.921.43.372.823 1.102.823 2.222v3.293c0 .319.192.694.801.576 4.765-1.589 8.199-6.086 8.199-11.386 0-6.627-5.373-12-12-12z"/></svg>
          </a>
          <Link href="/install" className="btn-p !py-2.5 !px-5 !text-[13px]">Deploy Now</Link>
        </div>

        <button onClick={() => setOpen(!open)} className="md:hidden p-2 text-zinc-400 hover:text-white transition-colors" aria-label="Menu">
          {open ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>
      </div>

      {open && (
        <div className="fixed inset-0 z-40 md:hidden">
          <div className="absolute inset-0 bg-black/60" onClick={() => setOpen(false)} />
          <nav className="absolute top-16 inset-x-0 bg-zinc-950 border-b border-zinc-800 p-4 space-y-1">
            {nav.map(l => (
              <Link key={l.href} href={l.href} onClick={() => setOpen(false)} className="block px-4 py-3 text-[15px] font-medium text-zinc-400 hover:text-white rounded-xl hover:bg-zinc-800/40 transition-colors">{l.label}</Link>
            ))}
            <div className="pt-3">
              <Link href="/install" onClick={() => setOpen(false)} className="btn-p w-full">Deploy Now</Link>
            </div>
          </nav>
        </div>
      )}
    </header>
  );
}
