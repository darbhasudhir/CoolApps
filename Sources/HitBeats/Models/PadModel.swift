import SwiftUI

enum InstrumentType: String, CaseIterable {
    case drums
    case bass
    case synth
    case vocal
    case fx
    
    var color: Color {
        switch self {
        case .drums: return .blue
        case .bass: return .green
        case .synth: return .yellow
        case .vocal: return .purple
        case .fx: return .orange
        }
    }
}

struct PadModel: Identifiable {
    let id: Int
    let instrument: InstrumentType
    var isActive: Bool = false
    
    var color: Color {
        instrument.color
    }
}
