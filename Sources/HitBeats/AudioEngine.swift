import Foundation
import AVFoundation

class AudioEngine: ObservableObject {
    @Published var allPads: [PadModel] = []
    @Published var currentSide: PadSide = .A
    @Published var currentPack: SoundPack = .edmAnthem
    
    var pads: [PadModel] {
        allPads.filter { $0.side == currentSide }
    }
    
    // DJ FX States
    @Published var isFilterActive = false {
        didSet { filterNode.bypass = !isFilterActive }
    }
    @Published var isReverbActive = false {
        didSet { reverbNode.wetDryMix = isReverbActive ? 60 : 0 }
    }
    @Published var isDelayActive = false {
        didSet { delayNode.wetDryMix = isDelayActive ? 50 : 0 }
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
        setupEngine()
        loadPack(.edmAnthem)
    }
    
    func toggleSide() {
        currentSide = currentSide == .A ? .B : .A
    }
    
    func loadPack(_ pack: SoundPack) {
        for player in players.values {
            player.stop()
        }
        
        currentPack = pack
        delayNode.delayTime = 60.0 / pack.bpm
        
        setupPads(with: pack)
        setupPlayers()
    }
    
    private func setupPads(with pack: SoundPack) {
        let types: [InstrumentType] = [.drums, .drums, .drums, .drums,
                                       .bass, .bass, .bass, .bass,
                                       .synth, .synth, .synth, .synth,
                                       .vocal, .vocal, .vocal, .vocal,
                                       .fx, .fx, .fx, .fx,
                                       .drums, .bass, .synth, .vocal]
        
        var newPads: [PadModel] = []
        let beatDuration = 60.0 / pack.bpm
        
        // Generate Side A
        for i in 0..<24 {
            let type = types[i]
            let baseFreq = pack.baseFrequencies[type] ?? 440.0
            let multipliers = [1.0, 1.122, 1.259, 1.498, 1.681]
            let freq = baseFreq * multipliers[i % multipliers.count]
            newPads.append(PadModel(id: i, instrument: type, side: .A, frequency: freq, loopDuration: beatDuration * 4)) // 4 beat loops
        }
        
        // Generate Side B (slightly different frequencies/pitch shifted up a 4th)
        for i in 0..<24 {
            let type = types[i]
            let baseFreq = (pack.baseFrequencies[type] ?? 440.0) * 1.334 // up a perfect fourth
            let multipliers = [1.0, 1.122, 1.259, 1.498, 1.681]
            let freq = baseFreq * multipliers[i % multipliers.count]
            newPads.append(PadModel(id: i + 24, instrument: type, side: .B, frequency: freq, loopDuration: beatDuration * 4))
        }
        
        allPads = newPads
    }
    
    private func setupPlayers() {
        let format = engine.outputNode.inputFormat(forBus: 0)
        
        for pad in allPads {
            let player = players[pad.id] ?? AVAudioPlayerNode()
            if players[pad.id] == nil {
                engine.attach(player)
                players[pad.id] = player
            } else {
                engine.disconnectNodeInput(player)
            }
            
            // Generate a 4-beat loop buffer
            if let buffer = generateComplexBuffer(pad: pad, format: format, bpm: currentPack.bpm) {
                engine.connect(player, to: mixer, format: buffer.format)
                player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            }
        }
    }
    
    private func setupEngine() {
        let band = filterNode.bands[0]
        band.filterType = .lowPass
        band.frequency = 600.0
        filterNode.bypass = true
        
        reverbNode.loadFactoryPreset(.largeHall)
        reverbNode.wetDryMix = 0
        
        delayNode.feedback = 50.0
        delayNode.wetDryMix = 0
        
        engine.attach(mixer)
        engine.attach(filterNode)
        engine.attach(reverbNode)
        engine.attach(delayNode)
        
        let format = engine.outputNode.inputFormat(forBus: 0)
        engine.connect(mixer, to: filterNode, format: format)
        engine.connect(filterNode, to: delayNode, format: format)
        engine.connect(delayNode, to: reverbNode, format: format)
        engine.connect(reverbNode, to: engine.outputNode, format: format)
        
        do {
            try engine.start()
        } catch {
            print("Failed to start AudioEngine: \(error.localizedDescription)")
        }
    }
    
    func togglePad(id: Int) {
        guard let index = allPads.firstIndex(where: { $0.id == id }) else { return }
        
        allPads[index].isActive.toggle()
        
        let isActive = allPads[index].isActive
        if let player = players[id] {
            if isActive {
                // To keep everything perfectly in sync, we could use scheduleBuffer with hostTime, 
                // but for a quick prototype, standard play() works okay.
                player.play()
            } else {
                player.pause()
            }
        }
    }
    
    func toggleFilter() { isFilterActive.toggle() }
    func toggleReverb() { isReverbActive.toggle() }
    func toggleDelay() { isDelayActive.toggle() }
    
    // Improved Audio Synthesis Engine
    private func generateComplexBuffer(pad: PadModel, format: AVAudioFormat, bpm: Double) -> AVAudioPCMBuffer? {
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44100.0
        let channelCount = format.channelCount > 0 ? format.channelCount : 2
        
        guard let finalFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: channelCount) else { return nil }
        
        let beatDuration = 60.0 / bpm
        let loopDuration = beatDuration * 4 // 4 beats per loop
        let frameCount = AVAudioFrameCount(sampleRate * loopDuration)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: finalFormat, frameCapacity: frameCount) else { return nil }
        buffer.frameLength = frameCount
        
        let channels = Int(finalFormat.channelCount)
        let f = pad.frequency
        
        for ch in 0..<channels {
            guard let samples = buffer.floatChannelData?[ch] else { continue }
            for i in 0..<Int(frameCount) {
                let time = Double(i) / sampleRate
                let beatTime = fmod(time, beatDuration) // time within the current beat
                let measureTime = time / loopDuration // 0.0 to 1.0 progression of the 4-beat loop
                
                var value: Float = 0.0
                
                switch pad.instrument {
                case .drums:
                    // Synthesize Kick + Hi-Hat pattern
                    // Kick on the downbeat (0 and 0.5 of beatDuration)
                    let kickEnv = Float(exp(-10.0 * beatTime))
                    let kickPitchDrop = exp(-20.0 * beatTime)
                    let kick = Float(sin(2.0 * .pi * (60.0 * kickPitchDrop) * beatTime)) * kickEnv * 1.2
                    
                    // HiHat on the offbeat (0.25 and 0.75)
                    let offBeatTime = fmod(time + (beatDuration/2.0), beatDuration)
                    let hatEnv = Float(exp(-30.0 * offBeatTime))
                    let noise = Float.random(in: -1...1)
                    let hat = noise * hatEnv * 0.4
                    
                    value = kick + hat
                    
                case .bass:
                    // FM Synthesis Wobble Bass
                    let lfo = sin(2.0 * .pi * (bpm/60.0) * time) // wobble linked to bpm
                    let modulator = sin(2.0 * .pi * (f * 2.0) * time) * (2.0 + lfo)
                    let carrier = sin(2.0 * .pi * f * time + modulator)
                    let envelope = Float(exp(-2.0 * beatTime)) // Pump every beat
                    value = Float(carrier) * envelope * 0.6
                    
                case .synth:
                    // Layered SuperSaw Chords (Root, Major 3rd, Perfect 5th)
                    let f3 = f * 1.2599
                    let f5 = f * 1.4983
                    
                    func saw(_ freq: Double, _ t: Double) -> Double {
                        let p = 1.0 / freq
                        return 2.0 * (fmod(t, p) / p) - 1.0
                    }
                    
                    let root = saw(f, time)
                    let third = saw(f3, time)
                    let fifth = saw(f5, time)
                    
                    // Arpeggiator effect based on measureTime
                    let arpEnv = Float(exp(-8.0 * fmod(time, beatDuration / 4.0))) // 16th notes
                    value = Float(root + third + fifth) * 0.15 * arpEnv
                    
                case .vocal, .fx:
                    // Sweeping, ethereal textures
                    let slowLfo = sin(2.0 * .pi * 0.1 * time)
                    let tone = sin(2.0 * .pi * (f + slowLfo * 10.0) * time)
                    let shimmer = sin(2.0 * .pi * (f * 4.0) * time) * 0.3
                    
                    // Volume swells
                    let swell = (sin(2.0 * .pi * (bpm/120.0) * time) + 1.0) / 2.0
                    value = Float(tone + shimmer) * Float(swell) * 0.4
                }
                
                // Soft clipping to prevent distortion
                value = max(-1.0, min(1.0, value))
                samples[i] = value
            }
        }
        
        return buffer
    }
}
