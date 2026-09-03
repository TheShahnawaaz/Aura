"use client";

import React from "react";
import { Sparkles, Terminal, ShieldCheck, KeyRound, Cpu, Sliders, Music, Zap, Layers, Lock, ShieldAlert } from "lucide-react";
import { LivingOrbCanvas } from "../hero/LivingOrbCanvas";

export const BentoGrid: React.FC = () => {
  return (
    <section id="features" className="py-28 px-4 max-w-6xl mx-auto w-full">
      {/* Refined Section Header */}
      <div className="max-w-2xl mb-16">
        <span className="text-xs font-mono uppercase tracking-widest text-cyan-400 font-semibold block mb-2">
          Engineering & Craft
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.03em] text-white leading-tight">
          Built for the Mac. <br />
          <span className="text-slate-500">Not ported from the web.</span>
        </h2>
      </div>

      {/* Modern High-End Bento Grid */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {/* CARD 1: Double Width - Hardware Notch HUD */}
        <div className="md:col-span-2 rounded-[24px] p-8 sm:p-10 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.14] transition-all flex flex-col justify-between relative overflow-hidden group">
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

          {/* Micro Visual Architecture of the Notch */}
          <div className="mt-10 pt-6 border-t border-white/[0.06] flex flex-wrap items-center justify-between gap-4 z-10">
            <div className="flex items-center gap-2.5">
              <span className="w-2 h-2 rounded-full bg-cyan-400" />
              <span className="text-xs font-mono text-slate-300">
                Pixel-perfect flush (<code className="text-cyan-300">screenFrame.maxY - panelHeight</code>)
              </span>
            </div>
            <span className="text-xs font-mono text-slate-400 bg-white/[0.04] border border-white/[0.08] px-3 py-1 rounded-full">
              SwiftUI + AppKit NSPanel
            </span>
          </div>
        </div>

        {/* CARD 2: 4 Living Aurora Orb Archetypes */}
        <div className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.14] transition-all flex flex-col justify-between group">
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
            <div className="flex flex-col items-center gap-1.5">
              <LivingOrbCanvas state="idle" size={28} />
              <span className="text-[9px] font-mono text-slate-500">Idle</span>
            </div>
            <div className="flex flex-col items-center gap-1.5">
              <LivingOrbCanvas state="listening" size={28} />
              <span className="text-[9px] font-mono text-cyan-400">Listen</span>
            </div>
            <div className="flex flex-col items-center gap-1.5">
              <LivingOrbCanvas state="processing" size={28} />
              <span className="text-[9px] font-mono text-purple-400">Think</span>
            </div>
            <div className="flex flex-col items-center gap-1.5">
              <LivingOrbCanvas state="speaking" size={28} />
              <span className="text-[9px] font-mono text-rose-400">Speak</span>
            </div>
          </div>
        </div>

        {/* CARD 3: Autonomous Desktop Execution */}
        <div className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.14] transition-all flex flex-col justify-between group">
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
            <div className="px-3 py-1.5 rounded-lg bg-black/40 border border-white/[0.05] text-slate-300 flex items-center justify-between">
              <span>open_application</span>
              <span className="text-cyan-400">AppKit</span>
            </div>
            <div className="px-3 py-1.5 rounded-lg bg-black/40 border border-white/[0.05] text-slate-300 flex items-center justify-between">
              <span>adjust_volume</span>
              <span className="text-cyan-400">CoreAudio</span>
            </div>
            <div className="px-3 py-1.5 rounded-lg bg-black/40 border border-white/[0.05] text-slate-300 flex items-center justify-between">
              <span>take_screenshot</span>
              <span className="text-cyan-400">CoreGraphics</span>
            </div>
          </div>
        </div>

        {/* CARD 4: Proactive Safety Guardrails */}
        <div className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.14] transition-all flex flex-col justify-between group">
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

          <div className="mt-6 p-3 rounded-xl bg-rose-950/20 border border-rose-500/20 flex items-center gap-2.5 text-xs text-rose-300 font-mono">
            <ShieldAlert className="w-4 h-4 text-rose-400 shrink-0" />
            <span>Destructive scripts require manual confirmation</span>
          </div>
        </div>

        {/* CARD 5: Privacy-First macOS Keychain */}
        <div className="rounded-[24px] p-8 bg-[#0c0e14] border border-white/[0.07] hover:border-white/[0.14] transition-all flex flex-col justify-between group">
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
            <Lock className="w-3.5 h-3.5 text-emerald-400" />
            <span>Encrypted locally in Keychain Vault</span>
          </div>
        </div>
      </div>
    </section>
  );
};
