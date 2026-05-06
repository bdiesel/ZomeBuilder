import SwiftUI
import ZomeKit

/// Live readout of the dome's overall dimensions + counts.
/// Inch-formatted (Brian's default unit); a unit toggle is planned.
struct EnvelopeReadout: View {
    let geometry: ZomeGeometry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            row("Height",            value: CutList.formatInches(geometry.envelope.height))
            row("Diameter",          value: CutList.formatInches(geometry.envelope.diameter))
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
