"use client";

import React, { useState, useEffect, useCallback, useRef } from "react";
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

const STATE_ORDER: AssistantOrbState[] = [
  "idle",
  "listening",
  "processing",
  "speaking",
];
const STATE_DURATION = 4500; // ms per state

const stateGlowColors: Record<AssistantOrbState, string> = {
  idle: "rgba(0, 229, 255, 0.12)",
  listening: "rgba(20, 184, 166, 0.18)",
  processing: "rgba(168, 85, 247, 0.18)",
  speaking: "rgba(251, 113, 133, 0.18)",
};

const stateAccentColors: Record<AssistantOrbState, string> = {
  idle: "#00E5FF",
  listening: "#14B8A6",
  processing: "#A855F7",
  speaking: "#FB7185",
};

export const NotchSimulator: React.FC = () => {
  const [activeState, setActiveState] = useState<AssistantOrbState>("idle");
  const [isHovered, setIsHovered] = useState(false);
  const [isUserInteracting, setIsUserInteracting] = useState(false);
  const [progress, setProgress] = useState(0);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const progressRef = useRef<NodeJS.Timeout | null>(null);

  // Auto-cycle through states
  const startAutoCycle = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (progressRef.current) clearInterval(progressRef.current);

    setProgress(0);

    // Progress bar update
    const progressInterval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) return 100;
        return prev + 100 / (STATE_DURATION / 50);
      });
    }, 50);
    progressRef.current = progressInterval;

    // State transition
    const timer = setTimeout(() => {
      setActiveState((prev) => {
        const currentIdx = STATE_ORDER.indexOf(prev);
        return STATE_ORDER[(currentIdx + 1) % STATE_ORDER.length];
      });
      setProgress(0);
    }, STATE_DURATION);
    timerRef.current = timer;
  }, []);

  useEffect(() => {
    if (!isUserInteracting) {
      startAutoCycle();
    }
    return () => {
      if (timerRef.current) clearTimeout(timerRef.current);
      if (progressRef.current) clearInterval(progressRef.current);
    };
  }, [activeState, isUserInteracting, startAutoCycle]);

  const handleManualStateChange = (state: AssistantOrbState) => {
    setIsUserInteracting(true);
    setActiveState(state);
    setProgress(0);

    // Resume auto-cycle after 8 seconds of no interaction
    setTimeout(() => setIsUserInteracting(false), 8000);
  };

  // Global Option + Space hotkey handler matching native Aura
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.altKey && (e.code === "Space" || e.key === " ")) {
        e.preventDefault();
        setActiveState((prev) => {
          const currentIdx = STATE_ORDER.indexOf(prev);
          return STATE_ORDER[(currentIdx + 1) % STATE_ORDER.length];
        });
        setIsUserInteracting(true);
        setTimeout(() => setIsUserInteracting(false), 8000);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  // Dimensions derived directly from NotchGeometry.swift
  const dimensions: Record<
    AssistantOrbState,
    { width: number; height: number }
  > = {
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
      <motion.div
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 1.2, duration: 0.5 }}
        className="mb-5 flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-[#12141c]/80 border border-white/[0.08] text-xs text-slate-300 backdrop-blur-xl shadow-xl"
      >
        <span className="relative flex h-1.5 w-1.5">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-cyan-400" />
        </span>
        <span className="text-slate-400">Press</span>
        <kbd className="px-2 py-0.5 rounded-md bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[11px] font-semibold">
          ⌥ Option
        </kbd>
        <span className="text-slate-500">+</span>
        <kbd className="px-2 py-0.5 rounded-md bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[11px] font-semibold">
          Space
        </kbd>
        <span className="text-slate-400">anywhere on this page to trigger</span>
      </motion.div>

      {/* 16-INCH MACBOOK PRO SPACE BLACK HARDWARE CHASSIS */}
      <div className="relative w-full">
        {/* Ambient glow behind MacBook - changes per state */}
        <motion.div
          className="absolute -inset-20 aurora-glow"
          animate={{
            backgroundColor: stateGlowColors[activeState],
            scale: isExpanded ? 1.1 : 1,
          }}
          transition={{ duration: 1.5, ease: "easeInOut" }}
        />

        <div className="relative w-full rounded-[28px] p-3 sm:p-4 bg-[#14161a] border border-[#262830] shadow-[0_30px_100px_-20px_rgba(0,0,0,0.95)] animate-breathe">
          {/* Top Camera Bezel & Display Glass */}
          <div className="relative w-full h-[460px] sm:h-[520px] rounded-[18px] overflow-hidden bg-[#0a0a0f] border border-[#1f2129] flex flex-col items-center">
            {/* PHOTO-REALISTIC MACOS SEQUOIA TWILIGHT WALLPAPER */}
            <div className="absolute inset-0 bg-gradient-to-b from-[#090b14] via-[#11172a] to-[#0a101f]">
              {/* Atmospheric Aurora Light Cones */}
              <motion.div
                className="absolute -top-20 left-1/4 w-[500px] h-[350px] rounded-full blur-[110px] pointer-events-none"
                animate={{
                  backgroundColor: stateGlowColors[activeState],
                  scale: [1, 1.1, 1],
                }}
                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
              />
              <motion.div
                className="absolute top-10 right-1/4 w-[450px] h-[300px] bg-purple-600/15 rounded-full blur-[120px] pointer-events-none"
                animate={{ scale: [1, 1.08, 1], opacity: [0.15, 0.25, 0.15] }}
                transition={{
                  duration: 5,
                  repeat: Infinity,
                  ease: "easeInOut",
                  delay: 1,
                }}
              />
              <div className="absolute bottom-10 left-1/3 w-[600px] h-[220px] bg-blue-600/10 rounded-full blur-[130px] pointer-events-none" />
            </div>

            {/* NATIVE MACOS MENUBAR */}
            <div className="w-full h-7 px-4 flex items-center justify-between text-[11px] font-medium text-slate-200/90 z-20 backdrop-blur-xl bg-black/20 border-b border-white/[0.04]">
              {/* Left Menubar Items */}
              <div className="flex items-center gap-3.5">
                <span className="text-white text-xs opacity-90"></span>
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
                <span className="font-mono text-[10px] tracking-tight">
                  Thu Sep 3 3:50 PM
                </span>
              </div>
            </div>

            {/* DESKTOP CONTENT */}
            <div className="w-full flex-1 p-6 relative z-10 flex flex-col justify-between pointer-events-none">
              {/* Desktop Icons */}
              <div className="flex flex-col gap-5 items-end">
                <motion.div
                  className="flex flex-col items-center gap-1 group cursor-pointer"
                  whileHover={{ scale: 1.1 }}
                >
                  <div className="w-10 h-10 rounded-lg bg-cyan-500/10 border border-cyan-400/30 flex items-center justify-center shadow-lg backdrop-blur-md">
                    <Folder className="w-5 h-5 text-cyan-400 fill-cyan-400/20" />
                  </div>
                  <span className="text-[10px] font-medium text-white/90 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                    Projects
                  </span>
                </motion.div>

                <motion.div
                  className="flex flex-col items-center gap-1 group cursor-pointer"
                  whileHover={{ scale: 1.1 }}
                >
                  <div className="w-10 h-10 rounded-lg bg-purple-500/10 border border-purple-400/30 flex items-center justify-center shadow-lg backdrop-blur-md">
                    <FileCode className="w-5 h-5 text-purple-400" />
                  </div>
                  <span className="text-[10px] font-medium text-white/90 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                    Aura.swift
                  </span>
                </motion.div>
              </div>

              {/* NATIVE MACOS DOCK */}
              <div className="self-center flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-white/[0.08] backdrop-blur-2xl border border-white/[0.12] shadow-[0_10px_30px_rgba(0,0,0,0.6)]">
                {/* Finder */}
                <motion.div
                  className="w-9 h-9 rounded-xl bg-gradient-to-tr from-sky-600 to-sky-400 flex items-center justify-center text-white text-xs font-bold shadow-md"
                  whileHover={{ scale: 1.2, y: -4 }}
                  transition={{ type: "spring", stiffness: 400, damping: 17 }}
                >
                  Finder
                </motion.div>

                {/* Safari */}
                <motion.div
                  className="w-9 h-9 rounded-xl bg-gradient-to-tr from-blue-700 to-cyan-400 flex items-center justify-center text-white text-xs shadow-md"
                  whileHover={{ scale: 1.2, y: -4 }}
                  transition={{ type: "spring", stiffness: 400, damping: 17 }}
                >
                  <Wifi className="w-5 h-5 text-white" />
                </motion.div>

                {/* Terminal */}
                <motion.div
                  className="w-9 h-9 rounded-xl bg-[#111317] border border-white/20 flex items-center justify-center shadow-md"
                  whileHover={{ scale: 1.2, y: -4 }}
                  transition={{ type: "spring", stiffness: 400, damping: 17 }}
                >
                  <Terminal className="w-4 h-4 text-emerald-400" />
                </motion.div>

                {/* AURA APP */}
                <motion.div
                  className="relative flex flex-col items-center"
                  whileHover={{ scale: 1.2, y: -4 }}
                  transition={{ type: "spring", stiffness: 400, damping: 17 }}
                >
                  <div className="w-9 h-9 rounded-xl overflow-hidden shadow-lg border border-white/25 ring-2 ring-cyan-400/30">
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
                </motion.div>
              </div>
            </div>

            {/* THE REAL MACBOOK NOTCH HUD */}
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
              {/* Ambient notch glow */}
              <motion.div
                className="absolute -bottom-8 left-1/2 -translate-x-1/2 w-[80%] h-[40px] rounded-full blur-[20px] pointer-events-none"
                animate={{
                  backgroundColor: stateAccentColors[activeState],
                  opacity: isExpanded ? 0.2 : 0,
                }}
                transition={{ duration: 0.8 }}
              />

              {/* Top Cap Bar */}
              <div className="relative w-full h-[34px] flex items-center justify-between px-4 select-none shrink-0">
                {/* Left Ear */}
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

                {/* Center Hardware FaceTime HD Camera */}
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

                {/* Right Ear */}
                <div className="flex items-center gap-1.5">
                  {activeState === "idle" ? (
                    <button
                      onClick={() => handleManualStateChange("listening")}
                      className="flex items-center gap-1 text-[10px] font-mono text-slate-400 hover:text-white px-2 py-0.5 rounded-md bg-white/[0.06] hover:bg-white/[0.12] transition-colors"
                    >
                      <Mic className="w-2.5 h-2.5 text-cyan-400" />
                      <span>Talk</span>
                    </button>
                  ) : activeState === "speaking" ? (
                    <button
                      onClick={() => handleManualStateChange("idle")}
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

              {/* EXPANDED CONTENT AREA */}
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
                      <div className="shrink-0 mt-0.5">
                        <LivingOrbCanvas state={activeState} size={38} />
                      </div>

                      <div className="flex-1 min-w-0">
                        {activeState === "listening" && (
                          <motion.div
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="space-y-1"
                          >
                            <span className="inline-flex items-center gap-1.5 text-[10px] font-mono uppercase tracking-wider text-cyan-400 font-semibold">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                              Listening to you...
                            </span>
                            <p className="text-[12.5px] text-slate-100 font-medium leading-snug">
                              &ldquo;Turn down Spotify volume to 20% and list my
                              desktop files&rdquo;
                            </p>
                          </motion.div>
                        )}

                        {activeState === "processing" && (
                          <motion.div
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="space-y-2"
                          >
                            <div className="flex items-center gap-2">
                              <span className="text-[10px] font-mono uppercase tracking-wider text-purple-400 font-semibold">
                                OpenAgentSDK Reasoning
                              </span>
                              <motion.span
                                className="w-1.5 h-1.5 rounded-full bg-purple-400"
                                animate={{ scale: [1, 1.5, 1], opacity: [1, 0.5, 1] }}
                                transition={{ repeat: Infinity, duration: 0.8 }}
                              />
                            </div>
                            {/* Animated progress bar */}
                            <div className="h-1 w-full bg-white/[0.06] rounded-full overflow-hidden">
                              <motion.div
                                className="h-full rounded-full bg-gradient-to-r from-purple-500 via-cyan-400 to-purple-500"
                                initial={{ width: "0%" }}
                                animate={{ width: "75%" }}
                                transition={{ duration: 3, ease: "easeOut" }}
                              />
                            </div>
                            <div className="flex flex-wrap gap-1.5">
                              <motion.span
                                initial={{ opacity: 0, scale: 0.9 }}
                                animate={{ opacity: 1, scale: 1 }}
                                transition={{ delay: 0.3 }}
                                className="inline-flex items-center gap-1 text-[10.5px] font-mono bg-purple-950/70 border border-purple-800/60 px-2 py-0.5 rounded text-purple-200"
                              >
                                <Volume2 className="w-3 h-3 text-purple-400" />
                                adjust_volume(20%)
                              </motion.span>
                              <motion.span
                                initial={{ opacity: 0, scale: 0.9 }}
                                animate={{ opacity: 1, scale: 1 }}
                                transition={{ delay: 0.6 }}
                                className="inline-flex items-center gap-1 text-[10.5px] font-mono bg-cyan-950/70 border border-cyan-800/60 px-2 py-0.5 rounded text-cyan-200"
                              >
                                <Terminal className="w-3 h-3 text-cyan-400" />
                                list_files(&quot;~/Desktop&quot;)
                              </motion.span>
                            </div>
                          </motion.div>
                        )}

                        {activeState === "speaking" && (
                          <motion.div
                            initial={{ opacity: 0, x: -10 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="space-y-1"
                          >
                            <span className="text-[10px] font-mono uppercase tracking-wider text-rose-400 font-semibold">
                              Aura Output
                            </span>
                            <p className="text-[12.5px] text-slate-100 leading-snug">
                              Lowered Spotify volume to 20%. Found 8 items on
                              your Desktop including{" "}
                              <span className="text-cyan-300 font-mono">
                                Projects
                              </span>{" "}
                              and{" "}
                              <span className="text-cyan-300 font-mono">
                                Aura.swift
                              </span>
                              .
                            </p>
                          </motion.div>
                        )}
                      </div>
                    </div>

                    {/* FOOTER */}
                    <div className="flex items-center justify-between pt-2 border-t border-white/[0.08] text-[10px] text-slate-400">
                      <div className="flex items-center gap-1.5 text-slate-400 hover:text-cyan-300 transition-colors cursor-pointer">
                        <MessageSquare className="w-3 h-3" />
                        <span>Open Chat Panel (⌘K)</span>
                      </div>
                      <span className="font-mono text-[9px] text-slate-500">
                        {activeState === "listening" &&
                          "Press shortcut again to send"}
                        {activeState === "processing" &&
                          "In-process concurrency"}
                        {activeState === "speaking" &&
                          "Press ⌥ Space to barge-in"}
                      </span>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </div>
        </div>
      </div>

      {/* STATE SELECTOR WITH PROGRESS INDICATORS */}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-2 p-1.5 rounded-2xl bg-[#0f1118]/90 border border-white/[0.08] backdrop-blur-2xl shadow-xl">
        {[
          {
            state: "idle" as const,
            icon: Sparkles,
            label: "1. Idle (Floating Nebula)",
            color: "cyan",
          },
          {
            state: "listening" as const,
            icon: Mic,
            label: "2. Listening (Acoustic Wave)",
            color: "cyan",
          },
          {
            state: "processing" as const,
            icon: Cpu,
            label: "3. Thinking (Galactic Vortex)",
            color: "purple",
          },
          {
            state: "speaking" as const,
            icon: Volume2,
            label: "4. Speaking (Vocal Ribbon)",
            color: "rose",
          },
        ].map(({ state, icon: Icon, label, color }) => {
          const isActive = activeState === state;
          const activeClasses: Record<string, string> = {
            cyan: "bg-white/[0.14] text-white border border-white/20 shadow-sm",
            purple:
              "bg-purple-500/20 text-purple-300 border border-purple-500/40 shadow-sm",
            rose: "bg-rose-500/20 text-rose-300 border border-rose-500/40 shadow-sm",
          };
          const iconColors: Record<string, string> = {
            cyan: "text-cyan-400",
            purple: "text-purple-400",
            rose: "text-rose-400",
          };

          return (
            <button
              key={state}
              onClick={() => handleManualStateChange(state)}
              className={`relative flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all overflow-hidden ${
                isActive
                  ? activeClasses[color]
                  : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.05]"
              }`}
            >
              <Icon className={`w-3.5 h-3.5 ${iconColors[color]}`} />
              <span>{label}</span>

              {/* Progress bar overlay */}
              {isActive && !isUserInteracting && (
                <motion.div
                  className="absolute bottom-0 left-0 h-[2px] bg-white/20 rounded-full"
                  style={{ width: `${progress}%` }}
                  transition={{ duration: 0.05 }}
                />
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
};
