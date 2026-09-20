import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        background: "#07080b",
        surface: {
          50: "#181b24",
          100: "#13151d",
          200: "#0e1017",
          300: "#0a0b10",
        },
        aurora: {
          cyan: "#00E5FF",
          blue: "#38BDF8",
          sapphire: "#2563EB",
          purple: "#A855F7",
          coral: "#FB7185",
          emerald: "#10B981",
          teal: "#14B8A6",
        },
      },
      fontFamily: {
        sans: [
          "-apple-system",
          "BlinkMacSystemFont",
          "SF Pro Display",
          "Inter",
          "system-ui",
          "sans-serif",
        ],
        mono: [
          "SF Mono",
          "ui-monospace",
          "Menlo",
          "Monaco",
          "Consolas",
          "monospace",
        ],
      },
      animation: {
        "aurora-pulse": "auroraPulse 8s ease-in-out infinite",
        "orbit-spin": "orbitSpin 20s linear infinite",
        "float-gentle": "floatGentle 6s ease-in-out infinite",
        "shimmer": "shimmer 2.5s linear infinite",
        "glow-pulse": "glowPulse 3s ease-in-out infinite",
        "gradient-shift": "gradientShift 8s ease-in-out infinite",
        "float-particle": "floatParticle 6s ease-in-out infinite",
        "typing-cursor": "typingCursor 1s step-end infinite",
        "progress-sweep": "progressSweep 4s linear infinite",
        "fade-in-up": "fadeInUp 0.6s ease-out forwards",
        "scale-in": "scaleIn 0.5s ease-out forwards",
        "slide-in-right": "slideInRight 0.5s ease-out forwards",
        "breathe": "breathe 4s ease-in-out infinite",
      },
      keyframes: {
        auroraPulse: {
          "0%, 100%": { opacity: "0.4", transform: "scale(1)" },
          "50%": { opacity: "0.75", transform: "scale(1.08)" },
        },
        orbitSpin: {
          "0%": { transform: "rotate(0deg)" },
          "100%": { transform: "rotate(360deg)" },
        },
        floatGentle: {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-8px)" },
        },
        shimmer: {
          "0%": { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
        glowPulse: {
          "0%, 100%": { opacity: "0.4", boxShadow: "0 0 20px rgba(0, 229, 255, 0.1)" },
          "50%": { opacity: "0.8", boxShadow: "0 0 40px rgba(0, 229, 255, 0.3)" },
        },
        gradientShift: {
          "0%, 100%": { backgroundPosition: "0% 50%" },
          "50%": { backgroundPosition: "100% 50%" },
        },
        floatParticle: {
          "0%, 100%": { transform: "translateY(0) translateX(0)", opacity: "0" },
          "10%": { opacity: "1" },
          "90%": { opacity: "1" },
          "50%": { transform: "translateY(-100px) translateX(20px)" },
        },
        typingCursor: {
          "0%, 100%": { opacity: "1" },
          "50%": { opacity: "0" },
        },
        progressSweep: {
          "0%": { transform: "translateX(-100%)" },
          "100%": { transform: "translateX(100%)" },
        },
        fadeInUp: {
          "0%": { opacity: "0", transform: "translateY(30px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        scaleIn: {
          "0%": { opacity: "0", transform: "scale(0.9)" },
          "100%": { opacity: "1", transform: "scale(1)" },
        },
        slideInRight: {
          "0%": { opacity: "0", transform: "translateX(-30px)" },
          "100%": { opacity: "1", transform: "translateX(0)" },
        },
        breathe: {
          "0%, 100%": { transform: "scale(1)" },
          "50%": { transform: "scale(1.005)" },
        },
      },
      boxShadow: {
        glow: "0 0 50px -10px rgba(0, 229, 255, 0.25)",
        "glow-purple": "0 0 50px -10px rgba(168, 85, 247, 0.25)",
        "glow-coral": "0 0 50px -10px rgba(251, 113, 133, 0.25)",
        squircle: "0 12px 36px -8px rgba(0, 0, 0, 0.65), 0 0 0 1px rgba(255, 255, 255, 0.12)",
        "glow-lg": "0 0 80px -15px rgba(0, 229, 255, 0.4)",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};

export default config;
