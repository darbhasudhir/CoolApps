import SwiftUI

struct ContentView: View {
    @StateObject private var audioEngine = AudioEngine()
    
    var body: some View {
        ZStack {
            // Club Background
            RadialGradient(
                gradient: Gradient(colors: [Color(white: 0.15), Color.black]),
                center: .center,
                startRadius: 50,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header & Pack Selector
                VStack(spacing: 15) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("\(Int(audioEngine.currentPack.bpm)) BPM")
                                .font(.system(.title2, design: .monospaced, weight: .black))
                                .foregroundColor(.cyan)
                                .shadow(color: .cyan.opacity(0.5), radius: 5)
                            Text("SYNC LOCKED")
                                .font(.caption2.bold())
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            // Toggle recording
                        }) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 35, height: 35)
                                .overlay(Circle().stroke(Color.white.opacity(0.5), lineWidth: 2))
                                .shadow(color: .red.opacity(0.8), radius: 10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Sound Pack Selector
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            ForEach(SoundPack.allPacks) { pack in
                                Button(action: {
                                    withAnimation {
                                        audioEngine.loadPack(pack)
                                    }
                                }) {
                                    Text(pack.name)
                                        .font(.subheadline.bold())
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(
                                            Capsule()
                                                .fill(audioEngine.currentPack == pack ? Color.cyan.opacity(0.2) : Color.white.opacity(0.05))
                                        )
                                        .overlay(
                                            Capsule()
                                                .stroke(audioEngine.currentPack == pack ? Color.cyan : Color.white.opacity(0.1), lineWidth: 1.5)
                                        )
                                        .foregroundColor(audioEngine.currentPack == pack ? .cyan : .gray)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 15)
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .background(.ultraThinMaterial)
                )
                
                // Main Grid
                ScrollView {
                    GridView(audioEngine: audioEngine)
                        .padding(.top, 10)
                }
                
                // Footer (FX Bar)
                HStack(spacing: 15) {
                    fxButton(title: "FILTER", isActive: audioEngine.isFilterActive, color: .purple) { audioEngine.toggleFilter() }
                    fxButton(title: "REVERB", isActive: audioEngine.isReverbActive, color: .cyan) { audioEngine.toggleReverb() }
                    fxButton(title: "DELAY", isActive: audioEngine.isDelayActive, color: .pink) { audioEngine.toggleDelay() }
                }
                .padding()
                .background(
                    Rectangle()
                        .fill(Color.black.opacity(0.6))
                        .background(.ultraThinMaterial)
                )
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func fxButton(title: String, isActive: Bool, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isActive ? color.opacity(0.3) : Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(isActive ? color : Color.white.opacity(0.1), lineWidth: 2)
                )
                .foregroundColor(isActive ? .white : .gray)
                .shadow(color: isActive ? color.opacity(0.5) : .clear, radius: 8)
        }
    }
}

#Preview {
    ContentView()
}
