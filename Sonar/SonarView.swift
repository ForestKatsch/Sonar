//
//  SonarView.swift
//  Sonar
//
//  Created by Forest Katsch on 10/28/20.
//

import SwiftUI

struct SonarView: View {
    
    @ObservedObject
    var sonar = Sonar.instance
    
    var haptics = SonarHaptics()
    
    @GestureState
    private var activated = false
    
    var distanceView: some View {
        HStack {
            Text(sonar.distance < 0 ? "---" : String(format: "%.2fm", sonar.distance))
                .font(.system(.largeTitle, design: .monospaced))
                .foregroundColor(.accentColor)
        }
        .padding()
    }
    
    var engageButtonView: some View {
        Text("Hold To Enable Haptics")
            .padding()
            .frame(maxWidth: .infinity)
            .foregroundColor(activated ? .white : Color.accentColor)
            .font(.headline)
            .padding(EdgeInsets(top: 10, leading: 20, bottom: 10, trailing: 20))
            .background(activated ? Color.accentColor : Color("InactiveColor"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($activated) { (_, activated, _) in
                        haptics.resume()
                        
                        activated = true
                    }
                    .onEnded({ _ in
                        haptics.pause()
                    })
            )
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            distanceView
            Spacer()
            engageButtonView
            // You'd
            Text("Point your device at the object you’d like to ‘feel’. Taps get stronger and closer together as you approach the object.")
                .padding()
                .font(.system(.body))
            Text("Sonar uses your LiDAR sensor to detect the distance ahead, sending the information to the Taptic Engine for you to feel. It uses both ARKit and the Taptic Engine, so power consumption can be higher than normal.")
                .padding()
                .font(.system(.caption))
                .foregroundColor(.secondary)
        }
        .padding()
        .navigationTitle("Sonar")
        .onAppear {
            sonar.delegate = haptics
            sonar.start()
        }
        .onDisappear {
            sonar.stop()
            sonar.delegate = nil
        }
    }
}

struct SonarView_Previews: PreviewProvider {
    static var previews: some View {
        SonarView()
    }
}
