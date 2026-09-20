"use client";

import React from "react";
import { motion } from "framer-motion";
import { Apple, ArrowRight, Terminal, ArrowDown } from "lucide-react";
import { NotchSimulator } from "./NotchSimulator";
import { AuroraBackground } from "./AuroraBackground";

const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      staggerChildren: 0.12,
      delayChildren: 0.3,
    },
  },
};

const itemVariants = {
  hidden: { opacity: 0, y: 30, filter: "blur(10px)" },
  visible: {
    opacity: 1,
    y: 0,
    filter: "blur(0px)",
    transition: {
      type: "spring",
      stiffness: 100,
      damping: 20,
    },
  },
};

export const HeroSection: React.FC = () => {
  return (
    <section
      id="notch"
      className="relative pt-36 pb-24 px-4 flex flex-col items-center justify-center overflow-hidden w-full min-h-screen"
    >
      {/* 3D WebGL Aurora Background */}
      <AuroraBackground />

      {/* Precision Radial Lighting */}
      <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full max-w-6xl h-[650px] bg-[radial-gradient(ellipse_at_top,_var(--tw-gradient-stops))] from-cyan-500/10 via-purple-500/5 to-transparent pointer-events-none" />

      {/* Animated content */}
      <motion.div
        variants={containerVariants}
        initial="hidden"
        animate="visible"
        className="relative z-10 flex flex-col items-center"
      >
        {/* Hardware Architecture Pill */}
        <motion.div
          variants={itemVariants}
          className="inline-flex items-center gap-2.5 px-3.5 py-1.5 rounded-full bg-[#11131a]/80 border border-white/[0.08] text-xs font-medium text-slate-300 shadow-xl backdrop-blur-xl mb-7 hover:border-white/20 transition-colors"
        >
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-cyan-400" />
          </span>
          <span className="text-white font-semibold">Aura 0.1.0 Public Beta</span>
          <span className="text-slate-600">/</span>
          <span className="text-slate-400">
            Engineered for Apple Silicon & macOS Sequoia
          </span>
        </motion.div>

        {/* Main Headline */}
        <motion.h1
          variants={itemVariants}
          className="text-4xl sm:text-6xl md:text-7xl font-extrabold tracking-[-0.035em] text-center max-w-4xl text-white leading-[1.08] mb-6"
        >
          The desktop intelligence <br className="hidden sm:inline" />
          <span className="shimmer-text">
            anchored at your notch.
          </span>
        </motion.h1>

        {/* Subtitle */}
        <motion.p
          variants={itemVariants}
          className="text-base sm:text-lg md:text-xl text-slate-400 text-center max-w-2xl leading-relaxed mb-10 font-normal"
        >
          Aura transforms the MacBook camera notch into an autonomous action
          center. Activated by voice, powered by OpenAgentSDK, and built purely
          in native Swift.
        </motion.p>

        {/* CTA Row */}
        <motion.div
          variants={itemVariants}
          className="flex flex-wrap items-center justify-center gap-4 mb-20"
        >
          <motion.a
            href="#download"
            className="relative flex items-center gap-2.5 px-7 py-3.5 rounded-2xl bg-white text-black font-semibold text-sm shadow-[0_10px_30px_-5px_rgba(255,255,255,0.3)] hover:bg-slate-100 transition-all overflow-hidden group"
            whileHover={{ scale: 1.04, y: -2 }}
            whileTap={{ scale: 0.97 }}
          >
            <Apple className="w-4 h-4 fill-current" />
            <span>Download for macOS</span>
            <ArrowRight className="w-4 h-4 text-slate-500 group-hover:translate-x-1 transition-transform" />
            {/* Button shine */}
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/40 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
          </motion.a>

          <motion.a
            href="https://github.com/TheShahnawaaz/Aura"
            target="_blank"
            rel="noreferrer"
            className="flex items-center gap-2 px-5 py-3.5 rounded-2xl bg-[#11131a] border border-white/[0.08] hover:border-white/20 text-slate-300 font-mono text-xs transition-all hover:bg-[#161822]"
            whileHover={{ scale: 1.04, y: -2 }}
            whileTap={{ scale: 0.97 }}
          >
            <Terminal className="w-3.5 h-3.5 text-cyan-400" />
            <span>brew install TheShahnawaaz/tap/aura</span>
          </motion.a>
        </motion.div>
      </motion.div>

      {/* PHOTOREALISTIC MACBOOK PRO SIMULATOR */}
      <motion.div
        initial={{ opacity: 0, y: 60, scale: 0.95 }}
        animate={{ opacity: 1, y: 0, scale: 1 }}
        transition={{
          duration: 1.0,
          delay: 0.8,
          ease: [0.22, 1, 0.36, 1],
        }}
        className="relative z-10"
      >
        <NotchSimulator />
      </motion.div>

      {/* Scroll indicator */}
      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 2, duration: 1 }}
        className="absolute bottom-8 left-1/2 -translate-x-1/2 z-10"
      >
        <motion.div
          animate={{ y: [0, 8, 0] }}
          transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
          className="flex flex-col items-center gap-2"
        >
          <span className="text-[10px] text-slate-500 font-mono uppercase tracking-widest">
            Scroll to explore
          </span>
          <ArrowDown size={14} className="text-slate-500" />
        </motion.div>
      </motion.div>

      {/* Bottom fade */}
      <div className="absolute bottom-0 left-0 right-0 h-40 bg-gradient-to-t from-background via-background/80 to-transparent pointer-events-none z-20" />
    </section>
  );
};
