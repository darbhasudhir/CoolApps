import SwiftUI

struct GridView: View {
    @ObservedObject var audioEngine: AudioEngine
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(audioEngine.pads) { pad in
                PadView(pad: pad) {
                    audioEngine.togglePad(id: pad.id)
                }
            }
        }
        .padding()
    }
}

#Preview {
    GridView(audioEngine: AudioEngine())
        .background(Color.black)
}
