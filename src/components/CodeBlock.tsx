"use client";
import { useState } from "react";
import { Check, Copy } from "lucide-react";

export function CodeBlock({ code }: { code: string }) {
  const [ok, setOk] = useState(false);
  const copy = () => { try { navigator.clipboard.writeText(code); } catch {} setOk(true); setTimeout(() => setOk(false), 2000); };
  return (
    <div className="terminal">
      <div className="terminal-bar">
        <div className="terminal-left">
          <div className="terminal-dots">
            <div className="terminal-dot" style={{ background: "#ef4444" }} />
            <div className="terminal-dot" style={{ background: "#f59e0b" }} />
            <div className="terminal-dot" style={{ background: "#22c55e" }} />
          </div>
          <span className="text-[11px] text-zinc-700 font-mono">bash</span>
        </div>
        <button onClick={copy} className="copy-btn">
          {ok ? <><Check className="w-3.5 h-3.5 text-emerald-500" /><span className="text-emerald-500">Copied</span></> : <><Copy className="w-3.5 h-3.5" /><span>Copy</span></>}
        </button>
      </div>
      <div className="terminal-code">{code}</div>
    </div>
  );
}
