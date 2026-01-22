import SwiftUI

struct PulseRipple: View {
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0.0
    
    var body: some View {
        Circle()
            .stroke(Color.white.opacity(0.3), lineWidth: 1)
            .scaleEffect(scale)
            .opacity(opacity)
            .onAppear {
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    scale = 2.0
                    opacity = 0.0
                }
                
                // Reset/Restart logic if needed, but repeatForever works for simple ripple
                // Actually to make it fade out properly we need a keyframe or custom timeline,
                // but for simple SwiftUI:
                // Start opaque max, scale min -> End transparent min, scale max
            }
            .onAppear {
                 // Hack for keyframe-ish behavior: 
                 // We want: Start at scale 0, opacity 0.5 -> End scale 2, opacity 0
            }
            // Let's use a simpler Phase Animator approach or just a recursive spring?
            // "Every few seconds" -> Delay
        
        ZStack {
            ForEach(0..<2) { i in
                RippleCircle(delay: Double(i) * 2.5)
            }
        }
    }
}

struct RippleCircle: View {
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [.white.opacity(0.1), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            )
            .scaleEffect(animate ? 4.0 : 0.1)
            .opacity(animate ? 0.0 : 0.4)
            .onAppear {
                // Initial delay
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    withAnimation(.easeOut(duration: 4.0).repeatForever(autoreverses: false)) {
                        animate = true
                    }
                }
            }
    }
}
