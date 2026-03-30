"use client";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { CodeBlock } from "@/components/CodeBlock";
import { FAQ } from "@/components/FAQ";
import { InlineCopy } from "@/components/InlineCopy";
import { Check, Monitor, HardDrive, Shield, Terminal, AlertCircle, Zap, ArrowRight } from "lucide-react";
import Link from "next/link";

const steps = [
  { n: "01", t: "Install Server Stack", d: "SSH into your fresh Ubuntu 22.04/24.04 server and run the command below. Installs NGINX with FlashXPRESS FastCGI Cache, MariaDB 11.4, PHP 8.4 (fallback 8.3/8.2/8.1), Redis, WP-CLI, Certbot, UFW, Fail2Ban, and fx CLI.", c: "bash <(curl -sSL https://wp.flashxpress.cloud/install.sh)" },
  { n: "02", t: "Create WordPress + Cache", d: "Creates a fully configured WordPress site. Downloads WordPress, creates MariaDB database, configures NGINX with FastCGI Cache, sets up Redis Object Cache, and creates optimized server block.", c: "fx site create example.com" },
  { n: "03", t: "Install Free SSL", d: "Secures your site with Let's Encrypt SSL. Generates HTTPS config with HSTS headers, HTTP-to-HTTPS redirect, preserves all cache settings. Auto-renews via cron.", c: "fx ssl install example.com" },
];

const reqs = [
  { icon: Monitor, l: "Ubuntu 22.04 / 24.04 LTS", d: "64-bit clean installation" },
  { icon: HardDrive, l: "1 GB RAM minimum", d: "2 GB+ recommended" },
  { icon: Shield, l: "Root SSH access", d: "sudo or direct root" },
  { icon: Zap, l: "Clean server", d: "No existing web server" },
];

const postCmds = [
  { c: "fx status", d: "Check all service statuses" },
  { c: "fx site create yourdomain.com", d: "Create WordPress site" },
  { c: "fx ssl install yourdomain.com", d: "Install SSL certificate" },
  { c: "fx cache clear", d: "Clear FastCGI cache" },
  { c: "fx cache status", d: "Cache size & files" },
  { c: "fx php version", d: "Check PHP version" },
  { c: "fx backup create yourdomain.com", d: "Full site backup" },
  { c: "fx help", d: "All commands" },
];

const faq = [
  { question: "What if the installation fails?", answer: "Check your server meets requirements (Ubuntu 22.04/24.04, 1GB+ RAM, root access). Ensure no other web server is running. Run fx status to check services." },
  { question: "Can I install on an existing server?", answer: "FlashXpress is designed for fresh servers. Existing web services (Apache, MySQL) may cause conflicts. Use a clean server." },
  { question: "How do I update FlashXpress?", answer: "Run fx update. It preserves your site configurations and data." },
  { question: "Does it support multiple PHP versions?", answer: "Yes! PHP 8.4 default with fallback to 8.3/8.2/8.1. Switch with fx php switch 8.3." },
  { question: "How to verify FastCGI cache?", answer: "Run curl -I https://yourdomain.com. First visit shows FlashXpress MISS, subsequent shows FlashXpress HIT." },
  { question: "How to renew SSL certificates?", answer: "Auto-renews via Certbot cron. Manual: fx ssl renew yourdomain.com." },
];

export default function InstallPage() {
  return (
    <div className="min-h-screen flex flex-col bg-black">
      <Navbar />
      <main className="flex-1 pt-28 pb-12">

        {/* Header */}
        <div className="max-w-2xl mx-auto px-5 sm:px-6 text-center mb-12">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full border border-zinc-800 bg-zinc-950 mb-6">
            <Zap className="w-3.5 h-3.5 text-indigo-400" />
            <span className="text-[12px] font-medium text-zinc-500">Installation Guide</span>
          </div>
          <h1 className="text-3xl sm:text-4xl font-extrabold text-white mb-4"><span className="grad">3 Steps</span> to WordPress</h1>
          <p className="text-sm text-zinc-500">Server ready, WordPress live, SSL secured — under 5 minutes.</p>
        </div>

        {/* Quick Install */}
        <div className="max-w-2xl mx-auto px-5 sm:px-6 mb-14">
          <CodeBlock code="bash <(curl -sSL https://wp.flashxpress.cloud/install.sh)" />
          <div className="mt-4 flex flex-wrap items-center justify-center gap-5 text-xs text-zinc-600">
            <span className="flex items-center gap-1.5"><Check className="w-3.5 h-3.5 text-emerald-500" />All components</span>
            <span className="flex items-center gap-1.5"><Check className="w-3.5 h-3.5 text-emerald-500" />Auto-configure NGINX</span>
            <span className="flex items-center gap-1.5"><Check className="w-3.5 h-3.5 text-emerald-500" />Firewall setup</span>
          </div>
        </div>

        {/* Requirements */}
        <div className="border-t border-zinc-800/50 py-14">
          <div className="max-w-3xl mx-auto px-5 sm:px-6">
            <h2 className="text-xl font-bold text-white text-center mb-8">System Requirements</h2>
            <div className="grid sm:grid-cols-2 gap-3">
              {reqs.map((r, i) => (
                <div key={i} className="card p-5 flex items-start gap-4">
                  <div className="w-10 h-10 rounded-xl bg-indigo-500/10 flex items-center justify-center shrink-0"><r.icon className="w-5 h-5 text-indigo-400" /></div>
                  <div><div className="text-sm font-medium text-white">{r.l}</div><div className="text-xs text-zinc-600 mt-0.5">{r.d}</div></div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Steps Timeline */}
        <div className="py-14">
          <div className="max-w-3xl mx-auto px-5 sm:px-6">
            <h2 className="text-xl sm:text-2xl font-bold text-white text-center mb-10">Step-by-Step Guide</h2>
            <div className="space-y-6">
              {steps.map((s, i) => (
                <div key={i} className="flex gap-4 sm:gap-5">
                  <div className="flex flex-col items-center shrink-0">
                    <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-600 to-indigo-500 flex items-center justify-center text-white font-bold text-xs">{s.n}</div>
                    {i < steps.length - 1 && <div className="w-px flex-1 bg-zinc-800 mt-2" />}
                  </div>
                  <div className="pb-2 flex-1 min-w-0">
                    <h3 className="text-base font-semibold text-white mb-2">{s.t}</h3>
                    <p className="text-sm text-zinc-500 leading-relaxed mb-4">{s.d}</p>
                    <CodeBlock code={s.c} />
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Verify Cache */}
        <div className="border-t border-zinc-800/50 py-14">
          <div className="max-w-2xl mx-auto px-5 sm:px-6">
            <h2 className="text-xl font-bold text-white text-center mb-2">Verify <span className="grad">FastCGI Cache</span></h2>
            <p className="text-sm text-zinc-500 text-center mb-8">After all 3 steps, verify caching is working.</p>
            <div className="card p-6 space-y-4">
              <p className="text-sm text-zinc-500">Run this command:</p>
              <CodeBlock code="curl -I https://yourdomain.com" />
              <p className="text-sm text-zinc-500">You should see:</p>
              <div className="bg-emerald-500/10 border border-emerald-500/20 rounded-lg px-5 py-3 font-mono text-sm">
                <span className="text-zinc-500">X-Cache: </span><span className="text-emerald-400 font-bold">FlashXpress HIT</span>
              </div>
              <p className="text-xs text-zinc-600">First: <span className="cmd">FlashXpress MISS</span> or <span className="cmd">FlashXpress BYPASS</span>. Refresh → <span className="cmd !text-emerald-400 !bg-emerald-400/10 !border-emerald-400/20">FlashXpress HIT</span></p>
            </div>
          </div>
        </div>

        {/* Post-Install */}
        <div className="py-14">
          <div className="max-w-3xl mx-auto px-5 sm:px-6">
            <h2 className="text-xl font-bold text-white text-center mb-8">Post-Installation Commands</h2>
            <div className="grid sm:grid-cols-2 gap-3">
              {postCmds.map((x, i) => (
                <div key={i} className="card p-4 flex items-center justify-between gap-3">
                  <div className="min-w-0"><code className="text-sm font-mono text-cyan-400 block">{x.c}</code><p className="text-xs text-zinc-600 mt-1">{x.d}</p></div>
                  <InlineCopy text={x.c} />
                </div>
              ))}
            </div>
          </div>
        </div>

        {/* Troubleshooting */}
        <div className="border-t border-zinc-800/50 py-14" id="troubleshooting">
          <div className="max-w-2xl mx-auto px-5 sm:px-6">
            <div className="text-center mb-8">
              <AlertCircle className="w-6 h-6 text-indigo-400 mx-auto mb-3" />
              <h2 className="text-xl font-bold text-white mb-2">Troubleshooting</h2>
              <p className="text-sm text-zinc-500">Common questions and solutions.</p>
            </div>
            <FAQ items={faq} />
          </div>
        </div>

        {/* CTA */}
        <div className="py-14">
          <div className="max-w-2xl mx-auto px-5 sm:px-6 text-center">
            <h2 className="text-xl font-bold text-white mb-3">Explore <span className="grad">CLI Commands</span></h2>
            <p className="text-sm text-zinc-500 mb-6">45+ powerful commands for complete WordPress stack management.</p>
            <Link href="/commands" className="btn-p"><Terminal className="w-4 h-4" /> View CLI Reference <ArrowRight className="w-4 h-4" /></Link>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
