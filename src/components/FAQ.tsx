"use client";
import { useState } from "react";
import { ChevronDown } from "lucide-react";

export function FAQ({ items }: { items: { question: string; answer: string }[] }) {
  const [open, setOpen] = useState<number | null>(null);
  return (
    <div className="space-y-2">
      {items.map((item, i) => (
        <div key={i} className="faq-item">
          <button onClick={() => setOpen(open === i ? null : i)} className="faq-q">
            <span className="pr-4">{item.question}</span>
            <ChevronDown className={`w-4 h-4 text-zinc-600 shrink-0 transition-transform duration-200 ${open === i ? "rotate-180" : ""}`} />
          </button>
          <div className="faq-a" style={{ maxHeight: open === i ? "400px" : "0" }}>
            <div className="faq-a-inner">{item.answer}</div>
          </div>
        </div>
      ))}
    </div>
  );
}
