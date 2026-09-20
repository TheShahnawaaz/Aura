"use client";

import React, { useRef } from "react";
import { motion, useInView } from "framer-motion";
import { Terminal, ShieldCheck, Cpu, Sliders, Music, Lock, ShieldAlert, Sparkles, Layers } from "lucide-react";
import { LivingOrbCanvas } from "../hero/LivingOrbCanvas";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.1,
      delayChildren: 0.15,
    },
  },
};

const cardVariants = {
  hidden: { opacity: 0, y: 30 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.7,
      ease: [0.16, 1, 0.3, 1],
    },
  },
};

export const BentoGrid: React.FC = () => {
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="features" className="py-28 sm:py-36 px-4 max-w-6xl mx-auto w-full" ref={ref}>
      {/* Section Header */}
      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="max-w-2xl mb-16"
      >
        <span className="text-[11px] font-mono uppercase tracking-[0.2em] text-iris-400 font-semibold block mb-3">
          Architecture & Hardware Craft
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.035em] text-white leading-[1.1]">
          Engineered for the Mac. <br />
          <span className="text-slate-500">Not ported from the web.</span>
        </h2>
      </motion.div>

      {/* High-End Double-Bezel Bento Grid */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate={isInView ? "visible" : "hidden"}
        className="grid grid-cols-1 md:grid-cols-3 gap-6"
      >
        {/* CARD 1: Double Width - Hardware Notch HUD */}
        <motion.div
          variants={cardVariants}
          className="md:col-span-2 card-bezel-outer flex flex-col justify-between"
        >
          <div className="card-bezel-inner p-7 sm:p-9 h-full flex flex-col justify-between">
            <div className="space-y-3 max-w-lg">
              <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                Hardware Geometry
              </span>
              <h3 className="text-2xl font-bold text-white tracking-tight">
                Concave MacBook Notch HUD
              </h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Curves gracefully around the camera bezel with 6pt concave reverse fillets.
                It auto-expands with native spring physics to present live tool statuses, transcription,
                and outputs without stealing active window focus.
              </p>
            </div>

            <div className="mt-8 pt-5 border-t border-white/[0.06] flex flex-wrap items-center justify-between gap-4">
              <div className="flex items-center gap-2">
                <span className="w-2 h-2 rounded-full bg-emerald-400" />
                <span className="text-xs font-mono text-slate-300">
                  Sub-pixel alignment (<code className="text-iris-300">screenFrame.maxY - panelHeight</code>)
                </span>
              </div>
              <span className="text-[11px] font-mono text-slate-400 bg-white/[0.04] border border-white/[0.08] px-3 py-1 rounded-full">
                SwiftUI + AppKit NSPanel
              </span>
            </div>
          </div>
        </motion.div>

        {/* CARD 2: Living Aurora Orb */}
        <motion.div
          variants={cardVariants}
          className="card-bezel-outer flex flex-col justify-between"
        >
          <div className="card-bezel-inner p-7 h-full flex flex-col justify-between">
            <div className="space-y-2.5">
              <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                Dynamic Presence
              </span>
              <h3 className="text-xl font-bold text-white tracking-tight">
                Living Aurora Orb
              </h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                4 reactive visual states rendered with GPU particle shaders, reacting live to speech RMS and model reasoning.
              </p>
            </div>

            <div className="mt-6 grid grid-cols-4 gap-2 p-3 rounded-xl bg-black/40 border border-white/[0.05]">
              {(["idle", "listening", "processing", "speaking"] as const).map((state) => (
                <div key={state} className="flex flex-col items-center gap-1.5">
                  <LivingOrbCanvas state={state} size={24} />
                  <span className="text-[9.5px] font-mono text-slate-400 capitalize">
                    {state === "processing" ? "Think" : state}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </motion.div>

        {/* CARD 3: Native System Tools */}
        <motion.div
          variants={cardVariants}
          className="card-bezel-outer flex flex-col justify-between"
        >
          <div className="card-bezel-inner p-7 h-full flex flex-col justify-between">
            <div className="space-y-2.5">
              <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                Autonomous Execution
              </span>
              <h3 className="text-xl font-bold text-white tracking-tight">
                Native System Tools
              </h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Controls your Mac directly. Dispatches shell commands, adjusts volume, launches applications, and queries files in milliseconds.
              </p>
            </div>

            <div className="mt-6 space-y-1.5 font-mono text-[11px]">
              {[
                { name: "open_application", framework: "AppKit" },
                { name: "adjust_volume", framework: "CoreAudio" },
                { name: "take_screenshot", framework: "CoreGraphics" },
              ].map((tool) => (
                <div
                  key={tool.name}
                  className="px-3 py-1.5 rounded-lg bg-black/40 border border-white/[0.05] text-slate-300 flex items-center justify-between"
                >
                  <span>{tool.name}</span>
                  <span className="text-iris-400 text-[10px]">{tool.framework}</span>
                </div>
              ))}
            </div>
          </div>
        </motion.div>

        {/* CARD 4: Proactive Safety Guardrails */}
        <motion.div
          variants={cardVariants}
          className="card-bezel-outer flex flex-col justify-between"
        >
          <div className="card-bezel-inner p-7 h-full flex flex-col justify-between">
            <div className="space-y-2.5">
              <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                Deterministic Security
              </span>
              <h3 className="text-xl font-bold text-white tracking-tight">
                Safety Guardrails
              </h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                AST token classification halts destructive commands like <code className="text-rose-400 font-mono text-xs">rm -rf</code> or <code className="text-rose-400 font-mono text-xs">sudo</code> before any terminal execution occurs.
              </p>
            </div>

            <div className="mt-6 p-3 rounded-xl bg-rose-950/20 border border-rose-500/20 flex items-center gap-2.5 text-xs text-rose-300 font-mono">
              <ShieldAlert className="w-4 h-4 text-rose-400 shrink-0" />
              <span>Blocks destructive system modifications</span>
            </div>
          </div>
        </motion.div>

        {/* CARD 5: Privacy-First macOS Keychain */}
        <motion.div
          variants={cardVariants}
          className="card-bezel-outer flex flex-col justify-between"
        >
          <div className="card-bezel-inner p-7 h-full flex flex-col justify-between">
            <div className="space-y-2.5">
              <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                Zero Cloud Storage
              </span>
              <h3 className="text-xl font-bold text-white tracking-tight">
                Keychain Vault
              </h3>
              <p className="text-sm text-slate-400 leading-relaxed">
                Bring your own API keys for Google Gemini or OpenAI. Credentials are saved locally into the macOS Keychain with hardware Secure Enclave isolation.
              </p>
            </div>

            <div className="mt-6 flex items-center gap-2 text-xs font-mono text-slate-400">
              <Lock className="w-3.5 h-3.5 text-emerald-400" />
              <span>Hardware Secure Enclave Isolation</span>
            </div>
          </div>
        </motion.div>
      </motion.div>
    </section>
  );
};
