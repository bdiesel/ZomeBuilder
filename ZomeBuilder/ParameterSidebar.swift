import SwiftUI
import ZomeKit

/// Sliders + readouts for the live-tunable subset of `ZomeParameters`.
/// Skips bindu ratios and vanishingY — those are advanced inputs.
struct ParameterSidebar: View {
    @Binding var params: ZomeParameters
    @Binding var showBoundingBox: Bool
    let geometry: ZomeGeometry
    let onShowCutList: () -> Void
    let onExportCutList: () -> Void
    let onNewDocument: () -> Void
    let onOpenDocument: () -> Void
    let onSaveDocument: () -> Void
    let onSaveAsDocument: () -> Void
    let onFitToView: () -> Void

    @AppStorage(UnitSystem.storageKey) private var rawUnit: Int = UnitSystem.imperial.rawValue
    private var unitSystem: UnitSystem { UnitSystem(rawValue: rawUnit) ?? .imperial }

    var body: some View {
        Form {
            Section("File") {
                Button("New",         action: onNewDocument)
                Button("Open…",       action: onOpenDocument)
                Button("Save",        action: onSaveDocument)
                Button("Save As…",    action: onSaveAsDocument)
            }

            Section("View") {
                Picker("Units", selection: $rawUnit) {
                    ForEach(UnitSystem.allCases) { sys in
                        Text(sys.label).tag(sys.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                Button("Fit to view", action: onFitToView)
            }

            Section("Bounding box") {
                EnvelopeReadout(geometry: geometry)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
                Toggle("Show in 3D view", isOn: $showBoundingBox)
            }

            Section("Cut list") {
                Button("View cut list…", action: onShowCutList)
                Button("Export CSV…", action: onExportCutList)
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
                lengthRow("Zome height", inches: $params.zomeHeight, inchRange: 36...360)
            }

            Section("Timbers") {
                lengthRow("Width", inches: $params.timberWidth, inchRange: 0.5...12)
                lengthRow("Thickness", inches: $params.timberThickness, inchRange: 0.5...4)
            }

            Section {
                Button("Reset to defaults") { params = .goodKarmaDefault }
                    .buttonStyle(.bordered)
            }
        }
        .formStyle(.grouped)
    }

    /// Slider row for a length — stored in inches internally, formatted in the
    /// active unit system, with step matching that unit's natural snap (1/16″
    /// or 1 mm).
    @ViewBuilder
    private func lengthRow(
        _ label: String,
        inches: Binding<Double>,
        inchRange: ClosedRange<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                Spacer()
                Text(unitSystem.formatLength(inches: inches.wrappedValue))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            Slider(value: inches, in: inchRange, step: unitSystem.lengthStepInches)
        }
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
