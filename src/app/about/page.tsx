import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { Server, Database, Shield, Cpu, Globe, Terminal, Zap, Code2 } from "lucide-react";

const stack = [
  { icon: Server, name: "NGINX", detail: "FlashXPRESS FastCGI Cache, HTTP/2, gzip", color: "#6366f1" },
  { icon: Database, name: "MariaDB 11.4", detail: "Optimized WordPress database", color: "#06b6d4" },
  { icon: Code2, name: "PHP 8.4", detail: "OPCache, JIT, smart version fallback", color: "#8b5cf6" },
  { icon: Cpu, name: "Redis", detail: "In-memory cache (256MB LRU)", color: "#ef4444" },
  { icon: Globe, name: "Certbot", detail: "Let's Encrypt SSL auto-renewal", color: "#10b981" },
  { icon: Shield, name: "UFW + Fail2Ban", detail: "Firewall + intrusion prevention", color: "#f59e0b" },
  { icon: Terminal, name: "WP-CLI", detail: "WordPress CLI management", color: "#3b82f6" },
  { icon: Zap, name: "fx CLI", detail: "45+ stack management commands", color: "#ec4899" },
];

const changelog = [
  { v: "3.2.0", d: "2025", c: ["PHP 8.4 with 8.3/8.2/8.1 fallback", "MariaDB 11.4 support", "3-step deploy workflow", "X-Cache: FlashXpress HIT header"] },
  { v: "3.1.0", d: "2025", c: ["Redis Object Cache", "Improved NGINX config", "Security headers"] },
  { v: "3.0.0", d: "2025", c: ["Complete rewrite with fx CLI", "45+ commands", "New install architecture"] },
  { v: "2.0.0", d: "2024", c: ["WordPress Multisite", "phpMyAdmin + Adminer", "File Manager"] },
  { v: "1.0.0", d: "2024", c: ["Initial release", "NGINX + MariaDB + PHP", "Basic SSL"] },
];

export default function AboutPage() {
  return (
    <div className="min-h-screen flex flex-col bg-black">
      <Navbar />
      <main className="flex-1 pt-28 pb-12">
        <div className="max-w-2xl mx-auto px-5 sm:px-6 text-center mb-12">
          <h1 className="text-3xl sm:text-4xl font-extrabold text-white mb-4">About <span className="grad">FlashXpress</span></h1>
          <p className="text-sm text-zinc-500 max-w-lg mx-auto leading-relaxed">A professional WordPress stack installer for speed, simplicity, and reliability. Deploy a complete, cached, SSL-secured WordPress site with just 3 commands.</p>
        </div>

        <div className="border-t border-zinc-800/50 py-14">
          <div className="max-w-2xl mx-auto px-5 sm:px-6">
            <div className="card p-6 sm:p-8">
              <h2 className="text-lg font-bold text-white mb-4">Our Mission</h2>
              <p className="text-sm text-zinc-500 leading-relaxed mb-4">FlashXpress was born out of frustration with the complex, error-prone process of setting up a high-performance WordPress server. Every tutorial uses different configs, every guide has outdated instructions, and every manual setup introduces subtle bugs.</p>
              <p className="text-sm text-zinc-500 leading-relaxed">We built FlashXpress to eliminate all of that. One command installs the entire stack. One command creates a WordPress site with FastCGI caching and Redis object cache. One command adds free SSL. No decision fatigue. No config hunting. No wasted hours.</p>
            </div>
          </div>
        </div>

        <div className="border-t border-zinc-800/50 py-14">
          <div className="max-w-4xl mx-auto px-5 sm:px-6">
            <h2 className="text-2xl sm:text-3xl font-bold text-white text-center mb-10">The <span className="grad">Complete Stack</span></h2>
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {stack.map(s => (
                <div key={s.name} className="card p-5">
                  <div className="w-9 h-9 rounded-lg flex items-center justify-center mb-3" style={{ backgroundColor: `${s.color}12` }}><s.icon className="w-[18px] h-[18px]" style={{ color: s.color }} /></div>
                  <h3 className="text-sm font-semibold text-white mb-1">{s.name}</h3>
                  <p className="text-xs text-zinc-600 leading-relaxed">{s.detail}</p>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="py-14">
          <div className="max-w-2xl mx-auto px-5 sm:px-6" id="changelog">
            <h2 className="text-2xl sm:text-3xl font-bold text-white text-center mb-10">Version <span className="grad">History</span></h2>
            <div className="space-y-3">
              {changelog.map(c => (
                <div key={c.v} className="card p-5">
                  <div className="flex items-center gap-3 mb-3">
                    <span className="text-sm font-bold text-white">v{c.v}</span>
                    <span className="text-[11px] px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-400 font-medium">{c.d}</span>
                  </div>
                  <ul className="space-y-1.5">{c.c.map((x, j) => <li key={j} className="flex items-start gap-2 text-sm text-zinc-500"><span className="text-emerald-500 mt-0.5 shrink-0">&#8226;</span>{x}</li>)}</ul>
                </div>
              ))}
            </div>
          </div>
        </div>

        <div className="border-t border-zinc-800/50 py-14">
          <div className="max-w-2xl mx-auto px-5 sm:px-6 text-center">
            <div className="w-16 h-16 rounded-full bg-gradient-to-br from-indigo-500 to-cyan-500 flex items-center justify-center text-white text-xl font-bold mx-auto mb-5">W</div>
            <h2 className="text-lg font-bold text-white mb-1">Wasim Akram</h2>
            <p className="text-sm text-zinc-500 mb-5">Creator & Maintainer</p>
            <a href="https://buymeacoffee.com/wasimb" target="_blank" rel="noopener noreferrer" className="btn-p">&#9749; Buy Me a Coffee</a>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
