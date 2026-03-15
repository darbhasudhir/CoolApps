import SwiftUI

struct ContentView: View {
    @State private var pads: [PadModel] = (0..<24).map { i in
        // Distribute instrument types across the 24 pads
        let types: [InstrumentType] = [.drums, .drums, .drums, .drums,
                                       .bass, .bass, .bass, .bass,
                                       .synth, .synth, .synth, .synth,
                                       .vocal, .vocal, .vocal, .vocal,
                                       .fx, .fx, .fx, .fx,
                                       .drums, .bass, .synth, .vocal]
        return PadModel(id: i, instrument: types[i])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("128 BPM")
                        .font(.system(.title2, design: .monospaced, weight: .bold))
                        .foregroundColor(.green)
                    Text("Side A")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Button(action: {
                    // Toggle recording
                }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
            .padding()
            .background(Color(white: 0.1))
            
            // Main Grid
            ScrollView {
                GridView(pads: $pads)
            }
            .background(Color.black)
            
            // Footer (FX Bar)
            HStack(spacing: 20) {
                fxButton(title: "FILTER")
                fxButton(title: "REVERB")
                fxButton(title: "DELAY")
            }
            .padding()
            .background(Color(white: 0.1))
        }
        .preferredColorScheme(.dark)
    }
    
    private func fxButton(title: String) -> some View {
        Button(action: {
            // Toggle effect
        }) {
            Text(title)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
}
