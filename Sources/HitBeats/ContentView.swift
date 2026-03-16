import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    
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
                GridView(audioEngine: audioEngine)
            }
            .background(Color.black)
            
            // Footer (FX Bar)
            HStack(spacing: 20) {
                fxButton(title: "FILTER", isActive: audioEngine.isFilterActive) { audioEngine.toggleFilter() }
                fxButton(title: "REVERB", isActive: audioEngine.isReverbActive) { audioEngine.toggleReverb() }
                fxButton(title: "DELAY", isActive: audioEngine.isDelayActive) { audioEngine.toggleDelay() }
            }
            .padding()
            .background(Color(white: 0.1))
        }
        .preferredColorScheme(.dark)
    }
    
    private func fxButton(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isActive ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
}

#Preview {
    ContentView()
}
