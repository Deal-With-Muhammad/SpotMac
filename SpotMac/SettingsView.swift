import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = SpotSettings.shared
    @ObservedObject private var accessibility = AccessibilityMonitor.shared
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled

    var body: some View {
        Form {
            triggerSection
            appearanceSection
            dismissalSection
            systemSection
            footerSection
        }
        .formStyle(.grouped)
        .frame(width: 560, height: 640)
        .onAppear {
            launchAtLogin = LaunchAtLogin.isEnabled
            accessibility.refresh()
        }
    }

    // MARK: - Sections

    private var triggerSection: some View {
        Section("Trigger") {
            Picker("Trigger key", selection: $settings.triggerKey) {
                ForEach(TriggerKey.allCases) { key in
                    Text(key.displayName).tag(key)
                }
            }

            LabeledSlider(
                title: "Double-tap window",
                value: $settings.doubleTapWindowMs,
                range: 200...600,
                step: 25,
                format: { "\(Int($0)) ms" }
            )
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            LabeledSlider(
                title: "Spotlight radius",
                value: $settings.spotlightRadius,
                range: 60...220,
                step: 5,
                format: { "\(Int($0)) px" }
            )
            LabeledSlider(
                title: "Dim level",
                value: $settings.dimLevel,
                range: 0.30...0.85,
                step: 0.05,
                format: { "\(Int($0 * 100))%" }
            )
            Toggle("Soft edge", isOn: $settings.softEdge)
            Toggle("Show ring around spotlight", isOn: $settings.showRing)
            Toggle("Fade in/out", isOn: $settings.animateFade)
        }
    }

    private var dismissalSection: some View {
        Section("Dismissal") {
            Toggle("Auto-dismiss when mouse stops moving", isOn: $settings.settleEnabled)
            if settings.settleEnabled {
                LabeledSlider(
                    title: "Settle delay",
                    value: $settings.settleDelayMs,
                    range: 200...1500,
                    step: 50,
                    format: { "\(Int($0)) ms" }
                )
            }
            Text("Pressing any key or clicking always dismisses the spotlight.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var systemSection: some View {
        Section("System") {
            Toggle("Launch SpotMac at login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    launchAtLogin = newValue
                    LaunchAtLogin.isEnabled = newValue
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            ))

            HStack {
                Text("Accessibility permission")
                Spacer()
                Image(systemName: accessibility.isTrusted
                      ? "checkmark.circle.fill"
                      : "exclamationmark.triangle.fill")
                    .foregroundStyle(accessibility.isTrusted ? .green : .orange)
                Text(accessibility.isTrusted ? "Granted" : "Not granted")
                    .foregroundStyle(.secondary)
                if !accessibility.isTrusted {
                    Button("Open System Settings…") {
                        AccessibilityMonitor.openSystemSettings()
                    }
                }
            }
        }
    }

    private var footerSection: some View {
        Section {
            HStack {
                Button("Reset to defaults") {
                    settings.resetToDefaults()
                }
                Spacer()
                Button("Try Spotlight Now") {
                    AppActions.showSpotlightNow()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!accessibility.isTrusted)
            }
        }
    }
}

// MARK: - LabeledSlider

private struct LabeledSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let format: (Double) -> String

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 12)
            Slider(value: $value, in: range, step: step)
                .frame(maxWidth: 220)
            Text(format(value))
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 64, alignment: .trailing)
        }
    }
}

#Preview {
    SettingsView()
}
