"use client";

import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";

export type AssistantOrbState = "idle" | "listening" | "processing" | "speaking";

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

  const [pulsePhase, setPulsePhase] = useState(0);

  useEffect(() => {
    let animId: number;
    const start = Date.now();
    const loop = () => {
      setPulsePhase((Date.now() - start) / 1000);
      animId = requestAnimationFrame(loop);
    };
    animId = requestAnimationFrame(loop);
    return () => cancelAnimationFrame(animId);
  }, []);

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
        {state === "idle" && (
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
                x: [Math.sin(pulsePhase * 0.8) * (size * 0.08)],
                y: [Math.cos(pulsePhase * 0.6) * (size * 0.06)],
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
              className="absolute w-[32%] h-[32%] rounded-full blur-[1px]"
              style={{
                background: "radial-gradient(circle, #FFFFFF 0%, #38BDF8 50%, transparent 100%)",
              }}
            />
          </motion.div>
        )}

        {state === "listening" && (
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
              const phase = (pulsePhase * 2.4 + idx * 0.33) % 1.0;
              const scale = 0.4 + phase * 0.7;
              const opacity = (1.0 - phase) * 0.8;
              return (
                <div
                  key={idx}
                  className="absolute rounded-full border border-cyan-300 pointer-events-none"
                  style={{
                    width: `${size * scale}px`,
                    height: `${size * scale}px`,
                    opacity: opacity,
                    borderColor: "rgba(0, 229, 255, 0.75)",
                    borderWidth: Math.max(0.7, size * 0.03),
                  }}
                />
              );
            })}

            {/* Voice Surge Core */}
            <motion.div
              animate={{ scale: [0.95, 1.3, 1.0, 1.35, 0.95] }}
              transition={{ repeat: Infinity, duration: 1.1, ease: "easeInOut" }}
              className="absolute w-[60%] h-[60%] rounded-full blur-[3px]"
              style={{
                background: "radial-gradient(circle, #FFFFFF 0%, #00E5FF 55%, #1D4ED8 90%, transparent 100%)",
              }}
            />
          </motion.div>
        )}

        {state === "processing" && (
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
              transition={{ repeat: Infinity, duration: 2.2, ease: "linear" }}
              className="absolute w-[92%] h-[92%] rounded-full blur-[2.5px]"
              style={{
                background: "conic-gradient(from 0deg, #A855F7, #38BDF8, #6366F1, #A855F7)",
              }}
            />

            <motion.div
              animate={{ rotate: [360, 0] }}
              transition={{ repeat: Infinity, duration: 1.6, ease: "linear" }}
              className="absolute w-[76%] h-[76%] rounded-full blur-[3px] mix-blend-screen opacity-80"
              style={{
                background: "conic-gradient(from 180deg, #00E5FF, #C084FC, #A855F7, #00E5FF)",
              }}
            />

            {/* Pulsing Core */}
            <motion.div
              animate={{ scale: [0.75, 1.15, 0.75], opacity: [0.8, 1, 0.8] }}
              transition={{ repeat: Infinity, duration: 0.85, ease: "easeInOut" }}
              className="absolute w-[30%] h-[30%] rounded-full blur-[1px]"
              style={{
                background: "radial-gradient(circle, #FFFFFF 0%, #C084FC 70%, transparent 100%)",
              }}
            />
          </motion.div>
        )}

        {state === "speaking" && (
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
              transition={{ repeat: Infinity, duration: 3.8, ease: "linear" }}
              className="absolute w-[92%] h-[92%] rounded-full blur-[3px]"
              style={{
                background: "conic-gradient(from 0deg, #FB7185, #F43F5E, #FB923C, #F472B6, #FB7185)",
              }}
            />

            {/* Vocal Cadence Core */}
            <motion.div
              animate={{ scale: [0.85, 1.2, 0.9, 1.25, 0.85] }}
              transition={{ repeat: Infinity, duration: 1.3, ease: "easeInOut" }}
              className="absolute w-[68%] h-[68%] rounded-full blur-[2px] mix-blend-screen opacity-90"
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
          boxShadow: "inset 0 0 4px rgba(0, 0, 0, 0.8)",
        }}
      />

      {/* 3. Caustic Fresnel Edge & Refraction Rim */}
      <div
        className="absolute inset-0 rounded-full pointer-events-none border"
        style={{
          borderColor: state === "speaking" ? "rgba(251, 113, 133, 0.6)" : "rgba(255, 255, 255, 0.45)",
          borderWidth: Math.max(0.6, size * 0.025),
          boxShadow: state === "speaking" ? "0 0 6px rgba(251, 113, 133, 0.4)" : "0 0 6px rgba(0, 229, 255, 0.35)",
        }}
      />

      {/* 4. Specular Curved Glass Glare (Top-Left) */}
      <div
        className="absolute top-[8%] left-[10%] w-[42%] h-[24%] rounded-full pointer-events-none"
        style={{
          background: "linear-gradient(135deg, rgba(255, 255, 255, 0.85) 0%, rgba(255, 255, 255, 0.2) 60%, transparent 100%)",
          transform: "rotate(-25deg)",
          filter: "blur(0.6px)",
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
          background: state === "speaking" ? "rgba(251, 113, 133, 0.35)" : "rgba(0, 229, 255, 0.3)",
        }}
      />

      {orbContent}
    </div>
  );
};
