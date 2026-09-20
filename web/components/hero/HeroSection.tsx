"use client";

import React from "react";
import { motion } from "framer-motion";
import { ArrowRight, Terminal } from "lucide-react";
import { SiApple } from "@icons-pack/react-simple-icons";
import { NotchSimulator } from "./NotchSimulator";
import { AuroraBackground } from "./AuroraBackground";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.12,
      delayChildren: 0.2,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 24 },
  visible: {
    opacity: 1,
    y: 0,
    transition: {
      duration: 0.7,
      ease: [0.16, 1, 0.3, 1],
    },
  },
};

export const HeroSection: React.FC = () => {
  return (
    <section
      id="notch"
      className="relative pt-32 sm:pt-40 pb-24 px-4 flex flex-col items-center justify-center overflow-hidden w-full min-h-screen"
    >
      {/* 3D WebGL Aurora Background */}
      <AuroraBackground />

      {/* Specular Radial Ambient Depth */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-5xl h-[550px] bg-[radial-gradient(ellipse_at_top,_rgba(99,102,241,0.12),_rgba(15,17,23,0)_70%)] pointer-events-none" />

      {/* Hero Content */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="relative z-10 flex flex-col items-center text-center max-w-4xl mx-auto"
      >
        {/* Hardware Status Pill */}
        <motion.div
          variants={itemVariants}
          className="inline-flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-[#0D1017]/90 border border-white/[0.08] text-xs text-slate-300 shadow-hairline backdrop-blur-xl mb-8"
        >
          <span className="flex h-2 w-2 relative">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-400" />
          </span>
          <span className="text-white font-semibold">Aura v0.1.0</span>
          <span className="text-slate-600">·</span>
          <span className="text-slate-400 font-mono text-[11px]">
            Native Swift · Apple Silicon & macOS Sequoia
          </span>
        </motion.div>

        {/* High-Impact Heading (No rainbow text-clipping) */}
        <motion.h1
          variants={itemVariants}
          className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-[-0.04em] text-white leading-[1.06] mb-6"
        >
          The desktop intelligence <br />
          <span className="text-transparent bg-clip-text bg-gradient-to-r from-white via-slate-200 to-slate-400">
            anchored at your notch.
          </span>
        </motion.h1>

        {/* Technical Subtitle */}
        <motion.p
          variants={itemVariants}
          className="text-base sm:text-lg text-slate-400 max-w-2xl leading-relaxed mb-10 font-normal"
        >
          Aura transforms the MacBook camera bezel into a tactile, responsive action center.
          Driven by voice with instant barge-in, backed by OpenAgentSDK, and running natively with zero electron bloat.
        </motion.p>

        {/* Action CTAs with Button-in-Button Architecture */}
        <motion.div
          variants={itemVariants}
          className="flex flex-wrap items-center justify-center gap-4 mb-20"
        >
          {/* Primary Download Button */}
          <motion.a
            href="#download"
            className="group relative flex items-center gap-3 pl-6 pr-2 py-2 rounded-full bg-white text-black font-semibold text-sm shadow-[0_12px_32px_-8px_rgba(255,255,255,0.25)] hover:bg-slate-100 transition-all"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <SiApple className="w-4 h-4 fill-current" />
            <span>Download for macOS</span>
            {/* Nested button-in-button circular icon wrapper */}
            <div className="w-8 h-8 rounded-full bg-black/10 flex items-center justify-center group-hover:scale-105 group-hover:translate-x-0.5 transition-all">
              <ArrowRight className="w-3.5 h-3.5 text-black" />
            </div>
          </motion.a>

          {/* Terminal Command Button */}
          <motion.a
            href="https://github.com/TheShahnawaaz/Aura"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-2 px-5 py-3 rounded-full bg-[#0D1017] border border-white/[0.08] hover:border-white/20 text-slate-300 font-mono text-xs transition-all hover:bg-[#121620] shadow-hairline"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <Terminal className="w-3.5 h-3.5 text-iris-400" />
            <span>brew install TheShahnawaaz/tap/aura</span>
          </motion.a>
        </motion.div>
      </motion.div>

      {/* PHOTOREALISTIC MACBOOK PRO SIMULATOR */}
      <motion.div
        initial={{ opacity: 0, y: 50, scale: 0.98 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{
          duration: 0.9,
          delay: 0.4,
          ease: [0.16, 1, 0.3, 1],
        }}
        className="relative z-10 w-full"
      >
        <NotchSimulator />
      </motion.div>
    </section>
  );
};
