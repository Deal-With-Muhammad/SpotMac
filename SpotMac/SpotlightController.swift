import AppKit

final class SpotlightController {
    private let settings: SpotSettings
    private let fadeDuration: TimeInterval = 0.12

    private var window: NSWindow?
    private var view: SpotlightView?
    private var monitors: [Any] = []
    private var settleTimer: Timer?
    private var isDismissing = false

    init(settings: SpotSettings = .shared) {
        self.settings = settings
    }

    var isVisible: Bool { window != nil && !isDismissing }

    func show() {
        if isVisible { return }
        if isDismissing {
            // A previous fade-out is still in flight — finish it instantly so the
            // new show() doesn't fight the animation.
            forceTeardown()
        }

        guard let screen = NSScreen.main else { return }
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
        applySettings(to: spotlight)
        spotlight.cursorPoint = localCursorPoint(in: frame)
        win.contentView = spotlight

        if settings.animateFade {
            win.alphaValue = 0
            win.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = fadeDuration
                win.animator().alphaValue = 1
            }
        } else {
            win.alphaValue = 1
            win.orderFrontRegardless()
        }

        self.window = win
        self.view = spotlight

        installMonitors()
    }

    func hide() {
        guard window != nil, !isDismissing else { return }
        isDismissing = true
        removeMonitors()
        settleTimer?.invalidate()
        settleTimer = nil

        if settings.animateFade, let win = window {
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = fadeDuration
                win.animator().alphaValue = 0
            }, completionHandler: { [weak self] in
                self?.forceTeardown()
            })
        } else {
            forceTeardown()
        }
    }

    private func forceTeardown() {
        window?.orderOut(nil)
        window = nil
        view = nil
        isDismissing = false
    }

    private func applySettings(to view: SpotlightView) {
        view.holeRadius = CGFloat(settings.spotlightRadius)
        view.dimAlpha = CGFloat(settings.dimLevel)
        view.softEdge = settings.softEdge
        view.showRing = settings.showRing
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

        guard settings.settleEnabled else { return }
        settleTimer?.invalidate()
        let delay = max(0.05, settings.settleDelayMs / 1000.0)
        settleTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.hide()
        }
    }
}
