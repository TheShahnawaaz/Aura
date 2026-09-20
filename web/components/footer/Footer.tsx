"use client";

import React from "react";
import Image from "next/image";
import { Github } from "lucide-react";

export const Footer: React.FC = () => {
  return (
    <footer className="w-full relative py-14 px-4 bg-[#050608] text-slate-400 text-xs border-t border-white/[0.06]">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <div className="w-6 h-6 rounded-lg overflow-hidden border border-white/10 shadow-sm">
            <Image
              src="/icon.png"
              alt="Aura Logo"
              width={24}
              height={24}
              className="object-cover"
            />
          </div>
          <span className="font-bold text-white text-sm">Aura</span>
          <span className="text-slate-600">/</span>
          <span className="text-slate-400">Autonomous Voice & Desktop AI Assistant</span>
        </div>

        {/* Links */}
        <div className="flex items-center gap-6 font-medium text-slate-400">
          {[
            { label: "GitHub", href: "https://github.com/TheShahnawaaz/Aura" },
            { label: "OpenAgentSDK", href: "https://github.com/terryso/open-agent-sdk-swift" },
            { label: "MIT License", href: "https://github.com/TheShahnawaaz/Aura/blob/main/LICENSE" },
          ].map((link) => (
            <a
              key={link.label}
              href={link.href}
              target="_blank"
              rel="noreferrer"
              className="hover:text-white transition-colors"
            >
              {link.label}
            </a>
          ))}
        </div>

        {/* Technical Colophon */}
        <div className="text-slate-500 font-mono text-[11px]">
          SwiftUI & AppKit · Apple Silicon Native
        </div>
      </div>
    </footer>
  );
};
