"use client";
import { Navbar } from "@/components/Navbar";
import { Footer } from "@/components/Footer";
import { FAQ } from "@/components/FAQ";
import { ExternalLink, MessageCircle, BookOpen, Bug, Heart } from "lucide-react";

const faq = [
  { question: "How do I install FlashXpress?", answer: "Run bash <(curl -sSL https://wp.flashxpress.cloud/install.sh) on Ubuntu 22.04/24.04 as root. Then fx site create yourdomain.com and fx ssl install yourdomain.com." },
  { question: "Which PHP versions are supported?", answer: "PHP 8.4 default with fallback to 8.3, 8.2, 8.1. Switch with fx php switch 8.3." },
  { question: "How to create multiple sites?", answer: "fx site create domain1.com, fx site create domain2.com, etc. Each gets its own database, config, and SSL." },
  { question: "How to backup and restore?", answer: "fx backup create example.com creates tar.gz. Restore with fx backup restore file.tar.gz." },
  { question: "Is FlashXpress free?", answer: "Yes, 100% free and open source (MIT License)." },
  { question: "How to switch PHP versions?", answer: "fx php list to see versions, fx php switch 8.3 to switch. Updates all configs." },
  { question: "SSL certificate failed?", answer: "Ensure domain DNS points to server IP. DNS propagation can take up to 48 hours." },
  { question: "How to check FastCGI cache?", answer: "curl -I https://yourdomain.com — look for X-Cache header. MISS first, then HIT." },
];

const links = [
  { icon: BookOpen, label: "Installation Guide", desc: "Step-by-step setup", href: "/install" },
  { icon: MessageCircle, label: "CLI Reference", desc: "All 45+ fx commands", href: "/commands" },
  { icon: Bug, label: "Report a Bug", desc: "Open issue on GitHub", href: "https://github.com", ext: true },
  { icon: Heart, label: "Support the Project", desc: "Buy Me a Coffee", href: "https://buymeacoffee.com/wasimb", ext: true },
];

export default function SupportPage() {
  return (
    <div className="min-h-screen flex flex-col bg-black">
      <Navbar />
      <main className="flex-1 pt-28 pb-12">
        <div className="max-w-2xl mx-auto px-5 sm:px-6">
          <div className="text-center mb-12">
            <h1 className="text-3xl sm:text-4xl font-extrabold text-white mb-3"><span className="grad">Support</span> Center</h1>
            <p className="text-sm text-zinc-500 max-w-md mx-auto">Find answers, explore docs, or get in touch.</p>
          </div>

          <div className="grid sm:grid-cols-2 gap-3 mb-14">
            {links.map(l => (
              <a key={l.label} href={l.href} target={l.ext ? "_blank" : undefined} rel={l.ext ? "noopener noreferrer" : undefined} className="card p-5 flex items-start gap-4 group">
                <div className="w-10 h-10 rounded-xl bg-indigo-500/10 flex items-center justify-center shrink-0"><l.icon className="w-5 h-5 text-indigo-400" /></div>
                <div>
                  <div className="text-sm font-semibold text-white group-hover:text-indigo-400 transition-colors flex items-center gap-2">{l.label}{l.ext && <ExternalLink className="w-3 h-3 text-zinc-600" />}</div>
                  <p className="text-xs text-zinc-600 mt-1">{l.desc}</p>
                </div>
              </a>
            ))}
          </div>

          <div className="mb-14">
            <h2 className="text-2xl font-bold text-white text-center mb-8">Frequently Asked Questions</h2>
            <FAQ items={faq} />
          </div>

          <div className="card p-7 text-center">
            <h2 className="text-lg font-bold text-white mb-2">Still need help?</h2>
            <p className="text-sm text-zinc-500 mb-6">Support the project and get priority help.</p>
            <a href="https://buymeacoffee.com/wasimb" target="_blank" rel="noopener noreferrer" className="btn-p">&#9749; Buy Me a Coffee <ExternalLink className="w-4 h-4" /></a>
          </div>
        </div>
      </main>
      <Footer />
    </div>
  );
}
