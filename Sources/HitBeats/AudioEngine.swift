import Foundation
import AVFoundation

class AudioEngine: ObservableObject {
    @Published var pads: [PadModel] = []
    
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    // Manage players for each pad
    private var players: [Int: AVAudioPlayerNode] = [:]
    
    init() {
        setupPads()
        setupEngine()
    }
    
    private func setupPads() {
        let types: [InstrumentType] = [.drums, .drums, .drums, .drums,
                                       .bass, .bass, .bass, .bass,
                                       .synth, .synth, .synth, .synth,
                                       .vocal, .vocal, .vocal, .vocal,
                                       .fx, .fx, .fx, .fx,
                                       .drums, .bass, .synth, .vocal]
        
        // Base frequencies for different instruments to sound somewhat musical
        let baseFrequencies: [InstrumentType: Double] = [
            .drums: 60.0,
            .bass: 110.0,
            .synth: 440.0,
            .vocal: 880.0,
            .fx: 1200.0
        ]
        
        pads = (0..<24).map { i in
            let type = types[i]
            let baseFreq = baseFrequencies[type] ?? 440.0
            // Increment frequency slightly for each pad within the same instrument group
            let frequency = baseFreq * pow(1.05946, Double(i % 4)) // Semi-tones
            return PadModel(id: i, instrument: type, frequency: frequency)
        }
    }
    
    private func setupEngine() {
        engine.attach(mixer)
        engine.connect(mixer, to: engine.outputNode, format: nil)
        
        // Setup a player and buffer for each pad
        for pad in pads {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: nil)
            players[pad.id] = player
            
            // Generate a continuous sine wave buffer for the pad's frequency
            if let buffer = generateSineWaveBuffer(frequency: pad.frequency, duration: 2.0) {
                // Schedule the buffer to loop infinitely
                player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            }
        }
        
        do {
            try engine.start()
        } catch {
            print("Failed to start AudioEngine: \(error.localizedDescription)")
        }
    }
    
    func togglePad(id: Int) {
        guard let index = pads.firstIndex(where: { $0.id == id }) else { return }
        
        pads[index].isActive.toggle()
        
        let isActive = pads[index].isActive
        if let player = players[id] {
            if isActive {
                player.play()
            } else {
                player.pause()
            }
        }
    }
    
    private func generateSineWaveBuffer(frequency: Double, duration: Double) -> AVAudioPCMBuffer? {
        // Output format might be missing sample rate occasionally if not started, so use a standard one
        let sampleRate: Double = 44100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return nil }
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let channels = Int(format.channelCount)
        for ch in 0..<channels {
            let samples = buffer.floatChannelData![ch]
            for i in 0..<Int(frameCount) {
                let time = Double(i) / sampleRate
                let value = Float(sin(2.0 * .pi * frequency * time))
                samples[i] = value * 0.1 // Volume scaling to avoid clipping when many play
            }
        }
        
        return buffer
    }
}
