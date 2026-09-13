"use client";

import React from "react";
import { Apple, ArrowRight, Terminal } from "lucide-react";
import { NotchSimulator } from "./NotchSimulator";

export const HeroSection: React.FC = () => {
  return (
    <section id="notch" className="relative pt-36 pb-24 px-4 flex flex-col items-center justify-center overflow-hidden w-full">
      {/* Precision Radial Lighting */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-6xl h-[650px] bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-cyan-500/10 via-purple-500/5 to-transparent pointer-events-none" />

      {/* Hardware Architecture Pill */}
      <div className="inline-flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-[#11131a] border border-white/[0.08] text-xs font-medium text-slate-300 shadow-xl backdrop-blur-xl mb-7 hover:border-white/20 transition-colors">
        <span className="flex h-1.5 w-1.5 rounded-full bg-cyan-400" />
        <span className="text-white font-semibold">Aura 0.1.0 Public Beta</span>
        <span className="text-slate-600">/</span>
        <span className="text-slate-400">Engineered for Apple Silicon & macOS Sequoia</span>
      </div>

      {/* Main Headline */}
      <h1 className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-[-0.035em] text-center max-w-4xl text-white leading-[1.08] mb-6">
        The desktop intelligence <br className="hidden sm:inline" />
        <span className="bg-gradient-to-r from-slate-100 via-cyan-200 to-slate-400 bg-clip-text text-transparent">
          anchored at your notch.
        </span>
      </h1>

      {/* Subtitle */}
      <p className="text-base sm:text-lg md:text-xl text-slate-400 text-center max-w-2xl leading-relaxed mb-10 font-normal">
        Aura transforms the MacBook camera notch into an autonomous action center. Activated by voice, powered by OpenAgentSDK, and built purely in native Swift.
      </p>

      {/* CTA Row */}
      <div className="flex flex-wrap items-center justify-center gap-4 mb-20">
        <a
          href="#download"
          className="flex items-center gap-2.5 px-7 py-3.5 rounded-2xl bg-white text-black font-semibold text-sm shadow-[0_10px_30px_-5px_rgba(255,255,255,0.3)] hover:bg-slate-100 transition-all hover:scale-[1.02] active:scale-[0.98]"
        >
          <Apple className="w-4 h-4 fill-current" />
          <span>Download for macOS</span>
          <ArrowRight className="w-4 h-4 text-slate-500" />
        </a>

        <a
          href="https://github.com/TheShahnawaaz/Aura"
          target="_blank"
          rel="noreferrer"
          className="flex items-center gap-2 px-5 py-3.5 rounded-2xl bg-[#11131a] border border-white/[0.08] hover:border-white/20 text-slate-300 font-mono text-xs transition-all hover:bg-[#161822]"
        >
          <Terminal className="w-3.5 h-3.5 text-cyan-400" />
          <span>brew install --cask aura</span>
        </a>
      </div>

      {/* PHOTOREALISTIC MACBOOK PRO SIMULATOR */}
      <NotchSimulator />
    </section>
  );
};
