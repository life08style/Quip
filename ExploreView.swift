import SwiftUI
import SwiftData

struct ExploreView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(ActivityManager.self) private var activityManager
    
    @Query private var activities: [Activity]
    
    // Z-Space Camera State
    @State private var cameraZ: Double = 0.0
    @State private var dragTranslation: CGFloat = 0.0
    @State private var simulatedUser: User? // The user we are "acting" as
    
    // Motion Manager for Parallax
    @State private var motionManager = MotionManager()
    
    // Cached visible activities to prevent recalculation on every render
    @State private var cachedVisibleActivities: [Activity] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Vapor Map Background
                VaporMapBackground()
                    // Apply inverse parallax to map for "Look-down" effect (deeper layer moves slower/differently)
                    .offset(x: motionManager.roll * 10, y: motionManager.pitch * 10)
                    .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: motionManager.roll)
                    .animation(.interactiveSpring(response: 0.2, dampingFraction: 0.8), value: motionManager.pitch)
                    .overlay(
                        // "The Pulse" Ripple
                        PulseRipple()
                    )
                
                // 3D Activity Cloud
                GeometryReader { geometry in
                    let centerX = geometry.size.width / 2
                    let centerY = geometry.size.height / 2
                    
                    ZStack {
                        // Apply parallax to parent ZStack instead of individual bubbles
                        ForEach(cachedVisibleActivities.sorted(by: { $0.z > $1.z }), id: \.id) { activity in
                            ActivityBubble(
                                activity: activity,
                                cameraZ: cameraZ,
                                centerX: centerX,
                                centerY: centerY,
                                currentUser: activityManager.currentUser,
                                toggleAction: { toggleInterest(for: activity) }
                            )
                        }
                    }
                    .offset(x: -motionManager.roll * 50, y: -motionManager.pitch * 50)
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let delta = value.translation.height - dragTranslation
                            cameraZ -= Double(delta) * 5
                            dragTranslation = value.translation.height
                        }
                        .onEnded { _ in
                            dragTranslation = 0
                        }
                )
                
                // UI Overlays
                VStack {
                    // Header
                    HStack(alignment: .top) {
                        VStack(alignment: .leading) {
                            Text("Quip")
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .shadow(color: .purple, radius: 10)
                            
                            Text("Exploring the Void")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        // User Profile with nil safety
                        if let user = activityManager.currentUser {
                            Circle()
                                .fill(Color(hex: user.avatarColor))
                                .frame(width: 50, height: 50)
                                .overlay(Text(user.name.prefix(1)).foregroundStyle(.white).fontWeight(.bold))
                                .shadow(radius: 5)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        }
                    }
                    .padding()
                    .background(
                        // Indicator that we are Simulating
                        Group {
                            if let sim = simulatedUser {
                                Rectangle()
                                    .fill(Color(hex: sim.avatarColor).opacity(0.2))
                                    .edgesIgnoringSafeArea(.top)
                                    .overlay(alignment: .bottom) {
                                        Text("Simulating: \(sim.name)")
                                            .font(.caption)
                                            .padding(4)
                                            .background(.black.opacity(0.6))
                                            .cornerRadius(4)
                                    }
                            }
                        }
                    )
                    
                    Spacer()
                    
                    // Empty state message
                    if cachedVisibleActivities.isEmpty {
                        Text("No activities nearby")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding()
                    }
                    
                    Text("Drag to Fly")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.bottom, 5)
                    
                    SimulationPanel(manager: activityManager, selectedSimulant: $simulatedUser)
                        .padding()
                }
            }
            .navigationTitle("Quip")
            .navigationBarHidden(true)
            .onAppear {
                updateVisibleActivities(force: true)
            }
            .onChange(of: cameraZ) { _, _ in
                updateVisibleActivities()
            }
            .onChange(of: activities.count) { _, _ in
                updateVisibleActivities(force: true)
            }
            .onDisappear {
                // Reset simulation state to prevent leaks
                simulatedUser = nil
            }
        }
    }
    
    // Optimization State
    @State private var lastFilterCameraZ: Double = -10000
    
    // Update cached visible activities only when camera moves significantly or activities change
    private func updateVisibleActivities(force: Bool = false) {
        // Buffer range: Re-calculate only if camera moved more than 500 units
        // or if forced (e.g. data changed)
        guard force || abs(cameraZ - lastFilterCameraZ) > 500 else { return }
        
        lastFilterCameraZ = cameraZ
        
        // Fetch with a generous buffer so we don't have to update frequently
        // Visible range is approx 10...3000. We fetch -500...4000 relative to camera.
        cachedVisibleActivities = activities.filter { activity in
            let relativeZ = activity.z - cameraZ
            return relativeZ > -500 && relativeZ < 4000
        }
    }
    
    private func toggleInterest(for activity: Activity) {
        // If Simulating, toggle for that friend
        if let simUser = simulatedUser {
            activityManager.simulateFriendInterest(friend: simUser, activity: activity, context: modelContext)
            return
        }
        
        // Otherwise normal "Me" toggle
        guard let user = activityManager.currentUser else {
            print("⚠️ No current user available")
            return
        }
        
        // Perform toggle without wrapping entire block in animation
        if let interest = activity.interests.first(where: { $0.user?.id == user.id }) {
            modelContext.delete(interest)
        } else {
            let interest = Interest(user: user, activity: activity)
            modelContext.insert(interest)
        }
        
        // Save and check matches
        do {
            try modelContext.save()
            activityManager.checkMatches(modelContext: modelContext, specificActivity: activity)
        } catch {
            print("⚠️ Failed to toggle interest: \(error.localizedDescription)")
        }
    }
}

// MARK: - ActivityBubble Helper

struct ActivityBubble: View {
    let activity: Activity
    let cameraZ: Double
    let centerX: CGFloat
    let centerY: CGFloat
    let currentUser: User?
    let toggleAction: () -> Void
    
    private var relativeZ: Double { activity.z - cameraZ }
    private var perspectiveScale: Double { 800 / relativeZ }
    private var isSelected: Bool { 
        activity.interests.contains(where: { $0.user?.id == currentUser?.id }) 
    }
    
    var body: some View {
        if relativeZ > 10 {
            DriftingView(range: 20) {
                BubbleView(activity: activity, isSelected: isSelected, currentUser: currentUser, depth: relativeZ, action: toggleAction)
                    .equatable()
            }
            .scaleEffect(perspectiveScale * (isSelected ? 1.2 : 1.0))
            .position(
                x: activity.x * perspectiveScale + centerX,
                y: activity.y * perspectiveScale + centerY
            )
            .zIndex(-relativeZ)
            .opacity(min(1.0, relativeZ / 200))
        }
    }
}

// MARK: - Components

struct SessionCard: View {
    let session: GroupSession
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(session.activityName)
                .font(.headline)
                .foregroundColor(.white)
            Text(session.scheduledTime.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(width: 140, height: 80)
        .background(Color.blue)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

struct SimulationPanel: View {
    @Bindable var manager: ActivityManager
    @Binding var selectedSimulant: User?
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Tap As...")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // "Me" Option
                    Button(action: {
                        withAnimation { selectedSimulant = nil } // nil = Me
                    }) {
                        VStack {
                            Circle()
                                .fill(Color(hex: manager.currentUser?.avatarColor ?? "FFFFFF"))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary, lineWidth: selectedSimulant == nil ? 3 : 0)
                                )
                            Text("Me")
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Friends Options
                    ForEach(manager.allUsers.filter { $0.id != manager.currentUser?.id }) { user in
                        Button(action: {
                            withAnimation {
                                selectedSimulant = user
                            }
                        }) {
                            VStack {
                                Circle()
                                    .fill(Color(hex: user.avatarColor))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedSimulant?.id == user.id ? 3 : 0)
                                    )
                                Text(user.name)
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(10)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}
