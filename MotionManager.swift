import CoreMotion
import SwiftUI

@Observable
@MainActor
class MotionManager {
    private nonisolated let motionManager = CMMotionManager()
    
    var pitch: Double = 0.0
    var roll: Double = 0.0
    
    init() {
        startUpdates()
    }
    
    func startUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion not available")
            return
        }
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("⚠️ Motion update error: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            // Smooth out the values with animation
            withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.8)) {
                self.pitch = data.attitude.pitch
                self.roll = data.attitude.roll
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
