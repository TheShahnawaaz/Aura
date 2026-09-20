import React from "react";
import type { Metadata } from "next";
import "./globals.css";
import { SmoothScrollProvider } from "@/components/SmoothScrollProvider";

export const metadata: Metadata = {
  metadataBase: new URL("https://aura.mac"),
  title: "Aura — Autonomous Voice & Desktop AI Assistant for macOS",
  description:
    "Aura is an autonomous, voice-first desktop AI assistant engineered for macOS Sequoia and Apple Silicon. Living in your MacBook camera notch, it executes native workflows, automates system calls, ducks audio playback, and connects to Model Context Protocol (MCP) servers.",
  icons: {
    icon: "/icon.png",
    apple: "/icon.png",
  },
  openGraph: {
    title: "Aura — Autonomous Voice & Desktop AI Assistant for macOS",
    description:
      "Hardware intelligence anchored at the MacBook notch. Executes AppleScript and terminal commands, enforces destructive shell guardrails, and integrates MCP tools.",
    url: "https://aura.mac",
    siteName: "Aura",
    images: [
      {
        url: "/icon.png",
        width: 1024,
        height: 1024,
        alt: "Aura App Icon",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Aura — Autonomous Voice & Desktop AI Assistant for macOS",
    description:
      "Aura lives in your MacBook camera notch, responds to speech with real-time acoustic shockwaves, and executes autonomous desktop tasks.",
    images: ["/icon.png"],
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" className="dark scroll-smooth">
      <body className="bg-background text-slate-200 antialiased min-h-screen selection:bg-iris-500/30 selection:text-iris-100 font-sans">
        <SmoothScrollProvider>
          {children}
        </SmoothScrollProvider>
      </body>
    </html>
  );
}
