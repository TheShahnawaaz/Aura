import AVFoundation
import Foundation

/// Lightweight, high-performance WAV audio encoder for packaging CoreAudio PCM buffers
/// into standard 16-bit 16kHz Mono RIFF WAV byte payloads for cloud STT endpoints (Groq Whisper, ElevenLabs Scribe).
public enum WAVAudioEncoder {

    /// Encodes an array of 16kHz mono AVAudioPCMBuffer instances into a valid 16-bit linear PCM WAV Data payload.
    public static func encode(buffers: [AVAudioPCMBuffer], sampleRate: Double = 16000) -> Data? {
        guard !buffers.isEmpty else { return nil }

        var totalFrames: Int = 0
        for buf in buffers {
            totalFrames += Int(buf.frameLength)
        }
        guard totalFrames > 0 else { return nil }

        let bytesPerSample = 2 // 16-bit PCM
        let numChannels = 1
        let pcmDataSize = totalFrames * numChannels * bytesPerSample

        var wavData = Data(capacity: 44 + pcmDataSize)

        // 1. RIFF Chunk Header
        wavData.append(contentsOf: [UInt8]("RIFF".utf8))
        let chunkSize = UInt32(36 + pcmDataSize)
        withUnsafeBytes(of: chunkSize.littleEndian) { wavData.append(contentsOf: $0) }
        wavData.append(contentsOf: [UInt8]("WAVE".utf8))

        // 2. fmt Subchunk
        wavData.append(contentsOf: [UInt8]("fmt ".utf8))
        let subchunk1Size = UInt32(16)
        withUnsafeBytes(of: subchunk1Size.littleEndian) { wavData.append(contentsOf: $0) }
        let audioFormat = UInt16(1) // PCM
        withUnsafeBytes(of: audioFormat.littleEndian) { wavData.append(contentsOf: $0) }
        let channels = UInt16(numChannels)
        withUnsafeBytes(of: channels.littleEndian) { wavData.append(contentsOf: $0) }
        let sampleRateU32 = UInt32(sampleRate)
        withUnsafeBytes(of: sampleRateU32.littleEndian) { wavData.append(contentsOf: $0) }
        let byteRate = UInt32(sampleRate * Double(numChannels * bytesPerSample))
        withUnsafeBytes(of: byteRate.littleEndian) { wavData.append(contentsOf: $0) }
        let blockAlign = UInt16(numChannels * bytesPerSample)
        withUnsafeBytes(of: blockAlign.littleEndian) { wavData.append(contentsOf: $0) }
        let bitsPerSample = UInt16(16)
        withUnsafeBytes(of: bitsPerSample.littleEndian) { wavData.append(contentsOf: $0) }

        // 3. data Subchunk
        wavData.append(contentsOf: [UInt8]("data".utf8))
        let subchunk2Size = UInt32(pcmDataSize)
        withUnsafeBytes(of: subchunk2Size.littleEndian) { wavData.append(contentsOf: $0) }

        // 4. Sample Conversion (Float32 [-1.0, 1.0] -> Int16 [-32768, 32767])
        for buf in buffers {
            guard let channelData = buf.floatChannelData?[0] else { continue }
            let frameCount = Int(buf.frameLength)

            for i in 0..<frameCount {
                let floatSample = channelData[i]
                let clamped = max(-1.0, min(1.0, floatSample))
                let int16Sample = Int16(clamped * 32767.0)
                withUnsafeBytes(of: int16Sample.littleEndian) { wavData.append(contentsOf: $0) }
            }
        }

        return wavData
    }
}
