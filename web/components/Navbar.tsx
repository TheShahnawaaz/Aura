"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import { motion, AnimatePresence } from "framer-motion";
import { Download, Github, Menu, X } from "lucide-react";

const navLinks = [
  { href: "#notch", label: "Notch HUD" },
  { href: "#features", label: "Capabilities" },
  { href: "#workflows", label: "Workflows" },
  { href: "#comparison", label: "Why Aura" },
  { href: "#download", label: "Install" },
];

export const Navbar: React.FC = () => {
  const [isMobileOpen, setIsMobileOpen] = useState(false);
  const [activeSection, setActiveSection] = useState("");
  const [isScrolled, setIsScrolled] = useState(false);

  useEffect(() => {
    const handleScroll = () => {
      setIsScrolled(window.scrollY > 20);
    };
    window.addEventListener("scroll", handleScroll, { passive: true });
    return () => window.removeEventListener("scroll", handleScroll);
  }, []);

  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            setActiveSection("#" + entry.target.id);
          }
        });
      },
      { rootMargin: "-40% 0px -40% 0px" }
    );

    const sections = document.querySelectorAll("section[id]");
    sections.forEach((section) => observer.observe(section));
    return () => observer.disconnect();
  }, []);

  return (
    <>
      <motion.header
        initial={{ y: -60, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="fixed top-0 inset-x-0 z-50 flex items-center justify-center pt-4 px-4 select-none pointer-events-none"
      >
        <nav
          className={`pointer-events-auto w-full max-w-5xl h-13 px-4 sm:px-5 rounded-full flex items-center justify-between transition-all duration-300 ${
            isScrolled
              ? "bg-[#090B10]/85 backdrop-blur-xl border border-white/[0.09] shadow-[0_16px_40px_-12px_rgba(0,0,0,0.85)]"
              : "bg-[#090B10]/60 backdrop-blur-md border border-white/[0.05]"
          }`}
        >
          {/* Brand Logo & Name */}
          <motion.a
            href="#"
            className="flex items-center gap-2.5 group py-1.5"
            whileHover={{ scale: 1.02 }}
            whileTap={{ scale: 0.98 }}
          >
            <div className="relative w-7 h-7 rounded-lg overflow-hidden border border-white/15 shadow-sm">
              <Image
                src="/icon.png"
                alt="Aura Icon"
                width={28}
                height={28}
                className="object-cover"
                priority
              />
            </div>
            <div className="flex items-center gap-2">
              <span className="font-bold tracking-tight text-white text-sm">Aura</span>
              <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-iris-500/15 text-iris-300 border border-iris-500/25">
                v0.1.0
              </span>
            </div>
          </motion.a>

          {/* Center Navigation Links */}
          <div className="hidden md:flex items-center gap-1 text-xs font-medium">
            {navLinks.map((link) => (
              <a
                key={link.href}
                href={link.href}
                className={`relative px-3.5 py-1.5 rounded-full transition-colors ${
                  activeSection === link.href
                    ? "text-white"
                    : "text-slate-400 hover:text-white"
                }`}
              >
                {activeSection === link.href && (
                  <motion.div
                    layoutId="activeNavPill"
                    className="absolute inset-0 rounded-full bg-white/[0.08] border border-white/[0.06]"
                    transition={{ type: "spring", stiffness: 400, damping: 30 }}
                  />
                )}
                <span className="relative z-10">{link.label}</span>
              </a>
            ))}
          </div>

          {/* Action CTAs */}
          <div className="hidden md:flex items-center gap-2.5">
            <motion.a
              href="https://github.com/TheShahnawaaz/Aura"
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-1.5 text-xs text-slate-300 hover:text-white px-3 py-1.5 rounded-full border border-white/10 hover:border-white/20 bg-white/[0.03] hover:bg-white/[0.07] transition-all"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <Github className="w-3.5 h-3.5" />
              <span>GitHub</span>
            </motion.a>

            <motion.a
              href="#download"
              className="group flex items-center gap-2 text-xs font-semibold text-black bg-white hover:bg-slate-100 pl-3.5 pr-1.5 py-1 rounded-full shadow-[0_4px_16px_-4px_rgba(255,255,255,0.3)] transition-all"
              whileHover={{ scale: 1.02 }}
              whileTap={{ scale: 0.98 }}
            >
              <span>Download</span>
              <div className="w-6 h-6 rounded-full bg-black/10 flex items-center justify-center group-hover:scale-105 transition-transform">
                <Download className="w-3 h-3 text-black" />
              </div>
            </motion.a>
          </div>

          {/* Mobile Menu Button */}
          <motion.button
            className="md:hidden p-1.5 text-white/70 hover:text-white"
            onClick={() => setIsMobileOpen(!isMobileOpen)}
            whileTap={{ scale: 0.92 }}
            aria-label="Toggle navigation menu"
          >
            {isMobileOpen ? <X size={18} /> : <Menu size={18} />}
          </motion.button>
        </nav>
      </motion.header>

      {/* Mobile Menu Overlay */}
      <AnimatePresence>
        {isMobileOpen && (
          <motion.div
            initial={{ opacity: 0, y: -15 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -15 }}
            transition={{ duration: 0.25, ease: [0.16, 1, 0.3, 1] }}
            className="fixed top-20 inset-x-4 z-50 p-4 rounded-2xl bg-[#090B10]/95 backdrop-blur-2xl border border-white/[0.09] shadow-2xl md:hidden"
          >
            <div className="space-y-1">
              {navLinks.map((link) => (
                <a
                  key={link.href}
                  href={link.href}
                  className="block px-4 py-2.5 text-sm text-white/70 hover:text-white rounded-xl hover:bg-white/[0.05] transition-colors"
                  onClick={() => setIsMobileOpen(false)}
                >
                  {link.label}
                </a>
              ))}
              <div className="pt-3 mt-2 border-t border-white/[0.06] flex flex-col gap-2">
                <a
                  href="#download"
                  className="flex items-center justify-center gap-2 py-2.5 rounded-xl bg-white text-black font-semibold text-xs text-center"
                  onClick={() => setIsMobileOpen(false)}
                >
                  <Download className="w-3.5 h-3.5" />
                  <span>Download for macOS</span>
                </a>
              </div>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};
