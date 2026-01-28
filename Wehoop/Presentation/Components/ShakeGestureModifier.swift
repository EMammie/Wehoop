//
//  ShakeGestureModifier.swift
//  Wehoop
//
//  Created by E on 1/2/26.
//

import SwiftUI
import UIKit

/// View modifier to detect shake gestures
struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                NotificationCenter.default.addObserver(
                    forName: UIDevice.deviceDidShakeNotification,
                    object: nil,
                    queue: .main
                ) { _ in
                    action()
                }
            }
            .onDisappear {
                NotificationCenter.default.removeObserver(
                    self,
                    name: UIDevice.deviceDidShakeNotification,
                    object: nil
                )
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(ShakeGestureModifier(action: action))
    }
}

// MARK: - UIDevice Shake Notification Extension

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}
