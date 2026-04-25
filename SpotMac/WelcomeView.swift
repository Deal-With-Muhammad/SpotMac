import SwiftUI

struct WelcomeView: View {
    @ObservedObject private var accessibility = AccessibilityMonitor.shared
    @ObservedObject private var settings = SpotSettings.shared

    var body: some View {
        VStack(spacing: 24) {
            hero

            VStack(spacing: 12) {
                accessibilityRow
                triggerRow
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )

            actions

            Spacer(minLength: 0)

            HStack {
                Button("Open Settings…") { AppActions.openSettings() }
                Spacer()
                Button("Done") { AppActions.dismissWelcome() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 480, height: 540)
        .onAppear { accessibility.refresh() }
    }

    // MARK: - Pieces

    private var hero: some View {
        VStack(spacing: 10) {
            Image(systemName: "scope")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(.tint)
            Text("Welcome to SpotMac")
                .font(.largeTitle.bold())
            Text("Lost your cursor? Double-tap a key and SpotMac will spotlight it for you.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var accessibilityRow: some View {
        HStack(alignment: .top, spacing: 12) {
            statusIcon(ok: accessibility.isTrusted)
            VStack(alignment: .leading, spacing: 2) {
                Text("Accessibility permission")
                    .font(.headline)
                Text(accessibility.isTrusted
                     ? "Granted — SpotMac can watch for your trigger key."
                     : "SpotMac needs this to watch for the trigger key globally.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            if !accessibility.isTrusted {
                Button("Open…") { AccessibilityMonitor.openSystemSettings() }
            }
        }
    }

    private var triggerRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "keyboard")
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text("Trigger")
                    .font(.headline)
                Text("Double-tap **\(settings.triggerKey.displayName)** within \(Int(settings.doubleTapWindowMs)) ms.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Change…") { AppActions.openSettings() }
        }
    }

    private var actions: some View {
        HStack(spacing: 12) {
            Button {
                AppActions.showSpotlightNow()
            } label: {
                Label("Try Spotlight Now", systemImage: "scope")
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)
            .disabled(!accessibility.isTrusted)
        }
    }

    private func statusIcon(ok: Bool) -> some View {
        Image(systemName: ok ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.system(size: 18))
            .foregroundStyle(ok ? Color.green : Color.orange)
            .frame(width: 22)
    }
}

#Preview {
    WelcomeView()
}
