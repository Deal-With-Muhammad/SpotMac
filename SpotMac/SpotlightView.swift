import AppKit

final class SpotlightView: NSView {
    static let holeRadius: CGFloat = 110
    static let dimAlpha: CGFloat = 0.55

    var cursorPoint: NSPoint = .zero {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }
    override var wantsDefaultClipping: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.clear(bounds)
        ctx.setFillColor(NSColor.black.withAlphaComponent(Self.dimAlpha).cgColor)
        ctx.fill(bounds)

        let r = Self.holeRadius
        let hole = CGRect(x: cursorPoint.x - r, y: cursorPoint.y - r, width: r * 2, height: r * 2)
        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: hole)
        ctx.setBlendMode(.normal)
    }
}
