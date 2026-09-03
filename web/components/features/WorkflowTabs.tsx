"use client";

import React, { useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Terminal, Music, Network, ShieldCheck, CheckCircle2, Volume2, ShieldAlert, Play } from "lucide-react";

interface WorkflowItem {
  id: string;
  title: string;
  category: string;
  icon: React.ElementType;
  voicePrompt: string;
  systemAction: string;
  toolChain: string[];
  terminalOutput: string;
  status: "success" | "blocked" | "streaming";
}

const workflows: WorkflowItem[] = [
  {
    id: "system",
    title: "System & Desktop",
    category: "Desktop Automation",
    icon: Terminal,
    voicePrompt: "“Quit Slack, set volume to 20%, and take a screenshot of my workspace”",
    systemAction: "Executes native macOS system calls via AppleScript and CoreGraphics.",
    toolChain: ["open_application('Slack', action: .quit)", "adjust_volume(20)", "take_screenshot('~/Desktop/Screen.png')"],
    terminalOutput: "✓ Slack gracefully closed via AppleScript\n✓ System audio output set to 20%\n✓ Capture written to ~/Desktop/Screen.png (1024x768 PNG)",
    status: "success",
  },
  {
    id: "ducking",
    title: "Media Ducking",
    category: "Voice Pipeline",
    icon: Music,
    voicePrompt: "“What's the weather in San Francisco this weekend?”",
    systemAction: "Instant RMS audio tap dips Apple Music & Spotify playback to 10% during speech.",
    toolChain: ["AudioDuckingManager.duck(to: 0.10)", "gemini.query('weather in SF')", "AudioDuckingManager.restore()"],
    terminalOutput: "▶ Spotify volume ducked: 85% -> 10%\n✓ Weather forecast retrieved: 68°F, Sunny\n▶ Synthesizing response with barge-in active\n▶ Audio restored smoothly: 10% -> 85%",
    status: "streaming",
  },
  {
    id: "mcp",
    title: "Model Context Protocol",
    category: "Extensible Ecosystem",
    icon: Network,
    voicePrompt: "“Query our internal Postgres database for active subscriptions”",
    systemAction: "Mounts local and remote MCP servers over stdio and SSE directly into the agent tool registry.",
    toolChain: ["mcp.postgres.query('SELECT count(*) FROM users WHERE active = true')", "OpenAgentSDK.synthesizeOutput()"],
    terminalOutput: "✓ Connected to stdio MCP server: postgres-mcp\n✓ Query executed in 128ms\n✓ Returned 1,428 active subscribers\n✓ Formatted table in Control Center Chat",
    status: "success",
  },
  {
    id: "guardrails",
    title: "Proactive Guardrails",
    category: "Safety Classifier",
    icon: ShieldCheck,
    voicePrompt: "“Run this cleanup script: sudo rm -rf /var/log/*”",
    systemAction: "Interception engine parses shell tokens and halts destructive operations before execution.",
    toolChain: ["GuardrailsEngine.classify('sudo rm -rf')", "ActionSafety.blockDestructive()", "NotchHUD.requireConfirmation()"],
    terminalOutput: "⚠️ DESTRUCTIVE COMMAND BLOCKED\nReason: 'sudo rm -rf' detected on root filesystem\nStatus: Execution halted. Explicit manual confirmation required in Notch HUD.",
    status: "blocked",
  },
];

export const WorkflowTabs: React.FC = () => {
  const [selectedTab, setSelectedTab] = useState<string>("system");
  const current = workflows.find((w) => w.id === selectedTab) || workflows[0];

  return (
    <section id="workflows" className="py-28 px-4 max-w-6xl mx-auto w-full">
      {/* Header */}
      <div className="max-w-2xl mb-14">
        <span className="text-xs font-mono uppercase tracking-widest text-cyan-400 font-semibold block mb-2">
          Autonomous Dispatch
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.03em] text-white leading-tight">
          One sentence. <br />
          <span className="text-slate-500">Real desktop execution.</span>
        </h2>
      </div>

      {/* Tab Selector Buttons */}
      <div className="flex flex-wrap items-center gap-2 mb-8">
        {workflows.map((tab) => {
          const Icon = tab.icon;
          const isSelected = selectedTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setSelectedTab(tab.id)}
              className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all ${
                isSelected
                  ? "bg-white text-black font-semibold shadow-lg scale-[1.02]"
                  : "bg-[#0c0e14] text-slate-400 hover:text-white border border-white/[0.06] hover:border-white/[0.12]"
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{tab.title}</span>
            </button>
          );
        })}
      </div>

      {/* Interactive Workflow Display */}
      <AnimatePresence mode="wait">
        <motion.div
          key={current.id}
          initial={{ opacity: 0, y: 8 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -8 }}
          transition={{ duration: 0.2 }}
          className="rounded-[24px] p-6 sm:p-10 bg-[#0c0e14] border border-white/[0.07] shadow-2xl relative overflow-hidden"
        >
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            {/* Left Narrative Column */}
            <div className="lg:col-span-6 space-y-6">
              <div>
                <span className="text-[11px] font-mono uppercase text-slate-500 font-semibold block mb-1">
                  {current.category}
                </span>
                <h3 className="text-2xl font-bold text-white tracking-tight">{current.title}</h3>
                <p className="text-sm text-slate-400 mt-2 leading-relaxed">
                  {current.systemAction}
                </p>
              </div>

              {/* Spoken Voice Prompt Quote */}
              <div className="p-4 rounded-2xl bg-[#07080c] border border-white/[0.06]">
                <span className="text-[10px] uppercase font-mono text-slate-500 block mb-1.5">
                  Voice Query
                </span>
                <p className="text-base text-white font-medium leading-snug">
                  {current.voicePrompt}
                </p>
              </div>

              {/* Tool Execution Sequence */}
              <div>
                <span className="text-[10px] uppercase font-mono text-slate-500 block mb-2">
                  Autonomous Tool Dispatch
                </span>
                <div className="space-y-1.5 font-mono text-xs">
                  {current.toolChain.map((step, idx) => (
                    <div
                      key={idx}
                      className="flex items-center gap-2.5 px-3 py-2 rounded-xl bg-black/40 border border-white/[0.04] text-slate-300"
                    >
                      <span className="text-cyan-400 font-bold">{idx + 1}.</span>
                      <span className="truncate">{step}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Right Native macOS Terminal Window */}
            <div className="lg:col-span-6">
              <div className="rounded-2xl bg-[#06070a] border border-[#22242c] overflow-hidden shadow-2xl">
                {/* Window Title Bar */}
                <div className="px-4 py-3 bg-[#0f1118] border-b border-white/[0.06] flex items-center justify-between text-xs text-slate-400 select-none">
                  <div className="flex items-center gap-2">
                    <div className="w-2.5 h-2.5 rounded-full bg-[#ff5f56]" />
                    <div className="w-2.5 h-2.5 rounded-full bg-[#ffbd2e]" />
                    <div className="w-2.5 h-2.5 rounded-full bg-[#27c93f]" />
                    <span className="ml-2 font-mono text-[11px] text-slate-400">
                      aura-dispatch.zsh
                    </span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    {current.status === "success" && (
                      <span className="flex items-center gap-1 text-[11px] font-mono text-emerald-400">
                        <CheckCircle2 className="w-3.5 h-3.5" /> Executed
                      </span>
                    )}
                    {current.status === "streaming" && (
                      <span className="flex items-center gap-1 text-[11px] font-mono text-cyan-400">
                        <Volume2 className="w-3.5 h-3.5 animate-pulse" /> Audio Active
                      </span>
                    )}
                    {current.status === "blocked" && (
                      <span className="flex items-center gap-1 text-[11px] font-mono text-rose-400">
                        <ShieldAlert className="w-3.5 h-3.5" /> Intercepted
                      </span>
                    )}
                  </div>
                </div>

                {/* Console Log Output */}
                <div className="p-5 font-mono text-xs text-slate-300 leading-relaxed whitespace-pre-wrap min-h-[190px] flex items-center">
                  <div className="w-full">
                    {current.terminalOutput.split("\n").map((line, i) => {
                      const isWarn = line.includes("⚠️") || line.includes("BLOCKED");
                      const isSuccess = line.includes("✓");
                      const isAudio = line.includes("▶");
                      return (
                        <div
                          key={i}
                          className={`py-1 ${
                            isWarn
                              ? "text-rose-400 font-semibold"
                              : isSuccess
                              ? "text-emerald-300"
                              : isAudio
                              ? "text-cyan-300"
                              : "text-slate-400"
                          }`}
                        >
                          {line}
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </div>
          </div>
        </motion.div>
      </AnimatePresence>
    </section>
  );
};
