import React from "react";
import type { Metadata } from "next";
import "./globals.css";
import { SmoothScrollProvider } from "@/components/SmoothScrollProvider";

export const metadata: Metadata = {
  metadataBase: new URL("https://aura.mac"),
  title: "Aura — Autonomous Voice & Desktop AI Assistant for macOS",
  description:
    "Aura is a native, voice-enabled desktop AI assistant for macOS that lives in your MacBook notch, responds to voice in real time, and executes real system workflows.",
  icons: {
    icon: "/icon.png",
    apple: "/icon.png",
  },
  openGraph: {
    title: "Aura — Autonomous Voice & Desktop AI Assistant for macOS",
    description:
      "Intelligence anchored at the notch. Executes terminal commands, controls media, queries Notion & Gmail, and connects to external MCP tools.",
    url: "https://aura.mac",
    siteName: "Aura",
    images: [
      {
        url: "/icon.png",
        width: 1024,
        height: 1024,
        alt: "Aura Liquid Glass App Icon",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Aura — Autonomous Voice & Desktop AI Assistant for macOS",
    description:
      "Aura lives in your MacBook camera notch, understands voice with real-time acoustic shockwaves, and executes autonomous desktop tasks.",
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
      <body className="bg-background text-slate-100 antialiased min-h-screen selection:bg-cyan-500/30 selection:text-cyan-200">
        <SmoothScrollProvider>
          {children}
        </SmoothScrollProvider>
      </body>
    </html>
  );
}
