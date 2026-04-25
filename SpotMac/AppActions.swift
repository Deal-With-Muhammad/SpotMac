import AppKit

/// Router for actions that need to talk to the AppDelegate from SwiftUI views,
/// menu items, or anywhere else. Routes through `AppDelegate.shared` (set in
/// `applicationDidFinishLaunching`) instead of casting `NSApp.delegate`, which
/// can be unreliable when the SwiftUI App adapter is involved.
enum AppActions {
    private static var delegate: AppDelegate? { AppDelegate.shared }

    static func showSpotlightNow() {
        delegate?.showSpotlightNow()
    }

    static func openSettings() {
        delegate?.openSettingsWindow()
    }

    static func openWelcome() {
        delegate?.openWelcomeWindow()
    }

    static func dismissWelcome() {
        delegate?.dismissWelcomeWindow()
    }

    static func showAbout() {
        delegate?.showAboutPanel()
    }

    static func quit() {
        NSApp.terminate(nil)
    }
}
