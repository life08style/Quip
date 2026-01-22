import SwiftUI

struct BubbleView: View, Equatable {
    let activity: Activity
    var isSelected: Bool
    var currentUser: User?
    var depth: Double = 0.0 // Distance from camera
    var action: () -> Void
    
    // Animation States
    @State private var scale: CGFloat = 1.0
    @State private var innerGlowOpacity: Double = 0.0
    @State private var pulsePhase: Bool = false
    @State private var jitterOffset: CGSize = .zero
    @State private var orbitRotation: Double = 0.0 // For orbiting avatars
    @State private var isVisible: Bool = false // Track visibility for animation optimization
    @State private var lastTapTime: Date = .distantPast // Debouncing
    
    static func == (lhs: BubbleView, rhs: BubbleView) -> Bool {
        lhs.activity.id == rhs.activity.id && 
        lhs.isSelected == rhs.isSelected &&
        lhs.activity.interests.count == rhs.activity.interests.count &&
        lhs.currentUser?.id == rhs.currentUser?.id &&
        lhs.depth == rhs.depth
    }
    
    // ...
    
    // Dynamic Shadow based on depth
    // Closer (smaller depth) -> Larger, softer shadow
    // Farther (larger depth) -> Smaller, sharper shadow
    private var shadowRadius: CGFloat {
        let base = isSelected ? 25.0 : 15.0
        // Decay shadow as it gets further away
        return max(5.0, base - (depth / 100.0))
    }
    
    private var shadowOpacity: Double {
        let base = isSelected ? 0.6 : 0.3
        return max(0.1, base - (depth / 1000.0))
    }

    private var interestedUsers: [User] {
        activity.interests.compactMap { $0.user }
    }
    
    // Filter out "Me" from interested users for friend visualization
    private var friendsInterested: [User] {
        guard let currentId = currentUser?.id else { return interestedUsers }
        return interestedUsers.filter { $0.id != currentId }
    }
    
    private var popularity: Int {
        activity.interests.count
    }
    
    // The "Wash" color - user's color if selected, otherwise activity default
    var displayColor: Color {
        if isSelected, let user = currentUser {
            return Color(hex: user.avatarColor)
        }
        return Color(hex: activity.color)
    }
    
    var body: some View {
        Button(action: handleTap) {
            ZStack {
                // 1. Friend Interest Rings
                if !friendsInterested.isEmpty {
                    BubbleInterestRings(friends: friendsInterested)
                }
                
                // 2. Pulse Glow (Outer) - Only animate when visible
                if isSelected && isVisible {
                    BubblePulseGlow(color: displayColor, phase: pulsePhase)
                }
                
                // 3. Main Bubble Surface
                BubbleBackground(displayColor: displayColor, isSelected: isSelected, shadowOpacity: shadowOpacity, shadowRadius: shadowRadius)
                
                // 4. Icon & Text
                BubbleContent(icon: activity.icon, name: activity.name)
                
                // 5. Avatar Stacking (4 o'clock position)
                if !interestedUsers.isEmpty {
                    BubbleAvatarStack(users: interestedUsers)
                }
            }
            .frame(width: 80, height: 80)
            .scaleEffect(scale)
            .offset(jitterOffset) // Multiplier Effect (Vibration)
            .onChange(of: popularity) { _, newValue in
                if newValue > 1 {
                    triggerVibration()
                }
            }
            .onAppear {
                isVisible = true
                if isSelected {
                    startPulseAnimation()
                }
            }
            .onDisappear {
                isVisible = false
                resetAnimationStates()
            }
            .onChange(of: isSelected) { _, newValue in
                if newValue && isVisible {
                    startPulseAnimation()
                } else {
                    pulsePhase = false
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func handleTap() {
        // Debounce rapid taps
        let now = Date()
        guard now.timeIntervalSince(lastTapTime) > 0.2 else { return }
        lastTapTime = now
        
        // Haptic Feedback
        HapticManager.shared.playImpact(style: .medium)
        
        // Scale Animation Sequence using keyframes
        withAnimation(.easeIn(duration: 0.1)) {
            scale = 0.95
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                scale = 1.05
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    scale = 1.0
                }
            }
        }
        
        action()
    }
    private func triggerVibration() {
        // "Growing Heat" - simplified vibration with single animation
        let intensity = CGFloat(min(Double(popularity), 5.0))
        
        // Use spring animation for natural vibration effect
        withAnimation(.interpolatingSpring(stiffness: 300, damping: 5).repeatCount(3, autoreverses: true)) {
            jitterOffset = CGSize(width: intensity, height: 0)
        }
        
        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation {
                jitterOffset = .zero
            }
        }
    }
    
    private func startPulseAnimation() {
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulsePhase = true
        }
    }
    
    private func resetAnimationStates() {
        pulsePhase = false
        scale = 1.0
        jitterOffset = .zero
    }
}

// MARK: - Subviews for Optimization

struct BubbleInterestRings: View {
    let friends: [User]
    
    var body: some View {
        ZStack {
            ForEach(Array(friends.enumerated()), id: \.element.id) { index, friend in
                Circle()
                    .stroke(Color(hex: friend.avatarColor), lineWidth: 2)
                    .padding(-Double(index + 1) * 3) // Expand outwards
                    .opacity(0.8)
            }
        }
    }
}

struct BubblePulseGlow: View {
    let color: Color
    let phase: Bool
    
    var body: some View {
        Circle()
            .fill(color)
            .blur(radius: 15)
            .scaleEffect(phase ? 1.3 : 1.1)
            .opacity(phase ? 0.6 : 0.3)
    }
}

struct BubbleBackground: View {
    let displayColor: Color
    let isSelected: Bool
    let shadowOpacity: Double
    let shadowRadius: CGFloat
    
    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        displayColor.opacity(isSelected ? 0.9 : 0.4),
                        displayColor.opacity(0.1)
                    ],
                    center: .center,
                    startRadius: 5,
                    endRadius: 80
                )
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .background(
                Circle().fill(.ultraThinMaterial).opacity(0.5)
            )
            .shadow(color: displayColor.opacity(shadowOpacity), radius: shadowRadius)
            .drawingGroup() // Enable GPU rendering
    }
}

struct BubbleContent: View {
    let icon: String
    let name: String
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
            
            Text(name)
                .font(.system(size: 10, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 2)
                .frame(maxWidth: 80)
        }
    }
}

struct BubbleAvatarStack: View {
    let users: [User]
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(users.enumerated()), id: \.element.id) { index, user in
                Circle()
                    .fill(Color(hex: user.avatarColor))
                    .frame(width: 15, height: 15)
                    .overlay(Circle().stroke(Color.white, lineWidth: 1))
                    .shadow(radius: 2)
            }
        }
    }
    

}

// Hex Color Utility (kept from original)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
