//
//  SonarHaptics.swift
//  Sonar
//
//  Created by Forest Katsch on 10/28/20.
//

import Foundation
import CoreHaptics

func lerp(_ value: Double, _ min: Double, _ max: Double) -> Double {
    return value * (max - min) + min
}

func ilerp(_ value: Double, _ min: Double, _ max: Double) -> Double {
    return (value - min) / (max - min)
}

func clamp(_ value: Double, _ low: Double, _ high: Double) -> Double {
    return min(max(value, low), high)
}

class SonarHaptics: SonarDelegate {
    
    var sonar: Sonar? = nil;
    
    var velocity = 0.0
    var lastDistance = -1.0
    
    var paused: Bool = true
    
    func distanceChanged(_ sonar: Sonar) {
        self.sonar = sonar
    }
    
    func makeTap(_ distance: Double) {
        let fraction = clamp(distance / 10, 0, 1)
        
        if distance < 0 {
            return
        }
        
        if lastDistance >= 0 {
            velocity = lastDistance - distance
        }
        
        lastDistance = distance
        
        let intensity = lerp(pow(fraction, 0.5), 1, 0.4)
        let sharpness = lerp(clamp(ilerp(velocity * -90, -1, 1), 0, 1), 1, 0)
        let attack = 0//lerp(fraction, 0.0, 0.1)
        let release = 0//lerp(fraction, 0.02, 0.2)
        let decay = 0//lerp(fraction, 0.01, 0.5)
        
        //let duration lerp(pow(fraction, 0.3), 1/60, 1/10)
        let duration = lerp(pow(fraction, 0.3), 1/240.0, 1/40.0)
        
        let tap = CHHapticEvent(
            eventType: .hapticContinuous,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(intensity)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(sharpness)),
                CHHapticEventParameter(parameterID: .attackTime, value: Float(attack)),
                CHHapticEventParameter(parameterID: .releaseTime, value: Float(release)),
                CHHapticEventParameter(parameterID: .decayTime, value: Float(decay))
            ],
            relativeTime: 0,
            duration: TimeInterval(duration))
        
        guard let engine = self.engine else { return }
        
        do {
            let pattern = try CHHapticPattern(events: [tap], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Could not create or play pattern: \(error)")
            
            start()
        }
    }
    
    func ping() {
        guard let sonar = self.sonar else {
            return
        }
        
        if paused {
            return
        }
        
        let fraction = max(min(sonar.distance / 10, 1), 0)
        
        var delay = lerp(pow(fraction, 1), 1/120.0, 1/2.0)
        delay = lerp(clamp(ilerp(velocity * -30, -1, 1), 0, 1), delay * 0.5, delay * 1.5)

        makeTap(sonar.distance)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            self.ping()
        }
    }
        
    var engine: CHHapticEngine?
    
    func start(_ sonar: Sonar) {
        self.sonar = sonar
        start()
    }
    
    func start() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("This device does not support haptics")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch let error {
            print("Haptic engine initialization error: \(error)")
            return
        }
        
        engine?.resetHandler = {
            print("Reset Handler: Restarting engine.")
            
            do {
                try self.engine?.start()
            } catch {
                print("Failed to restart the engine: \(error)")
            }
        }
        
        print("Haptic engine started")
    }
    
    func pause() {
        if paused {
            return
        }
        
        paused = true
    }
    
    func resume() {
        if !paused {
            return
        }
        
        paused = false
        
        ping()
    }
    
    func stop(_ sonar: Sonar) {
        stop()
        self.sonar = nil
    }
    
    func stop() {
        engine?.stop()
        print("Haptic engine stopped")
    }

}
