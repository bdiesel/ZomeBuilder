import SwiftUI
import ZomeKit

/// Live readout of the dome's overall dimensions + counts.
/// Length values use the active `UnitSystem` (imperial / metric).
struct EnvelopeReadout: View {
    let geometry: ZomeGeometry

    @AppStorage(UnitSystem.storageKey) private var rawUnit: Int = UnitSystem.imperial.rawValue
    private var unitSystem: UnitSystem { UnitSystem(rawValue: rawUnit) ?? .imperial }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Height",            value: unitSystem.formatLength(inches: geometry.envelope.height))
            row("Diameter",          value: unitSystem.formatLength(inches: geometry.envelope.diameter))
            row("Crowns",            value: "\(geometry.crownCount)")
            row("Timbers / spiral",  value: "\(geometry.envelope.timbersPerSpiral)")
            row("Total timbers",     value: "\(geometry.envelope.timbersPerSpiral * geometry.parameters.numSpirals)")
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundStyle(.primary)
        }
    }
}
