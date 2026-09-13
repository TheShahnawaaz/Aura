"use client";

import React, { useState } from "react";
import Image from "next/image";
import { Download, Apple, Copy, Check, Shield, Cpu } from "lucide-react";

export const DownloadSection: React.FC = () => {
  const [copied, setCopied] = useState(false);
  const brewCommand = "brew install --cask aura";

  const handleCopy = () => {
    navigator.clipboard.writeText(brewCommand);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="download" className="py-28 px-4 max-w-5xl mx-auto w-full">
      <div className="relative rounded-[32px] p-8 sm:p-16 bg-[#0c0e14] border border-white/[0.08] shadow-[0_30px_100px_-20px_rgba(0,0,0,0.8)] overflow-hidden text-center flex flex-col items-center">
        {/* Subtle Ambient Radial Glow */}
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_var(--tw-gradient-stops))] from-cyan-500/10 via-transparent to-transparent pointer-events-none" />

        {/* Master Liquid Glass App Icon */}
        <div className="relative w-24 h-24 sm:w-28 sm:h-28 rounded-[24px] overflow-hidden shadow-2xl mb-8 border border-white/20 transition-transform hover:scale-105">
          <Image
            src="/icon.png"
            alt="Aura App Icon"
            width={112}
            height={112}
            className="object-cover"
            priority
          />
        </div>

        {/* Title & Copy */}
        <h2 className="text-3xl sm:text-5xl font-extrabold text-white tracking-[-0.03em] mb-4">
          Install Aura for macOS
        </h2>
        <p className="text-slate-400 text-base sm:text-lg max-w-lg mb-10 leading-relaxed">
          Compiled natively as an Apple Silicon & Intel Universal binary. Free and open source under the MIT License.
        </p>

        {/* Download Action Buttons */}
        <div className="flex flex-col items-center justify-center gap-3 mb-8">
          <a
            href="https://github.com/TheShahnawaaz/Aura/releases/latest/download/Aura.dmg"
            className="flex items-center gap-2.5 px-8 py-4 rounded-2xl bg-white text-black font-bold text-sm shadow-xl hover:bg-slate-100 transition-all hover:scale-[1.02] active:scale-[0.98]"
          >
            <Apple className="w-5 h-5 fill-current" />
            <span>Download for Mac (.dmg)</span>
          </a>
          <a
            href="https://github.com/TheShahnawaaz/Aura/releases"
            target="_blank"
            rel="noreferrer"
            className="text-xs text-slate-400 hover:text-white transition-colors"
          >
            View Changelog & All Releases →
          </a>
        </div>

        {/* Terminal Quick-Install Copy Box */}
        <div className="w-full max-w-sm p-2.5 rounded-xl bg-[#06070a] border border-white/[0.07] flex items-center justify-between shadow-inner mb-8">
          <div className="flex items-center gap-2 font-mono text-xs text-slate-300 px-2 truncate">
            <span className="text-cyan-400 font-bold">$</span>
            <span className="truncate">{brewCommand}</span>
          </div>
          <button
            onClick={handleCopy}
            className="flex items-center gap-1 text-[11px] font-mono text-slate-400 hover:text-white px-2.5 py-1 rounded-lg bg-white/[0.05] hover:bg-white/[0.1] transition-colors shrink-0"
          >
            {copied ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
            <span>{copied ? "Copied" : "Copy"}</span>
          </button>
        </div>

        {/* System Badges */}
        <div className="flex flex-wrap items-center justify-center gap-6 text-xs text-slate-400 font-medium">
          <div className="flex items-center gap-2">
            <Check className="w-3.5 h-3.5 text-cyan-400" />
            <span>macOS 14.0+ Sonoma & Sequoia</span>
          </div>
          <div className="flex items-center gap-2">
            <Cpu className="w-3.5 h-3.5 text-cyan-400" />
            <span>M1 / M2 / M3 / M4 & Intel</span>
          </div>
          <div className="flex items-center gap-2">
            <Shield className="w-3.5 h-3.5 text-emerald-400" />
            <span>Encrypted Local Keychain</span>
          </div>
        </div>
      </div>
    </section>
  );
};
