import XCTest
import AVFoundation
@testable import Aura

final class VoiceStackTests: XCTestCase {

    func testWAVAudioEncoder_validBuffer_createsValidRIFFHeader() {
        guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 16000, channels: 1, interleaved: false),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 1600) else {
            XCTFail("Failed to allocate test AVAudioPCMBuffer")
            return
        }

        buffer.frameLength = 1600
        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<1600 {
                channelData[i] = Float(sin(Double(i) * 0.1))
            }
        }

        let wavData = WAVAudioEncoder.encode(buffers: [buffer], sampleRate: 16000)
        XCTAssertNotNil(wavData)
        guard let data = wavData else { return }

        // RIFF header must be 44 bytes + PCM data (1600 frames * 2 bytes = 3200 bytes) = 3244 bytes
        XCTAssertEqual(data.count, 44 + 3200)

        // Check RIFF magic bytes
        let riffHeader = String(data: data[0..<4], encoding: .ascii)
        XCTAssertEqual(riffHeader, "RIFF")

        let waveHeader = String(data: data[8..<12], encoding: .ascii)
        XCTAssertEqual(waveHeader, "WAVE")

        let fmtHeader = String(data: data[12..<16], encoding: .ascii)
        XCTAssertEqual(fmtHeader, "fmt ")

        let dataHeader = String(data: data[36..<40], encoding: .ascii)
        XCTAssertEqual(dataHeader, "data")
    }

    func testWAVAudioEncoder_emptyBuffers_returnsNil() {
        let result = WAVAudioEncoder.encode(buffers: [])
        XCTAssertNil(result)
    }

    func testVoiceDiscoveryService_emptyKey_throwsMissingApiKey() async {
        do {
            _ = try await VoiceDiscoveryService.shared.fetchElevenLabsVoices(apiKey: "")
            XCTFail("Expected missingApiKey error")
        } catch let error as VoiceDiscoveryError {
            switch error {
            case .missingApiKey(let provider):
                XCTAssertEqual(provider, "ElevenLabs")
            default:
                XCTFail("Unexpected error type: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testVoiceDiscoveryService_invalidKey_strictlyThrowsWithoutFallback() async {
        do {
            _ = try await VoiceDiscoveryService.shared.fetchElevenLabsVoices(apiKey: "invalid_key_12345")
            XCTFail("Expected invalidResponse error for bad API key")
        } catch let error as VoiceDiscoveryError {
            switch error {
            case .invalidResponse(let status, _):
                XCTAssertEqual(status, 401)
            default:
                break
            }
        } catch {
            // URLSession / network error is also acceptable
        }
    }

    func testSTTAndTTSProviderEnums_haveAllExpectedOptions() {
        XCTAssertEqual(STTProvider.allCases.count, 3)
        XCTAssertEqual(STTProvider.apple.rawValue, "apple")
        XCTAssertEqual(STTProvider.groq.rawValue, "groq")
        XCTAssertEqual(STTProvider.elevenlabs.rawValue, "elevenlabs")

        XCTAssertEqual(TTSProvider.allCases.count, 3)
        XCTAssertEqual(TTSProvider.apple.rawValue, "apple")
        XCTAssertEqual(TTSProvider.groq.rawValue, "groq")
        XCTAssertEqual(TTSProvider.elevenlabs.rawValue, "elevenlabs")
    }
}
