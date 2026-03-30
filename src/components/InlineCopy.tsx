"use client";
import { useState } from "react";
import { Check, Copy } from "lucide-react";

export function InlineCopy({ text }: { text: string }) {
  const [ok, setOk] = useState(false);
  const copy = () => { try { navigator.clipboard.writeText(text); } catch {} setOk(true); setTimeout(() => setOk(false), 2000); };
  return (
    <button onClick={copy} className="icon-btn" title="Copy">
      {ok ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
    </button>
  );
}
