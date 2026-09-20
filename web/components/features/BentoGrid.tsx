"use client";

import React, { useRef } from "react";
import { motion, useInView } from "framer-motion";
import { Sparkles, Terminal, ShieldCheck, KeyRound, Cpu, Sliders, Music, Zap, Layers, Lock, ShieldAlert } from "lucide-react";
import { LivingOrbCanvas } from "../hero/LivingOrbCanvas";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.2,
    },
  },
};

const cardVariants = {
  hidden: { opacity: 0, y: 40, scale: 0.95 },
  visible: {
    opacity: 1,
    y: 0,
    scale: 1,
    transition: {
      type: "spring",
      stiffness: 100,
      damping: 20,
    },
  },
};

export const BentoGrid: React.FC = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="features" className="py-28 px-4 max-w-6xl mx-auto w-full" ref={ref}>
      {/* Refined Section Header */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        className="max-w-2xl mb-16"
      >
        <span className="text-xs font-mono uppercase tracking-widest text-cyan-400 font-semibold block mb-2">
          Engineering & Craft
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.03em] text-white leading-tight">
          Built for the Mac. <br />
          <span className="text-slate-500">Not ported from the web.</span>
        </h2>
      </motion.div>

      {/* Modern High-End Bento Grid */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate={isInView ? "visible" : "hidden"}
        className="grid grid-cols-1 md:grid-cols-3 gap-5"
      >
        {/* CARD 1: Double Width - Hardware Notch HUD */}
        <motion.div
          variants={cardVariants}
          whileHover={{ y: -4, transition: { type: "spring", stiffness: 300, damping: 20 } }}
          className="md:col-span-2 rounded-[24px] p-8 sm:p-10 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.18] transition-all flex flex-col justify-between relative overflow-hidden group card-shine"
        >
          {/* Hover glow */}
          <div className="absolute -top-20 -right-20 w-[300px] h-[300px] rounded-full bg-cyan-500/[0.04] blur-[80px] opacity-0 group-hover:opacity-100 transition-opacity duration-700 pointer-events-none" />
          
          <div className="space-y-3 max-w-lg z-10">
            <span className="text-[11px] font-mono uppercase text-slate-500 font-semibold">
              Interface Innovation
            </span>
            <h3 className="text-2xl font-bold text-white tracking-tight">
              Fluid MacBook Notch HUD
            </h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Wraps around the physical camera bezel with smooth 6pt concave reverse fillets. It auto-expands with spring physics to present live response cards, tool statuses, and transcription without stealing window focus.
            </p>
          </div>

          <div className="mt-10 pt-6 border-t border-white/[0.06] flex flex-wrap items-center justify-between gap-4 z-10">
            <div className="flex items-center gap-2.5">
              <motion.span
                className="w-2 h-2 rounded-full bg-cyan-400"
                animate={{ scale: [1, 1.3, 1] }}
                transition={{ repeat: Infinity, duration: 2 }}
              />
              <span className="text-xs font-mono text-slate-300">
                Pixel-perfect flush (<code className="text-cyan-300">screenFrame.maxY - panelHeight</code>)
              </span>
            </div>
            <span className="text-xs font-mono text-slate-400 bg-white/[0.04] border border-white/[0.08] px-3 py-1 rounded-full">
              SwiftUI + AppKit NSPanel
            </span>
          </div>
        </motion.div>

        {/* CARD 2: Living Aurora Orb Archetypes */}
        <motion.div
          variants={cardVariants}
          whileHover={{ y: -4, transition: { type: "spring", stiffness: 300, damping: 20 } }}
          className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.18] transition-all flex flex-col justify-between group card-shine"
        >
          <div className="space-y-3">
            <span className="text-[11px] font-mono uppercase text-slate-500 font-semibold">
              Tactile Visual Feedback
            </span>
            <h3 className="text-xl font-bold text-white tracking-tight">
              Living Aurora Orb
            </h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Four distinct visual archetypes designed with specular glass glares and Fresnel caustics that react live to voice RMS and reasoning.
            </p>
          </div>

          <div className="mt-8 flex items-center justify-between p-3.5 rounded-2xl bg-black/40 border border-white/[0.05]">
            {(["idle", "listening", "processing", "speaking"] as const).map((state, i) => (
              <motion.div
                key={state}
                className="flex flex-col items-center gap-1.5"
                initial={{ opacity: 0, scale: 0.8 }}
                animate={isInView ? { opacity: 1, scale: 1 } : {}}
                transition={{ delay: 0.4 + i * 0.15, type: "spring" }}
              >
                <LivingOrbCanvas state={state} size={28} />
                <span className={`text-[9px] font-mono ${
                  state === "idle" ? "text-slate-500" :
                  state === "listening" ? "text-cyan-400" :
                  state === "processing" ? "text-purple-400" : "text-rose-400"
                }`}>
                  {state === "idle" ? "Idle" : state === "listening" ? "Listen" : state === "processing" ? "Think" : "Speak"}
                </span>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* CARD 3: Autonomous Desktop Execution */}
        <motion.div
          variants={cardVariants}
          whileHover={{ y: -4, transition: { type: "spring", stiffness: 300, damping: 20 } }}
          className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.18] transition-all flex flex-col justify-between group card-shine"
        >
          <div className="space-y-3">
            <span className="text-[11px] font-mono uppercase text-slate-500 font-semibold">
              Autonomous Runtime
            </span>
            <h3 className="text-xl font-bold text-white tracking-tight">
              Native System Tools
            </h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Controls your Mac directly. Dispatches shell scripts, adjusts speaker volume, launches applications, and queries files in milliseconds.
            </p>
          </div>

          <div className="mt-6 space-y-1.5 font-mono text-[11px]">
            {["open_application", "adjust_volume", "take_screenshot"].map((tool, i) => (
              <motion.div
                key={tool}
                initial={{ opacity: 0, x: -20 }}
                animate={isInView ? { opacity: 1, x: 0 } : {}}
                transition={{ delay: 0.5 + i * 0.1, type: "spring" }}
                className="px-3 py-1.5 rounded-lg bg-black/40 border border-white/[0.05] text-slate-300 flex items-center justify-between hover:border-cyan-500/20 hover:bg-cyan-950/10 transition-colors"
              >
                <span>{tool}</span>
                <span className="text-cyan-400">
                  {tool === "open_application" ? "AppKit" : tool === "adjust_volume" ? "CoreAudio" : "CoreGraphics"}
                </span>
              </motion.div>
            ))}
          </div>
        </motion.div>

        {/* CARD 4: Proactive Safety Guardrails */}
        <motion.div
          variants={cardVariants}
          whileHover={{ y: -4, transition: { type: "spring", stiffness: 300, damping: 20 } }}
          className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.18] transition-all flex flex-col justify-between group card-shine"
        >
          <div className="space-y-3">
            <span className="text-[11px] font-mono uppercase text-slate-500 font-semibold">
              Security by Default
            </span>
            <h3 className="text-xl font-bold text-white tracking-tight">
              Safety Guardrails
            </h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Proactive classification blocks destructive operations like <code className="text-rose-400 font-mono text-xs">rm -rf</code> or <code className="text-rose-400 font-mono text-xs">sudo</code> before any shell execution occurs.
            </p>
          </div>

          <motion.div
            whileHover={{ scale: 1.02 }}
            className="mt-6 p-3 rounded-xl bg-rose-950/20 border border-rose-500/20 flex items-center gap-2.5 text-xs text-rose-300 font-mono"
          >
            <ShieldAlert className="w-4 h-4 text-rose-400 shrink-0" />
            <span>Destructive scripts require manual confirmation</span>
          </motion.div>
        </motion.div>

        {/* CARD 5: Privacy-First macOS Keychain */}
        <motion.div
          variants={cardVariants}
          whileHover={{ y: -4, transition: { type: "spring", stiffness: 300, damping: 20 } }}
          className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.18] transition-all flex flex-col justify-between group card-shine"
        >
          <div className="space-y-3">
            <span className="text-[11px] font-mono uppercase text-slate-500 font-semibold">
              Zero Telemetry
            </span>
            <h3 className="text-xl font-bold text-white tracking-tight">
              Keychain Encrypted
            </h3>
            <p className="text-sm text-slate-400 leading-relaxed">
              Bring your own API keys for Google Gemini or OpenAI. Credentials are saved directly into the macOS Keychain with hardware Secure Enclave isolation.
            </p>
          </div>

          <div className="mt-6 flex items-center gap-2 text-xs font-mono text-slate-400">
            <motion.div
              animate={{ rotate: [0, 5, -5, 0] }}
              transition={{ repeat: Infinity, duration: 3, ease: "easeInOut" }}
            >
              <Lock className="w-3.5 h-3.5 text-emerald-400" />
            </motion.div>
            <span>Encrypted locally in Keychain Vault</span>
          </div>
        </motion.div>
      </motion.div>
    </section>
  );
};
