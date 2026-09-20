"use client";

import React, { useRef } from "react";
import { motion, useInView } from "framer-motion";
import { Check, Minus } from "lucide-react";

interface MatrixRow {
  capability: string;
  aura: string | boolean;
  siri: string | boolean;
  raycast: string | boolean;
  chatgpt: string | boolean;
}

const matrixData: MatrixRow[] = [
  {
    capability: "Physical Hardware Interface",
    aura: "MacBook Notch Concave HUD",
    siri: "Bottom screen bar",
    raycast: "Spotlight modal window",
    chatgpt: "Floating desktop app",
  },
  {
    capability: "Autonomous System Tools",
    aura: true,
    siri: "Limited Shortcuts",
    raycast: "Script commands",
    chatgpt: false,
  },
  {
    capability: "Model Context Protocol (MCP)",
    aura: true,
    siri: false,
    raycast: false,
    chatgpt: false,
  },
  {
    capability: "Sub-Second Voice & Barge-In",
    aura: true,
    siri: "Fixed timeout",
    raycast: false,
    chatgpt: "Voice modal",
  },
  {
    capability: "Dynamic Media Ducking (Spotify/Apple)",
    aura: true,
    siri: "Full audio pause",
    raycast: false,
    chatgpt: false,
  },
  {
    capability: "Destructive Shell Guardrails",
    aura: true,
    siri: false,
    raycast: false,
    chatgpt: false,
  },
  {
    capability: "Key Storage Security",
    aura: "macOS Keychain Vault",
    siri: "Apple Account",
    raycast: "Account Cloud",
    chatgpt: "Cloud Subscription",
  },
];

export const ComparisonMatrix: React.FC = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-80px" });

  const renderCell = (val: string | boolean, isAura = false) => {
    if (typeof val === "boolean") {
      return val ? (
        <div className="flex items-center justify-center">
          <div
            className={`w-5 h-5 rounded-full flex items-center justify-center ${
              isAura
                ? "bg-iris-500/20 text-iris-300 border border-iris-500/30"
                : "bg-white/[0.08] text-slate-300"
            }`}
          >
            <Check className="w-3 h-3" />
          </div>
        </div>
      ) : (
        <div className="flex items-center justify-center">
          <Minus className="w-3.5 h-3.5 text-slate-600" />
        </div>
      );
    }
    return (
      <span
        className={`text-xs ${
          isAura ? "font-semibold text-iris-300" : "text-slate-400"
        }`}
      >
        {val}
      </span>
    );
  };

  return (
    <section id="comparison" className="py-28 sm:py-36 px-4 max-w-5xl mx-auto w-full" ref={ref}>
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="max-w-2xl mb-14"
      >
        <span className="text-[11px] font-mono uppercase tracking-[0.2em] text-iris-400 font-semibold block mb-3">
          Architecture Comparison
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.035em] text-white leading-[1.1]">
          A new paradigm for <br />
          <span className="text-slate-500">desktop intelligence.</span>
        </h2>
      </motion.div>

      {/* Double-Bezel Table Architecture */}
      <div className="double-bezel-outer w-full overflow-hidden">
        <div className="double-bezel-inner overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[640px]">
            <thead>
              <tr className="border-b border-white/[0.06] bg-black/40 text-[11px] uppercase font-mono tracking-wider text-slate-400">
                <th className="p-4 sm:p-5 font-semibold">Capability</th>
                <th className="p-4 sm:p-5 text-iris-300 bg-iris-950/25 border-x border-iris-500/20 font-bold">
                  Aura
                </th>
                <th className="p-4 sm:p-5 text-center font-normal">Apple Siri</th>
                <th className="p-4 sm:p-5 text-center font-normal">Raycast</th>
                <th className="p-4 sm:p-5 text-center font-normal">ChatGPT</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04] text-sm">
              {matrixData.map((row, idx) => (
                <tr
                  key={idx}
                  className="hover:bg-white/[0.02] transition-colors"
                >
                  <td className="p-4 sm:p-5 font-medium text-slate-300 text-xs sm:text-sm">
                    {row.capability}
                  </td>
                  <td className="p-4 sm:p-5 bg-iris-950/15 border-x border-iris-500/20 text-center">
                    {renderCell(row.aura, true)}
                  </td>
                  <td className="p-4 sm:p-5 text-center">{renderCell(row.siri)}</td>
                  <td className="p-4 sm:p-5 text-center">{renderCell(row.raycast)}</td>
                  <td className="p-4 sm:p-5 text-center">{renderCell(row.chatgpt)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </section>
  );
};
