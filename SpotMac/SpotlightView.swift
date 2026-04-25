import AppKit

final class SpotlightView: NSView {
    var cursorPoint: NSPoint = .zero {
        didSet { needsDisplay = true }
    }
    var holeRadius: CGFloat = 110 {
        didSet { needsDisplay = true }
    }
    var dimAlpha: CGFloat = 0.55 {
        didSet { needsDisplay = true }
    }
    var softEdge: Bool = true {
        didSet { needsDisplay = true }
    }
    var showRing: Bool = false {
        didSet { needsDisplay = true }
    }

    override var isFlipped: Bool { false }
    override var isOpaque: Bool { false }
    override var wantsDefaultClipping: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }

        ctx.clear(bounds)
        ctx.setFillColor(NSColor.black.withAlphaComponent(dimAlpha).cgColor)
        ctx.fill(bounds)

        if softEdge {
            punchSoftHole(ctx: ctx)
        } else {
            punchHardHole(ctx: ctx)
        }

        if showRing {
            drawRing(ctx: ctx)
        }
    }

    private func punchHardHole(ctx: CGContext) {
        let rect = CGRect(
            x: cursorPoint.x - holeRadius,
            y: cursorPoint.y - holeRadius,
            width: holeRadius * 2,
            height: holeRadius * 2
        )
        ctx.setBlendMode(.clear)
        ctx.fillEllipse(in: rect)
        ctx.setBlendMode(.normal)
    }

    private func punchSoftHole(ctx: CGContext) {
        // `.destinationOut` erases the dim layer using the gradient as alpha.
        // Opaque white at the center → fully erased; clear at the edge → kept.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let opaque = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 1)
        let clear  = CGColor(srgbRed: 1, green: 1, blue: 1, alpha: 0)
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: [opaque, opaque, clear] as CFArray,
            locations: [0.0, 0.65, 1.0]
        ) else {
            punchHardHole(ctx: ctx)
            return
        }

        ctx.saveGState()
        ctx.setBlendMode(.destinationOut)
        ctx.drawRadialGradient(
            gradient,
            startCenter: cursorPoint, startRadius: 0,
            endCenter:   cursorPoint, endRadius:   holeRadius,
            options: []
        )
        ctx.restoreGState()
    }

    private func drawRing(ctx: CGContext) {
        let ringWidth: CGFloat = 2
        let radius = holeRadius - ringWidth
        let rect = CGRect(
            x: cursorPoint.x - radius,
            y: cursorPoint.y - radius,
            width: radius * 2,
            height: radius * 2
        )
        ctx.setStrokeColor(NSColor.white.withAlphaComponent(0.85).cgColor)
        ctx.setLineWidth(ringWidth)
        ctx.strokeEllipse(in: rect)
    }
}
