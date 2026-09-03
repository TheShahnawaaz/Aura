import SwiftUI

/// Complete configuration for each distinct visual state of the Living Aurora Orb.
/// Each state has its own unique geometry, animation curves, and audio reactivity.
public enum LivingAuroraTheme {

    // MARK: - 1. IDLE STATE DESIGN: Celestial Floating Nebula
    public struct IdleDesign: Sendable {
        public var driftSpeed: Double = 0.55
        public var rotationSpeed: Double = 12.0
        public var breathRate: Double = 0.85
        public var coreScaleBase: CGFloat = 0.86
        public var nebulaColors: [Color] = [
            Color(red: 0.05, green: 0.68, blue: 0.82), // Oceanic Teal
            Color(red: 0.18, green: 0.88, blue: 0.90), // Cyan
            Color(red: 0.10, green: 0.45, blue: 0.92), // Azure
            Color(red: 0.35, green: 0.40, blue: 0.88), // Soft Lilac
            Color(red: 0.05, green: 0.68, blue: 0.82)
        ]
        public var starCoreColor: Color = Color.cyan.opacity(0.85)
        public var ambientGlow: Color = Color.cyan.opacity(0.28)
        public var causticColor: Color = Color.cyan
    }

    // MARK: - 2. LISTENING STATE DESIGN: Voice Acoustic Resonator
    public struct ListeningDesign: Sendable {
        public var surgeSpeed: Double = 35.0
        public var shockwaveCount: Int = 3
        public var waveformFrequency: Double = 3.2
        public var maxWaveAmplitudeRatio: CGFloat = 0.38
        public var audioReactivityGain: CGFloat = 1.35
        public var coreScaleMax: CGFloat = 1.65
        public var acousticColors: [Color] = [
            Color(red: 0.0, green: 1.0, blue: 0.92),   // Neon Cyan
            Color(red: 0.1, green: 0.85, blue: 0.98),  // Turquoise
            Color(red: 0.2, green: 0.98, blue: 0.75),  // Mint flash
            Color(red: 0.0, green: 0.95, blue: 1.0)
        ]
        public var ringColor: Color = Color(red: 0.2, green: 0.98, blue: 0.85)
        public var peakFlashColor: Color = Color.white
        public var ambientGlow: Color = Color(red: 0.0, green: 0.95, blue: 0.92).opacity(0.55)
        public var causticColor: Color = Color.cyan
    }

    // MARK: - 3. PROCESSING STATE DESIGN: Galactic Vortex Accelerator
    public struct ProcessingDesign: Sendable {
        public var vortexSpinSpeed: Double = 58.0      // Rapid rotational vortex
        public var orbitalRingSpeed: Double = 42.0     // Counter-spinning orbital ring
        public var vortexArmCount: Int = 2
        public var eventHorizonPulseRate: Double = 3.4
        public var vortexColors: [Color] = [
            Color(red: 0.65, green: 0.15, blue: 0.98), // Deep Royal Violet
            Color(red: 0.88, green: 0.25, blue: 0.92), // Vivid Orchid
            Color(red: 0.20, green: 0.80, blue: 1.00), // Electric Cyan
            Color(red: 0.50, green: 0.10, blue: 0.90), // Royal Purple
            Color(red: 0.65, green: 0.15, blue: 0.98)
        ]
        public var ringColor: Color = Color(red: 0.85, green: 0.30, blue: 0.95)
        public var coreColor: Color = Color.white
        public var ambientGlow: Color = Color(red: 0.70, green: 0.25, blue: 0.98).opacity(0.45)
        public var causticColor: Color = Color(red: 0.85, green: 0.30, blue: 0.95)
    }

    // MARK: - 4. SPEAKING STATE DESIGN: Harmonic Vocal Ribbon & Speech Pulses
    public struct SpeakingDesign: Sendable {
        public var ribbonFrequency: Double = 2.6
        public var ribbonWaveSpeed: Double = 18.0
        public var pulseCadenceRate: Double = 3.6
        public var warmColors: [Color] = [
            Color(red: 1.00, green: 0.44, blue: 0.54), // Radiant Warm Coral
            Color(red: 1.00, green: 0.68, blue: 0.52), // Golden Sunset Peach
            Color(red: 0.92, green: 0.35, blue: 0.65), // Soft Magenta
            Color(red: 0.82, green: 0.50, blue: 0.90), // Lavender
            Color(red: 1.00, green: 0.44, blue: 0.54)
        ]
        public var waveStrokeColor: Color = Color(red: 1.0, green: 0.75, blue: 0.65)
        public var coreColor: Color = Color(red: 1.0, green: 0.92, blue: 0.85)
        public var ambientGlow: Color = Color(red: 1.00, green: 0.48, blue: 0.58).opacity(0.45)
        public var causticColor: Color = Color(red: 1.00, green: 0.55, blue: 0.65)
    }

    // Static default instances that can be customized anytime
    public static let idle = IdleDesign()
    public static let listening = ListeningDesign()
    public static let processing = ProcessingDesign()
    public static let speaking = SpeakingDesign()
}
