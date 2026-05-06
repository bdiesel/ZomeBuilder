import SwiftUI
import ZomeKit
import ZomeRendering

/// Modal sheet showing the grouped cut list as a sortable table with an
/// inline 3D-ish preview of each unique timber size. Length values follow
/// the active `UnitSystem`.
struct CutListSheet: View {
    let rows: [CutListEntry]
    /// One representative ZomeTimber per cut-list row, keyed by `entry.label`.
    let representatives: [String: ZomeTimber]
    @Binding var isPresented: Bool
    let onExport: () -> Void

    @AppStorage(UnitSystem.storageKey) private var rawUnit: Int = UnitSystem.imperial.rawValue
    private var unitSystem: UnitSystem { UnitSystem(rawValue: rawUnit) ?? .imperial }

    private var maxLength: Double {
        rows.map(\.length).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Cut List")
                    .font(.title2.weight(.semibold))
                Spacer()
                Text(summary)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            Table(rows) {
                TableColumn("Label", value: \.label)
                    .width(min: 48, ideal: 56)
                TableColumn("Shape") { row in
                    if let timber = representatives[row.label] {
                        TimberSketch(timber: timber, lengthHint: row.length, maxLength: maxLength)
                    } else {
                        Color.clear
                    }
                }
                .width(min: 140, ideal: 180)
                TableColumn("Qty") { row in
                    Text("\(row.quantity)").monospacedDigit()
                }
                .width(min: 40, ideal: 48)
                TableColumn("Length") { row in
                    Text(unitSystem.formatLength(inches: row.length)).monospacedDigit()
                }
                .width(min: 90, ideal: 110)
                TableColumn("Width") { row in
                    Text(unitSystem.formatLength(inches: row.width)).monospacedDigit()
                }
                .width(min: 70, ideal: 80)
                TableColumn("Thickness") { row in
                    Text(unitSystem.formatLength(inches: row.thickness)).monospacedDigit()
                }
                .width(min: 80, ideal: 90)
                TableColumn("Cut A") { row in
                    Text(String(format: "%.1f°", row.cutAngleA)).monospacedDigit()
                }
                .width(min: 60, ideal: 70)
                TableColumn("Cut B") { row in
                    Text(String(format: "%.1f°", row.cutAngleB)).monospacedDigit()
                }
                .width(min: 60, ideal: 70)
                TableColumn("Faces") { row in
                    Text(row.faceLabels).foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Button("Done") { isPresented = false }
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Export CSV…", action: onExport)
                    .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(minWidth: 860, idealWidth: 960, minHeight: 480, idealHeight: 560)
    }

    private var summary: String {
        let totals = CutList.totals(rows)
        return "\(rows.count) sizes · \(totals.pieceCount) pieces · \(unitSystem.formatLength(inches: totals.linearUnits)) total"
    }
}
