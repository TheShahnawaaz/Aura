# Changelog

All notable changes to **Aura** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-09-14

### Added
- **Dynamic MacBook Notch HUD**:
  - Precision bezel-blending SwiftUI view that wraps around physical MacBook camera notch.
  - Active turn inspector, live streaming markdown cards, tool call visualization, and keycap badges.
  - Ambient Living Aurora Orb with 60 FPS audio reactive surge dynamics.
- **In-Process Agent Engine**:
  - Powered by `OpenAgentSDK` with native Swift 6 concurrency (`async`/`await`).
  - Strict zero-fallback dynamic model discovery across Gemini, OpenAI, and Anthropic.
  - Multi-turn conversation persistence with session serialization.
- **Native macOS Execution Tools**:
  - `open_application`: Launch macOS applications via AppleScript and system dispatch.
  - `adjust_volume`: Native audio volume adjustment (up, down, mute, unmute).
  - `take_screenshot`: Desktop screen captures directly to PNG.
  - `list_files`: Filesystem inspection and directory traversal.
  - `execute_terminal_command`: Shell command execution in user's default login shell (`zsh`).
  - `search_emails` & `query_notion`: Workspace connectors for Gmail and Notion.
- **Model Context Protocol (MCP)**:
  - First-class support for external MCP servers over `stdio` and `SSE`.
  - Dynamic tool schema translation and lifecycle management.
- **Safety Guardrails**:
  - Pre-tool inspection engine that blocks destructive commands (`rm -rf`, `sudo`, `kill -9`).
  - Approval coordinator for sensitive system operations.
- **Voice Pipeline**:
  - Real-time 16kHz mono microphone tap with RMS audio metering.
  - Multi-provider STT (Apple Speech, Groq Whisper) and TTS (AVSpeechSynthesizer, ElevenLabs).
  - Low-latency barge-in speech cancellation with automatic media ducking for Spotify and Apple Music.
- **Control Center Settings**:
  - Liquid glass sidebar with tabs for AI Models, Tools, Skills, Voice, Permissions, Shortcuts, and Telemetry.
  - In-app version indicator and update check service.
- **Distribution & CI/CD**:
  - Native DMG packager with drag-to-Applications layout.
  - Automated GitHub Actions release pipeline with Apple Developer ID signing and Apple Notarization.
