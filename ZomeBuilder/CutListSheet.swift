import SwiftUI
import ZomeKit

/// Modal sheet showing the grouped cut list as a sortable table.
/// "Done" closes; "Export CSV…" delegates back to the host via `onExport`.
struct CutListSheet: View {
    let rows: [CutListEntry]
    @Binding var isPresented: Bool
    let onExport: () -> Void

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
                TableColumn("Qty") { row in
                    Text("\(row.quantity)").monospacedDigit()
                }
                .width(min: 40, ideal: 48)
                TableColumn("Length") { row in
                    Text(CutList.formatInches(row.length)).monospacedDigit()
                }
                .width(min: 90, ideal: 110)
                TableColumn("Width") { row in
                    Text(CutList.formatInches(row.width)).monospacedDigit()
                }
                .width(min: 70, ideal: 80)
                TableColumn("Thickness") { row in
                    Text(CutList.formatInches(row.thickness)).monospacedDigit()
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
        .frame(minWidth: 760, idealWidth: 860, minHeight: 460, idealHeight: 540)
    }

    private var summary: String {
        let totals = CutList.totals(rows)
        return "\(rows.count) sizes · \(totals.pieceCount) pieces · \(CutList.formatInches(totals.linearUnits)) total"
    }
}
