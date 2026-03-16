import SwiftUI

struct PadView: View {
    let pad: PadModel
    let action: () -> Void
    
    @State private var isPulsing = false
    @State private var loopProgress: CGFloat = 0.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.6)) {
                action()
            }
        }) {
            ZStack {
                // 3D Base (The "thick" part of the rubber pad)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(white: 0.1))
                    .offset(y: pad.isActive ? 2 : 6)
                
                // Main Pad Surface
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: pad.isActive ? 
                                [pad.color.opacity(0.9), pad.color.opacity(0.6)] : 
                                [Color(white: 0.2), Color(white: 0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .offset(y: pad.isActive ? 2 : 0)
                    .shadow(color: pad.isActive ? pad.color.opacity(0.8) : .clear, radius: isPulsing ? 15 : 5, x: 0, y: isPulsing ? 0 : 0)
                
                // Top Highlight (Plastic reflection)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: pad.isActive ? [.white.opacity(0.8), .clear] : [Color(white: 0.4), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .offset(y: pad.isActive ? 2 : 0)
                
                // Loop Progress Ring (Only visible when active)
                if pad.isActive {
                    Circle()
                        .trim(from: 0, to: loopProgress)
                        .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                        .offset(y: 2)
                }
                
                // Icon
                Image(systemName: pad.iconName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(pad.isActive ? .white : pad.color.opacity(0.6))
                    .shadow(color: pad.isActive ? .white : .clear, radius: 5)
                    .offset(y: pad.isActive ? 2 : 0)
            }
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(pad.isActive ? 0.96 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: pad.isActive) { _, isActive in
            if isActive {
                // Pulse Animation
                withAnimation(.easeInOut(duration: pad.loopDuration / 4.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
                
                // Loop Sweep Animation
                loopProgress = 0.0
                withAnimation(.linear(duration: pad.loopDuration).repeatForever(autoreverses: false)) {
                    loopProgress = 1.0
                }
            } else {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPulsing = false
                    loopProgress = 0.0
                }
            }
        }
    }
}

#Preview {
    HStack {
        PadView(pad: PadModel(id: 1, instrument: .drums, side: .A, isActive: false)) {}
        PadView(pad: PadModel(id: 2, instrument: .drums, side: .A, isActive: true)) {}
    }
    .padding()
    .background(Color.black)
}
