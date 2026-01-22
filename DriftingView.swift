import SwiftUI

struct DriftingView<Content: View>: View {
    let content: Content
    let range: CGFloat
    
    @State private var offset: CGSize = .zero
    
    init(range: CGFloat = 10, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.range = range
    }
    
    var body: some View {
        content
            .offset(offset)
            .onAppear(perform: startDrifting)
    }
    
    private func startDrifting() {
        // Longer, varied durations to reduce concurrent animation load
        let duration = Double.random(in: 3...8)
        
        // Use easeInOut instead of spring for simpler calculation (more performant)
        withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
            offset = CGSize(
                width: CGFloat.random(in: -range...range), 
                height: CGFloat.random(in: -range...range)
            )
        }
    }
}
