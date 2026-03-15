import SwiftUI

struct PadView: View {
    let pad: PadModel
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                action()
            }
        }) {
            RoundedRectangle(cornerRadius: 12)
                .fill(pad.isActive ? pad.color : pad.color.opacity(0.3))
                .shadow(color: pad.isActive ? pad.color : .clear, radius: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(pad.isActive ? 0.8 : 0.2), lineWidth: 2)
                )
                .aspectRatio(1, contentMode: .fit)
        }
        .buttonStyle(.plain)
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
