"use client";

import React from "react";
import Image from "next/image";
import { Download, Github, Sparkles } from "lucide-react";

export const Navbar: React.FC = () => {
  return (
    <header className="fixed top-0 inset-x-0 z-50 flex items-center justify-center p-4 select-none">
      <nav className="w-full max-w-5xl h-14 px-4 sm:px-6 rounded-2xl glass-panel flex items-center justify-between shadow-2xl backdrop-blur-xl border border-white/10">
        {/* Brand Logo & Name */}
        <a href="#" className="flex items-center gap-3 group">
          <div className="relative w-8 h-8 rounded-lg overflow-hidden border border-white/15 shadow-md group-hover:scale-105 transition-transform">
            <Image
              src="/icon.png"
              alt="Aura Icon"
              width={32}
              height={32}
              className="object-cover"
              priority
            />
          </div>
          <div className="flex items-center gap-1.5">
            <span className="font-bold tracking-tight text-white text-base">Aura</span>
            <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-cyan-500/15 text-cyan-300 border border-cyan-500/30">
              Beta
            </span>
          </div>
        </a>

        {/* Center Navigation Links */}
        <div className="hidden md:flex items-center gap-7 text-xs font-medium text-slate-300">
          <a href="#notch" className="hover:text-cyan-300 transition-colors">
            Notch HUD
          </a>
          <a href="#features" className="hover:text-cyan-300 transition-colors">
            Capabilities
          </a>
          <a href="#workflows" className="hover:text-cyan-300 transition-colors">
            Workflows
          </a>
          <a href="#comparison" className="hover:text-cyan-300 transition-colors">
            Why Aura
          </a>
          <a href="#download" className="hover:text-cyan-300 transition-colors">
            Install
          </a>
        </div>

        {/* Action CTAs */}
        <div className="flex items-center gap-3">
          <a
            href="https://github.com/shahnawaz/Aura"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-1.5 text-xs text-slate-300 hover:text-white px-3 py-1.5 rounded-xl border border-white/10 hover:border-white/20 bg-white/5 hover:bg-white/10 transition-all"
          >
            <Github className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Star on GitHub</span>
          </a>

          <a
            href="#download"
            className="flex items-center gap-1.5 text-xs font-semibold text-black bg-gradient-to-r from-cyan-300 via-sky-300 to-cyan-200 hover:brightness-110 px-4 py-2 rounded-xl shadow-lg shadow-cyan-500/20 transition-all hover:scale-[1.02]"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Download .dmg</span>
          </a>
        </div>
      </nav>
    </header>
  );
};
