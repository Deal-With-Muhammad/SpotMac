import AppKit

final class SpotlightController {
    private let settleDelay: TimeInterval = 0.5

    private var window: NSWindow?
    private var view: SpotlightView?
    private var monitors: [Any] = []
    private var settleTimer: Timer?

    func show() {
        guard window == nil, let screen = NSScreen.main else { return }
        let frame = screen.frame

        let win = NSWindow(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false,
            screen: screen
        )
        win.isOpaque = false
        win.backgroundColor = .clear
        win.hasShadow = false
        win.level = .screenSaver
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        win.isReleasedWhenClosed = false

        let spotlight = SpotlightView(frame: NSRect(origin: .zero, size: frame.size))
        spotlight.cursorPoint = localCursorPoint(in: frame)
        win.contentView = spotlight
        win.orderFrontRegardless()

        self.window = win
        self.view = spotlight

        installMonitors()
    }

    func hide() {
        removeMonitors()
        settleTimer?.invalidate()
        settleTimer = nil
        window?.orderOut(nil)
        window = nil
        view = nil
    }

    private func localCursorPoint(in windowFrame: NSRect) -> NSPoint {
        let m = NSEvent.mouseLocation
        return NSPoint(x: m.x - windowFrame.origin.x, y: m.y - windowFrame.origin.y)
    }

    private func installMonitors() {
        let dismiss: (NSEvent) -> Void = { [weak self] _ in
            DispatchQueue.main.async { self?.hide() }
        }
        let moved: (NSEvent) -> Void = { [weak self] _ in
            DispatchQueue.main.async { self?.handleMouseMoved() }
        }

        let mouseDownMask: NSEvent.EventTypeMask = [.leftMouseDown, .rightMouseDown, .otherMouseDown]

        addGlobal(.keyDown, handler: dismiss)
        addGlobal(mouseDownMask, handler: dismiss)
        addGlobal(.mouseMoved, handler: moved)

        addLocal(.keyDown) { dismiss($0); return $0 }
        addLocal(mouseDownMask) { dismiss($0); return $0 }
        addLocal(.mouseMoved) { moved($0); return $0 }
    }

    private func addGlobal(_ mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) {
        if let m = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) {
            monitors.append(m)
        }
    }

    private func addLocal(_ mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) {
        if let m = NSEvent.addLocalMonitorForEvents(matching: mask, handler: handler) {
            monitors.append(m)
        }
    }

    private func removeMonitors() {
        for m in monitors { NSEvent.removeMonitor(m) }
        monitors.removeAll()
    }

    private func handleMouseMoved() {
        guard let view = view, let window = window else { return }
        view.cursorPoint = localCursorPoint(in: window.frame)

        settleTimer?.invalidate()
        settleTimer = Timer.scheduledTimer(withTimeInterval: settleDelay, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
}
