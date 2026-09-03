import SwiftUI
import Combine

/// A tactile, iridescent living glass sphere with 4 completely distinct visual archetypes:
/// 1. Idle: Celestial floating nebula with calm organic Lissajous drift and breathing star-core.
/// 2. Listening: High-energy acoustic fluid resonator with live voice-reactive shockwave rings,
///               amplifying sine waveforms, and dynamic volume flash.
/// 3. Processing: Galactic particle vortex accelerator with dual spinning vortex arms and counter-orbiting rings.
/// 4. Speaking: Harmonic vocal ribbon undulating across warm speech cadence pulse waves.
public struct LivingAuroraOrbView: View {
    @ObservedObject public var appState: AppState
    public var overrideState: AssistantState?
    public var overrideAudioLevel: Float?
    public var size: CGFloat
    public var showSquircleBackground: Bool

    public init(
        appState: AppState = .shared,
        overrideState: AssistantState? = nil,
        overrideAudioLevel: Float? = nil,
        size: CGFloat = 120,
        showSquircleBackground: Bool = true
    ) {
        self.appState = appState
        self.overrideState = overrideState
        self.overrideAudioLevel = overrideAudioLevel
        self.size = size
        self.showSquircleBackground = showSquircleBackground
    }

    private var activeState: AssistantState {
        overrideState ?? appState.state
    }

    private var effectiveAudioLevel: CGFloat {
        let raw = overrideAudioLevel ?? appState.audioLevel
        return CGFloat(max(0.0, min(1.0, raw)))
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let level = effectiveAudioLevel

            if showSquircleBackground {
                let squircleSize = size * 1.36
                let cornerRadius = squircleSize * 0.2237

                ZStack {
                    // 1. Apple Liquid Glass Squircle Frame
                    squircleContainer(squircleSize: squircleSize, cornerRadius: cornerRadius)

                    // 2. Ambient Backglow (strictly clipped inside squircle so no light spills into macOS Dock)
                    ambientBackglow(state: activeState, level: level)
                        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))

                    // 3. The Living Glass Orb Body
                    glassOrbBody(time: time, level: level)
                }
                .frame(width: squircleSize, height: squircleSize)
                .shadow(color: Color.black.opacity(0.42), radius: max(2, squircleSize * 0.065), x: 0, y: squircleSize * 0.04)
            } else {
                ZStack {
                    ambientBackglow(state: activeState, level: level)
                    glassOrbBody(time: time, level: level)
                }
                .frame(width: size, height: size)
            }
        }
        .frame(
            width: showSquircleBackground ? size * 1.36 : size,
            height: showSquircleBackground ? size * 1.36 : size
        )
    }

    // MARK: - Spherical Glass Orb Body
    private func glassOrbBody(time: Double, level: CGFloat) -> some View {
        ZStack {
            // 1. Deep Space Base
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 0.03, green: 0.06, blue: 0.12),
                            Color(red: 0.01, green: 0.02, blue: 0.05)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.5
                    )
                )

            // 2. State-Specific Internal Visual Architecture
            Group {
                switch activeState {
                case .idle:
                    idleNebulaView(time: time)

                case .listening:
                    listeningAcousticView(time: time, level: level)

                case .processing, .awaitingConfirmation:
                    processingVortexView(time: time)

                case .speaking:
                    speakingHarmonicView(time: time, level: level)

                case .error:
                    errorStateView(time: time)
                }
            }
            .clipShape(Circle())

            // 3. Glass Depth: Inner Ambient Occlusion Vignette
            Circle()
                .strokeBorder(
                    RadialGradient(
                        colors: [.clear, Color.black.opacity(0.65)],
                        center: .center,
                        startRadius: size * 0.32,
                        endRadius: size * 0.5
                    ),
                    lineWidth: size * 0.14
                )
                .blendMode(.multiply)

            // 4. Caustic Fresnel Edge & Refraction Rim
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: causticColors(for: activeState),
                        center: .center,
                        angle: .degrees(time * causticRotationSpeed(for: activeState))
                    ),
                    lineWidth: max(1.0, size * 0.02)
                )

            // 5. Specular Glare (Top-Left Curved Glass Window Highlight)
            specularHighlight
                .blendMode(.screen)

            // 6. Secondary Bottom-Right Specular Bounce
            secondaryHighlight
                .blendMode(.screen)
        }
        .frame(width: size, height: size)
    }

    // MARK: - 1. IDLE STATE: Celestial Floating Nebula
    private func idleNebulaView(time: Double) -> some View {
        let theme = LivingAuroraTheme.idle
        let breath = CGFloat(sin(time * theme.breathRate)) * 0.05
        let driftX = CGFloat(sin(time * theme.driftSpeed * 0.7)) * (size * 0.10)
        let driftY = CGFloat(cos(time * theme.driftSpeed * 0.5)) * (size * 0.08)

        return ZStack {
            // Drifting Nebula Stream
            Circle()
                .fill(
                    AngularGradient(
                        colors: theme.nebulaColors,
                        center: .center,
                        angle: .degrees(time * theme.rotationSpeed)
                    )
                )
                .scaleEffect(theme.coreScaleBase + breath)
                .offset(x: driftX, y: driftY)
                .blur(radius: size * 0.16)

            // Counter-harmonic celestial mist
            Circle()
                .fill(
                    AngularGradient(
                        colors: theme.nebulaColors.reversed(),
                        center: .center,
                        angle: .degrees(-time * (theme.rotationSpeed * 0.7) + 90.0)
                    )
                )
                .scaleEffect(theme.coreScaleBase * 0.90)
                .offset(x: -driftX * 0.8, y: -driftY * 0.8)
                .blur(radius: size * 0.18)
                .blendMode(.screen)

            // Calm Breathing Star Core Singularity
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            theme.starCoreColor,
                            theme.starCoreColor.opacity(0.15),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.28
                    )
                )
                .scaleEffect(0.82 + breath)
                .blur(radius: size * 0.05)
        }
    }

    // MARK: - 2. LISTENING STATE: Voice Acoustic Resonator
    private func listeningAcousticView(time: Double, level: CGFloat) -> some View {
        let theme = LivingAuroraTheme.listening
        // Highly responsive voice surge calculation
        let surge = level * theme.audioReactivityGain
        let coreScale = 0.85 + (surge * 0.65)
        let waveAmp = (size * theme.maxWaveAmplitudeRatio) * max(0.15, surge)

        return ZStack {
            // Concentric Acoustic Shockwave Rings pulsing with voice intensity
            ForEach(0..<theme.shockwaveCount, id: \.self) { ringIndex in
                let ringPhase = (time * 2.2 + Double(ringIndex) * 0.33).truncatingRemainder(dividingBy: 1.0)
                let ringScale = 0.45 + CGFloat(ringPhase) * (0.65 + surge * 0.5)
                let ringOpacity = (1.0 - ringPhase) * Double(0.35 + surge * 0.65)

                Circle()
                    .stroke(
                        theme.ringColor.opacity(ringOpacity),
                        lineWidth: max(1.2, (size * 0.04) * (1.0 - CGFloat(ringPhase)))
                    )
                    .scaleEffect(ringScale)
                    .blur(radius: size * 0.02)
            }

            // Horizontal Voice Equalizer Waveforms crossing the orb
            FluidAcousticWave(
                amplitude: waveAmp,
                frequency: CGFloat(theme.waveformFrequency),
                phase: time * theme.surgeSpeed * 0.3
            )
            .fill(
                LinearGradient(
                    colors: [
                        theme.acousticColors[0].opacity(0.55 + surge * 0.4),
                        theme.acousticColors[2].opacity(0.35 + surge * 0.4),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: max(2.0, size * 0.03))

            FluidAcousticWave(
                amplitude: waveAmp * 0.8,
                frequency: CGFloat(theme.waveformFrequency * 1.4),
                phase: -time * theme.surgeSpeed * 0.35 + 1.2
            )
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.9),
                        theme.ringColor,
                        theme.acousticColors[1],
                        Color.white.opacity(0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: max(1.5, size * 0.025 * (1.0 + surge))
            )
            .shadow(color: theme.ringColor.opacity(Double(surge)), radius: size * 0.08)
            .blendMode(.screen)

            // Dynamic Luminous Vocal Core (Expands & Flashes with voice intensity)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white.opacity(min(1.0, 0.75 + Double(surge * 0.35))),
                            theme.acousticColors[0].opacity(0.9),
                            theme.acousticColors[1].opacity(0.35),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.30
                    )
                )
                .scaleEffect(coreScale)
                .blur(radius: size * 0.04)
        }
    }

    // MARK: - 3. PROCESSING STATE: Galactic Vortex Accelerator
    private func processingVortexView(time: Double) -> some View {
        let theme = LivingAuroraTheme.processing
        let pulse = CGFloat(sin(time * theme.eventHorizonPulseRate)) * 0.06

        return ZStack {
            // Rapid Swirling Spiral Vortex Arms
            Circle()
                .fill(
                    AngularGradient(
                        colors: theme.vortexColors,
                        center: .center,
                        angle: .degrees(time * theme.vortexSpinSpeed)
                    )
                )
                .scaleEffect(0.92 + pulse)
                .blur(radius: size * 0.12)

            // Counter-spinning Tilted Orbital Ring 1
            Ellipse()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            theme.ringColor,
                            theme.vortexColors[2],
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.5, size * 0.022)
                )
                .frame(width: size * 0.75, height: size * 0.32)
                .rotationEffect(.degrees(time * -theme.orbitalRingSpeed + 25.0))
                .blur(radius: 1.0)
                .blendMode(.screen)

            // Counter-spinning Tilted Orbital Ring 2
            Ellipse()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.85),
                            theme.ringColor,
                            Color.clear
                        ],
                        startPoint: .bottomLeading,
                        endPoint: .topTrailing
                    ),
                    lineWidth: max(1.2, size * 0.018)
                )
                .frame(width: size * 0.68, height: size * 0.28)
                .rotationEffect(.degrees(time * (theme.orbitalRingSpeed * 1.2) - 45.0))
                .blur(radius: 1.2)
                .blendMode(.screen)

            // High-Density Pulsing Event Horizon Singularity
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            theme.ringColor,
                            theme.vortexColors[0].opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.24
                    )
                )
                .scaleEffect(0.78 + pulse)
                .blur(radius: size * 0.03)
        }
    }

    // MARK: - 4. SPEAKING STATE: Harmonic Vocal Ribbon & Speech Pulses
    private func speakingHarmonicView(time: Double, level: CGFloat) -> some View {
        let theme = LivingAuroraTheme.speaking
        let cadence = CGFloat(sin(time * theme.pulseCadenceRate)) * 0.08
        let vocalEnergy = max(cadence, level * 0.8)

        return ZStack {
            // Warm Speech Cadence Radial Pulses
            ForEach(0..<2, id: \.self) { waveIdx in
                let pulsePhase = (time * 1.8 + Double(waveIdx) * 0.5).truncatingRemainder(dividingBy: 1.0)
                let waveScale = 0.50 + CGFloat(pulsePhase) * 0.55

                Circle()
                    .stroke(
                        theme.warmColors[0].opacity((1.0 - pulsePhase) * 0.5),
                        lineWidth: max(1.5, (size * 0.03) * (1.0 - CGFloat(pulsePhase)))
                    )
                    .scaleEffect(waveScale)
                    .blur(radius: size * 0.03)
            }

            // Flowing Undulating Vocal Ribbon
            FluidAcousticWave(
                amplitude: size * 0.22 * (1.0 + vocalEnergy * 0.8),
                frequency: CGFloat(theme.ribbonFrequency),
                phase: time * theme.ribbonWaveSpeed * 0.2
            )
            .fill(
                LinearGradient(
                    colors: [
                        theme.warmColors[0].opacity(0.65),
                        theme.warmColors[1].opacity(0.45),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .blur(radius: size * 0.04)

            FluidAcousticWave(
                amplitude: size * 0.18 * (1.0 + vocalEnergy * 0.8),
                frequency: CGFloat(theme.ribbonFrequency * 1.2),
                phase: -time * theme.ribbonWaveSpeed * 0.25 + 0.8
            )
            .stroke(
                LinearGradient(
                    colors: [
                        theme.coreColor,
                        theme.waveStrokeColor,
                        theme.warmColors[0],
                        theme.coreColor
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                lineWidth: max(1.5, size * 0.02)
            )
            .blendMode(.screen)

            // Warm Radiant Vocal Core
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.white,
                            theme.coreColor,
                            theme.warmColors[0].opacity(0.85),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.28
                    )
                )
                .scaleEffect(0.86 + vocalEnergy * 0.3)
                .blur(radius: size * 0.04)
        }
    }

    // MARK: - Error State
    private func errorStateView(time: Double) -> some View {
        let pulse = CGFloat(sin(time * 4.0)) * 0.08
        return ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.red,
                            Color(red: 0.6, green: 0.05, blue: 0.1),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: size * 0.4
                    )
                )
                .scaleEffect(0.9 + pulse)
                .blur(radius: size * 0.06)

            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: size * 0.42))
                .foregroundColor(.white)
        }
    }

    // MARK: - Optical Helpers
    private func ambientBackglow(state: AssistantState, level: CGFloat) -> some View {
        let color: Color
        let ratio: CGFloat

        switch state {
        case .idle:
            color = LivingAuroraTheme.idle.ambientGlow
            ratio = 0.28
        case .listening:
            color = LivingAuroraTheme.listening.ambientGlow.opacity(0.40 + level * 0.45)
            ratio = 0.35 + level * 0.30
        case .processing, .awaitingConfirmation:
            color = LivingAuroraTheme.processing.ambientGlow
            ratio = 0.32
        case .speaking:
            color = LivingAuroraTheme.speaking.ambientGlow
            ratio = 0.34
        case .error:
            color = Color.red.opacity(0.4)
            ratio = 0.30
        }

        return Circle()
            .fill(color)
            .frame(width: size * 0.95, height: size * 0.95)
            .blur(radius: size * ratio)
    }

    private func causticColors(for state: AssistantState) -> [Color] {
        switch state {
        case .idle:
            return [Color.white.opacity(0.65), Color.cyan.opacity(0.85), Color.white.opacity(0.35), Color.blue.opacity(0.75), Color.white.opacity(0.65)]
        case .listening:
            return [Color.white.opacity(0.85), Color(red: 0.1, green: 0.95, blue: 0.85), Color.white.opacity(0.4), Color.cyan, Color.white.opacity(0.85)]
        case .processing, .awaitingConfirmation:
            return [Color.white.opacity(0.7), Color.purple, Color.white.opacity(0.35), Color.cyan, Color.white.opacity(0.7)]
        case .speaking:
            return [Color.white.opacity(0.75), Color(red: 1.0, green: 0.55, blue: 0.65), Color.white.opacity(0.35), Color.orange.opacity(0.8), Color.white.opacity(0.75)]
        case .error:
            return [Color.white.opacity(0.6), Color.red, Color.white.opacity(0.3), Color.red, Color.white.opacity(0.6)]
        }
    }

    private func causticRotationSpeed(for state: AssistantState) -> Double {
        switch state {
        case .idle: return 12.0
        case .listening: return 28.0
        case .processing, .awaitingConfirmation: return 48.0
        case .speaking: return 16.0
        case .error: return 8.0
        }
    }

    // MARK: - Specular Glass Glare
    private var specularHighlight: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.82),
                        Color.white.opacity(0.32),
                        Color.white.opacity(0.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: size * 0.48, height: size * 0.26)
            .rotationEffect(.degrees(-32))
            .offset(x: -size * 0.18, y: -size * 0.20)
            .blur(radius: 1.5)
    }

    private var secondaryHighlight: some View {
        Ellipse()
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.0),
                        Color.white.opacity(0.20)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: size * 0.34, height: size * 0.14)
            .rotationEffect(.degrees(-30))
            .offset(x: size * 0.18, y: size * 0.24)
            .blur(radius: 2.5)
    }

    // MARK: - Apple HIG Liquid Glass Squircle Background
    private func squircleContainer(squircleSize: CGFloat, cornerRadius: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.12, green: 0.14, blue: 0.18),
                        Color(red: 0.05, green: 0.06, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Liquid Glass Inner Top Specular Sheen
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.14),
                                Color.white.opacity(0.02),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            )
            .overlay(
                // Apple HIG Specular Rim Stroke
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.32),
                                Color.white.opacity(0.08),
                                Color.white.opacity(0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: max(0.8, squircleSize * 0.009)
                    )
            )
            .frame(width: squircleSize, height: squircleSize)
    }
}

// MARK: - Fluid Acoustic Wave Shape
private struct FluidAcousticWave: Shape {
    var amplitude: CGFloat
    var frequency: CGFloat
    var phase: Double

    var animatableData: AnimatablePair<CGFloat, Double> {
        get { AnimatablePair(amplitude, phase) }
        set {
            amplitude = newValue.first
            phase = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        let width = rect.width

        path.move(to: CGPoint(x: 0, y: midY))

        let step: CGFloat = 2.0
        for x in stride(from: 0, through: width, by: step) {
            let relativeX = x / width
            // Windowing curve to taper waves smoothly toward the edges of the sphere
            let window = sin(relativeX * .pi)
            let y = midY + sin(relativeX * frequency * .pi * 2.0 + phase) * amplitude * window
            path.addLine(to: CGPoint(x: x, y: y))
        }

        path.addLine(to: CGPoint(x: width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()

        return path
    }
}
