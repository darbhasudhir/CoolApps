import SwiftUI

enum InstrumentType: String, CaseIterable {
    case drums
    case bass
    case synth
    case vocal
    case fx
    
    var color: Color {
        switch self {
        case .drums: return .cyan
        case .bass: return .green
        case .synth: return .pink
        case .vocal: return .purple
        case .fx: return .orange
        }
    }
    
    var iconName: String {
        switch self {
        case .drums: return "music.mic"
        case .bass: return "guitars"
        case .synth: return "waveform.path.ecg"
        case .vocal: return "waveform"
        case .fx: return "sparkles"
        }
    }
}

struct SoundPack: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let bpm: Double
    let baseFrequencies: [InstrumentType: Double]
    let description: String
    
    static let edmAnthem = SoundPack(
        name: "EDM Anthem",
        bpm: 128.0,
        baseFrequencies: [.drums: 60.0, .bass: 55.0, .synth: 220.0, .vocal: 440.0, .fx: 880.0],
        description: "High energy, four-on-the-floor festival vibes."
    )
    
    static let lofiChill = SoundPack(
        name: "Lo-Fi Chill",
        bpm: 85.0,
        baseFrequencies: [.drums: 45.0, .bass: 40.0, .synth: 150.0, .vocal: 300.0, .fx: 600.0],
        description: "Relaxed tempos and dusty vinyl textures."
    )
    
    static let trapHouse = SoundPack(
        name: "Trap House",
        bpm: 140.0,
        baseFrequencies: [.drums: 50.0, .bass: 35.0, .synth: 180.0, .vocal: 350.0, .fx: 700.0],
        description: "Heavy 808s and fast hi-hat rolls."
    )
    
    static let popAnthem = SoundPack(
        name: "Pop",
        bpm: 115.0,
        baseFrequencies: [.drums: 55.0, .bass: 65.0, .synth: 261.6, .vocal: 329.6, .fx: 523.2],
        description: "Catchy melodies and upbeat rhythms."
    )
    
    static let allPacks = [edmAnthem, lofiChill, trapHouse, popAnthem]
}

struct PadModel: Identifiable {
    let id: Int
    let instrument: InstrumentType
    var isActive: Bool = false
    var frequency: Double = 440.0
    
    var color: Color {
        instrument.color
    }
    
    var iconName: String {
        instrument.iconName
    }
}
