"use client";

import React, { useState, useEffect } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";
import { LivingOrbCanvas, AssistantOrbState } from "./LivingOrbCanvas";
import {
  MessageSquare,
  Check,
  Volume2,
  Terminal,
  Sparkles,
  Mic,
  Cpu,
  Wifi,
  Battery,
  Search,
  Folder,
  FileCode,
  Sliders,
} from "lucide-react";

export const NotchSimulator: React.FC = () => {
  const [activeState, setActiveState] = useState<AssistantOrbState>("idle");
  const [isHovered, setIsHovered] = useState(false);

  // Global Option + Space hotkey handler matching native Aura
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.altKey && (e.code === "Space" || e.key === " ")) {
        e.preventDefault();
        setActiveState((prev) => {
          if (prev === "idle") return "listening";
          if (prev === "listening") return "processing";
          if (prev === "processing") return "speaking";
          return "idle";
        });
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Dimensions derived directly from NotchGeometry.swift
  const dimensions = {
    idle: { width: 218, height: 34 },
    listening: { width: 388, height: 138 },
    processing: { width: 414, height: 154 },
    speaking: { width: 442, height: 182 },
  };

  const current = dimensions[activeState];
  const isExpanded = activeState !== "idle";

  return (
    <div className="relative w-full max-w-5xl mx-auto flex flex-col items-center select-none">
      {/* Keyboard Shortcut Banner */}
      <div className="mb-5 flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-[#12141c]/80 border border-white/[0.08] text-xs text-slate-300 backdrop-blur-xl shadow-xl">
        <span className="flex h-1.5 w-1.5 rounded-full bg-cyan-400 animate-ping" />
        <span className="text-slate-400">Press</span>
        <kbd className="px-2 py-0.5 rounded-md bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[11px] font-semibold">
          ⌥ Option
        </kbd>
        <span className="text-slate-500">+</span>
        <kbd className="px-2 py-0.5 rounded-md bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[11px] font-semibold">
          Space
        </kbd>
        <span className="text-slate-400">anywhere on this page to trigger</span>
      </div>

      {/* 16-INCH MACBOOK PRO SPACE BLACK HARDWARE CHASSIS */}
      <div className="relative w-full rounded-[28px] p-3 sm:p-4 bg-[#14161a] border border-[#262830] shadow-[0_30px_100px_-20px_rgba(0,0,0,0.95)]">
        {/* Top Camera Bezel & Display Glass */}
        <div className="relative w-full h-[460px] sm:h-[520px] rounded-[18px] overflow-hidden bg-[#0a0a0f] border border-[#1f2129] flex flex-col items-center">
          
          {/* PHOTO-REALISTIC MACOS SEQUOIA TWILIGHT WALLPAPER */}
          <div className="absolute inset-0 bg-gradient-to-b from-[#090b14] via-[#11172a] to-[#0a101f]">
            {/* Atmospheric Aurora Light Cones */}
            <div className="absolute -top-20 left-1/4 w-[500px] h-[350px] bg-cyan-600/15 rounded-full blur-[110px] pointer-events-none" />
            <div className="absolute top-10 right-1/4 w-[450px] h-[300px] bg-purple-600/15 rounded-full blur-[120px] pointer-events-none" />
            <div className="absolute bottom-10 left-1/3 w-[600px] h-[220px] bg-blue-600/10 rounded-full blur-[130px] pointer-events-none" />
          </div>

          {/* NATIVE MACOS MENUBAR */}
          <div className="w-full h-7 px-4 flex items-center justify-between text-[11px] font-medium text-slate-200/90 z-20 backdrop-blur-xl bg-black/20 border-b border-white/[0.04]">
            {/* Left Menubar Items */}
            <div className="flex items-center gap-3.5">
              <span className="text-white text-xs opacity-90"></span>
              <span className="font-semibold text-white">Finder</span>
              <span className="hidden sm:inline text-slate-300">File</span>
              <span className="hidden sm:inline text-slate-300">Edit</span>
              <span className="hidden sm:inline text-slate-300">View</span>
              <span className="hidden sm:inline text-slate-300">Go</span>
              <span className="hidden sm:inline text-slate-300">Window</span>
              <span className="hidden sm:inline text-slate-300">Help</span>
            </div>

            {/* Right Menubar Status Icons */}
            <div className="flex items-center gap-3 text-slate-300">
              <Battery className="w-3.5 h-3.5 opacity-80" />
              <Wifi className="w-3.5 h-3.5 opacity-80" />
              <Search className="w-3 h-3 opacity-80" />
              <Sliders className="w-3 h-3 opacity-80" />
              <span className="font-mono text-[10px] tracking-tight">Thu Sep 3 3:50 PM</span>
            </div>
          </div>

          {/* DESKTOP CONTENT (Realistic Mac Workspace behind the Notch) */}
          <div className="w-full flex-1 p-6 relative z-10 flex flex-col justify-between pointer-events-none">
            {/* Desktop Icons */}
            <div className="flex flex-col gap-5 items-end">
              <div className="flex flex-col items-center gap-1 group cursor-pointer">
                <div className="w-10 h-10 rounded-lg bg-cyan-500/10 border border-cyan-400/30 flex items-center justify-center shadow-lg backdrop-blur-md">
                  <Folder className="w-5 h-5 text-cyan-400 fill-cyan-400/20" />
                </div>
                <span className="text-[10px] font-medium text-white/90 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                  Projects
                </span>
              </div>

              <div className="flex flex-col items-center gap-1 group cursor-pointer">
                <div className="w-10 h-10 rounded-lg bg-purple-500/10 border border-purple-400/30 flex items-center justify-center shadow-lg backdrop-blur-md">
                  <FileCode className="w-5 h-5 text-purple-400" />
                </div>
                <span className="text-[10px] font-medium text-white/90 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                  Aura.swift
                </span>
              </div>
            </div>

            {/* NATIVE MACOS DOCK */}
            <div className="self-center flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-white/[0.08] backdrop-blur-2xl border border-white/[0.12] shadow-[0_10px_30px_rgba(0,0,0,0.6)]">
              {/* Finder */}
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-sky-600 to-sky-400 flex items-center justify-center text-white text-xs font-bold shadow-md">
                Finder
              </div>

              {/* Safari */}
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-blue-700 to-cyan-400 flex items-center justify-center text-white text-xs shadow-md">
                <Wifi className="w-5 h-5 text-white" />
              </div>

              {/* Terminal */}
              <div className="w-9 h-9 rounded-xl bg-[#111317] border border-white/20 flex items-center justify-center shadow-md">
                <Terminal className="w-4 h-4 text-emerald-400" />
              </div>

              {/* AURA APP (Active Running Dot in Dock) */}
              <div className="relative flex flex-col items-center">
                <div className="w-9 h-9 rounded-xl overflow-hidden shadow-lg border border-white/25 ring-2 ring-cyan-400/30 transition-transform hover:scale-110">
                  <Image
                    src="/icon.png"
                    alt="Aura Dock Icon"
                    width={36}
                    height={36}
                    className="object-cover"
                  />
                </div>
                {/* macOS Running App Dot Indicator */}
                <div className="w-1 h-1 rounded-full bg-white/90 mt-1 shadow-[0_0_4px_white]" />
              </div>
            </div>
          </div>

          {/* THE REAL MACBOOK NOTCH HUD (EXACT NOTCHSHAPE CURVATURE & BEZEL ATTACHMENT) */}
          <motion.div
            animate={{
              width: current.width,
              height: current.height,
            }}
            transition={{
              type: "spring",
              stiffness: 380,
              damping: 32,
              mass: 0.85,
            }}
            onMouseEnter={() => setIsHovered(true)}
            onMouseLeave={() => setIsHovered(false)}
            className="absolute top-0 z-40 bg-black text-white rounded-b-[16px] shadow-[0_20px_50px_-10px_rgba(0,0,0,0.95)] border-b border-x border-white/[0.12] flex flex-col overflow-hidden"
          >
            {/* Top Cap Bar (Bezel Flush with 6pt Concave Reverse Fillets) */}
            <div className="relative w-full h-[34px] flex items-center justify-between px-4 select-none shrink-0">
              {/* Left Ear: Living Orb + "Aura" Brand */}
              <div className="flex items-center gap-2">
                {!isExpanded && (
                  <motion.div layoutId="orbSlot">
                    <LivingOrbCanvas state="idle" size={20} />
                  </motion.div>
                )}
                <span className="text-[11px] font-bold tracking-tight text-white/95 font-sans">
                  Aura
                </span>
              </div>

              {/* Center Hardware FaceTime HD Camera & Ambient Light Sensor */}
              <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-2">
                <div className="w-2.5 h-2.5 rounded-full bg-[#0c0d12] border border-white/[0.15] flex items-center justify-center">
                  <div className="w-1 h-1 rounded-full bg-blue-900/80" />
                </div>
                {activeState === "listening" && (
                  <motion.div
                    animate={{ opacity: [0.3, 1, 0.3] }}
                    transition={{ repeat: Infinity, duration: 1.1 }}
                    className="w-1.5 h-1.5 rounded-full bg-emerald-400 shadow-[0_0_6px_#34d399]"
                  />
                )}
              </div>

              {/* Right Ear: Activity pill or Done button */}
              <div className="flex items-center gap-1.5">
                {activeState === "idle" ? (
                  <button
                    onClick={() => setActiveState("listening")}
                    className="flex items-center gap-1 text-[10px] font-mono text-slate-400 hover:text-white px-2 py-0.5 rounded-md bg-white/[0.06] hover:bg-white/[0.12] transition-colors"
                  >
                    <Mic className="w-2.5 h-2.5 text-cyan-400" />
                    <span>Talk</span>
                  </button>
                ) : activeState === "speaking" ? (
                  <button
                    onClick={() => setActiveState("idle")}
                    className="flex items-center gap-1 text-[10px] font-medium text-slate-200 hover:text-white px-2 py-0.5 rounded-md bg-white/10 hover:bg-white/15 transition-colors"
                  >
                    <Check className="w-3 h-3 text-emerald-400" />
                    <span>Done</span>
                  </button>
                ) : (
                  <span className="text-[10px] font-mono text-cyan-300 px-2 py-0.5 rounded bg-cyan-950/60 border border-cyan-800/50 capitalize">
                    {activeState}
                  </span>
                )}
              </div>
            </div>

            {/* EXPANDED CONTENT AREA (Active States) */}
            <AnimatePresence mode="wait">
              {isExpanded && (
                <motion.div
                  initial={{ opacity: 0, y: 4 }}
                  animate={{ opacity: 1, y: 0 }}
                  exit={{ opacity: 0, y: 4 }}
                  transition={{ duration: 0.18 }}
                  className="flex-1 px-4 pb-2.5 flex flex-col justify-between"
                >
                  {/* Dynamic Message Body */}
                  <div className="flex items-start gap-3.5 pt-1">
                    {/* Living Orb descended into message area (x = 16) */}
                    <div className="shrink-0 mt-0.5">
                      <LivingOrbCanvas state={activeState} size={38} />
                    </div>

                    {/* Content Columns */}
                    <div className="flex-1 min-w-0">
                      {activeState === "listening" && (
                        <div className="space-y-1">
                          <span className="text-[10px] font-mono uppercase tracking-wider text-cyan-400 font-semibold">
                            Listening to you...
                          </span>
                          <p className="text-[12.5px] text-slate-100 font-medium leading-snug">
                            “Turn down Spotify volume to 20% and list my desktop files”
                          </p>
                        </div>
                      )}

                      {activeState === "processing" && (
                        <div className="space-y-2">
                          <div className="flex items-center gap-2">
                            <span className="text-[10px] font-mono uppercase tracking-wider text-purple-400 font-semibold">
                              OpenAgentSDK Reasoning
                            </span>
                            <span className="w-1.5 h-1.5 rounded-full bg-purple-400 animate-pulse" />
                          </div>
                          <div className="flex flex-wrap gap-1.5">
                            <span className="inline-flex items-center gap-1 text-[10.5px] font-mono bg-purple-950/70 border border-purple-800/60 px-2 py-0.5 rounded text-purple-200">
                              <Volume2 className="w-3 h-3 text-purple-400" />
                              adjust_volume(20%)
                            </span>
                            <span className="inline-flex items-center gap-1 text-[10.5px] font-mono bg-cyan-950/70 border border-cyan-800/60 px-2 py-0.5 rounded text-cyan-200">
                              <Terminal className="w-3 h-3 text-cyan-400" />
                              list_files("~/Desktop")
                            </span>
                          </div>
                        </div>
                      )}

                      {activeState === "speaking" && (
                        <div className="space-y-1">
                          <span className="text-[10px] font-mono uppercase tracking-wider text-rose-400 font-semibold">
                            Aura Output
                          </span>
                          <p className="text-[12.5px] text-slate-100 leading-snug">
                            Lowered Spotify volume to 20%. Found 8 items on your Desktop including <span className="text-cyan-300 font-mono">Projects</span> and <span className="text-cyan-300 font-mono">Aura.swift</span>.
                          </p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* UNIFORM PINNED FOOTER (Matches our exact SwiftUI NotchHUDView padding) */}
                  <div className="flex items-center justify-between pt-2 border-t border-white/[0.08] text-[10px] text-slate-400">
                    <div className="flex items-center gap-1.5 text-slate-400 hover:text-cyan-300 transition-colors cursor-pointer">
                      <MessageSquare className="w-3 h-3" />
                      <span>Open Chat Panel (⌘K)</span>
                    </div>
                    <span className="font-mono text-[9px] text-slate-500">
                      {activeState === "listening" && "Press shortcut again to send"}
                      {activeState === "processing" && "In-process concurrency"}
                      {activeState === "speaking" && "Press ⌥ Space to barge-in"}
                    </span>
                  </div>
                </motion.div>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </div>

      {/* REFINED ARCHETYPE SELECTOR PILLS */}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-2 p-1.5 rounded-2xl bg-[#0f1118]/90 border border-white/[0.08] backdrop-blur-2xl shadow-xl">
        <button
          onClick={() => setActiveState("idle")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all ${
            activeState === "idle"
              ? "bg-white/[0.14] text-white border border-white/20 shadow-sm"
              : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]"
          }`}
        >
          <Sparkles className="w-3.5 h-3.5 text-cyan-400" />
          <span>1. Idle (Floating Nebula)</span>
        </button>

        <button
          onClick={() => setActiveState("listening")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all ${
            activeState === "listening"
              ? "bg-cyan-500/20 text-cyan-300 border border-cyan-500/40 shadow-sm"
              : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]"
          }`}
        >
          <Mic className="w-3.5 h-3.5 text-cyan-400" />
          <span>2. Listening (Acoustic Wave)</span>
        </button>

        <button
          onClick={() => setActiveState("processing")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all ${
            activeState === "processing"
              ? "bg-purple-500/20 text-purple-300 border border-purple-500/40 shadow-sm"
              : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]"
          }`}
        >
          <Cpu className="w-3.5 h-3.5 text-purple-400" />
          <span>3. Thinking (Galactic Vortex)</span>
        </button>

        <button
          onClick={() => setActiveState("speaking")}
          className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all ${
            activeState === "speaking"
              ? "bg-rose-500/20 text-rose-300 border border-rose-500/40 shadow-sm"
              : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]"
          }`}
        >
          <Volume2 className="w-3.5 h-3.5 text-rose-400" />
          <span>4. Speaking (Vocal Ribbon)</span>
        </button>
      </div>
    </div>
  );
};
