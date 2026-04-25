import AppKit
import ApplicationServices

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private let trigger = DoubleCtrlTrigger()
    private let spotlight = SpotlightController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        setupStatusItem()
        promptForAccessibilityIfNeeded()
        trigger.onTrigger = { [weak self] in self?.spotlight.show() }
        trigger.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        trigger.stop()
        spotlight.hide()
    }

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "scope", accessibilityDescription: "SpotMac")
            image?.isTemplate = true
            button.image = image
        }
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Quit SpotMac",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        item.menu = menu
        statusItem = item
    }

    private func promptForAccessibilityIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
}
