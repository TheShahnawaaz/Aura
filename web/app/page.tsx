"use client";

import React from "react";
import { Navbar } from "@/components/Navbar";
import { HeroSection } from "@/components/hero/HeroSection";
import { WorkflowTabs } from "@/components/features/WorkflowTabs";
import { BentoGrid } from "@/components/features/BentoGrid";
import { ComparisonMatrix } from "@/components/comparison/ComparisonMatrix";
import { DownloadSection } from "@/components/download/DownloadSection";
import { Footer } from "@/components/footer/Footer";
import { ScrollProgress } from "@/components/ScrollProgress";
import { FloatingParticles } from "@/components/FloatingParticles";

export default function HomePage() {
  return (
    <div className="relative min-h-screen bg-background text-slate-100 selection:bg-cyan-500/30 selection:text-cyan-200">
      <ScrollProgress />
      <FloatingParticles />
      <Navbar />
      <main className="flex flex-col items-center justify-center">
        <HeroSection />
        <WorkflowTabs />
        <BentoGrid />
        <ComparisonMatrix />
        <DownloadSection />
      </main>
      <Footer />
    </div>
  );
}
