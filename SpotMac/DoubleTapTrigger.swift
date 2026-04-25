import AppKit

/// Detects a double-tap of a configurable modifier key (e.g. Left Ctrl).
///
/// We only watch `.flagsChanged` events whose `keyCode` matches the configured
/// physical key, then use the device-specific bit in `modifierFlags` to tell
/// "is this *that* key down right now?" — the OS-level flag (`.control` etc.)
/// can't distinguish left vs right when both are involved.
final class DoubleTapTrigger {
    var onTrigger: (() -> Void)?

    var key: TriggerKey {
        didSet {
            guard key != oldValue else { return }
            keyWasDown = false
            lastPressTime = 0
        }
    }
    var doubleTapWindow: TimeInterval

    private var lastPressTime: TimeInterval = 0
    private var keyWasDown = false
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(key: TriggerKey = .leftControl, doubleTapWindow: TimeInterval = 0.4) {
        self.key = key
        self.doubleTapWindow = doubleTapWindow
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    func stop() {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
        globalMonitor = nil
        localMonitor = nil
        keyWasDown = false
        lastPressTime = 0
    }

    func restart() {
        stop()
        start()
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode == key.keyCode else { return }

        let isDown = (event.modifierFlags.rawValue & key.deviceMask) != 0
        defer { keyWasDown = isDown }
        guard isDown, !keyWasDown else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if now - lastPressTime <= doubleTapWindow {
            lastPressTime = 0
            DispatchQueue.main.async { [weak self] in self?.onTrigger?() }
        } else {
            lastPressTime = now
        }
    }
}
