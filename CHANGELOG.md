# Changelog

All notable changes to **Aura** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-09-21

### Added
- **Photorealistic MacBook Pro Hardware Simulator**:
  - Unibody space black aluminum chassis with authentic 16:10 Apple Retina display aspect ratio.
  - Interactive macOS Sequoia menubar with system menus, date/time, battery, WiFi, control center, and status icons.
  - Symmetrical 3D lower aluminum deck with iconic centered lid-opening indent and subtle desk contact shadow.
  - Dynamic proportional scaling (`notchScale = 0.76` desktop, `0.68` tablet, `0.52` mobile) matching actual Apple Retina hardware proportions.
- **Interactive 5-State Notch HUD Simulator**:
  - Full 1:1 pixel parity across all five states:
    - **Idle (Resting)**: Mini Living Orb, camera space, and message count indicator flush with native menubar.
    - **Listening**: 5-bar vocal equalizer, microphone dot, Living Orb with acoustic waveform, and global shortcut hints.
    - **Reasoning**: Thinking orbit loader, purple cosmic vortex orb, and animated gradient shimmer beam.
    - **Speaking**: Real-time voice equalizer, coral sound-ribbon orb, and response bubble with one-click copy.
    - **Chat Inspector**: Conversation inspector with stacked user and assistant message turns and quick actions.
- **Aurora Design System & Interactive Landing Page**:
  - GPU-accelerated living background with radial blur aurora beams.
  - Smooth scrolling powered by Lenis and scroll progress tracking.
  - Interactive comparison matrix, dynamic capability tabs, and native Homebrew install snippet.
- **Official Brand Icon Assets**:
  - Integrated `@icons-pack/react-simple-icons` for authentic, trademark vector brand assets.
  - Added official Apple vector SVG asset to `web/public/icons/apple.svg`.

### Changed
- **Settings & Control Center Redesign**:
  - Streamlined Control Center navigation by removing redundant search filters and simplifying sidebar categories.
  - Modernized liquid glass card hierarchy and tokens.
- **Homebrew Installation**:
  - Updated Homebrew tap install command to `brew install TheShahnawaaz/tap/aura`.

### Removed
- **Unused Workspace Connectors**:
  - Removed deprecated and unstable Gmail, Notion, and SQLite connectors in favor of direct Model Context Protocol (MCP) integrations.

### Fixed
- **Cross-Platform Web Builds**:
  - Fixed platform-specific Darwin SWC dependencies to ensure reliable cross-platform builds on Linux/Vercel and CI environments.
- **Notch Preview Centering**:
  - Anchored notch HUD mount to strict 50% centerline container, eliminating lateral shift when transitioning between collapsed and expanded states.

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
