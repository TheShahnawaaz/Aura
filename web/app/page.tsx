"use client";

import React from "react";
import { Navbar } from "@/components/Navbar";
import { HeroSection } from "@/components/hero/HeroSection";
import { BentoGrid } from "@/components/features/BentoGrid";
import { WorkflowTabs } from "@/components/features/WorkflowTabs";
import { ComparisonMatrix } from "@/components/comparison/ComparisonMatrix";
import { DownloadSection } from "@/components/download/DownloadSection";
import { Footer } from "@/components/footer/Footer";
import { ScrollProgress } from "@/components/ScrollProgress";

export default function HomePage() {
  return (
    <div className="relative min-h-screen bg-background text-slate-100 selection:bg-iris-500/30 selection:text-iris-100">
      <ScrollProgress />
      <Navbar />
      <main className="flex flex-col items-center justify-center w-full">
        <HeroSection />
        <BentoGrid />
        <WorkflowTabs />
        <ComparisonMatrix />
        <DownloadSection />
      </main>
      <Footer />
    </div>
  );
}
