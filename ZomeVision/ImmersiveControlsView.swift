import SwiftUI
import ZomeKit
import ZomeRendering

/// Floating window shown alongside the ImmersiveSpace. The user can drag it
/// anywhere in the room. Contents: appearance picker, in-situ sliders for
/// the most useful tuning knobs (θ, timber width, height ratio), and an
/// Exit button. Geometry rebuilds live as you drag a slider — including
/// while you're standing inside the dome.
struct ImmersiveControlsView: View {
    @Environment(ZomeStore.self)          private var store
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow)         private var dismissWindow

    @AppStorage("timberAppearance") private var rawAppearance: String = TimberAppearance.rainbow.rawValue

    var body: some View {
        @Bindable var store = store

        VStack(alignment: .leading, spacing: 16) {
            Text(store.documentName ?? "Default zome")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                Text("Timbers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Timbers", selection: $rawAppearance) {
                    ForEach(TimberAppearance.allCases) { ap in
                        Text(ap.label).tag(ap.rawValue)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            Divider()

            sliderRow(
                "θ",
                value: $store.params.thetaDegrees,
                range: 30...75,
                step: 0.25,
                format: "%.2f°"
            )
            sliderRow(
                "Timber width",
                value: $store.params.timberWidth,
                range: 0.5...12,
                step: 0.25,
                format: "%@",
                formatter: { CutList.formatInches($0) }
            )
            sliderRow(
                "Height ratio",
                value: $store.params.heightRatio,
                range: 0.30...0.95,
                step: 0.01,
                format: "%.2f"
            )

            Divider()

            Button(role: .destructive, action: exit) {
                Text("Exit Zome")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
        .frame(width: 360)
    }

    @ViewBuilder
    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        formatter: ((Double) -> String)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatter?(value.wrappedValue) ?? String(format: format, value.wrappedValue))
                    .font(.system(.callout, design: .monospaced))
                    .foregroundStyle(.primary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    private func exit() {
        Task {
            await dismissImmersiveSpace()
            // Close this floating window so the user isn't left with stale
            // controls in mid-air after returning to the launcher.
            dismissWindow(id: "controls")
        }
    }
}
