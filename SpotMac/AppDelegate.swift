import AppKit
import Combine

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Strong process-wide reference. We don't rely on `NSApp.delegate as? AppDelegate`
    /// because the SwiftUI `@NSApplicationDelegateAdaptor` plumbing has been observed
    /// to interpose, which silently nils the cast in `AppActions`.
    static private(set) weak var shared: AppDelegate?

    private var statusItem: NSStatusItem?
    private var statusMenuItem: NSMenuItem?

    private let trigger = DoubleTapTrigger()
    private let spotlight = SpotlightController()
    private let settings = SpotSettings.shared
    private let accessibility = AccessibilityMonitor.shared

    private var welcomeWindow: WelcomeWindowController?
    private var settingsWindow: SettingsWindowController?
    private var cancellables = Set<AnyCancellable>()
    private var windowCloseObserver: NSObjectProtocol?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        configureTrigger()
        observeSettings()
        observeAccessibility()
        observeWindowCloses()

        accessibility.start()
        accessibility.promptIfNeeded()
        trigger.onTrigger = { [weak self] in self?.showSpotlightNow() }
        trigger.start()

        if !settings.hasCompletedWelcome {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.openWelcomeWindow()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let obs = windowCloseObserver {
            NotificationCenter.default.removeObserver(obs)
        }
        trigger.stop()
        accessibility.stop()
        spotlight.hide()
    }

    // MARK: - Public actions

    func showSpotlightNow() {
        spotlight.show()
    }

    func openSettingsWindow() {
        enterForeground()
        if settingsWindow == nil {
            settingsWindow = SettingsWindowController()
        }
        settingsWindow?.present()
    }

    func openWelcomeWindow() {
        enterForeground()
        if welcomeWindow == nil {
            welcomeWindow = WelcomeWindowController()
        }
        welcomeWindow?.present()
    }

    func dismissWelcomeWindow() {
        settings.hasCompletedWelcome = true
        welcomeWindow?.dismiss()
    }

    func showAboutPanel() {
        enterForeground()
        NSApp.orderFrontStandardAboutPanel(nil)
    }

    // MARK: - Activation policy

    private func enterForeground() {
        if NSApp.activationPolicy() != .regular {
            NSApp.setActivationPolicy(.regular)
        }
        NSApp.activate(ignoringOtherApps: true)
    }

    private func observeWindowCloses() {
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.async { self?.evaluateActivationPolicy() }
        }
    }

    private func evaluateActivationPolicy() {
        let hasUserWindow = NSApp.windows.contains { window in
            window.isVisible && window.canBecomeKey
        }
        if !hasUserWindow, NSApp.activationPolicy() != .accessory {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Status item

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.image = statusItemImage(trusted: accessibility.isTrusted)
            button.image?.isTemplate = true
        }
        item.menu = buildMenu()
        statusItem = item
        refreshStatusItem()
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let status = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        statusMenuItem = status

        menu.addItem(.separator())

        addMenuItem(menu, title: "Show Spotlight Now",
                    selector: #selector(menuShowSpotlight))

        menu.addItem(.separator())

        addMenuItem(menu, title: "Welcome / Quick Start…",
                    selector: #selector(menuOpenWelcome))
        addMenuItem(menu, title: "Settings…",
                    selector: #selector(menuOpenSettings),
                    keyEquivalent: ",")

        menu.addItem(.separator())

        addMenuItem(menu, title: "About SpotMac",
                    selector: #selector(menuShowAbout))
        addMenuItem(menu, title: "Quit SpotMac",
                    selector: #selector(menuQuit),
                    keyEquivalent: "q")

        return menu
    }

    @discardableResult
    private func addMenuItem(_ menu: NSMenu,
                             title: String,
                             selector: Selector,
                             keyEquivalent: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: keyEquivalent)
        item.target = self
        menu.addItem(item)
        return item
    }

    private func refreshStatusItem() {
        let trusted = accessibility.isTrusted
        statusMenuItem?.title = trusted
            ? "Ready — double-tap \(settings.triggerKey.displayName)"
            : "⚠︎ Accessibility permission needed"
        if let button = statusItem?.button {
            button.image = statusItemImage(trusted: trusted)
            button.image?.isTemplate = true
            button.toolTip = trusted ? "SpotMac" : "SpotMac — needs Accessibility permission"
        }
    }

    private func statusItemImage(trusted: Bool) -> NSImage? {
        let name = trusted ? "scope" : "exclamationmark.triangle"
        return NSImage(systemSymbolName: name, accessibilityDescription: "SpotMac")
    }

    // MARK: - Menu actions (all targeted on self → guaranteed to fire)

    @objc private func menuShowSpotlight() {
        if accessibility.isTrusted {
            showSpotlightNow()
        } else {
            openWelcomeWindow()
        }
    }

    @objc private func menuOpenWelcome() {
        openWelcomeWindow()
    }

    @objc private func menuOpenSettings() {
        openSettingsWindow()
    }

    @objc private func menuShowAbout() {
        showAboutPanel()
    }

    @objc private func menuQuit() {
        NSApp.terminate(nil)
    }

    // MARK: - Observers

    private func configureTrigger() {
        trigger.key = settings.triggerKey
        trigger.doubleTapWindow = settings.doubleTapWindowMs / 1000.0
    }

    private func observeSettings() {
        settings.$triggerKey
            .dropFirst()
            .sink { [weak self] newKey in
                guard let self else { return }
                self.trigger.key = newKey
                self.trigger.restart()
                self.refreshStatusItem()
            }
            .store(in: &cancellables)

        settings.$doubleTapWindowMs
            .dropFirst()
            .sink { [weak self] ms in
                self?.trigger.doubleTapWindow = ms / 1000.0
            }
            .store(in: &cancellables)
    }

    private func observeAccessibility() {
        accessibility.$isTrusted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshStatusItem()
            }
            .store(in: &cancellables)
    }
}
