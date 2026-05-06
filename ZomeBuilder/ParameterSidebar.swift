import SwiftUI
import ZomeKit

/// Sliders + readouts for the live-tunable subset of `ZomeParameters`.
/// Skips bindu ratios and vanishingY — those are advanced inputs.
struct ParameterSidebar: View {
    @Binding var params: ZomeParameters
    let geometry: ZomeGeometry

    var body: some View {
        Form {
            Section("Bounding box") {
                EnvelopeReadout(geometry: geometry)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            Section("Geometry") {
                stepperRow(
                    "Spirals (N)",
                    value: Binding(
                        get: { Double(params.numSpirals) },
                        set: { params.numSpirals = max(3, Int($0.rounded())) }
                    ),
                    range: 3...24,
                    step: 1,
                    format: "%.0f"
                )
                sliderRow("θ (deg)", value: $params.thetaDegrees, range: 30...75, step: 0.25, format: "%.2f")
                sliderRow("Kite ratio", value: $params.kiteRatio, range: 0.4...1.6, step: 0.01, format: "%.2f")
                sliderRow("Height ratio", value: $params.heightRatio, range: 0.30...0.95, step: 0.01, format: "%.2f")
                sliderRow("Zome height", value: $params.zomeHeight, range: 36...360, step: 1, format: "%.0f")
            }

            Section("Timbers") {
                sliderRow("Width", value: $params.timberWidth, range: 0.5...12, step: 0.25, format: "%.2f")
                sliderRow("Thickness", value: $params.timberThickness, range: 0.5...4, step: 0.125, format: "%.3f")
            }

            Section {
                Button("Reset to defaults") { params = .goodKarmaDefault }
                    .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func sliderRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(String(format: format, value.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: value, in: range, step: step)
        }
    }

    @ViewBuilder
    private func stepperRow(
        _ label: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String
    ) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: format, value.wrappedValue))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
    }
}
