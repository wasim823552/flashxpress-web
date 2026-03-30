"use client";
import Link from "next/link";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { CodeBlock } from "@/components/CodeBlock";
import { AnimatedCounter } from "@/components/AnimatedCounter";
import { Zap, Server, Database, Code2, Shield, Globe, Terminal, Cpu, ArrowRight, ExternalLink, Check, Star } from "lucide-react";

const features = [
  { icon: Server, title: "NGINX + FastCGI Cache", desc: "Pre-configured NGINX with FlashXPRESS FastCGI Cache. X-Cache: FlashXpress HIT on every cached response.", c: "#6366f1" },
  { icon: Database, title: "MariaDB 11.4", desc: "Latest MariaDB with optimized WordPress configuration and enhanced security.", c: "#06b6d4" },
  { icon: Code2, title: "PHP 8.4", desc: "Latest PHP 8.4 with smart fallback to 8.3/8.2/8.1. JIT and OPCache enabled.", c: "#8b5cf6" },
  { icon: Cpu, title: "Redis Object Cache", desc: "In-memory Redis cache for WordPress objects, reducing DB queries by 80%.", c: "#ec4899" },
  { icon: Globe, title: "Free SSL / HTTPS", desc: "Automated Let's Encrypt SSL with HTTP→HTTPS redirect, HSTS, auto-renewal.", c: "#10b981" },
  { icon: Shield, title: "UFW + Fail2Ban", desc: "Enterprise-grade security with UFW firewall and Fail2Ban intrusion prevention.", c: "#f59e0b" },
  { icon: Terminal, title: "WP-CLI + fx CLI", desc: "Full WP-CLI integration plus 45+ custom fx commands for stack management.", c: "#3b82f6" },
  { icon: Zap, title: "3-Command Deploy", desc: "Install stack, create site, add SSL — 3 commands. Under 5 minutes to live.", c: "#ef4444" },
];

export default function HomePage() {
  return (
    <div className="min-h-screen flex flex-col bg-black">
      <Navbar />

      {/* ===== HERO ===== */}
      <section className="pt-32 sm:pt-40 lg:pt-48 pb-20 sm:pb-28">
        <div className="max-w-4xl mx-auto px-5 sm:px-6 text-center">
          {/* Badge */}
          <div className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-zinc-800 bg-zinc-950 mb-8">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-[13px] font-medium text-zinc-500">v3.2.0 — PHP 8.4 + MariaDB 11.4</span>
          </div>

          {/* Heading */}
          <h1 className="text-4xl sm:text-5xl lg:text-[3.5rem] font-extrabold text-white tracking-tight leading-[1.1] mb-6">
            Deploy WordPress<br /><span className="grad">in Minutes</span>
          </h1>

          {/* Sub */}
          <p className="text-base sm:text-lg text-zinc-500 max-w-2xl mx-auto mb-10">
            NGINX + FastCGI Cache + MariaDB 11.4 + PHP 8.4 + Redis — production-ready stack, one command.
          </p>

          {/* Command */}
          <div className="max-w-2xl mx-auto mb-10">
            <CodeBlock code="bash <(curl -sSL https://wp.flashxpress.cloud/install.sh)" />
          </div>

          {/* CTAs */}
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
            <Link href="/install" className="btn-p w-full sm:w-auto">Get Started <ArrowRight className="w-4 h-4" /></Link>
            <Link href="/commands" className="btn-g w-full sm:w-auto"><Terminal className="w-4 h-4" /> CLI Reference</Link>
          </div>
        </div>
      </section>

      {/* ===== STATS ===== */}
      <div className="border-t border-zinc-800/50" />
      <section className="py-16 sm:py-24">
        <div className="max-w-3xl mx-auto px-5 sm:px-6">
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-8 sm:gap-10">
            <AnimatedCounter target={10000} suffix="+" label="Servers Deployed" />
            <AnimatedCounter target={45} suffix="+" label="CLI Commands" />
            <AnimatedCounter target={99} suffix=".9%" label="Uptime" />
            <AnimatedCounter target={5} suffix=" min" label="Setup Time" />
          </div>
        </div>
      </section>

      {/* ===== 3 STEPS ===== */}
      <div className="border-t border-zinc-800/50" />
      <section className="py-16 sm:py-24">
        <div className="max-w-4xl mx-auto px-5 sm:px-6">
          <p className="text-[12px] font-semibold text-indigo-400 uppercase tracking-widest text-center mb-3">How It Works</p>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white text-center mb-3">
            <span className="grad">3 Commands.</span> Full Stack.
          </h2>
          <p className="text-sm text-zinc-500 text-center mb-12 max-w-md mx-auto">
            Deploy a complete, cached, SSL-secured WordPress site in under 5 minutes.
          </p>

          <div className="grid sm:grid-cols-3 gap-4 sm:gap-5">
            {[
              { n: "01", t: "Install Stack", d: "NGINX, MariaDB 11.4, PHP 8.4, Redis, WP-CLI, Certbot, UFW, Fail2Ban, fx CLI.", c: "bash <(curl -sSL https://wp.flashxpress.cloud/install.sh)", bg: "bg-indigo-600" },
              { n: "02", t: "Create WordPress + Cache", d: "WordPress with FastCGI Cache, Redis Object Cache, and optimized NGINX.", c: "fx site create example.com", bg: "bg-blue-600" },
              { n: "03", t: "Install SSL", d: "Free Let's Encrypt SSL with HTTP→HTTPS redirect and HSTS.", c: "fx ssl install example.com", bg: "bg-cyan-600" },
            ].map(s => (
              <div key={s.n} className="card p-6 flex flex-col">
                <div className={`w-10 h-10 rounded-xl ${s.bg} flex items-center justify-center text-white font-bold text-sm mb-5`}>{s.n}</div>
                <h3 className="text-[15px] font-semibold text-white mb-2">{s.t}</h3>
                <p className="text-sm text-zinc-500 leading-relaxed mb-5 flex-1">{s.d}</p>
                <div className="terminal !rounded-lg mt-auto"><div className="terminal-code !text-xs !py-3 !px-4">{s.c}</div></div>
              </div>
            ))}
          </div>

          {/* X-Cache badge */}
          <div className="mt-10 text-center">
            <div className="inline-flex flex-col items-center gap-1.5 bg-zinc-950 border border-zinc-800 rounded-2xl px-8 py-5">
              <p className="text-[10px] text-zinc-600 uppercase tracking-widest font-semibold">Response Header</p>
              <div className="font-mono text-sm sm:text-base">
                <span className="text-zinc-500">X-Cache: </span><span className="text-emerald-400 font-bold">FlashXpress HIT</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ===== FEATURES ===== */}
      <div className="border-t border-zinc-800/50" />
      <section className="py-16 sm:py-24">
        <div className="max-w-5xl mx-auto px-5 sm:px-6">
          <p className="text-[12px] font-semibold text-indigo-400 uppercase tracking-widest text-center mb-3">The Complete Stack</p>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white text-center mb-3">
            Everything for <span className="grad">Blazing WordPress</span>
          </h2>
          <p className="text-sm text-zinc-500 text-center mb-12 max-w-md mx-auto">
            Production-ready, tuned for performance, security, and reliability.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {features.map(f => (
              <div key={f.title} className="card p-5 group">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-4 group-hover:scale-110 transition-transform" style={{ backgroundColor: `${f.c}12` }}>
                  <f.icon className="w-5 h-5" style={{ color: f.c }} />
                </div>
                <h3 className="text-sm font-semibold text-white mb-1.5">{f.title}</h3>
                <p className="text-[13px] text-zinc-500 leading-relaxed">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== TERMINAL ===== */}
      <div className="border-t border-zinc-800/50" />
      <section className="py-16 sm:py-24">
        <div className="max-w-5xl mx-auto px-5 sm:px-6">
          <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-center">
            <div>
              <p className="text-[12px] font-semibold text-indigo-400 uppercase tracking-widest mb-3">Why FlashXpress?</p>
              <h2 className="text-3xl sm:text-4xl font-extrabold text-white leading-[1.15] mb-5">
                One Command. <span className="grad">Full Stack.</span>
              </h2>
              <p className="text-sm text-zinc-500 leading-relaxed mb-8">
                No manual configs. No setup headaches. FlashXpress handles everything from server setup to SSL certificates.
              </p>
              <ul className="space-y-3 mb-10">
                {["NGINX with FlashXPRESS FastCGI Cache", "MariaDB 11.4 — secured & optimized", "PHP 8.4 with OPCache + JIT", "Redis Object Cache", "Let's Encrypt SSL — auto-renewal", "UFW + Fail2Ban security"].map((x, i) => (
                  <li key={i} className="flex items-center gap-3 text-sm text-zinc-400">
                    <div className="w-5 h-5 rounded-full bg-indigo-500/10 border border-indigo-500/20 flex items-center justify-center shrink-0"><Check className="w-3 h-3 text-indigo-400" /></div>{x}
                  </li>
                ))}
              </ul>
              <Link href="/install" className="btn-p"><Zap className="w-4 h-4" /> Installation Guide</Link>
            </div>
            <div>
              <div className="terminal !rounded-2xl">
                <div className="terminal-bar"><div className="terminal-left"><div className="terminal-dots"><div className="terminal-dot" style={{ background: "#ef4444" }} /><div className="terminal-dot" style={{ background: "#f59e0b" }} /><div className="terminal-dot" style={{ background: "#22c55e" }} /></div><span className="text-[11px] text-zinc-700 font-mono">root@server ~</span></div></div>
                <div className="terminal-code space-y-0.5">
                  <div><span className="text-indigo-400">$</span> <span className="text-zinc-300">fx status</span></div>
                  <div className="text-emerald-500/70">&#10003; NGINX .............. Running</div>
                  <div className="text-emerald-500/70">&#10003; MariaDB 11.4 ........ Running</div>
                  <div className="text-emerald-500/70">&#10003; PHP-FPM 8.4 ........ Running</div>
                  <div className="text-emerald-500/70">&#10003; Redis .............. Running</div>
                  <div className="text-emerald-500/70">&#10003; UFW ............... Active</div>
                  <div className="text-emerald-500/70">&#10003; Fail2Ban .......... Active</div>
                  <div className="mt-2"><span className="text-indigo-400">$</span> <span className="text-zinc-300">fx cache status</span></div>
                  <div className="text-zinc-600">Cache Size: 12.4 MB | Files: 3,241</div>
                  <div className="mt-2"><span className="text-indigo-400">$</span> <span className="text-zinc-300">fx version</span></div>
                  <div className="text-white">FlashXpress v3.2.0</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* ===== TESTIMONIALS ===== */}
      <div className="border-t border-zinc-800/50" />
      <section className="py-16 sm:py-24">
        <div className="max-w-5xl mx-auto px-5 sm:px-6">
          <p className="text-[12px] font-semibold text-indigo-400 uppercase tracking-widest text-center mb-3">Testimonials</p>
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white text-center mb-12">Loved by <span className="grad">Developers</span></h2>
          <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {[
              { n: "Alex Chen", r: "WordPress Developer", t: "FlashXpress cut my server setup from 2 hours to 5 minutes. FastCGI cache is brilliant — sites load under 200ms." },
              { n: "Sarah Mitchell", r: "DevOps Engineer", t: "I manage 50+ WordPress sites. FlashXpress standardized our deployment. The fx CLI is intuitive." },
              { n: "Raj Patel", r: "Freelance Developer", t: "3-step workflow is perfect. Redis dropped my TTFB from 800ms to under 100ms." },
            ].map(x => (
              <div key={x.n} className="card p-6">
                <div className="flex gap-0.5 mb-4">{[...Array(5)].map((_, j) => <Star key={j} className="w-3.5 h-3.5 text-yellow-500 fill-yellow-500" />)}</div>
                <p className="text-sm text-zinc-400 leading-relaxed mb-5 italic">&ldquo;{x.t}&rdquo;</p>
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-full bg-gradient-to-br from-indigo-500 to-cyan-500 flex items-center justify-center text-white text-xs font-bold">{x.n[0]}</div>
                  <div><div className="text-sm font-medium text-white">{x.n}</div><div className="text-xs text-zinc-600">{x.r}</div></div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ===== CTA ===== */}
      <div className="border-t border-zinc-800/50" />
      <section className="py-16 sm:py-24">
        <div className="max-w-2xl mx-auto px-5 sm:px-6 text-center">
          <h2 className="text-3xl sm:text-4xl font-extrabold text-white mb-5">
            Ready to Deploy?<br /><span className="grad">Get Started Free.</span>
          </h2>
          <p className="text-sm text-zinc-500 mb-8 max-w-md mx-auto">
            No complex configurations — just one command and you&apos;re live.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
            <Link href="/install" className="btn-p w-full sm:w-auto"><Zap className="w-4 h-4" /> Install Now</Link>
            <a href="https://buymeacoffee.com/wasimb" target="_blank" rel="noopener noreferrer" className="btn-g w-full sm:w-auto">&#9749; Support <ExternalLink className="w-4 h-4" /></a>
          </div>
        </div>
      </section>

      <Footer />
    </div>
  );
}
