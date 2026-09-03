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
      },
      boxShadow: {
        glow: "0 0 50px -10px rgba(0, 229, 255, 0.25)",
        "glow-purple": "0 0 50px -10px rgba(168, 85, 247, 0.25)",
        squircle: "0 12px 36px -8px rgba(0, 0, 0, 0.65), 0 0 0 1px rgba(255, 255, 255, 0.12)",
      },
    },
  },
  plugins: [],
};

export default config;
