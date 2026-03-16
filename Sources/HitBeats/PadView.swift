import SwiftUI

struct PadView: View {
    let pad: PadModel
    let action: () -> Void
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                action()
            }
        }) {
            ZStack {
                // Background Gradient
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: pad.isActive ? 
                                [pad.color.opacity(0.8), pad.color] : 
                                [Color(white: 0.15), Color(white: 0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: pad.isActive ? pad.color.opacity(0.8) : .clear, radius: isPulsing ? 20 : 8, x: 0, y: isPulsing ? 5 : 0)
                
                // Inner Border
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: pad.isActive ? [.white, pad.color.opacity(0.5)] : [Color(white: 0.3), Color(white: 0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                
                // Icon
                Image(systemName: pad.iconName)
                    .font(.system(size: 28, weight: .light))
                    .foregroundColor(pad.isActive ? .white : pad.color.opacity(0.6))
                    .shadow(color: pad.isActive ? .white : .clear, radius: 5)
            }
            .aspectRatio(1, contentMode: .fit)
            .scaleEffect(isPulsing ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .onChange(of: pad.isActive) { _, isActive in
            if isActive {
                withAnimation(.easeInOut(duration: 60.0 / 128.0 / 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            } else {
                withAnimation(.easeOut(duration: 0.2)) {
                    isPulsing = false
                }
            }
        }
    }
}

#Preview {
    HStack {
        PadView(pad: PadModel(id: 1, instrument: .drums, isActive: false)) {}
        PadView(pad: PadModel(id: 2, instrument: .drums, isActive: true)) {}
    }
    .padding()
    .background(Color.black)
}
