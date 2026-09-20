"use client";

import React, { useRef } from "react";
import { motion, useInView } from "framer-motion";
import { Check, X } from "lucide-react";

interface MatrixRow {
  capability: string;
  aura: string | boolean;
  siri: string | boolean;
  raycast: string | boolean;
  chatgpt: string | boolean;
}

const matrixData: MatrixRow[] = [
  {
    capability: "Physical Interface",
    aura: "Fluid MacBook Notch HUD",
    siri: "Bottom screen overlay",
    raycast: "Spotlight search modal",
    chatgpt: "Floating window",
  },
  {
    capability: "Autonomous System Tools",
    aura: true,
    siri: "Limited Apple shortcuts",
    raycast: "User-invoked scripts",
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
    capability: "Instant Voice & Barge-In",
    aura: true,
    siri: "Fixed timeout",
    raycast: false,
    chatgpt: "Cloud voice modal",
  },
  {
    capability: "Spotify & Apple Music Ducking",
    aura: true,
    siri: "System audio pause",
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
    capability: "API Key Security & Storage",
    aura: "macOS Keychain Vault",
    siri: "Apple Account",
    raycast: "Cloud / Local Account",
    chatgpt: "Cloud Subscription",
  },
];

const rowVariants = {
  hidden: { opacity: 0, x: -20 },
  visible: (i: number) => ({
    opacity: 1,
    x: 0,
    transition: {
      delay: i * 0.08,
      type: "spring" as const,
      stiffness: 150,
      damping: 20,
    },
  }),
};

export const ComparisonMatrix: React.FC = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  const renderCell = (val: string | boolean, isAura = false) => {
    if (typeof val === "boolean") {
      return val ? (
        <div className="flex items-center justify-center">
          <motion.div
            className={`w-5 h-5 rounded-full flex items-center justify-center ${isAura ? "bg-cyan-500/20 text-cyan-300 border border-cyan-500/30" : "bg-emerald-500/20 text-emerald-300"}`}
            whileHover={{ scale: 1.2 }}
            animate={isAura ? { boxShadow: ["0 0 0px rgba(0,229,255,0)", "0 0 12px rgba(0,229,255,0.3)", "0 0 0px rgba(0,229,255,0)"] } : {}}
            transition={isAura ? { repeat: Infinity, duration: 3 } : {}}
          >
            <Check className="w-3.5 h-3.5" />
          </motion.div>
        </div>
      ) : (
        <div className="flex items-center justify-center">
          <div className="w-5 h-5 rounded-full bg-white/[0.04] text-slate-600 flex items-center justify-center">
            <X className="w-3 h-3" />
          </div>
        </div>
      );
    }
    return (
      <span className={`text-xs ${isAura ? "font-semibold text-cyan-300" : "text-slate-400"}`}>
        {val}
      </span>
    );
  };

  return (
    <section id="comparison" className="py-28 px-4 max-w-5xl mx-auto w-full" ref={ref}>
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        className="max-w-2xl mb-14"
      >
        <span className="text-xs font-mono uppercase tracking-widest text-cyan-400 font-semibold block mb-2">
          Competitive Analysis
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.03em] text-white leading-tight">
          A new paradigm for <br />
          <span className="text-slate-500">desktop AI.</span>
        </h2>
      </motion.div>

      {/* Modern Comparison Table */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6, delay: 0.2 }}
        className="overflow-x-auto rounded-[24px] bg-[#0c0e14] border border-white/[0.07] shadow-2xl"
      >
        <table className="w-full text-left border-collapse min-w-[620px]">
          <thead>
            <tr className="border-b border-white/[0.06] bg-black/40 text-[11px] uppercase font-mono tracking-wider text-slate-400">
              <th className="p-5 font-semibold">Capability</th>
              <th className="p-5 text-cyan-300 bg-cyan-950/30 border-x border-cyan-500/20 font-bold">
                \u26A1\uFE0F Aura
              </th>
              <th className="p-5 text-center font-normal">Apple Siri</th>
              <th className="p-5 text-center font-normal">Raycast</th>
              <th className="p-5 text-center font-normal">ChatGPT Desktop</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-white/[0.04] text-sm">
            {matrixData.map((row, idx) => (
              <motion.tr
                key={idx}
                custom={idx}
                variants={rowVariants}
                initial="hidden"
                animate={isInView ? "visible" : "hidden"}
                className="hover:bg-white/[0.02] transition-colors group"
              >
                <td className="p-5 font-medium text-slate-300 text-xs sm:text-sm group-hover:text-white transition-colors">
                  {row.capability}
                </td>
                <td className="p-5 bg-cyan-950/15 border-x border-cyan-500/20 text-center">
                  {renderCell(row.aura, true)}
                </td>
                <td className="p-5 text-center">{renderCell(row.siri)}</td>
                <td className="p-5 text-center">{renderCell(row.raycast)}</td>
                <td className="p-5 text-center">{renderCell(row.chatgpt)}</td>
              </motion.tr>
            ))}
          </tbody>
        </table>
      </motion.div>
    </section>
  );
};
