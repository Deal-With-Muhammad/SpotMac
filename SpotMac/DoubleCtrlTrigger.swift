import AppKit

final class DoubleCtrlTrigger {
    var onTrigger: (() -> Void)?

    private let doubleTapWindow: TimeInterval = 0.4
    private let leftControlKeyCode: UInt16 = 59

    private var lastPressTime: TimeInterval = 0
    private var controlWasDown = false
    private var globalMonitor: Any?
    private var localMonitor: Any?

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
    }

    private func handle(_ event: NSEvent) {
        guard event.keyCode == leftControlKeyCode else { return }

        let isDown = event.modifierFlags.contains(.control)
        defer { controlWasDown = isDown }
        guard isDown, !controlWasDown else { return }

        let now = ProcessInfo.processInfo.systemUptime
        if now - lastPressTime <= doubleTapWindow {
            lastPressTime = 0
            DispatchQueue.main.async { [weak self] in self?.onTrigger?() }
        } else {
            lastPressTime = now
        }
    }
}
