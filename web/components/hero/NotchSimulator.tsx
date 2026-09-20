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
  Activity,
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
  idle: "rgba(99, 102, 241, 0.10)",
  listening: "rgba(16, 185, 129, 0.12)",
  processing: "rgba(99, 102, 241, 0.16)",
  speaking: "rgba(139, 92, 246, 0.14)",
};

const stateAccentColors: Record<AssistantOrbState, string> = {
  idle: "#6366F1",
  listening: "#10B981",
  processing: "#6366F1",
  speaking: "#8B5CF6",
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

    const progressInterval = setInterval(() => {
      setProgress((prev) => {
        if (prev >= 100) return 100;
        return prev + 100 / (STATE_DURATION / 50);
      });
    }, 50);
    progressRef.current = progressInterval;

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

    setTimeout(() => setIsUserInteracting(false), 8000);
  };

  // Option + Space hotkey handler matching native Aura
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
      {/* Interactive Keycap Trigger Bar */}
      <motion.div
        initial={{ opacity: 0, y: 8 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.6, duration: 0.4 }}
        className="mb-5 flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-[#090B10]/90 border border-white/[0.08] text-xs text-slate-300 backdrop-blur-xl shadow-hairline"
      >
        <span className="flex h-1.5 w-1.5 relative">
          <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-iris-400 opacity-75" />
          <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-iris-400" />
        </span>
        <span className="text-slate-400">Press</span>
        <kbd className="px-1.5 py-0.5 rounded bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[10.5px] font-semibold">
          ⌥ Option
        </kbd>
        <span className="text-slate-500">+</span>
        <kbd className="px-1.5 py-0.5 rounded bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[10.5px] font-semibold">
          Space
        </kbd>
        <span className="text-slate-400">to toggle live HUD state</span>
      </motion.div>

      {/* 16-INCH MACBOOK PRO SPACE BLACK HARDWARE CHASSIS (Double-Bezel Architecture) */}
      <div className="relative w-full">
        {/* Ambient Backlight */}
        <motion.div
          className="absolute -inset-10 rounded-full blur-[100px] pointer-events-none"
          animate={{
            backgroundColor: stateGlowColors[activeState],
            scale: isExpanded ? 1.05 : 1,
          }}
          transition={{ duration: 1.2, ease: "easeInOut" }}
        />

        {/* Outer Machined Enclosure */}
        <div className="double-bezel-outer w-full">
          {/* Inner Display Bezel */}
          <div className="double-bezel-inner relative w-full h-[460px] sm:h-[520px] overflow-hidden bg-[#07090E] flex flex-col items-center">
            {/* macOS Sequoia Wallpaper Depth */}
            <div className="absolute inset-0 bg-gradient-to-b from-[#080A11] via-[#0D1220] to-[#080B13]">
              <motion.div
                className="absolute -top-24 left-1/3 w-[500px] h-[350px] rounded-full blur-[120px] pointer-events-none"
                animate={{
                  backgroundColor: stateGlowColors[activeState],
                  scale: [1, 1.08, 1],
                }}
                transition={{ duration: 4, repeat: Infinity, ease: "easeInOut" }}
              />
            </div>

            {/* Native macOS Menubar */}
            <div className="w-full h-7 px-4 flex items-center justify-between text-[11px] font-medium text-slate-300 z-20 backdrop-blur-xl bg-black/30 border-b border-white/[0.04]">
              <div className="flex items-center gap-3.5">
                <span className="text-white text-xs"></span>
                <span className="font-semibold text-white">Finder</span>
                <span className="hidden sm:inline text-slate-400">File</span>
                <span className="hidden sm:inline text-slate-400">Edit</span>
                <span className="hidden sm:inline text-slate-400">View</span>
                <span className="hidden sm:inline text-slate-400">Go</span>
                <span className="hidden sm:inline text-slate-400">Window</span>
                <span className="hidden sm:inline text-slate-400">Help</span>
              </div>

              <div className="flex items-center gap-3 text-slate-400">
                <Battery className="w-3.5 h-3.5 opacity-80" />
                <Wifi className="w-3.5 h-3.5 opacity-80" />
                <Search className="w-3 h-3 opacity-80" />
                <Sliders className="w-3 h-3 opacity-80" />
                <span className="font-mono text-[10px] tracking-tight text-slate-300">
                  Mon 10:42 AM
                </span>
              </div>
            </div>

            {/* Desktop Stage */}
            <div className="w-full flex-1 p-6 relative z-10 flex flex-col justify-between pointer-events-none">
              {/* Desktop Icons */}
              <div className="flex flex-col gap-5 items-end">
                <div className="flex flex-col items-center gap-1 group cursor-pointer">
                  <div className="w-10 h-10 rounded-lg bg-iris-500/10 border border-iris-500/25 flex items-center justify-center shadow-lg backdrop-blur-md">
                    <Folder className="w-5 h-5 text-iris-300" />
                  </div>
                  <span className="text-[10px] font-medium text-white/90 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                    Projects
                  </span>
                </div>

                <div className="flex flex-col items-center gap-1 group cursor-pointer">
                  <div className="w-10 h-10 rounded-lg bg-white/[0.05] border border-white/15 flex items-center justify-center shadow-lg backdrop-blur-md">
                    <FileCode className="w-5 h-5 text-slate-300" />
                  </div>
                  <span className="text-[10px] font-medium text-white/90 drop-shadow-[0_1px_2px_rgba(0,0,0,0.8)]">
                    Aura.swift
                  </span>
                </div>
              </div>

              {/* Native macOS Floating Dock */}
              <div className="self-center flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-black/40 backdrop-blur-2xl border border-white/[0.08] shadow-[0_10px_30px_rgba(0,0,0,0.6)]">
                <div className="w-8 h-8 rounded-xl bg-gradient-to-tr from-sky-600 to-sky-400 flex items-center justify-center text-white text-[10px] font-bold shadow-sm">
                  Finder
                </div>

                <div className="w-8 h-8 rounded-xl bg-[#111318] border border-white/15 flex items-center justify-center shadow-sm">
                  <Terminal className="w-3.5 h-3.5 text-emerald-400" />
                </div>

                {/* Aura Active Icon */}
                <div className="relative flex flex-col items-center">
                  <div className="w-8 h-8 rounded-xl overflow-hidden shadow-lg border border-white/20 ring-1 ring-iris-500/40">
                    <Image
                      src="/icon.png"
                      alt="Aura Dock Icon"
                      width={32}
                      height={32}
                      className="object-cover"
                    />
                  </div>
                  <div className="w-1 h-1 rounded-full bg-white/90 mt-1" />
                </div>
              </div>
            </div>

            {/* THE PHYSICAL MACBOOK NOTCH HUD */}
            <motion.div
              animate={{
                width: current.width,
                height: current.height,
              }}
              transition={{
                type: "spring",
                stiffness: 380,
                damping: 30,
                mass: 0.85,
              }}
              onMouseEnter={() => setIsHovered(true)}
              onMouseLeave={() => setIsHovered(false)}
              className="absolute top-0 z-40 bg-black text-white rounded-b-[16px] shadow-[0_20px_50px_-10px_rgba(0,0,0,0.95)] border-b border-x border-white/[0.10] flex flex-col overflow-hidden"
            >
              {/* Subtle Notch Bottom Highlight */}
              <motion.div
                className="absolute -bottom-6 left-1/2 -translate-x-1/2 w-[70%] h-[30px] rounded-full blur-[16px] pointer-events-none"
                animate={{
                  backgroundColor: stateAccentColors[activeState],
                  opacity: isExpanded ? 0.25 : 0,
                }}
                transition={{ duration: 0.6 }}
              />

              {/* Top Notch Status Bar */}
              <div className="relative w-full h-[34px] flex items-center justify-between px-4 select-none shrink-0">
                {/* Left Ear */}
                <div className="flex items-center gap-2">
                  {!isExpanded && (
                    <motion.div layoutId="orbSlot">
                      <LivingOrbCanvas state="idle" size={18} />
                    </motion.div>
                  )}
                  <span className="text-[11px] font-bold tracking-tight text-white/90 font-sans">
                    Aura
                  </span>
                </div>

                {/* Center Hardware FaceTime Camera */}
                <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-2">
                  <div className="w-2.5 h-2.5 rounded-full bg-[#08090C] border border-white/[0.15] flex items-center justify-center">
                    <div className="w-1 h-1 rounded-full bg-indigo-950" />
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
                      <Mic className="w-2.5 h-2.5 text-iris-300" />
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
                    <span className="text-[10px] font-mono text-iris-300 px-2 py-0.5 rounded bg-iris-950/60 border border-iris-800/50 capitalize">
                      {activeState}
                    </span>
                  )}
                </div>
              </div>

              {/* Expanded Action Surface */}
              <AnimatePresence mode="wait">
                {isExpanded && (
                  <motion.div
                    initial={{ opacity: 0, y: 4 }}
                    animate={{ opacity: 1, y: 0 }}
                    exit={{ opacity: 0, y: 4 }}
                    transition={{ duration: 0.18 }}
                    className="flex-1 px-4 pb-2.5 flex flex-col justify-between"
                  >
                    <div className="flex items-start gap-3 pt-1">
                      <div className="shrink-0 mt-0.5">
                        <LivingOrbCanvas state={activeState} size={36} />
                      </div>

                      <div className="flex-1 min-w-0">
                        {activeState === "listening" && (
                          <motion.div
                            initial={{ opacity: 0, x: -8 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="space-y-1"
                          >
                            <span className="inline-flex items-center gap-1.5 text-[10px] font-mono uppercase tracking-wider text-emerald-400 font-semibold">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                              Audio Tap Active
                            </span>
                            <p className="text-[12px] text-slate-100 font-medium leading-snug">
                              &ldquo;Set volume to 20% and take a workspace screenshot&rdquo;
                            </p>
                          </motion.div>
                        )}

                        {activeState === "processing" && (
                          <motion.div
                            initial={{ opacity: 0, x: -8 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="space-y-2"
                          >
                            <div className="flex items-center gap-2">
                              <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                                OpenAgentSDK Engine
                              </span>
                              <motion.span
                                className="w-1.5 h-1.5 rounded-full bg-iris-400"
                                animate={{ scale: [1, 1.4, 1] }}
                                transition={{ repeat: Infinity, duration: 0.8 }}
                              />
                            </div>
                            <div className="h-1 w-full bg-white/[0.06] rounded-full overflow-hidden">
                              <motion.div
                                className="h-full rounded-full bg-gradient-to-r from-iris-500 to-iris-300"
                                initial={{ width: "0%" }}
                                animate={{ width: "80%" }}
                                transition={{ duration: 2.5, ease: "easeOut" }}
                              />
                            </div>
                            <div className="flex flex-wrap gap-1.5">
                              <span className="inline-flex items-center gap-1 text-[10px] font-mono bg-white/[0.06] border border-white/[0.08] px-2 py-0.5 rounded text-slate-200">
                                <Volume2 className="w-3 h-3 text-iris-400" />
                                adjust_volume(20)
                              </span>
                              <span className="inline-flex items-center gap-1 text-[10px] font-mono bg-white/[0.06] border border-white/[0.08] px-2 py-0.5 rounded text-slate-200">
                                <Terminal className="w-3 h-3 text-emerald-400" />
                                take_screenshot()
                              </span>
                            </div>
                          </motion.div>
                        )}

                        {activeState === "speaking" && (
                          <motion.div
                            initial={{ opacity: 0, x: -8 }}
                            animate={{ opacity: 1, x: 0 }}
                            className="space-y-1"
                          >
                            <span className="text-[10px] font-mono uppercase tracking-wider text-iris-400 font-semibold">
                              Aura Speech Output
                            </span>
                            <p className="text-[12px] text-slate-100 leading-snug">
                              System audio ducked and set to 20%. Screenshot saved to Desktop as{" "}
                              <span className="text-iris-300 font-mono">
                                Screen.png
                              </span>.
                            </p>
                          </motion.div>
                        )}
                      </div>
                    </div>

                    {/* Footer */}
                    <div className="flex items-center justify-between pt-2 border-t border-white/[0.06] text-[10px] text-slate-400">
                      <div className="flex items-center gap-1.5 text-slate-400 hover:text-white transition-colors cursor-pointer">
                        <MessageSquare className="w-3 h-3" />
                        <span>Control Center Chat (⌘1)</span>
                      </div>
                      <span className="font-mono text-[9px] text-slate-500">
                        {activeState === "listening" && "Press ⌥ Space to send"}
                        {activeState === "processing" && "Executing native tools"}
                        {activeState === "speaking" && "Barge-in enabled"}
                      </span>
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>
            </motion.div>
          </div>
        </div>
      </div>

      {/* State Switcher Tabs */}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-1.5 p-1 rounded-full bg-[#090B10]/90 border border-white/[0.07] backdrop-blur-xl shadow-hairline">
        {[
          {
            state: "idle" as const,
            icon: Activity,
            label: "1. Idle (Ambient)",
          },
          {
            state: "listening" as const,
            icon: Mic,
            label: "2. Listening (Tap)",
          },
          {
            state: "processing" as const,
            icon: Cpu,
            label: "3. Reasoning (SDK)",
          },
          {
            state: "speaking" as const,
            icon: Volume2,
            label: "4. Speaking (TTS)",
          },
        ].map(({ state, icon: Icon, label }) => {
          const isActive = activeState === state;

          return (
            <button
              key={state}
              onClick={() => handleManualStateChange(state)}
              className={`relative flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-medium transition-all ${
                isActive
                  ? "bg-white/[0.10] text-white border border-white/15 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.03]"
              }`}
            >
              <Icon className={`w-3.5 h-3.5 ${isActive ? "text-iris-400" : "text-slate-500"}`} />
              <span>{label}</span>

              {isActive && !isUserInteracting && (
                <motion.div
                  className="absolute bottom-0 left-0 h-[2px] bg-iris-400 rounded-full"
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
