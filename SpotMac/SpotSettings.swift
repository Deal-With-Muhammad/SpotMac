import AppKit
import Combine
import Foundation

enum TriggerKey: String, CaseIterable, Identifiable {
    case leftControl
    case rightControl
    case leftCommand
    case rightCommand
    case leftShift
    case rightShift
    case leftOption
    case rightOption

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .leftControl:   return "Left Ctrl"
        case .rightControl:  return "Right Ctrl"
        case .leftCommand:   return "Left ⌘"
        case .rightCommand:  return "Right ⌘"
        case .leftShift:     return "Left Shift"
        case .rightShift:    return "Right Shift"
        case .leftOption:    return "Left Option"
        case .rightOption:   return "Right Option"
        }
    }

    var keyCode: UInt16 {
        switch self {
        case .leftControl:   return 59
        case .rightControl:  return 62
        case .leftCommand:   return 55
        case .rightCommand:  return 54
        case .leftShift:     return 56
        case .rightShift:    return 60
        case .leftOption:    return 58
        case .rightOption:   return 61
        }
    }

    /// Device-specific bit inside `NSEvent.modifierFlags.rawValue`. Lets us tell
    /// left-vs-right of the same modifier apart, which the OS-level flags
    /// (`.control`, `.command`, …) cannot do on their own.
    var deviceMask: UInt {
        switch self {
        case .leftControl:   return 0x00000001
        case .rightControl:  return 0x00002000
        case .leftShift:     return 0x00000002
        case .rightShift:    return 0x00000004
        case .leftCommand:   return 0x00000008
        case .rightCommand:  return 0x00000010
        case .leftOption:    return 0x00000020
        case .rightOption:   return 0x00000040
        }
    }
}

final class SpotSettings: ObservableObject {
    static let shared = SpotSettings()

    private enum Key {
        static let triggerKey         = "triggerKey"
        static let spotlightRadius    = "spotlightRadius"
        static let dimLevel           = "dimLevel"
        static let softEdge           = "softEdge"
        static let showRing           = "showRing"
        static let animateFade        = "animateFade"
        static let settleEnabled      = "settleEnabled"
        static let settleDelayMs      = "settleDelayMs"
        static let doubleTapWindowMs  = "doubleTapWindowMs"
        static let hasCompletedWelcome = "hasCompletedWelcome"
    }

    private enum Defaults {
        static let triggerKey         = TriggerKey.leftControl
        static let spotlightRadius    = 110.0
        static let dimLevel           = 0.55
        static let softEdge           = true
        static let showRing           = false
        static let animateFade        = true
        static let settleEnabled      = true
        static let settleDelayMs      = 500.0
        static let doubleTapWindowMs  = 400.0
    }

    @Published var triggerKey: TriggerKey {
        didSet { store.set(triggerKey.rawValue, forKey: Key.triggerKey) }
    }
    @Published var spotlightRadius: Double {
        didSet { store.set(spotlightRadius, forKey: Key.spotlightRadius) }
    }
    @Published var dimLevel: Double {
        didSet { store.set(dimLevel, forKey: Key.dimLevel) }
    }
    @Published var softEdge: Bool {
        didSet { store.set(softEdge, forKey: Key.softEdge) }
    }
    @Published var showRing: Bool {
        didSet { store.set(showRing, forKey: Key.showRing) }
    }
    @Published var animateFade: Bool {
        didSet { store.set(animateFade, forKey: Key.animateFade) }
    }
    @Published var settleEnabled: Bool {
        didSet { store.set(settleEnabled, forKey: Key.settleEnabled) }
    }
    @Published var settleDelayMs: Double {
        didSet { store.set(settleDelayMs, forKey: Key.settleDelayMs) }
    }
    @Published var doubleTapWindowMs: Double {
        didSet { store.set(doubleTapWindowMs, forKey: Key.doubleTapWindowMs) }
    }
    @Published var hasCompletedWelcome: Bool {
        didSet { store.set(hasCompletedWelcome, forKey: Key.hasCompletedWelcome) }
    }

    private let store: UserDefaults

    init(store: UserDefaults = .standard) {
        self.store = store

        let raw = store.string(forKey: Key.triggerKey) ?? Defaults.triggerKey.rawValue
        self.triggerKey = TriggerKey(rawValue: raw) ?? Defaults.triggerKey

        self.spotlightRadius = store.object(forKey: Key.spotlightRadius) as? Double ?? Defaults.spotlightRadius
        self.dimLevel = store.object(forKey: Key.dimLevel) as? Double ?? Defaults.dimLevel
        self.softEdge = store.object(forKey: Key.softEdge) as? Bool ?? Defaults.softEdge
        self.showRing = store.object(forKey: Key.showRing) as? Bool ?? Defaults.showRing
        self.animateFade = store.object(forKey: Key.animateFade) as? Bool ?? Defaults.animateFade
        self.settleEnabled = store.object(forKey: Key.settleEnabled) as? Bool ?? Defaults.settleEnabled
        self.settleDelayMs = store.object(forKey: Key.settleDelayMs) as? Double ?? Defaults.settleDelayMs
        self.doubleTapWindowMs = store.object(forKey: Key.doubleTapWindowMs) as? Double ?? Defaults.doubleTapWindowMs
        self.hasCompletedWelcome = store.bool(forKey: Key.hasCompletedWelcome)
    }

    func resetToDefaults() {
        triggerKey         = Defaults.triggerKey
        spotlightRadius    = Defaults.spotlightRadius
        dimLevel           = Defaults.dimLevel
        softEdge           = Defaults.softEdge
        showRing           = Defaults.showRing
        animateFade        = Defaults.animateFade
        settleEnabled      = Defaults.settleEnabled
        settleDelayMs      = Defaults.settleDelayMs
        doubleTapWindowMs  = Defaults.doubleTapWindowMs
    }
}
