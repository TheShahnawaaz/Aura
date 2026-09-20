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
        background: "#050608",
        obsidian: {
          DEFAULT: "#050608",
          950: "#050608",
          900: "#090B10",
          850: "#0D1017",
          800: "#121620",
          750: "#181D2A",
          700: "#22293A",
          600: "#353F57",
        },
        iris: {
          DEFAULT: "#6366F1",
          300: "#A5B4FC",
          400: "#818CF8",
          500: "#6366F1",
          600: "#4F46E5",
          700: "#4338CA",
          glow: "rgba(99, 102, 241, 0.15)",
        },
        telemetry: {
          emerald: "#10B981",
          amber: "#F59E0B",
          rose: "#F43F5E",
          cyan: "#06B6D4",
        },
      },
      fontFamily: {
        display: [
          "SF Pro Display",
          "-apple-system",
          "BlinkMacSystemFont",
          "system-ui",
          "sans-serif",
        ],
        sans: [
          "SF Pro Text",
          "-apple-system",
          "BlinkMacSystemFont",
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
      borderRadius: {
        "bezel-outer": "28px",
        "bezel-inner": "22px",
        "card-outer": "22px",
        "card-inner": "17px",
        "notch": "16px",
      },
      boxShadow: {
        "hairline": "inset 0 1px 0 0 rgba(255, 255, 255, 0.08)",
        "hairline-subtle": "inset 0 1px 0 0 rgba(255, 255, 255, 0.04)",
        "iris-glow": "0 0 32px -8px rgba(99, 102, 241, 0.25)",
        "notch-elevation": "0 20px 48px -12px rgba(0, 0, 0, 0.85), 0 0 0 1px rgba(255, 255, 255, 0.06)",
        "bezel-elevation": "0 24px 64px -16px rgba(0, 0, 0, 0.90), 0 0 0 1px rgba(255, 255, 255, 0.05)",
      },
      transitionTimingFunction: {
        "apple": "cubic-bezier(0.16, 1, 0.3, 1)",
        "haptic": "cubic-bezier(0.32, 0.72, 0, 1)",
      },
      animation: {
        "pulse-subtle": "pulseSubtle 3s ease-in-out infinite",
        "shimmer-specular": "shimmerSpecular 6s cubic-bezier(0.16, 1, 0.3, 1) infinite",
      },
      keyframes: {
        pulseSubtle: {
          "0%, 100%": { opacity: "1", transform: "scale(1)" },
          "50%": { opacity: "0.85", transform: "scale(1.02)" },
        },
        shimmerSpecular: {
          "0%": { transform: "translateX(-150%)" },
          "100%": { transform: "translateX(250%)" },
        },
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};

export default config;
