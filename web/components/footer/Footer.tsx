"use client";

import React from "react";
import Image from "next/image";
import { motion } from "framer-motion";
import { Github, Heart } from "lucide-react";

export const Footer: React.FC = () => {
  return (
    <footer className="w-full relative py-12 px-4 bg-[#050608] text-slate-400 text-xs">
      {/* Gradient separator line */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-cyan-500/30 to-transparent" />

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: 0.6 }}
        className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6"
      >
        {/* Brand */}
        <motion.div
          className="flex items-center gap-3"
          whileHover={{ x: 2 }}
        >
          <div className="w-6 h-6 rounded-md overflow-hidden border border-white/10 shadow-sm">
            <Image
              src="/icon.png"
              alt="Aura Logo"
              width={24}
              height={24}
              className="object-cover"
            />
          </div>
          <span className="font-bold text-white text-sm">Aura</span>
          <span className="text-slate-600">|</span>
          <span>Autonomous Voice & Desktop AI Assistant for macOS</span>
        </motion.div>

        {/* Links */}
        <div className="flex items-center gap-6 font-medium text-slate-400">
          {[
            { label: "GitHub Repository", href: "https://github.com/TheShahnawaaz/Aura" },
            { label: "OpenAgentSDK", href: "https://github.com/terryso/open-agent-sdk-swift" },
            { label: "MIT License", href: "https://github.com/TheShahnawaaz/Aura/blob/main/LICENSE" },
          ].map((link) => (
            <motion.a
              key={link.label}
              href={link.href}
              target="_blank"
              rel="noreferrer"
              className="hover:text-white transition-colors"
              whileHover={{ y: -2 }}
              transition={{ type: "spring", stiffness: 400, damping: 25 }}
            >
              {link.label}
            </motion.a>
          ))}
        </div>

        {/* Made with Swift */}
        <div className="flex items-center gap-1.5 text-slate-500">
          <span>Crafted with</span>
          <motion.div
            animate={{ scale: [1, 1.2, 1] }}
            transition={{ repeat: Infinity, duration: 1.5, ease: "easeInOut" }}
          >
            <Heart className="w-3.5 h-3.5 text-rose-500 fill-current" />
          </motion.div>
          <span>for macOS</span>
        </div>
      </motion.div>
    </footer>
  );
};
