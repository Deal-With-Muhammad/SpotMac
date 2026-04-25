import AppKit
import ApplicationServices
import Combine

final class AccessibilityMonitor: ObservableObject {
    static let shared = AccessibilityMonitor()

    @Published private(set) var isTrusted: Bool

    private var timer: Timer?
    private let pollInterval: TimeInterval = 2.0

    private init() {
        self.isTrusted = AXIsProcessTrusted()
    }

    func start() {
        stop()
        let t = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func refresh() {
        let trusted = AXIsProcessTrusted()
        if trusted != isTrusted {
            DispatchQueue.main.async { [weak self] in
                self?.isTrusted = trusted
            }
        }
    }

    /// Triggers the system prompt the first time only. Subsequent calls are no-ops.
    func promptIfNeeded() {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
