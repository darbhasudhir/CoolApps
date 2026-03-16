import Foundation
import AVFoundation

class AudioEngine: ObservableObject {
    @Published var pads: [PadModel] = []
    
    // DJ FX States
    @Published var isFilterActive = false {
        didSet {
            filterNode.bypass = !isFilterActive
        }
    }
    @Published var isReverbActive = false {
        didSet {
            reverbNode.wetDryMix = isReverbActive ? 50 : 0
        }
    }
    @Published var isDelayActive = false {
        didSet {
            delayNode.wetDryMix = isDelayActive ? 40 : 0
        }
    }
    
    private let engine = AVAudioEngine()
    private let mixer = AVAudioMixerNode()
    
    // DJ FX Nodes
    private let filterNode = AVAudioUnitEQ(numberOfBands: 1)
    private let reverbNode = AVAudioUnitReverb()
    private let delayNode = AVAudioUnitDelay()
    
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
        
        // Base frequencies
        let baseFrequencies: [InstrumentType: Double] = [
            .drums: 60.0,
            .bass: 55.0,
            .synth: 220.0,
            .vocal: 440.0,
            .fx: 880.0
        ]
        
        pads = (0..<24).map { i in
            let type = types[i]
            let baseFreq = baseFrequencies[type] ?? 440.0
            // Increment frequency musically (pentatonic scale approx for better sounding mashups)
            let multipliers = [1.0, 1.122, 1.259, 1.498, 1.681]
            let freq = baseFreq * multipliers[i % multipliers.count]
            return PadModel(id: i, instrument: type, frequency: freq)
        }
    }
    
    private func setupEngine() {
        // Setup FX Nodes
        let band = filterNode.bands[0]
        band.filterType = .lowPass
        band.frequency = 800.0 // Cut high frequencies when active
        filterNode.bypass = true
        
        reverbNode.loadFactoryPreset(.largeHall)
        reverbNode.wetDryMix = 0
        
        delayNode.delayTime = 60.0 / 128.0 // 1 beat delay at 128 BPM
        delayNode.feedback = 40.0
        delayNode.wetDryMix = 0
        
        // Attach all nodes
        engine.attach(mixer)
        engine.attach(filterNode)
        engine.attach(reverbNode)
        engine.attach(delayNode)
        
        // Connect the chain: Mixer -> Filter -> Delay -> Reverb -> Output
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(mixer, to: filterNode, format: format)
        engine.connect(filterNode, to: delayNode, format: format)
        engine.connect(delayNode, to: reverbNode, format: format)
        engine.connect(reverbNode, to: engine.outputNode, format: format)
        
        // Setup a player and buffer for each pad
        for pad in pads {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            
            // Generate a rhythmic 1-beat buffer for the pad's frequency
            if let buffer = generateRhythmicBuffer(frequency: pad.frequency, type: pad.instrument, format: format) {
                // Connect the player to the mixer
                engine.connect(player, to: mixer, format: buffer.format)
                players[pad.id] = player
                
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
    
    // Toggle FX Helpers
    func toggleFilter() { isFilterActive.toggle() }
    func toggleReverb() { isReverbActive.toggle() }
    func toggleDelay() { isDelayActive.toggle() }
    
    private func generateRhythmicBuffer(frequency: Double, type: InstrumentType, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44100.0
        let channelCount = format.channelCount > 0 ? format.channelCount : 2
        
        guard let finalFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount) else { return nil }
        
        // 128 BPM -> exactly 0.46875 seconds per beat
        let bpm = 128.0
        let beatDuration = 60.0 / bpm
        let frameCount = AVAudioFrameCount(sampleRate * beatDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: finalFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let channels = Int(finalFormat.channelCount)
        for ch in 0..<channels {
            guard let samples = buffer.floatChannelData?[ch] else { continue }
            for i in 0..<Int(frameCount) {
                let time = Double(i) / sampleRate
                var value: Float = 0.0
                
                // Fast decay envelope for rhythmic feel
                let envelope = Float(exp(-4.0 * time / beatDuration))
                
                switch type {
                case .drums:
                    // Kick drum: rapid pitch drop
                    let pitchDrop = exp(-15.0 * time)
                    value = Float(sin(2.0 * .pi * (frequency * pitchDrop) * time)) * Float(exp(-10.0 * time / beatDuration)) * 0.9
                case .bass:
                    // Sawtooth wave approximation
                    let period = 1.0 / frequency
                    let phase = fmod(time, period) / period
                    let saw = Float(2.0 * phase - 1.0)
                    value = saw * envelope * 0.5
                case .synth:
                    // Square wave approximation
                    let period = 1.0 / frequency
                    let phase = fmod(time, period) / period
                    let square = phase < 0.5 ? Float(1.0) : Float(-1.0)
                    // Add some simple modulation
                    let lfo = Float(sin(2.0 * .pi * 4.0 * time)) * 0.5 + 0.5
                    value = square * envelope * lfo * 0.2
                case .vocal, .fx:
                    // Shimmering sine
                    let tone = Float(sin(2.0 * .pi * frequency * time))
                    let tremolo = Float(sin(2.0 * .pi * 8.0 * time)) * 0.5 + 0.5
                    let slowEnv = Float(exp(-2.0 * time / beatDuration))
                    value = tone * slowEnv * tremolo * 0.3
                }
                
                samples[i] = value
            }
        }
        
        return buffer
    }
}
