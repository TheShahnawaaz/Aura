"use client";

import React, { useState, useEffect } from "react";
import Image from "next/image";
import { motion, AnimatePresence, useScroll, useTransform } from "framer-motion";
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
  const { scrollY } = useScroll();
  const bgOpacity = useTransform(scrollY, [0, 100], [0, 0.85]);
  const borderOpacity = useTransform(scrollY, [0, 100], [0, 0.08]);
  const blur = useTransform(scrollY, [0, 100], [0, 20]);

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
        initial={{ y: -80, opacity: 0 }}
        animate={{ y: 0, opacity: 1 }}
        transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1], delay: 0.2 }}
        className="fixed top-0 inset-x-0 z-50 flex items-center justify-center p-4 select-none"
      >
        <motion.nav
          style={{
            backgroundColor: useTransform(bgOpacity, (v) => `rgba(7, 8, 11, ${v})`),
            borderColor: useTransform(borderOpacity, (v) => `rgba(255, 255, 255, ${v})`),
            backdropFilter: useTransform(blur, (v) => `blur(${v}px)`),
          }}
          className="w-full max-w-5xl h-14 px-4 sm:px-6 rounded-2xl flex items-center justify-between shadow-2xl border border-transparent transition-shadow"
        >
          {/* Brand Logo & Name */}
          <motion.a
            href="#"
            className="flex items-center gap-3 group"
            whileHover={{ scale: 1.03 }}
            whileTap={{ scale: 0.98 }}
          >
            <div className="relative w-8 h-8 rounded-lg overflow-hidden border border-white/15 shadow-md group-hover:shadow-glow transition-shadow duration-300">
              <Image
                src="/icon.png"
                alt="Aura Icon"
                width={32}
                height={32}
                className="object-cover"
                priority
              />
            </div>
            <div className="flex items-center gap-1.5">
              <span className="font-bold tracking-tight text-white text-base">Aura</span>
              <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 rounded bg-cyan-500/15 text-cyan-300 border border-cyan-500/30">
                Beta
              </span>
            </div>
          </motion.a>

          {/* Center Navigation Links */}
          <div className="hidden md:flex items-center gap-1 text-xs font-medium">
            {navLinks.map((link) => (
              <motion.a
                key={link.href}
                href={link.href}
                className={`relative px-3.5 py-2 rounded-xl transition-colors ${
                  activeSection === link.href
                    ? "text-white"
                    : "text-slate-400 hover:text-white"
                }`}
                whileHover={{ y: -1 }}
                transition={{ type: "spring", stiffness: 400, damping: 25 }}
              >
                {activeSection === link.href && (
                  <motion.div
                    layoutId="activeNavBg"
                    className="absolute inset-0 rounded-xl bg-white/[0.08] border border-white/[0.06]"
                    transition={{ type: "spring", stiffness: 500, damping: 35 }}
                  />
                )}
                <span className="relative z-10">{link.label}</span>
              </motion.a>
            ))}
          </div>

          {/* Action CTAs */}
          <div className="hidden md:flex items-center gap-3">
            <motion.a
              href="https://github.com/TheShahnawaaz/Aura"
              target="_blank"
              rel="noreferrer"
              className="flex items-center gap-1.5 text-xs text-slate-300 hover:text-white px-3 py-1.5 rounded-xl border border-white/10 hover:border-white/20 bg-white/5 hover:bg-white/10 transition-all"
              whileHover={{ scale: 1.03, y: -1 }}
              whileTap={{ scale: 0.98 }}
            >
              <Github className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Star on GitHub</span>
            </motion.a>

            <motion.a
              href="#download"
              className="relative flex items-center gap-1.5 text-xs font-semibold text-black bg-gradient-to-r from-cyan-300 via-sky-300 to-cyan-200 hover:brightness-110 px-4 py-2 rounded-xl shadow-lg shadow-cyan-500/20 transition-all overflow-hidden"
              whileHover={{ scale: 1.05, y: -1 }}
              whileTap={{ scale: 0.97 }}
            >
              <Download className="w-3.5 h-3.5" />
              <span>Download .dmg</span>
              {/* Shimmer sweep */}
              <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent -translate-x-full animate-[shimmer_3s_ease-in-out_infinite]" />
            </motion.a>
          </div>

          {/* Mobile Menu Button */}
          <motion.button
            className="md:hidden p-2 text-white/60 hover:text-white"
            onClick={() => setIsMobileOpen(!isMobileOpen)}
            whileTap={{ scale: 0.9 }}
          >
            {isMobileOpen ? <X size={20} /> : <Menu size={20} />}
          </motion.button>
        </motion.nav>
      </motion.header>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isMobileOpen && (
          <motion.div
            initial={{ opacity: 0, y: -20 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -20 }}
            transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
            className="fixed top-20 inset-x-4 z-50 p-4 rounded-2xl bg-background/95 backdrop-blur-xl border border-white/[0.08] shadow-2xl"
          >
            <div className="space-y-1">
              {navLinks.map((link, i) => (
                <motion.a
                  key={link.href}
                  href={link.href}
                  initial={{ opacity: 0, x: -10 }}
                  animate={{ opacity: 1, x: 0 }}
                  transition={{ delay: i * 0.05 }}
                  className="block px-4 py-3 text-sm text-white/70 hover:text-white rounded-xl hover:bg-white/[0.04] transition-colors"
                  onClick={() => setIsMobileOpen(false)}
                >
                  {link.label}
                </motion.a>
              ))}
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </>
  );
};
