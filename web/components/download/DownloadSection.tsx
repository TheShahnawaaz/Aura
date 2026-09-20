"use client";

import React, { useState, useRef } from "react";
import Image from "next/image";
import { motion, useInView } from "framer-motion";
import { Copy, Check, Shield, Cpu, ArrowRight } from "lucide-react";
import { SiApple } from "@icons-pack/react-simple-icons";

export const DownloadSection: React.FC = () => {
  const [copied, setCopied] = useState(false);
  const brewCommand = "brew install TheShahnawaaz/tap/aura";
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-80px" });

  const handleCopy = () => {
    navigator.clipboard.writeText(brewCommand);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="download" className="py-28 sm:py-36 px-4 max-w-5xl mx-auto w-full" ref={ref}>
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
        className="double-bezel-outer w-full"
      >
        <div className="double-bezel-inner p-8 sm:p-16 flex flex-col items-center text-center">
          {/* App Icon */}
          <div className="relative w-20 h-20 sm:w-24 sm:h-24 rounded-[22px] overflow-hidden shadow-2xl mb-8 border border-white/20">
            <Image
              src="/icon.png"
              alt="Aura App Icon"
              width={96}
              height={96}
              className="object-cover"
              priority
            />
          </div>

          {/* Title & Copy */}
          <h2 className="text-3xl sm:text-5xl font-extrabold text-white tracking-[-0.035em] mb-4">
            Install Aura for macOS
          </h2>
          <p className="text-slate-400 text-base sm:text-lg max-w-lg mb-10 leading-relaxed font-normal">
            Compiled natively as an Apple Silicon & Intel Universal binary. Free and open source under the MIT License.
          </p>

          {/* Download Action Buttons with Button-in-Button pattern */}
          <div className="flex flex-col items-center justify-center gap-4 mb-8">
            <motion.a
              href="https://github.com/TheShahnawaaz/Aura/releases/latest/download/Aura.dmg"
              className="group relative flex items-center gap-3 pl-6 pr-2 py-2.5 rounded-full bg-white text-black font-bold text-sm shadow-[0_12px_32px_-8px_rgba(255,255,255,0.25)] hover:bg-slate-100 transition-all"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <SiApple className="w-4 h-4 fill-current" />
              <span>Download for Mac (.dmg)</span>
              <div className="w-8 h-8 rounded-full bg-black/10 flex items-center justify-center group-hover:scale-105 group-hover:translate-x-0.5 transition-all">
                <ArrowRight className="w-3.5 h-3.5 text-black" />
              </div>
            </motion.a>

            <a
              href="https://github.com/TheShahnawaaz/Aura/releases"
              target="_blank"
              rel="noreferrer"
              className="text-xs text-slate-400 hover:text-white transition-colors"
            >
              View Releases and Changelog
            </a>
          </div>

          {/* Terminal Quick-Install */}
          <div className="w-full max-w-md p-2 rounded-xl bg-black/50 border border-white/[0.08] flex items-center justify-between shadow-inner mb-10">
            <div className="flex items-center gap-2 font-mono text-xs text-slate-300 px-3 truncate">
              <span className="text-iris-400 font-bold">$</span>
              <span className="truncate">{brewCommand}</span>
            </div>
            <button
              onClick={handleCopy}
              className="flex items-center gap-1.5 text-xs font-mono text-slate-300 hover:text-white px-3 py-1.5 rounded-lg bg-white/[0.06] hover:bg-white/[0.12] transition-colors shrink-0"
            >
              {copied ? (
                <>
                  <Check className="w-3.5 h-3.5 text-emerald-400" />
                  <span className="text-emerald-400">Copied</span>
                </>
              ) : (
                <>
                  <Copy className="w-3.5 h-3.5" />
                  <span>Copy</span>
                </>
              )}
            </button>
          </div>

          {/* System Badges */}
          <div className="flex flex-wrap items-center justify-center gap-6 text-xs text-slate-400 font-medium">
            <div className="flex items-center gap-2">
              <Check className="w-3.5 h-3.5 text-emerald-400" />
              <span>macOS 14.0+ Sonoma & Sequoia</span>
            </div>
            <div className="flex items-center gap-2">
              <Cpu className="w-3.5 h-3.5 text-iris-400" />
              <span>Apple Silicon (M1/M2/M3/M4) & Intel</span>
            </div>
            <div className="flex items-center gap-2">
              <Shield className="w-3.5 h-3.5 text-emerald-400" />
              <span>Encrypted Local Keychain</span>
            </div>
          </div>
        </div>
      </motion.div>
    </section>
  );
};
