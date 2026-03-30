"use client";
import { useState, useMemo } from "react";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { InlineCopy } from "@/components/InlineCopy";
import { Search, Globe, Shield, Database, Cpu, Terminal, HardDrive, Key, Server, ChevronDown, ChevronRight } from "lucide-react";

interface Cmd { command: string; description: string; usage?: string }
interface Cat { name: string; icon: React.ElementType; color: string; commands: Cmd[] }

const data: Cat[] = [
  { name: "Site Management", icon: Globe, color: "#3b82f6", commands: [
    { command: "fx site create <domain>", description: "Create a new WordPress site with NGINX, database, and FastCGI cache.", usage: "fx site create example.com" },
    { command: "fx site delete <domain>", description: "Delete a WordPress site, database, and all configs.", usage: "fx site delete example.com" },
    { command: "fx site list", description: "List all WordPress sites with status." },
    { command: "fx site info <domain>", description: "Show paths, SSL, cache stats, disk usage.", usage: "fx site info example.com" },
  ]},
  { name: "SSL / HTTPS", icon: Shield, color: "#10b981", commands: [
    { command: "fx ssl install <domain>", description: "Install Let's Encrypt SSL with HTTPS redirect and HSTS.", usage: "fx ssl install example.com" },
    { command: "fx ssl renew <domain>", description: "Renew SSL certificate.", usage: "fx ssl renew example.com" },
    { command: "fx ssl remove <domain>", description: "Remove SSL and revert to HTTP.", usage: "fx ssl remove example.com" },
  ]},
  { name: "Authentication", icon: Key, color: "#8b5cf6", commands: [
    { command: "fx auth on <domain>", description: "Enable HTTP Basic Auth for wp-login.php.", usage: "fx auth on example.com" },
    { command: "fx auth off <domain>", description: "Disable HTTP Basic Auth.", usage: "fx auth off example.com" },
    { command: "fx auth add <domain> <user>", description: "Add Basic Auth user.", usage: "fx auth add example.com admin" },
    { command: "fx auth remove <domain> <user>", description: "Remove an auth user.", usage: "fx auth remove example.com admin" },
  ]},
  { name: "Database", icon: Database, color: "#06b6d4", commands: [
    { command: "fx db password <domain>", description: "Change DB password and update wp-config.php.", usage: "fx db password example.com" },
    { command: "fx db create <name>", description: "Create database with random password.", usage: "fx db create mydb" },
    { command: "fx db delete <name>", description: "Delete database and user.", usage: "fx db delete mydb" },
    { command: "fx db list", description: "List all databases with sizes." },
    { command: "fx db export <db>", description: "Export database to SQL.gz.", usage: "fx db export example_com" },
    { command: "fx db import <db> <file>", description: "Import SQL file into database.", usage: "fx db import example_com backup.sql" },
  ]},
  { name: "Cache", icon: Cpu, color: "#f97316", commands: [
    { command: "fx cache clear", description: "Clear NGINX FastCGI cache." },
    { command: "fx cache status", description: "Show cache size, file count, hit/miss stats." },
  ]},
  { name: "PHP Management", icon: Terminal, color: "#6366f1", commands: [
    { command: "fx php version", description: "Display current PHP version." },
    { command: "fx php list", description: "List installed PHP versions." },
    { command: "fx php switch <ver>", description: "Switch PHP version. Updates all configs.", usage: "fx php switch 8.3" },
    { command: "fx php restart", description: "Restart PHP-FPM." },
  ]},
  { name: "Backup", icon: HardDrive, color: "#ef4444", commands: [
    { command: "fx backup create <domain>", description: "Full backup: files + database.", usage: "fx backup create example.com" },
    { command: "fx backup list", description: "List backups with sizes and dates." },
    { command: "fx backup restore <file>", description: "Restore from backup.", usage: "fx backup restore file.tar.gz" },
  ]},
  { name: "Tools", icon: Server, color: "#eab308", commands: [
    { command: "fx pma install", description: "Install phpMyAdmin on port 8080." },
    { command: "fx pma remove", description: "Remove phpMyAdmin." },
    { command: "fx adminer install", description: "Install Adminer on port 8081." },
    { command: "fx adminer remove", description: "Remove Adminer." },
    { command: "fx files install", description: "Install TinyFileManager." },
    { command: "fx files remove", description: "Remove File Manager." },
  ]},
  { name: "System", icon: Server, color: "#71717a", commands: [
    { command: "fx status", description: "Status of all services." },
    { command: "fx version", description: "Display FlashXpress version." },
    { command: "fx update", description: "Update to latest version." },
    { command: "fx help", description: "Show all commands." },
  ]},
];

export default function CommandsPage() {
  const [search, setSearch] = useState("");
  const [expanded, setExpanded] = useState<Set<string>>(new Set(data.map(c => c.name)));
  const toggle = (n: string) => setExpanded(p => { const s = new Set(p); if (s.has(n)) s.delete(n); else s.add(n); return s; });
  const filtered = useMemo(() => {
    if (!search.trim()) return data;
    const q = search.toLowerCase();
    return data.map(c => ({ ...c, commands: c.commands.filter(cmd => cmd.command.toLowerCase().includes(q) || cmd.description.toLowerCase().includes(q)) })).filter(c => c.commands.length > 0);
  }, [search]);
  const total = data.reduce((a, c) => a + c.commands.length, 0);

  return (
    <div className="min-h-screen flex flex-col bg-black">
      <Navbar />
      <main className="flex-1 pt-28 pb-12">
        <div className="max-w-3xl mx-auto px-5 sm:px-6">
          <div className="text-center mb-8">
            <h1 className="text-3xl sm:text-4xl font-extrabold text-white mb-3"><span className="grad">CLI Reference</span></h1>
            <p className="text-sm text-zinc-500">{total} commands across {data.length} categories.</p>
          </div>

          {/* Search */}
          <div className="sticky top-16 z-40 -mx-5 sm:-mx-6 px-5 sm:px-6 py-3 bg-black/90 backdrop-blur-xl border-b border-zinc-800/50 mb-6">
            <div className="relative">
              <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-zinc-600" />
              <input type="text" placeholder="Search commands..." value={search} onChange={e => setSearch(e.target.value)}
                className="w-full pl-10 pr-4 py-2.5 bg-zinc-950 border border-zinc-800 rounded-lg text-sm text-white placeholder:text-zinc-600 focus:outline-none focus:border-indigo-500/40 transition-colors" />
            </div>
          </div>

          {/* Categories */}
          <div className="space-y-2">
            {filtered.length === 0 ? (
              <div className="text-center py-16"><p className="text-zinc-600">No commands found for &ldquo;{search}&rdquo;</p></div>
            ) : filtered.map(cat => {
              const open = expanded.has(cat.name);
              return (
                <div key={cat.name} className="card !p-0 !rounded-xl overflow-hidden">
                  <button onClick={() => toggle(cat.name)} className="w-full flex items-center justify-between p-4 sm:p-5 text-left hover:bg-zinc-900/50 transition-colors">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className="w-8 h-8 rounded-lg flex items-center justify-center shrink-0" style={{ backgroundColor: `${cat.color}15` }}><cat.icon className="w-4 h-4" style={{ color: cat.color }} /></div>
                      <div><h2 className="text-sm font-semibold text-white truncate">{cat.name}</h2><p className="text-xs text-zinc-600">{cat.commands.length} command{cat.commands.length !== 1 ? "s" : ""}</p></div>
                    </div>
                    {open ? <ChevronDown className="w-4 h-4 text-zinc-600 shrink-0" /> : <ChevronRight className="w-4 h-4 text-zinc-600 shrink-0" />}
                  </button>
                  <div className={`overflow-hidden transition-all duration-300 ${open ? "max-h-[3000px]" : "max-h-0"}`}>
                    <div className="border-t border-zinc-800/50 divide-y divide-zinc-800/30">
                      {cat.commands.map((cmd, i) => (
                        <div key={i} className="px-4 sm:px-5 py-3.5 flex items-start justify-between gap-3">
                          <div className="flex-1 min-w-0">
                            <code className="text-sm font-mono text-cyan-400 block">{cmd.command}</code>
                            <p className="text-xs sm:text-sm text-zinc-500 mt-1 leading-relaxed">{cmd.description}</p>
                            {cmd.usage && <code className="text-[11px] font-mono text-zinc-600 bg-zinc-900 px-2 py-0.5 rounded-md inline-block mt-2">{cmd.usage}</code>}
                          </div>
                          <InlineCopy text={cmd.command} />
                        </div>
                      ))}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
