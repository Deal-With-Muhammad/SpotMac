import AppKit
import SwiftUI

final class WelcomeWindowController: NSWindowController, NSWindowDelegate {
    convenience init() {
        let host = NSHostingController(rootView: WelcomeView())
        let window = NSWindow(contentViewController: host)
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.title = "Welcome to SpotMac"
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

    // Mark welcome as completed when the user closes the window any way.
    func windowWillClose(_ notification: Notification) {
        SpotSettings.shared.hasCompletedWelcome = true
    }
}
