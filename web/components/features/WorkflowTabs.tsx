"use client";

import React, { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence, useInView } from "framer-motion";
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
    voicePrompt: '\u201CQuit Slack, set volume to 20%, and take a screenshot of my workspace\u201D',
    systemAction: "Executes native macOS system calls via AppleScript and CoreGraphics.",
    toolChain: ["open_application('Slack', action: .quit)", "adjust_volume(20)", "take_screenshot('~/Desktop/Screen.png')"],
    terminalOutput: "\u2713 Slack gracefully closed via AppleScript\n\u2713 System audio output set to 20%\n\u2713 Capture written to ~/Desktop/Screen.png (1024x768 PNG)",
    status: "success",
  },
  {
    id: "ducking",
    title: "Media Ducking",
    category: "Voice Pipeline",
    icon: Music,
    voicePrompt: '\u201CWhat\u2019s the weather in San Francisco this weekend?\u201D',
    systemAction: "Instant RMS audio tap dips Apple Music & Spotify playback to 10% during speech.",
    toolChain: ["AudioDuckingManager.duck(to: 0.10)", "gemini.query('weather in SF')", "AudioDuckingManager.restore()"],
    terminalOutput: "\u25B6 Spotify volume ducked: 85% -> 10%\n\u2713 Weather forecast retrieved: 68\u00B0F, Sunny\n\u25B6 Synthesizing response with barge-in active\n\u25B6 Audio restored smoothly: 10% -> 85%",
    status: "streaming",
  },
  {
    id: "mcp",
    title: "Model Context Protocol",
    category: "Extensible Ecosystem",
    icon: Network,
    voicePrompt: '\u201CQuery our internal Postgres database for active subscriptions\u201D',
    systemAction: "Mounts local and remote MCP servers over stdio and SSE directly into the agent tool registry.",
    toolChain: ["mcp.postgres.query('SELECT count(*) FROM users WHERE active = true')", "OpenAgentSDK.synthesizeOutput()"],
    terminalOutput: "\u2713 Connected to stdio MCP server: postgres-mcp\n\u2713 Query executed in 128ms\n\u2713 Returned 1,428 active subscribers\n\u2713 Formatted table in Control Center Chat",
    status: "success",
  },
  {
    id: "guardrails",
    title: "Proactive Guardrails",
    category: "Safety Classifier",
    icon: ShieldCheck,
    voicePrompt: '\u201CRun this cleanup script: sudo rm -rf /var/log/*\u201D',
    systemAction: "Interception engine parses shell tokens and halts destructive operations before execution.",
    toolChain: ["GuardrailsEngine.classify('sudo rm -rf')", "ActionSafety.blockDestructive()", "NotchHUD.requireConfirmation()"],
    terminalOutput: "\u26A0\uFE0F DESTRUCTIVE COMMAND BLOCKED\nReason: 'sudo rm -rf' detected on root filesystem\nStatus: Execution halted. Explicit manual confirmation required in Notch HUD.",
    status: "blocked",
  },
];

// Typing animation component
function TypedTerminal({ text }: { text: string }) {
  const [visibleLines, setVisibleLines] = useState(0);
  const lines = text.split("\n");

  useEffect(() => {
    setVisibleLines(0);
    let i = 0;
    const interval = setInterval(() => {
      if (i < lines.length) {
        i++;
        setVisibleLines(i);
      } else {
        clearInterval(interval);
      }
    }, 400);
    return () => clearInterval(interval);
  }, [text, lines.length]);

  const getLineColor = (line: string) => {
    if (line.includes("\u26A0") || line.includes("BLOCKED")) return "text-rose-400 font-semibold";
    if (line.includes("\u2713")) return "text-emerald-300";
    if (line.includes("\u25B6")) return "text-cyan-300";
    return "text-slate-400";
  };

  return (
    <div className="w-full">
      {lines.slice(0, visibleLines).map((line, i) => (
        <motion.div
          key={`${text.slice(0, 10)}-${i}`}
          initial={{ opacity: 0, x: -5 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.2 }}
          className={`py-1 ${getLineColor(line)}`}
        >
          {line}
        </motion.div>
      ))}
      {visibleLines < lines.length && (
        <span className="text-cyan-400 animate-pulse">{"\u2587"}</span>
      )}
    </div>
  );
}

export const WorkflowTabs: React.FC = () => {
  const [selectedTab, setSelectedTab] = useState<string>("system");
  const current = workflows.find((w) => w.id === selectedTab) || workflows[0];
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-100px" });

  return (
    <section id="workflows" className="py-28 px-4 max-w-6xl mx-auto w-full" ref={ref}>
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 30 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
        className="max-w-2xl mb-14"
      >
        <span className="text-xs font-mono uppercase tracking-widest text-cyan-400 font-semibold block mb-2">
          Autonomous Dispatch
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.03em] text-white leading-tight">
          One sentence. <br />
          <span className="text-slate-500">Real desktop execution.</span>
        </h2>
      </motion.div>

      {/* Tab Selector Buttons */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.5, delay: 0.2 }}
        className="flex flex-wrap items-center gap-2 mb-8"
      >
        {workflows.map((tab) => {
          const Icon = tab.icon;
          const isSelected = selectedTab === tab.id;
          return (
            <motion.button
              key={tab.id}
              onClick={() => setSelectedTab(tab.id)}
              className={`relative flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-medium transition-all overflow-hidden ${
                isSelected
                  ? "bg-white text-black font-semibold shadow-lg"
                  : "bg-[#0c0e14] text-slate-400 hover:text-white border border-white/[0.06] hover:border-white/[0.12]"
              }`}
              whileHover={{ scale: 1.03, y: -1 }}
              whileTap={{ scale: 0.98 }}
              layout
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{tab.title}</span>
              {isSelected && (
                <motion.div
                  className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent -translate-x-full"
                  animate={{ translateX: "200%" }}
                  transition={{ duration: 1.5, delay: 0.2 }}
                />
              )}
            </motion.button>
          );
        })}
      </motion.div>

      {/* Interactive Workflow Display */}
      <AnimatePresence mode="wait">
        <motion.div
          key={current.id}
          initial={{ opacity: 0, y: 12, scale: 0.99 }}
          animate={{ opacity: 1, y: 0, scale: 1 }}
          exit={{ opacity: 0, y: -12, scale: 0.99 }}
          transition={{ duration: 0.3, ease: [0.22, 1, 0.36, 1] }}
          className="rounded-[24px] p-6 sm:p-10 bg-[#0c0e14] border border-white/[0.07] shadow-2xl relative overflow-hidden"
        >
          {/* Subtle ambient glow */}
          <div className="absolute -top-40 -right-40 w-[400px] h-[400px] rounded-full bg-cyan-500/[0.03] blur-[100px] pointer-events-none" />

          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center relative z-10">
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

              {/* Voice Prompt */}
              <motion.div
                initial={{ opacity: 0, x: -15 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.15 }}
                className="p-4 rounded-2xl bg-[#07080c] border border-white/[0.06] hover:border-white/[0.1] transition-colors"
              >
                <span className="text-[10px] uppercase font-mono text-slate-500 block mb-1.5">
                  Voice Query
                </span>
                <p className="text-base text-white font-medium leading-snug">
                  {current.voicePrompt}
                </p>
              </motion.div>

              {/* Tool Chain */}
              <div>
                <span className="text-[10px] uppercase font-mono text-slate-500 block mb-2">
                  Autonomous Tool Dispatch
                </span>
                <div className="space-y-1.5 font-mono text-xs">
                  {current.toolChain.map((step, idx) => (
                    <motion.div
                      key={idx}
                      initial={{ opacity: 0, x: -20 }}
                      animate={{ opacity: 1, x: 0 }}
                      transition={{ delay: 0.2 + idx * 0.1, type: "spring", stiffness: 200 }}
                      className="flex items-center gap-2.5 px-3 py-2 rounded-xl bg-black/40 border border-white/[0.04] text-slate-300 hover:border-cyan-500/20 transition-colors"
                    >
                      <span className="text-cyan-400 font-bold">{idx + 1}.</span>
                      <span className="truncate">{step}</span>
                    </motion.div>
                  ))}
                </div>
              </div>
            </div>

            {/* Right Terminal Window */}
            <div className="lg:col-span-6">
              <motion.div
                initial={{ opacity: 0, scale: 0.97 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ delay: 0.3, duration: 0.4 }}
                className="rounded-2xl bg-[#06070a] border border-[#22242c] overflow-hidden shadow-2xl"
              >
                {/* Window Title Bar */}
                <div className="px-4 py-3 bg-[#0f1118] border-b border-white/[0.06] flex items-center justify-between text-xs text-slate-400 select-none">
                  <div className="flex items-center gap-2">
                    <div className="flex items-center gap-1.5">
                      <div className="w-2.5 h-2.5 rounded-full bg-[#ff5f56] hover:brightness-110 transition" />
                      <div className="w-2.5 h-2.5 rounded-full bg-[#ffbd2e] hover:brightness-110 transition" />
                      <div className="w-2.5 h-2.5 rounded-full bg-[#27c93f] hover:brightness-110 transition" />
                    </div>
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

                {/* Console Log Output with typing effect */}
                <div className="p-5 font-mono text-xs text-slate-300 leading-relaxed whitespace-pre-wrap min-h-[190px] flex items-center">
                  <div className="w-full">
                    <TypedTerminal
                      key={current.id}
                      text={current.terminalOutput}
                    />
                  </div>
                </div>
              </motion.div>
            </div>
          </div>
        </motion.div>
      </AnimatePresence>
    </section>
  );
};
