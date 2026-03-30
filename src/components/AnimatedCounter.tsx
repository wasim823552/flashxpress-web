"use client";
import { useEffect, useRef, useState } from "react";

export function AnimatedCounter({ target, suffix = "", label }: { target: number; suffix?: string; label: string }) {
  const [n, setN] = useState(0);
  const ref = useRef<HTMLDivElement>(null);
  const done = useRef(false);
  useEffect(() => {
    const el = ref.current; if (!el) return;
    const obs = new IntersectionObserver(([e]) => {
      if (e.isIntersecting && !done.current) {
        done.current = true;
        const t0 = performance.now();
        const tick = (t: number) => { const p = Math.min((t - t0) / 1800, 1); setN(Math.floor((1 - (1-p)**3) * target)); if (p < 1) requestAnimationFrame(tick); };
        requestAnimationFrame(tick);
      }
    }, { threshold: 0.3 });
    obs.observe(el);
    return () => obs.disconnect();
  }, [target]);
  return (
    <div ref={ref} className="text-center">
      <div className="text-3xl sm:text-4xl font-bold text-white mb-1">{n.toLocaleString()}<span className="grad">{suffix}</span></div>
      <div className="text-sm text-zinc-600">{label}</div>
    </div>
  );
}
