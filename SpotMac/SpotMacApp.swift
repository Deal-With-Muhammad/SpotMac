import SwiftUI

@main
struct SpotMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // SwiftUI requires a Scene, but we manage our own windows from AppDelegate
        // (Welcome + Settings via NSWindowController). The Settings scene is left
        // empty so cmd+, in the system never resolves to a stub UI.
        Settings { EmptyView() }
    }
}
