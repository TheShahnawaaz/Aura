"use client";

import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export type AssistantOrbState =
  | "idle"
  | "listening"
  | "processing"
  | "speaking"
  | "inspector";

interface LivingOrbCanvasProps {
  state?: AssistantOrbState;
  size?: number;
  showSquircle?: boolean;
  className?: string;
}

export const LivingOrbCanvas: React.FC<LivingOrbCanvasProps> = ({
  state = "idle",
  size = 22,
  showSquircle = false,
  className = "",
}) => {
  const squircleSize = size * 1.36;
  const cornerRadius = squircleSize * 0.2237;

  const [time, setTime] = useState(0);

  useEffect(() => {
    let animId: number;
    const start = performance.now();
    const loop = (now: number) => {
      setTime((now - start) / 1000);
      animId = requestAnimationFrame(loop);
    };
    animId = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(animId);
  }, []);

  // Normalize state for rendering
  const orbState = state === "inspector" ? "idle" : state;

  // Generate dynamic horizontal acoustic sine wave path across the orb (matches Swift FluidAcousticWave)
  const generateSineWavePath = (
    w: number,
    h: number,
    amplitude: number,
    freq: number,
    phase: number
  ) => {
    const points: string[] = [];
    const steps = 24;
    const midY = h / 2;
    for (let i = 0; i <= steps; i++) {
      const x = (i / steps) * w;
      const angle = (i / steps) * Math.PI * 2 * freq + phase;
      const y = midY + Math.sin(angle) * amplitude;
      if (i === 0) {
        points.push(`M ${x.toFixed(1)} ${y.toFixed(1)}`);
      } else {
        points.push(`L ${x.toFixed(1)} ${y.toFixed(1)}`);
      }
    }
    return points.join(" ");
  };

  const orbContent = (
    <div
      className="relative flex items-center justify-center select-none overflow-hidden rounded-full"
      style={{
        width: `${size}px`,
        height: `${size}px`,
        background: "radial-gradient(circle at 45% 45%, #071120 0%, #020409 100%)",
        boxShadow: "0 2px 10px rgba(0,0,0,0.6), inset 0 0 1px rgba(255,255,255,0.4)",
      }}
    >
      {/* 1. STATE-SPECIFIC INTERNAL VISUAL ARCHITECTURE */}
      <AnimatePresence mode="wait">
        {orbState === "idle" && (
          <motion.div
            key="idle"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ duration: 0.35 }}
            className="absolute inset-0 flex items-center justify-center"
          >
            {/* Celestial Floating Nebula Stream */}
            <motion.div
              animate={{
                rotate: [0, 360],
                x: [Math.sin(time * 0.8) * (size * 0.08)],
                y: [Math.cos(time * 0.6) * (size * 0.06)],
              }}
              transition={{ rotate: { repeat: Infinity, duration: 16, ease: "linear" } }}
              className="absolute w-[92%] h-[92%] rounded-full blur-[3px]"
              style={{
                background: "conic-gradient(from 0deg, #00E5FF, #2563EB, #8B5CF6, #38BDF8, #00E5FF)",
              }}
            />

            {/* Counter-harmonic celestial mist */}
            <motion.div
              animate={{ rotate: [360, 0] }}
              transition={{ repeat: Infinity, duration: 12, ease: "linear" }}
              className="absolute w-[80%] h-[80%] rounded-full blur-[4px] mix-blend-screen opacity-75"
              style={{
                background: "conic-gradient(from 90deg, #A855F7, #00E5FF, #38BDF8, #A855F7)",
              }}
            />

            {/* Star-Core Singularity */}
            <motion.div
              animate={{ scale: [0.85, 1.1, 0.85], opacity: [0.9, 1.0, 0.9] }}
              transition={{ repeat: Infinity, duration: 2.8, ease: "easeInOut" }}
              className="absolute w-[34%] h-[34%] rounded-full blur-[1px]"
              style={{
                background: "radial-gradient(circle, #FFFFFF 0%, #38BDF8 50%, transparent 100%)",
              }}
            />
          </motion.div>
        )}

        {orbState === "listening" && (
          <motion.div
            key="listening"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ duration: 0.25 }}
            className="absolute inset-0 flex items-center justify-center"
          >
            {/* Acoustic Shockwave Rings */}
            {[0, 1, 2].map((idx) => {
              const phase = (time * 2.4 + idx * 0.33) % 1.0;
              const scale = 0.4 + phase * 0.7;
              const opacity = (1.0 - phase) * 0.75;
              return (
                <div
                  key={idx}
                  className="absolute rounded-full border pointer-events-none"
                  style={{
                    width: `${size * scale}px`,
                    height: `${size * scale}px`,
                    opacity: opacity,
                    borderColor: "rgba(0, 242, 235, 0.75)",
                    borderWidth: Math.max(0.7, size * 0.03),
                  }}
                />
              );
            })}

            {/* Horizontal Dynamic Voice Acoustic Sine Wave (~~~ in screenshot) */}
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none"
              viewBox={`0 0 ${size} ${size}`}
            >
              <defs>
                <linearGradient id="listeningWaveGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.8" />
                  <stop offset="40%" stopColor="#00F2EB" stopOpacity="1" />
                  <stop offset="70%" stopColor="#34D399" stopOpacity="0.9" />
                  <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0.8" />
                </linearGradient>
                <filter id="waveGlow">
                  <feDropShadow dx="0" dy="0" stdDeviation={size * 0.05} floodColor="#00F2EB" floodOpacity="0.9" />
                </filter>
              </defs>
              <path
                d={generateSineWavePath(size, size, size * 0.16, 2.0, time * 6.5)}
                fill="none"
                stroke="url(#listeningWaveGrad)"
                strokeWidth={Math.max(1.5, size * 0.045)}
                strokeLinecap="round"
                filter="url(#waveGlow)"
              />
            </svg>

            {/* Voice Surge Core */}
            <motion.div
              animate={{ scale: [0.9, 1.25, 0.95, 1.3, 0.9] }}
              transition={{ repeat: Infinity, duration: 1.2, ease: "easeInOut" }}
              className="absolute w-[52%] h-[52%] rounded-full blur-[2.5px]"
              style={{
                background: "radial-gradient(circle, #FFFFFF 0%, #00F2EB 55%, #0284C7 88%, transparent 100%)",
              }}
            />
          </motion.div>
        )}

        {orbState === "processing" && (
          <motion.div
            key="processing"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ duration: 0.25 }}
            className="absolute inset-0 flex items-center justify-center"
          >
            {/* Dual Vortex Accelerator */}
            <motion.div
              animate={{ rotate: [0, 360] }}
              transition={{ repeat: Infinity, duration: 2.4, ease: "linear" }}
              className="absolute w-[92%] h-[92%] rounded-full blur-[2.5px]"
              style={{
                background: "conic-gradient(from 0deg, #A855F7, #38BDF8, #7C3AED, #E879F9, #A855F7)",
              }}
            />

            {/* Counter-spinning Tilted Orbital Ring */}
            <motion.div
              animate={{ rotate: [360, 0] }}
              transition={{ repeat: Infinity, duration: 1.8, ease: "linear" }}
              className="absolute w-[76%] h-[40%] rounded-full border pointer-events-none mix-blend-screen opacity-90"
              style={{
                borderColor: "rgba(192, 132, 252, 0.75)",
                borderWidth: Math.max(1, size * 0.025),
                boxShadow: "0 0 6px rgba(192, 132, 252, 0.5)",
              }}
            />

            {/* High-Density Pulsing Event Horizon Singularity */}
            <motion.div
              animate={{ scale: [0.75, 1.15, 0.75], opacity: [0.85, 1, 0.85] }}
              transition={{ repeat: Infinity, duration: 0.9, ease: "easeInOut" }}
              className="absolute w-[36%] h-[36%] rounded-full blur-[1px]"
              style={{
                background: "radial-gradient(circle, #FFFFFF 0%, #C084FC 60%, #9333EA 85%, transparent 100%)",
              }}
            />
          </motion.div>
        )}

        {orbState === "speaking" && (
          <motion.div
            key="speaking"
            initial={{ opacity: 0, scale: 0.9 }}
            animate={{ opacity: 1, scale: 1 }}
            exit={{ opacity: 0, scale: 0.9 }}
            transition={{ duration: 0.25 }}
            className="absolute inset-0 flex items-center justify-center"
          >
            {/* Harmonic Vocal Ribbon in Coral/Rose */}
            <motion.div
              animate={{ rotate: [0, 360] }}
              transition={{ repeat: Infinity, duration: 4.2, ease: "linear" }}
              className="absolute w-[92%] h-[92%] rounded-full blur-[3px]"
              style={{
                background: "conic-gradient(from 0deg, #FB7185, #F43F5E, #FB923C, #F472B6, #FB7185)",
              }}
            />

            {/* Horizontal Dynamic Vocal Sine Wave (matches speaking screenshot) */}
            <svg
              className="absolute inset-0 w-full h-full pointer-events-none"
              viewBox={`0 0 ${size} ${size}`}
            >
              <defs>
                <linearGradient id="speakingWaveGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.9" />
                  <stop offset="40%" stopColor="#FB7185" stopOpacity="1" />
                  <stop offset="70%" stopColor="#FDBA74" stopOpacity="0.9" />
                  <stop offset="100%" stopColor="#FFFFFF" stopOpacity="0.9" />
                </linearGradient>
                <filter id="speakingWaveGlow">
                  <feDropShadow dx="0" dy="0" stdDeviation={size * 0.05} floodColor="#FB7185" floodOpacity="0.9" />
                </filter>
              </defs>
              <path
                d={generateSineWavePath(size, size, size * 0.17, 1.8, -time * 5.8)}
                fill="none"
                stroke="url(#speakingWaveGrad)"
                strokeWidth={Math.max(1.5, size * 0.045)}
                strokeLinecap="round"
                filter="url(#speakingWaveGlow)"
              />
            </svg>

            {/* Vocal Cadence Core */}
            <motion.div
              animate={{ scale: [0.85, 1.2, 0.9, 1.25, 0.85] }}
              transition={{ repeat: Infinity, duration: 1.3, ease: "easeInOut" }}
              className="absolute w-[55%] h-[55%] rounded-full blur-[2px] mix-blend-screen opacity-90"
              style={{
                background: "radial-gradient(circle, #FFF1F2 0%, #FB7185 50%, #EA580C 85%, transparent 100%)",
              }}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* 2. Glass Depth: Inner Ambient Occlusion Vignette */}
      <div
        className="absolute inset-0 rounded-full pointer-events-none"
        style={{
          boxShadow: "inset 0 0 4px rgba(0, 0, 0, 0.85)",
        }}
      />

      {/* 3. Caustic Fresnel Edge & Refraction Rim */}
      <div
        className="absolute inset-0 rounded-full pointer-events-none border"
        style={{
          borderColor:
            orbState === "speaking"
              ? "rgba(251, 113, 133, 0.65)"
              : orbState === "listening"
              ? "rgba(0, 242, 235, 0.65)"
              : orbState === "processing"
              ? "rgba(192, 132, 252, 0.65)"
              : "rgba(255, 255, 255, 0.5)",
          borderWidth: Math.max(0.6, size * 0.025),
          boxShadow:
            orbState === "speaking"
              ? "0 0 6px rgba(251, 113, 133, 0.4)"
              : orbState === "listening"
              ? "0 0 6px rgba(0, 242, 235, 0.4)"
              : "0 0 6px rgba(56, 189, 248, 0.35)",
        }}
      />

      {/* 4. Specular Curved Glass Glare (Top-Left) */}
      <div
        className="absolute top-[8%] left-[10%] w-[42%] h-[24%] rounded-full pointer-events-none"
        style={{
          background:
            "linear-gradient(135deg, rgba(255, 255, 255, 0.88) 0%, rgba(255, 255, 255, 0.22) 60%, transparent 100%)",
          transform: "rotate(-25deg)",
          filter: "blur(0.5px)",
        }}
      />

      {/* 5. Secondary Bottom-Right Specular Bounce */}
      <div
        className="absolute bottom-[8%] right-[10%] w-[25%] h-[15%] rounded-full pointer-events-none"
        style={{
          background: "linear-gradient(315deg, rgba(255, 255, 255, 0.35) 0%, transparent 80%)",
          transform: "rotate(-25deg)",
          filter: "blur(0.8px)",
        }}
      />
    </div>
  );

  if (!showSquircle) {
    return <div className={`relative ${className}`}>{orbContent}</div>;
  }

  // Apple HIG Liquid Glass Squircle Container
  return (
    <div
      className={`relative flex items-center justify-center select-none ${className}`}
      style={{
        width: `${squircleSize}px`,
        height: `${squircleSize}px`,
        borderRadius: `${cornerRadius}px`,
        background: "linear-gradient(135deg, #16181f 0%, #090a0e 100%)",
        boxShadow: "0 8px 24px -4px rgba(0, 0, 0, 0.7), inset 0 1px 1px rgba(255, 255, 255, 0.24)",
        border: "1px solid rgba(255, 255, 255, 0.12)",
      }}
    >
      {/* Top Inner Specular Sheen */}
      <div
        className="absolute inset-x-0 top-0 h-[45%] pointer-events-none"
        style={{
          borderTopLeftRadius: `${cornerRadius}px`,
          borderTopRightRadius: `${cornerRadius}px`,
          background: "linear-gradient(180deg, rgba(255, 255, 255, 0.12) 0%, transparent 100%)",
        }}
      />

      {/* Clipped Backglow */}
      <div
        className="absolute rounded-full blur-[16px] pointer-events-none"
        style={{
          width: `${size * 0.95}px`,
          height: `${size * 0.95}px`,
          background:
            orbState === "speaking"
              ? "rgba(251, 113, 133, 0.35)"
              : orbState === "listening"
              ? "rgba(0, 242, 235, 0.35)"
              : "rgba(168, 85, 247, 0.3)",
        }}
      />

      {orbContent}
    </div>
  );
};
