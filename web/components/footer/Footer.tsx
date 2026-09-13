"use client";

import React from "react";
import Image from "next/image";
import { Github, Heart } from "lucide-react";

export const Footer: React.FC = () => {
  return (
    <footer className="w-full border-t border-white/10 py-12 px-4 bg-[#050608] text-slate-400 text-xs">
      <div className="max-w-6xl mx-auto flex flex-col md:flex-row items-center justify-between gap-6">
        {/* Brand */}
        <div className="flex items-center gap-3">
          <div className="w-6 h-6 rounded-md overflow-hidden border border-white/10">
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
        </div>

        {/* Links */}
        <div className="flex items-center gap-6 font-medium text-slate-400">
          <a
            href="https://github.com/TheShahnawaaz/Aura"
            target="_blank"
            rel="noreferrer"
            className="hover:text-white transition-colors"
          >
            GitHub Repository
          </a>
          <a
            href="https://github.com/terryso/open-agent-sdk-swift"
            target="_blank"
            rel="noreferrer"
            className="hover:text-white transition-colors"
          >
            OpenAgentSDK
          </a>
          <a
            href="https://github.com/TheShahnawaaz/Aura/blob/main/LICENSE"
            target="_blank"
            rel="noreferrer"
            className="hover:text-white transition-colors"
          >
            MIT License
          </a>
        </div>

        {/* Made with Swift */}
        <div className="flex items-center gap-1.5 text-slate-500">
          <span>Crafted with</span>
          <Heart className="w-3.5 h-3.5 text-rose-500 fill-current" />
          <span>for macOS</span>
        </div>
      </div>
    </footer>
  );
};
