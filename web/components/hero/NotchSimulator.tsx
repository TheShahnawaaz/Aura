"use client";

import React, { useState, useEffect, useCallback, useRef } from "react";
import { motion, AnimatePresence } from "framer-motion";
import Image from "next/image";
import { AppleLogo } from "@/components/icons/AppleLogo";
import { LivingOrbCanvas, AssistantOrbState } from "./LivingOrbCanvas";
import {
  MessageSquare,
  Check,
  Volume2,
  Terminal,
  Mic,
  Cpu,
  Wifi,
  Battery,
  Search,
  Sliders,
  ChevronDown,
  Sparkles,
  Copy,
  Plus,
  ArrowUpRight,
  Radio,
} from "lucide-react";

export type ExtendedHUDState =
  | "idle"
  | "listening"
  | "processing"
  | "speaking"
  | "inspector";

const STATE_ORDER: ExtendedHUDState[] = [
  "idle",
  "listening",
  "processing",
  "speaking",
  "inspector",
];
const STATE_DURATION = 5000; // ms per state during auto-cycle

// Specular ambient glow colors matching HUDDesignTokens.Colors
const stateGlowColors: Record<ExtendedHUDState, string> = {
  idle: "rgba(99, 102, 241, 0.08)",
  listening: "rgba(0, 242, 235, 0.16)",
  processing: "rgba(168, 85, 247, 0.18)",
  speaking: "rgba(251, 113, 133, 0.16)",
  inspector: "rgba(56, 189, 248, 0.12)",
};

const stateAccentColors: Record<ExtendedHUDState, string> = {
  idle: "#6366F1",
  listening: "#00F2EB",
  processing: "#A855F7",
  speaking: "#FB7185",
  inspector: "#38BDF8",
};

// Dimensions matching native NotchGeometry and HUDDesignTokens
const dimensions: Record<ExtendedHUDState, { width: number; height: number }> = {
  idle: { width: 220, height: 34 },
  listening: { width: 520, height: 140 },
  processing: { width: 520, height: 162 },
  speaking: { width: 520, height: 172 },
  inspector: { width: 520, height: 215 },
};

// Mini Hardware Keycap Component matching MiniKeycapView.swift
export const MiniKeycap: React.FC<{ label: string }> = ({ label }) => (
  <kbd className="inline-flex items-center justify-center px-1.5 py-0.5 rounded-[3.5px] bg-gradient-to-b from-white/[0.14] to-white/[0.05] border border-white/20 text-white/75 font-mono text-[8.5px] font-semibold shadow-[0_1px_2px_rgba(0,0,0,0.4)]">
    {label}
  </kbd>
);

// Micro Copy Action Button matching HUDCopyButton.swift
export const HUDCopyButton: React.FC<{ text: string }> = ({ text }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = (e: React.MouseEvent) => {
    e.stopPropagation();
    if (typeof navigator !== "undefined" && navigator.clipboard) {
      navigator.clipboard.writeText(text);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 1600);
  };

  return (
    <button
      onClick={handleCopy}
      className="flex items-center gap-1 px-1.5 py-0.5 rounded-[4px] bg-white/[0.06] hover:bg-white/[0.12] border border-white/10 text-[8.5px] text-white/45 hover:text-white transition-all cursor-pointer"
      title="Copy to clipboard"
    >
      {copied ? (
        <>
          <Check className="w-2.5 h-2.5 text-emerald-400" />
          <span className="text-emerald-400 font-medium">Copied</span>
        </>
      ) : (
        <Copy className="w-2.5 h-2.5 text-white/50" />
      )}
    </button>
  );
};

// Fluid Audio Waveform View for Listening State matching FluidWaveformView.swift
const ListeningWaveformBars: React.FC = () => (
  <div className="flex items-center gap-[2.5px] h-4">
    {[0.45, 0.85, 1.2, 0.9, 0.5].map((mult, i) => (
      <motion.div
        key={i}
        className="w-[2.5px] rounded-full"
        style={{
          background: "linear-gradient(to top, #00F2EB, #34D399)",
          boxShadow: "0 0 3px rgba(0, 242, 235, 0.6)",
        }}
        animate={{
          height: [
            Math.max(4, 16 * mult * 0.35),
            Math.max(4, 16 * mult),
            Math.max(4, 16 * mult * 0.5),
          ],
        }}
        transition={{
          repeat: Infinity,
          duration: 0.85 + i * 0.12,
          ease: "easeInOut",
        }}
      />
    ))}
  </div>
);

// Vocal Equalizer Waveform View for Speaking State matching SpeakingWaveformView.swift
const SpeakingWaveformBars: React.FC = () => (
  <div className="flex items-center gap-[2.5px] h-4">
    {[0.4, 0.9, 1.25, 0.8, 0.45].map((mult, i) => (
      <motion.div
        key={i}
        className="w-[2.5px] rounded-full"
        style={{
          background: "linear-gradient(to top, #FB7185, #FDBA74)",
          boxShadow: "0 0 3px rgba(251, 113, 133, 0.6)",
        }}
        animate={{
          height: [
            Math.max(3.5, 16 * mult * 0.4),
            Math.max(3.5, 16 * mult),
            Math.max(3.5, 16 * mult * 0.3),
          ],
        }}
        transition={{
          repeat: Infinity,
          duration: 0.9 + i * 0.15,
          ease: "easeInOut",
        }}
      />
    ))}
  </div>
);

// Orbit Spinner matching AuroraOrbitSpinner.swift
const AuroraOrbitSpinner: React.FC = () => (
  <div className="flex items-center gap-1.5">
    <div className="relative w-2.5 h-2.5">
      <div className="absolute inset-0 rounded-full border border-white/15" />
      <motion.div
        className="absolute inset-0 rounded-full border border-transparent border-t-purple-400 border-r-cyan-400"
        animate={{ rotate: 360 }}
        transition={{ repeat: Infinity, duration: 0.9, ease: "linear" }}
      />
    </div>
    <span className="text-[9px] font-bold text-[#BF94FF] tracking-tight">Thinking</span>
  </div>
);

export const NotchSimulator: React.FC = () => {
  const [activeState, setActiveState] = useState<ExtendedHUDState>("idle");
  const [isHovered, setIsHovered] = useState(false);
  const [isUserInteracting, setIsUserInteracting] = useState(false);
  const [progress, setProgress] = useState(0);
  const [notchScale, setNotchScale] = useState(0.76);
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const progressRef = useRef<NodeJS.Timeout | null>(null);

  // Responsive proportional scale matching native Retina 16:10 hardware display ratio
  useEffect(() => {
    const handleResize = () => {
      const w = window.innerWidth;
      if (w < 480) {
        setNotchScale(0.52);
      } else if (w < 768) {
        setNotchScale(0.62);
      } else if (w < 1024) {
        setNotchScale(0.70);
      } else {
        setNotchScale(0.76);
      }
    };
    handleResize();
    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []);

  useEffect(() => {
    if (typeof window !== "undefined") {
      const params = new URLSearchParams(window.location.search);
      const s = params.get("state") as ExtendedHUDState;
      if (s && STATE_ORDER.includes(s)) {
        setActiveState(s);
        setIsUserInteracting(true);
      }
    }
  }, []);

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

  const handleManualStateChange = (state: ExtendedHUDState) => {
    setIsUserInteracting(true);
    setActiveState(state);
    setProgress(0);

    setTimeout(() => setIsUserInteracting(false), 9000);
  };

  // Keyboard shortcut handlers matching native Aura (⌥ Space or ⌥ A)
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.altKey && (e.code === "Space" || e.key === " " || e.key === "a" || e.key === "A")) {
        e.preventDefault();
        setActiveState((prev) => {
          const currentIdx = STATE_ORDER.indexOf(prev);
          return STATE_ORDER[(currentIdx + 1) % STATE_ORDER.length];
        });
        setIsUserInteracting(true);
        setTimeout(() => setIsUserInteracting(false), 9000);
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, []);

  const current = dimensions[activeState];
  const isExpanded = activeState !== "idle";

  // MacBook Notch geometry parameters (matching NotchShape.swift)
  const earRadius = 6;
  const bottomRadius = isExpanded ? 20 : 14;
  const W = current.width;
  const H = current.height;

  // Genuine Notch path with top concave fillets (reverse ears) and rounded bottom corners
  const notchFillPath = `
    M 0 0
    C ${earRadius * 0.552} 0, ${earRadius} ${earRadius * 0.448}, ${earRadius} ${earRadius}
    L ${earRadius} ${H - bottomRadius}
    Q ${earRadius} ${H}, ${earRadius + bottomRadius} ${H}
    L ${W - earRadius - bottomRadius} ${H}
    Q ${W - earRadius} ${H}, ${W - earRadius} ${H - bottomRadius}
    L ${W - earRadius} ${earRadius}
    C ${W - earRadius} ${earRadius * 0.448}, ${W - earRadius * 0.552} 0, ${W} 0
    Z
  `;

  // Perimeter stroke path: leaves top edge flush and unstroked (matching NotchBorderShape.swift)
  const notchStrokePath = `
    M 0 0
    C ${earRadius * 0.552} 0, ${earRadius} ${earRadius * 0.448}, ${earRadius} ${earRadius}
    L ${earRadius} ${H - bottomRadius}
    Q ${earRadius} ${H}, ${earRadius + bottomRadius} ${H}
    L ${W - earRadius - bottomRadius} ${H}
    Q ${W - earRadius} ${H}, ${W - earRadius} ${H - bottomRadius}
    L ${W - earRadius} ${earRadius}
    C ${W - earRadius} ${earRadius * 0.448}, ${W - earRadius * 0.552} 0, ${W} 0
  `;

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
          A
        </kbd>
        <span className="text-slate-400">or</span>
        <kbd className="px-1.5 py-0.5 rounded bg-white/[0.08] border border-white/[0.12] text-white font-mono text-[10.5px] font-semibold">
          Space
        </kbd>
        <span className="text-slate-400">to cycle live HUD preview</span>
      </motion.div>

      {/* 16-INCH MACBOOK PRO HARDWARE CHASSIS */}
      <div className="relative w-full">
        {/* Ambient Display Backlight */}
        <motion.div
          className="absolute -inset-10 rounded-full blur-[100px] pointer-events-none"
          animate={{
            backgroundColor: stateGlowColors[activeState],
            scale: isExpanded ? 1.05 : 1,
          }}
          transition={{ duration: 1.2, ease: "easeInOut" }}
        />

        {/* PHOTOREALISTIC MACBOOK PRO ENCLOSURE (16:10 RETINA DISPLAY) */}
        <div className="w-full flex flex-col items-center">
          {/* Top Lid / Display Bezel */}
          <div className="relative w-full rounded-t-[20px] rounded-b-[4px] p-2 sm:p-2.5 bg-gradient-to-b from-[#252831] via-[#16181F] to-[#0F1014] border border-white/[0.14] shadow-[0_30px_70px_-15px_rgba(0,0,0,0.95)]">
            {/* Active Display Screen (Strict 16:10 Apple Display Aspect Ratio) */}
            <div className="relative w-full aspect-[16/10] rounded-[10px] overflow-hidden bg-black flex flex-col items-center select-none shadow-[inset_0_0_0_1px_rgba(255,255,255,0.06)]">
              {/* Authentic macOS Sequoia Conifer Forest Wallpaper (100% Full Bleed - No Borders) */}
              <div
                className="absolute inset-0 bg-cover bg-center pointer-events-none"
                style={{
                  backgroundImage: "url('/wallpaper-forest.webp')",
                  backgroundPosition: "center 24%",
                }}
              />

              {/* Cinematic Vignette */}
              <div className="absolute inset-0 bg-gradient-to-b from-black/30 via-transparent to-black/50 pointer-events-none" />

              {/* Native macOS Sequoia Menubar (26px height - exactly flush with scaled idle notch) */}
              <div className="w-full h-[26px] px-3.5 flex items-center justify-between text-[10.5px] font-medium text-slate-200 z-20 backdrop-blur-md bg-black/25 border-b border-white/[0.06]">
                {/* Left System Items */}
                <div className="flex items-center gap-3">
                  <AppleLogo className="w-3 h-3 fill-white shrink-0 -translate-y-[0.5px]" />
                  <span className="font-semibold text-white">Finder</span>
                  <span className="hidden md:inline text-slate-300">File</span>
                  <span className="hidden md:inline text-slate-300">Edit</span>
                  <span className="hidden lg:inline text-slate-300">View</span>
                  <span className="hidden lg:inline text-slate-300">Go</span>
                  <span className="hidden xl:inline text-slate-300">Window</span>
                  <span className="hidden xl:inline text-slate-300">Help</span>
                </div>

                {/* Right Status Items matching screenshot */}
                <div className="flex items-center gap-2.5 text-slate-300">
                  <span className="text-slate-400 text-[10.5px]">✦</span>
                  <span className="text-slate-400 font-semibold text-[10px]">A</span>
                  <Battery className="w-3.5 h-3.5 opacity-85" />
                  <Wifi className="w-3 h-3 opacity-85" />
                  <Search className="w-2.5 h-2.5 opacity-85" />
                  <Sliders className="w-2.5 h-2.5 opacity-85" />
                  <span className="font-mono text-[9.5px] tracking-tight text-white font-medium">
                    Mon 10:42 AM
                  </span>
                </div>
              </div>

              {/* Floating macOS Dock */}
              <div className="absolute bottom-2.5 sm:bottom-3 left-1/2 -translate-x-1/2 flex items-center gap-2 px-3 py-1.5 rounded-2xl bg-black/40 backdrop-blur-2xl border border-white/[0.10] shadow-[0_12px_32px_rgba(0,0,0,0.65)] z-20">
                <div className="w-7 h-7 sm:w-8 sm:h-8 rounded-xl bg-gradient-to-tr from-sky-600 to-sky-400 flex items-center justify-center text-white text-[9px] sm:text-[10px] font-bold shadow-sm">
                  Finder
                </div>

                <div className="w-7 h-7 sm:w-8 sm:h-8 rounded-xl bg-[#111318] border border-white/15 flex items-center justify-center shadow-sm">
                  <Terminal className="w-3 h-3 sm:w-3.5 sm:h-3.5 text-emerald-400" />
                </div>

                {/* Aura Active Icon with Running Dot */}
                <div className="relative flex flex-col items-center">
                  <div className="w-7 h-7 sm:w-8 sm:h-8 rounded-xl overflow-hidden shadow-lg border border-white/25 ring-1 ring-iris-500/50">
                    <Image
                      src="/icon.png"
                      alt="Aura Dock Icon"
                      width={32}
                      height={32}
                      className="object-cover"
                    />
                  </div>
                  <div className="w-1 h-1 rounded-full bg-white/95 mt-0.5 shadow-sm" />
                </div>
              </div>

              {/* PROPORTIONALLY SCALED NOTCH MOUNT */}
              <div className="absolute top-0 left-1/2 w-0 flex justify-center pointer-events-none z-40">
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
                  className="relative flex flex-col items-center pointer-events-auto shrink-0"
                  style={{
                    width: `${current.width}px`,
                    height: `${current.height}px`,
                    transform: `scale(${notchScale})`,
                    transformOrigin: "top center",
                  }}
                >
              {/* Silhouette SVG Layer with Apple Reverse Fillet Ears & Specular Contour */}
              <svg
                className="absolute inset-0 w-full h-full pointer-events-none drop-shadow-[0_20px_40px_rgba(0,0,0,0.95)]"
                viewBox={`0 0 ${current.width} ${current.height}`}
              >
                <defs>
                  {/* Resting Notch Border Gradient (crisp contour rim) */}
                  <linearGradient id="restingNotchBorder" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="rgba(255,255,255,0.65)" />
                    <stop offset="50%" stopColor="rgba(255,255,255,0.48)" />
                    <stop offset="100%" stopColor="rgba(255,255,255,0.28)" />
                  </linearGradient>

                  {/* Expanded Notch Border Gradient (liquid-glass specular edge) */}
                  <linearGradient id="expandedNotchBorder" x1="0%" y1="0%" x2="0%" y2="100%">
                    <stop offset="0%" stopColor="rgba(255,255,255,0.0)" />
                    <stop offset="25%" stopColor="rgba(255,255,255,0.14)" />
                    <stop offset="65%" stopColor="rgba(255,255,255,0.26)" />
                    <stop offset="100%" stopColor="rgba(255,255,255,0.18)" />
                  </linearGradient>

                  {/* Clip Path to crop notch container to Apple physical silhouette */}
                  <clipPath id="notchClip">
                    <path d={notchFillPath} />
                  </clipPath>
                </defs>

                {/* Pure Pitch-Black Notch Fill */}
                <path d={notchFillPath} fill="#000000" />

                {/* Specular Hairline Contour Stroke (open at top display edge) */}
                <path
                  d={notchStrokePath}
                  fill="none"
                  stroke={isExpanded ? "url(#expandedNotchBorder)" : "url(#restingNotchBorder)"}
                  strokeWidth={isExpanded ? 0.9 : 1.25}
                />
              </svg>

              {/* Obsidian Liquid-Glass Interior Depth Layer */}
              <div
                className="relative w-full h-full flex flex-col overflow-hidden"
                style={{
                  clipPath: "url(#notchClip)",
                }}
              >
                {/* Lower Dropdown Glass & Ambient Radial Glow */}
                {isExpanded && (
                  <div className="absolute inset-0 pointer-events-none">
                    <div className="absolute inset-x-0 top-[34px] bottom-0 bg-[#090A0C]/85 backdrop-blur-xl" />
                    <motion.div
                      className="absolute bottom-0 left-1/2 -translate-x-1/2 w-[340px] h-[120px] rounded-full blur-[24px] pointer-events-none"
                      animate={{
                        backgroundColor: stateGlowColors[activeState],
                        opacity: 0.35,
                      }}
                      transition={{ duration: 0.5 }}
                    />
                  </div>
                )}

                {/* TOP NOTCH CAP BAR (34px tall: Left Ear | Camera Notch Spacer | Right Ear) */}
                <div className="relative w-full h-[34px] flex items-center justify-between px-3.5 select-none shrink-0 z-20">
                  {/* Left Ear */}
                  <div className="flex items-center gap-2 min-w-[50px]">
                    {activeState === "idle" ? (
                      /* Idle Resting: Living Orb Only (No text, exact match to screenshot) */
                      <LivingOrbCanvas state="idle" size={20} />
                    ) : activeState === "inspector" ? (
                      /* Chat Inspector: Living Orb + "Aura" text */
                      <>
                        <LivingOrbCanvas state="idle" size={20} />
                        <span className="text-[11px] font-bold tracking-[0.5px] text-white/92 font-sans">
                          Aura
                        </span>
                      </>
                    ) : (
                      /* Active Turn (Listening, Reasoning, Speaking): "Aura" text */
                      <span className="text-[11px] font-bold tracking-[0.5px] text-white/92 font-sans">
                        Aura
                      </span>
                    )}
                  </div>

                  {/* Center Hardware FaceTime Camera Spacer */}
                  <div className="absolute left-1/2 -translate-x-1/2 flex items-center gap-2 pointer-events-none">
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

                  {/* Right Ear Activity Indicator */}
                  <div className="flex items-center gap-1.5 justify-end min-w-[50px]">
                    {activeState === "idle" ? (
                      /* Idle: Message Pill */
                      <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-white/[0.06] border border-white/[0.08] text-[10px] font-semibold text-white/90">
                        <ChevronDown className="w-2.5 h-2.5 text-white/50" />
                        <span>8 msgs</span>
                      </div>
                    ) : activeState === "listening" ? (
                      /* Listening: 5-bar Cyan Equalizer */
                      <ListeningWaveformBars />
                    ) : activeState === "processing" ? (
                      /* Reasoning: Orbit Spinner + "Thinking" */
                      <AuroraOrbitSpinner />
                    ) : activeState === "speaking" ? (
                      /* Speaking: 5-bar Coral Equalizer */
                      <SpeakingWaveformBars />
                    ) : (
                      /* Inspector: Message Pill */
                      <div className="flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-white/[0.06] border border-white/[0.08] text-[10px] font-semibold text-white/90">
                        <ChevronDown className="w-2.5 h-2.5 text-white/50" />
                        <span>18 msgs</span>
                      </div>
                    )}
                  </div>
                </div>

                {/* DYNAMIC EXPANDED CONTENT AREA */}
                <AnimatePresence mode="wait">
                  {isExpanded && (
                    <motion.div
                      key={activeState}
                      initial={{ opacity: 0, y: 3 }}
                      animate={{ opacity: 1, y: 0 }}
                      exit={{ opacity: 0, y: 3 }}
                      transition={{ duration: 0.18 }}
                      className="flex-1 px-4 pb-3 flex flex-col justify-between z-20 min-h-0"
                    >
                      {/* STATE 2, 3, 4: ACTIVE TURN (Listening, Reasoning, Speaking) */}
                      {activeState !== "inspector" ? (
                        <div className="flex items-start gap-3.5 pt-0.5">
                          {/* Left Column: 40x40 Living Aurora Orb */}
                          <div className="shrink-0 mt-0.5 relative">
                            <LivingOrbCanvas
                              state={activeState as AssistantOrbState}
                              size={40}
                            />
                            {/* Ambient Orb Backglow */}
                            <div
                              className="absolute -inset-1 rounded-full blur-md -z-10 pointer-events-none"
                              style={{
                                backgroundColor: stateGlowColors[activeState],
                              }}
                            />
                          </div>

                          {/* Right Column: HUD Glass Card & Footer */}
                          <div className="flex-1 min-w-0 flex flex-col justify-between">
                            {/* 1. LISTENING CARD */}
                            {activeState === "listening" && (
                              <div className="rounded-[11px] bg-[#1a1a21]/55 backdrop-blur-md border border-white/10 p-2.5 shadow-sm">
                                <div className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-[#00F2EB]/12 border border-[#00F2EB]/25 text-[#00F2EB] text-[8.5px] font-bold tracking-wider">
                                  <span className="w-1.5 h-1.5 rounded-full bg-[#00F2EB] shadow-[0_0_4px_#00F2EB] animate-pulse" />
                                  LISTENING
                                </div>
                                <p className="text-[13px] font-medium text-white/95 leading-snug tracking-tight mt-1.5 font-sans">
                                  Hi Ara how are you
                                </p>
                              </div>
                            )}

                            {/* 2. REASONING / PROCESSING CARD */}
                            {activeState === "processing" && (
                              <div className="rounded-[11px] bg-[#1a1a21]/55 backdrop-blur-md border border-white/10 p-2.5 shadow-sm space-y-1.5">
                                <div className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-[#A855F7]/15 border border-[#A855F7]/25 text-[#C084FC] text-[8.5px] font-bold tracking-wider">
                                  <Sparkles className="w-2.5 h-2.5 text-[#C084FC]" />
                                  REASONING
                                </div>

                                {/* Shimmer Progress Beam matching AuroraShimmerBeam.swift */}
                                <div className="relative w-full h-[2.5px] bg-white/[0.08] rounded-full overflow-hidden">
                                  <motion.div
                                    className="h-full rounded-full"
                                    style={{
                                      width: "42%",
                                      background:
                                        "linear-gradient(90deg, #A855F7, #38BDF8, #E879F9, #38BDF8)",
                                      boxShadow: "0 0 8px rgba(168, 85, 247, 0.75)",
                                    }}
                                    animate={{ x: ["-10%", "145%", "-10%"] }}
                                    transition={{
                                      duration: 2.2,
                                      repeat: Infinity,
                                      ease: "easeInOut",
                                    }}
                                  />
                                </div>

                                <div className="space-y-0.5">
                                  <div className="text-[12.5px] font-semibold text-white/95 font-sans">
                                    Thinking...
                                  </div>
                                  <div className="text-[10px] text-white/45 font-sans">
                                    Aura is synthesizing context and orchestrating tools...
                                  </div>
                                </div>
                              </div>
                            )}

                            {/* 3. SPEAKING CARD */}
                            {activeState === "speaking" && (
                              <div className="rounded-[11px] bg-[#1a1a21]/55 backdrop-blur-md border border-white/10 p-2.5 shadow-sm">
                                <div className="flex items-center justify-between">
                                  <div className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full bg-[#FB7185]/12 border border-[#FB7185]/25 text-[#FB7185] text-[8.5px] font-bold tracking-wider">
                                    <Sparkles className="w-2.5 h-2.5 text-[#FB7185]" />
                                    AURA
                                  </div>
                                  <HUDCopyButton text="Hi! I'm doing great, thank you for asking. How are you doing today?" />
                                </div>
                                <p className="text-[12.5px] font-normal text-white/93 leading-relaxed mt-1.5 font-sans">
                                  Hi! I&apos;m doing great, thank you for asking. How are you doing today?
                                </p>
                              </div>
                            )}

                            {/* PINNED FOOTER ROW */}
                            <div className="flex items-center justify-between text-[9.5px] mt-2 pt-0.5">
                              {/* Left Hint */}
                              <div>
                                {activeState === "listening" && (
                                  <div className="flex items-center gap-1.5 text-white/45 font-sans">
                                    <span>Press</span>
                                    <MiniKeycap label="⌥ A" />
                                    <span>again to send</span>
                                  </div>
                                )}
                                {activeState === "processing" && (
                                  <div className="flex items-center gap-1.5 text-white/50 font-sans">
                                    <span className="w-1.5 h-1.5 rounded-full bg-purple-400" />
                                    <span>Orchestrating...</span>
                                  </div>
                                )}
                                {activeState === "speaking" && (
                                  <div className="flex items-center gap-1.5 text-white/50 font-sans">
                                    <span className="w-1.5 h-1.5 rounded-full bg-rose-400" />
                                    <span>Speaking response...</span>
                                  </div>
                                )}
                              </div>

                              {/* Right Actions */}
                              <div className="flex items-center gap-2">
                                <div className="flex items-center gap-1 text-white/40">
                                  <MiniKeycap label="⎋ esc" />
                                  <span className="text-[9px]">to cancel</span>
                                </div>
                                <span className="text-white/20 text-[8px]">•</span>
                                <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-white/[0.06] hover:bg-white/10 border border-white/[0.08] text-white/60 hover:text-white transition-colors cursor-pointer text-[9px] font-semibold">
                                  <MessageSquare className="w-2.5 h-2.5" />
                                  <span>Open Chat</span>
                                </div>
                              </div>
                            </div>
                          </div>
                        </div>
                      ) : (
                        /* STATE 5: CHAT INSPECTOR / HOVER THREAD (LastTurnInspectorView.swift) */
                        <div className="flex flex-col space-y-2 pt-0.5">
                          {/* Subheader Bar */}
                          <div className="flex items-center justify-between">
                            <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/[0.06] border border-white/10 text-white text-[11px] font-bold">
                              <MessageSquare className="w-3 h-3 text-blue-400 fill-blue-400/20" />
                              <span>Greeting and Audio Check</span>
                            </div>

                            <div className="flex items-center gap-2">
                              <button className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/[0.08] hover:bg-white/[0.14] border border-white/10 text-white/85 text-[9.5px] font-medium transition-colors cursor-pointer">
                                <Plus className="w-2.5 h-2.5 font-bold" />
                                <span>New Chat</span>
                              </button>
                              <button className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-blue-500/15 hover:bg-blue-500/25 border border-blue-500/30 text-blue-400 text-[9.5px] font-medium transition-colors cursor-pointer">
                                <span>Open in Full App</span>
                                <ArrowUpRight className="w-2.5 h-2.5" />
                              </button>
                            </div>
                          </div>

                          {/* Stacked Messages */}
                          <div className="space-y-2">
                            {/* User Message Card */}
                            <div className="rounded-[11px] bg-[#1a1a21]/55 backdrop-blur-md border border-white/10 p-2 shadow-sm space-y-1">
                              <div className="flex items-center gap-1 text-blue-400 text-[9px] font-bold">
                                <Mic className="w-2.5 h-2.5" />
                                <span>You</span>
                              </div>
                              <p className="text-[11.5px] font-medium text-white/92">
                                Say hi how are you
                              </p>
                            </div>

                            {/* Assistant Response Card */}
                            <div className="rounded-[11px] bg-[#1a1a21]/55 backdrop-blur-md border border-white/10 p-2 shadow-sm space-y-1">
                              <div className="flex items-center justify-between">
                                <div className="flex items-center gap-1 text-purple-400 text-[9px] font-bold">
                                  <Sparkles className="w-2.5 h-2.5" />
                                  <span>Aura</span>
                                </div>
                                <HUDCopyButton text="Hi! I'm doing great, thank you for asking. How are you doing today?" />
                              </div>
                              <p className="text-[12px] font-normal text-white/92 leading-relaxed">
                                Hi! I&apos;m doing great, thank you for asking. How are you doing today?
                              </p>
                            </div>
                          </div>
                        </div>
                      )}
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            </motion.div>
          </div>
        </div>
      </div>

      {/* LOWER MACBOOK UNIBODY CHASSIS (ALUMINUM DECK & THUMB SCOOP) */}
      <div className="relative w-[101.6%] self-center h-[14px] sm:h-[18px] bg-gradient-to-b from-[#282B34] via-[#1C1E25] to-[#121418] border-t border-white/[0.22] rounded-b-[10px] shadow-[0_20px_45px_-10px_rgba(0,0,0,0.95)] z-10 flex items-start justify-center">
        {/* Display Hinge Center Line */}
        <div className="absolute -top-[3px] inset-x-8 h-[3px] bg-[#0A0B0E] rounded-t-sm" />
        {/* Iconic Centered Lid Opening Thumb Scoop */}
        <div className="w-20 sm:w-28 h-[5px] sm:h-[6px] rounded-b-[6px] bg-[#090A0D] border-b border-white/[0.12] shadow-[inset_0_2px_4px_rgba(0,0,0,0.85)]" />
      </div>

      {/* Ambient Desk Reflection Shadow */}
      <div className="w-[88%] mx-auto h-[12px] bg-black/80 blur-[14px] rounded-full mt-0.5 pointer-events-none" />
    </div>
  </div>

      {/* State Switcher Tabs (All 5 states from user screenshots) */}
      <div className="mt-6 flex flex-wrap items-center justify-center gap-1.5 p-1 rounded-full bg-[#090B10]/90 border border-white/[0.07] backdrop-blur-xl shadow-hairline">
        {[
          {
            state: "idle" as const,
            icon: Radio,
            label: "1. Idle (Resting)",
          },
          {
            state: "listening" as const,
            icon: Mic,
            label: "2. Listening",
          },
          {
            state: "processing" as const,
            icon: Cpu,
            label: "3. Reasoning",
          },
          {
            state: "speaking" as const,
            icon: Volume2,
            label: "4. Speaking",
          },
          {
            state: "inspector" as const,
            icon: MessageSquare,
            label: "5. Chat Inspector",
          },
        ].map(({ state, icon: Icon, label }) => {
          const isActive = activeState === state;

          return (
            <button
              key={state}
              onClick={() => handleManualStateChange(state)}
              className={`relative flex items-center gap-2 px-3.5 py-1.5 rounded-full text-xs font-medium transition-all cursor-pointer ${
                isActive
                  ? "bg-white/[0.10] text-white border border-white/15 shadow-sm"
                  : "text-slate-400 hover:text-slate-200 hover:bg-white/[0.03]"
              }`}
            >
              <Icon
                className={`w-3.5 h-3.5 ${
                  isActive ? "text-iris-400" : "text-slate-500"
                }`}
              />
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
