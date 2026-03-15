import SwiftUI

struct GridView: View {
    @Binding var pads: [PadModel]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach($pads) { $pad in
                PadView(pad: pad) {
                    pad.isActive.toggle()
                }
            }
        }
        .padding()
    }
}

#Preview {
    @State var mockPads = (0..<24).map { i in
        PadModel(id: i, instrument: InstrumentType.allCases[i % InstrumentType.allCases.count])
    }
    return GridView(pads: $mockPads)
        .background(Color.black)
}
