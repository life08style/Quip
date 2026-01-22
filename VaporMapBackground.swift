import SwiftUI
import MapKit

struct VaporMapBackground: View {
    // Center on a default location (e.g. New York) or user's location
    // For now, let's pick a vibrant urban area like NYC/Manhattan
    @State private var position: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.7829, longitude: -73.9654), // Central Parkish
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    
    var body: some View {
        ZStack {
            // Simplified map rendering with reduced overhead
            Map(position: $position) {
                // We can add annotations here if we want specific landmarks
            }
            .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll)) // Clean look
            .saturation(0.0) // Muted/Grayscale base
            .colorMultiply(Color(white: 0.9)) // Lighten it up
            .allowsHitTesting(false) // Prevent interaction overhead
            
            // Consolidated "Frosted Glass" Overlay with tint
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.85)
                
                // Tint gradient overlay
                LinearGradient(
                    colors: [
                        .white.opacity(0.4),
                        .orange.opacity(0.1),
                        .purple.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.overlay)
            }
            .drawingGroup() // Enable GPU compositing for entire background
        }
        .ignoresSafeArea()
    }
}

#Preview {
    VaporMapBackground()
}
