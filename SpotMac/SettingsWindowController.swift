import AppKit
import SwiftUI

/// We host SettingsView in a hand-rolled NSWindowController instead of using
/// SwiftUI's `Settings` scene because the scene's `showSettingsWindow:` action
/// is unreliable for accessory apps — sometimes the responder chain doesn't
/// register the scene at all, and the action silently fails.
final class SettingsWindowController: NSWindowController, NSWindowDelegate {
    convenience init() {
        let host = NSHostingController(rootView: SettingsView())
        let window = NSWindow(contentViewController: host)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "SpotMac Settings"
        window.isReleasedWhenClosed = false
        window.collectionBehavior = [.moveToActiveSpace]
        window.center()
        self.init(window: window)
        window.delegate = self
    }

    func present() {
        guard let window else { return }
        if !window.isVisible {
            window.center()
        }
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
        window.orderFrontRegardless()
    }

    func dismiss() {
        window?.close()
    }
}
