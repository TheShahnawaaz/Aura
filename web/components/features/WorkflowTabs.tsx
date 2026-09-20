"use client";

import React, { useState, useRef, useEffect } from "react";
import { motion, AnimatePresence, useInView } from "framer-motion";
import { Terminal, Music, Network, ShieldCheck, CheckCircle2, Volume2, ShieldAlert } from "lucide-react";

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
    title: "Desktop Automation",
    category: "AppleScript & CoreGraphics",
    icon: Terminal,
    voicePrompt: '“Quit Slack, set system volume to 20%, and take a screenshot of my workspace”',
    systemAction: "Executes native macOS system calls directly via AppleScript and CoreGraphics with zero bridge delay.",
    toolChain: [
      "open_application('Slack', action: .quit)",
      "adjust_volume(20)",
      "take_screenshot('~/Desktop/Screen.png')",
    ],
    terminalOutput: "✓ Slack process terminated via NSWorkspace\n✓ System audio output set to 20%\n✓ Screen capture written to ~/Desktop/Screen.png (1440x900 PNG @2x)",
    status: "success",
  },
  {
    id: "ducking",
    title: "Media Ducking",
    category: "Speech Pipeline",
    icon: Music,
    voicePrompt: '“Summarize the latest commits on branch main”',
    systemAction: "Instant RMS audio tap dips Apple Music & Spotify playback down to 10% during speech, restoring smoothly upon completion.",
    toolChain: [
      "AudioDuckingManager.duck(to: 0.10)",
      "terminal_command('git log -n 3 --oneline')",
      "AudioDuckingManager.restore()",
    ],
    terminalOutput: "▶ Media playback smoothly attenuated: 80% -> 10%\n✓ Branch commits parsed in 42ms\n▶ Synthesizing audio with real-time barge-in active\n▶ Audio playback restored smoothly: 10% -> 80%",
    status: "streaming",
  },
  {
    id: "mcp",
    title: "Model Context Protocol",
    category: "Extensible Toolchain",
    icon: Network,
    voicePrompt: '“Query the local GitHub MCP server for open pull requests”',
    systemAction: "Connects to official Model Context Protocol (MCP) servers over stdio or SSE directly in the agent runtime.",
    toolChain: [
      "mcp.github.list_pull_requests(owner: 'TheShahnawaaz', repo: 'Aura')",
      "OpenAgentSDK.synthesizeOutput()",
    ],
    terminalOutput: "✓ Connected to stdio server: @modelcontextprotocol/server-github\n✓ Tool call executed in 118ms\n✓ 2 open pull requests retrieved and summarized in Control Center",
    status: "success",
  },
  {
    id: "guardrails",
    title: "Deterministic Guardrails",
    category: "Security Kernel",
    icon: ShieldCheck,
    voicePrompt: '“Execute this cleanup: sudo rm -rf /Library/Caches/*”',
    systemAction: "Proactive AST classifier intercepts and halts destructive shell operations before execution.",
    toolChain: [
      "GuardrailsEngine.classify('sudo rm -rf')",
      "ActionSafety.blockDestructive()",
      "NotchHUD.requireConfirmation()",
    ],
    terminalOutput: "⚠️ DESTRUCTIVE COMMAND INTERCEPTED\nReason: 'sudo rm -rf' detected on root system hierarchy\nStatus: Execution halted. Explicit physical confirmation required in Notch HUD.",
    status: "blocked",
  },
];

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
    }, 350);
    return () => clearInterval(interval);
  }, [text, lines.length]);

  const getLineColor = (line: string) => {
    if (line.includes("⚠️") || line.includes("INTERCEPTED")) return "text-rose-400 font-semibold";
    if (line.includes("✓")) return "text-emerald-400";
    if (line.includes("▶")) return "text-iris-300";
    return "text-slate-400";
  };

  return (
    <div className="w-full space-y-1">
      {lines.slice(0, visibleLines).map((line, i) => (
        <motion.div
          key={`${text.slice(0, 8)}-${i}`}
          initial={{ opacity: 0, x: -4 }}
          animate={{ opacity: 1, x: 0 }}
          transition={{ duration: 0.2 }}
          className={`py-0.5 ${getLineColor(line)}`}
        >
          {line}
        </motion.div>
      ))}
      {visibleLines < lines.length && (
        <span className="text-iris-400 animate-pulse">▌</span>
      )}
    </div>
  );
}

export const WorkflowTabs: React.FC = () => {
  const [selectedTab, setSelectedTab] = useState<string>("system");
  const current = workflows.find((w) => w.id === selectedTab) || workflows[0];
  const ref = useRef(null);
  const isInView = useInView(ref, { once: true, margin: "-80px" });

  return (
    <section id="workflows" className="py-28 sm:py-36 px-4 max-w-6xl mx-auto w-full" ref={ref}>
      {/* Header */}
      <motion.div
        initial={{ opacity: 0, y: 24 }}
        animate={isInView ? { opacity: 1, y: 0 } : {}}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
        className="max-w-2xl mb-14"
      >
        <span className="text-[11px] font-mono uppercase tracking-[0.2em] text-iris-400 font-semibold block mb-3">
          Autonomous Dispatch
        </span>
        <h2 className="text-3xl sm:text-5xl font-extrabold tracking-[-0.035em] text-white leading-[1.1]">
          One spoken sentence. <br />
          <span className="text-slate-500">Real macOS execution.</span>
        </h2>
      </motion.div>

      {/* Segment Switcher */}
      <div className="flex flex-wrap items-center gap-2 mb-8 p-1.5 rounded-full bg-[#090B10] border border-white/[0.08] w-max max-w-full">
        {workflows.map((tab) => {
          const Icon = tab.icon;
          const isSelected = selectedTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setSelectedTab(tab.id)}
              className={`relative flex items-center gap-2 px-4 py-2 rounded-full text-xs font-medium transition-all ${
                isSelected
                  ? "bg-white text-black font-semibold shadow-sm"
                  : "text-slate-400 hover:text-white hover:bg-white/[0.04]"
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              <span>{tab.title}</span>
            </button>
          );
        })}
      </div>

      {/* Double-Bezel Interactive Workflow Display */}
      <AnimatePresence mode="wait">
        <motion.div
          key={current.id}
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          exit={{ opacity: 0, y: -10 }}
          transition={{ duration: 0.3, ease: [0.16, 1, 0.3, 1] }}
          className="double-bezel-outer w-full"
        >
          <div className="double-bezel-inner p-6 sm:p-10">
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              {/* Left Column */}
              <div className="lg:col-span-6 space-y-6">
                <div>
                  <span className="text-[10px] font-mono uppercase text-iris-400 font-semibold block mb-1">
                    {current.category}
                  </span>
                  <h3 className="text-2xl font-bold text-white tracking-tight">{current.title}</h3>
                  <p className="text-sm text-slate-400 mt-2 leading-relaxed">
                    {current.systemAction}
                  </p>
                </div>

                {/* Spoken Voice Query Box */}
                <div className="p-4 rounded-xl bg-black/40 border border-white/[0.06]">
                  <span className="text-[10px] uppercase font-mono text-slate-500 block mb-1.5">
                    Spoken Voice Input
                  </span>
                  <p className="text-base text-white font-medium leading-snug">
                    {current.voicePrompt}
                  </p>
                </div>

                {/* Tool Chain Pipeline */}
                <div>
                  <span className="text-[10px] uppercase font-mono text-slate-500 block mb-2">
                    Native Tool Execution Chain
                  </span>
                  <div className="space-y-1.5 font-mono text-xs">
                    {current.toolChain.map((step, idx) => (
                      <div
                        key={idx}
                        className="flex items-center gap-2.5 px-3 py-2 rounded-lg bg-black/40 border border-white/[0.04] text-slate-300"
                      >
                        <span className="text-iris-400 font-bold">{idx + 1}.</span>
                        <span className="truncate">{step}</span>
                      </div>
                    ))}
                  </div>
                </div>
              </div>

              {/* Right Terminal Window */}
              <div className="lg:col-span-6">
                <div className="rounded-xl bg-[#06070A] border border-white/[0.08] overflow-hidden shadow-2xl">
                  {/* Title Bar */}
                  <div className="px-4 py-2.5 bg-[#0D1017] border-b border-white/[0.06] flex items-center justify-between text-xs select-none">
                    <div className="flex items-center gap-2">
                      <div className="flex items-center gap-1.5">
                        <div className="w-2.5 h-2.5 rounded-full bg-[#ff5f56]" />
                        <div className="w-2.5 h-2.5 rounded-full bg-[#ffbd2e]" />
                        <div className="w-2.5 h-2.5 rounded-full bg-[#27c93f]" />
                      </div>
                      <span className="ml-2 font-mono text-[11px] text-slate-400">
                        aura-agent-runner
                      </span>
                    </div>
                    <div>
                      {current.status === "success" && (
                        <span className="flex items-center gap-1 text-[11px] font-mono text-emerald-400">
                          <CheckCircle2 className="w-3 h-3" /> Executed (0 errors)
                        </span>
                      )}
                      {current.status === "streaming" && (
                        <span className="flex items-center gap-1 text-[11px] font-mono text-iris-300">
                          <Volume2 className="w-3 h-3 animate-pulse" /> Audio Ducking
                        </span>
                      )}
                      {current.status === "blocked" && (
                        <span className="flex items-center gap-1 text-[11px] font-mono text-rose-400">
                          <ShieldAlert className="w-3 h-3" /> Blocked by Guardrail
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Terminal Log */}
                  <div className="p-5 font-mono text-xs text-slate-300 leading-relaxed whitespace-pre-wrap min-h-[180px] flex items-center">
                    <TypedTerminal key={current.id} text={current.terminalOutput} />
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
