"use client";

import React, { useState, useRef } from "react";
import Image from "next/image";
import { motion, useInView } from "framer-motion";
import { Download, Apple, Copy, Check, Shield, Cpu } from "lucide-react";

export const DownloadSection: React.FC = () => {
  const [copied, setCopied] = useState(false);
  const brewCommand = "brew install TheShahnawaaz/tap/aura";
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  const handleCopy = () => {
    navigator.clipboard.writeText(brewCommand);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="download" className="py-28 px-4 max-w-5xl mx-auto w-full" ref={ref}>
      <motion.div
        initial={{ opacity: 0, y: 40, scale: 0.97 }}
        animate={isInView ? { opacity: 1, y: 0, scale: 1 } : {}}
        transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
        className="relative rounded-[32px] p-8 sm:p-16 bg-[#0c0e14] border border-white/[0.08] shadow-[0_30px_100px_-20px_rgba(0,0,0,0.8)] overflow-hidden text-center flex flex-col items-center"
      >
        {/* Animated Ambient Radial Glow */}
        <motion.div
          className="absolute inset-0 pointer-events-none"
          animate={{
            background: [
              "radial-gradient(circle at 30% 40%, rgba(0, 229, 255, 0.08) 0%, transparent 70%)",
              "radial-gradient(circle at 70% 60%, rgba(168, 85, 247, 0.08) 0%, transparent 70%)",
              "radial-gradient(circle at 50% 30%, rgba(0, 229, 255, 0.08) 0%, transparent 70%)",
            ],
          }}
          transition={{ duration: 8, repeat: Infinity, ease: "easeInOut" }}
        />

        {/* Floating particles */}
        {[...Array(8)].map((_, i) => (
          <motion.div
            key={i}
            className="absolute w-1 h-1 rounded-full bg-cyan-400/30"
            style={{
              left: `${15 + i * 10}%`,
              top: `${20 + (i % 3) * 25}%`,
            }}
            animate={{
              y: [-20, 20, -20],
              x: [-10, 10, -10],
              opacity: [0.2, 0.6, 0.2],
            }}
            transition={{
              duration: 4 + i * 0.5,
              repeat: Infinity,
              ease: "easeInOut",
              delay: i * 0.3,
            }}
          />
        ))}

        {/* Master Liquid Glass App Icon */}
        <motion.div
          initial={{ scale: 0.8, opacity: 0 }}
          animate={isInView ? { scale: 1, opacity: 1 } : {}}
          transition={{ delay: 0.2, type: "spring", stiffness: 200, damping: 20 }}
          whileHover={{ scale: 1.08, rotate: 2 }}
          className="relative w-24 h-24 sm:w-28 sm:h-28 rounded-[24px] overflow-hidden shadow-2xl mb-8 border border-white/20 z-10"
        >
          <Image
            src="/icon.png"
            alt="Aura App Icon"
            width={112}
            height={112}
            className="object-cover"
            priority
          />
          {/* Shine sweep */}
          <motion.div
            className="absolute inset-0 bg-gradient-to-tr from-transparent via-white/20 to-transparent"
            initial={{ x: "-100%", y: "-100%" }}
            animate={{ x: "100%", y: "100%" }}
            transition={{ duration: 2, repeat: Infinity, repeatDelay: 4 }}
          />
        </motion.div>

        {/* Title & Copy */}
        <motion.h2
          initial={{ opacity: 0, y: 20 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.3, duration: 0.6 }}
          className="text-3xl sm:text-5xl font-extrabold text-white tracking-[-0.03em] mb-4 z-10"
        >
          Install Aura for macOS
        </motion.h2>
        <motion.p
          initial={{ opacity: 0, y: 15 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.4, duration: 0.5 }}
          className="text-slate-400 text-base sm:text-lg max-w-lg mb-10 leading-relaxed z-10"
        >
          Compiled natively as an Apple Silicon & Intel Universal binary. Free and open source under the MIT License.
        </motion.p>

        {/* Download Action Buttons */}
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.5, duration: 0.5 }}
          className="flex flex-col items-center justify-center gap-3 mb-8 z-10"
        >
          <motion.a
            href="https://github.com/TheShahnawaaz/Aura/releases/latest/download/Aura.dmg"
            className="relative flex items-center gap-2.5 px-8 py-4 rounded-2xl bg-white text-black font-bold text-sm shadow-xl overflow-hidden group"
            whileHover={{ scale: 1.04, y: -2, boxShadow: "0 20px 40px -10px rgba(0, 229, 255, 0.3)" }}
            whileTap={{ scale: 0.97 }}
          >
            <Apple className="w-5 h-5 fill-current" />
            <span>Download for Mac (.dmg)</span>
            {/* Button shine */}
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/40 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
          </motion.a>
          <a
            href="https://github.com/TheShahnawaaz/Aura/releases"
            target="_blank"
            rel="noreferrer"
            className="text-xs text-slate-400 hover:text-white transition-colors"
          >
            View Changelog & All Releases \u2192
          </a>
        </motion.div>

        {/* Terminal Quick-Install */}
        <motion.div
          initial={{ opacity: 0, y: 15 }}
          animate={isInView ? { opacity: 1, y: 0 } : {}}
          transition={{ delay: 0.6, duration: 0.5 }}
          whileHover={{ borderColor: "rgba(0, 229, 255, 0.2)" }}
          className="w-full max-w-sm p-2.5 rounded-xl bg-[#06070a] border border-white/[0.07] flex items-center justify-between shadow-inner mb-8 z-10 transition-colors"
        >
          <div className="flex items-center gap-2 font-mono text-xs text-slate-300 px-2 truncate">
            <span className="text-cyan-400 font-bold">$</span>
            <span className="truncate">{brewCommand}</span>
          </div>
          <motion.button
            onClick={handleCopy}
            className="flex items-center gap-1 text-[11px] font-mono text-slate-400 hover:text-white px-2.5 py-1 rounded-lg bg-white/[0.05] hover:bg-white/[0.1] transition-colors shrink-0"
            whileTap={{ scale: 0.9 }}
          >
            {copied ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
            <span>{copied ? "Copied" : "Copy"}</span>
          </motion.button>
        </motion.div>

        {/* System Badges */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={isInView ? { opacity: 1 } : {}}
          transition={{ delay: 0.7, duration: 0.5 }}
          className="flex flex-wrap items-center justify-center gap-6 text-xs text-slate-400 font-medium z-10"
        >
          {[
            { icon: Check, text: "macOS 14.0+ Sonoma & Sequoia", color: "text-cyan-400" },
            { icon: Cpu, text: "M1 / M2 / M3 / M4 & Intel", color: "text-cyan-400" },
            { icon: Shield, text: "Encrypted Local Keychain", color: "text-emerald-400" },
          ].map(({ icon: Icon, text, color }, i) => (
            <motion.div
              key={text}
              className="flex items-center gap-2"
              initial={{ opacity: 0, y: 10 }}
              animate={isInView ? { opacity: 1, y: 0 } : {}}
              transition={{ delay: 0.8 + i * 0.1 }}
            >
              <Icon className={`w-3.5 h-3.5 ${color}`} />
              <span>{text}</span>
            </motion.div>
          ))}
        </motion.div>
      </motion.div>
    </section>
  );
};
