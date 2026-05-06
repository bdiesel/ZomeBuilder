import SwiftUI
import ZomeKit

struct ContentView: View {
    @State private var params: ZomeParameters = .goodKarmaDefault
    @State private var showBoundingBox: Bool = false
    @State private var showCutListSheet: Bool = false

    private var geometry: ZomeGeometry { Zome.build(params) }
    private var cutListRows: [CutListEntry] {
        CutList.build(geometry: geometry, params: params)
    }

    var body: some View {
        HStack(spacing: 0) {
            ParameterSidebar(
                params: $params,
                showBoundingBox: $showBoundingBox,
                geometry: geometry,
                onShowCutList: { showCutListSheet = true },
                onExportCutList: exportCutList
            )
            .frame(width: 300)

            Divider()

            ZomeView(params: params, showBoundingBox: showBoundingBox)
                .overlay(alignment: .bottomLeading) {
                    AxisGizmo()
                        .padding(12)
                }
        }
        .frame(minWidth: 900, minHeight: 600)
        .sheet(isPresented: $showCutListSheet) {
            CutListSheet(
                rows: cutListRows,
                isPresented: $showCutListSheet,
                onExport: exportCutList
            )
        }
    }

    private func exportCutList() {
        #if canImport(AppKit)
        let suggested = "Zome \(params.numSpirals)x\(Int(params.thetaDegrees.rounded()))° cut list"
        CutListExporter.export(rows: cutListRows, suggestedName: suggested)
        #endif
    }
}

#Preview {
    ContentView()
}
