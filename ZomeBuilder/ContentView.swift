import SwiftUI
import ZomeKit

struct ContentView: View {
    @State private var params: ZomeParameters = .goodKarmaDefault
    @State private var showBoundingBox: Bool = false
    @State private var showCutListSheet: Bool = false
    @State private var documentURL: URL? = nil

    // Orbit camera state lives here so the axis gizmo and the 3D view
    // both read from one source, and "Fit to view" can reset them.
    @State private var cameraYaw: Float = 0.55
    @State private var cameraPitch: Float = 0.32
    @State private var cameraDistance: Float = 3.5

    private var geometry: ZomeGeometry { Zome.build(params) }
    private var cutListRows: [CutListEntry] {
        CutList.build(geometry: geometry, params: params)
    }

    /// Pick one representative ZomeTimber per cut-list row so the sheet can
    /// show an inline 3D preview. Match by the row's stored sample dimensions.
    private var representativeTimbers: [String: ZomeTimber] {
        var byEntry: [String: ZomeTimber] = [:]
        let rows = cutListRows
        for timbers in geometry.faceTimbers {
            for timber in timbers {
                let m = CutList.measure(timber)
                for entry in rows where byEntry[entry.label] == nil {
                    if abs(m.length - entry.length) < 1e-6,
                       abs(m.cutA - entry.cutAngleA) < 1e-3,
                       abs(m.cutB - entry.cutAngleB) < 1e-3 {
                        byEntry[entry.label] = timber
                        break
                    }
                }
            }
        }
        return byEntry
    }

    private var documentTitle: String {
        documentURL?.deletingPathExtension().lastPathComponent ?? "Untitled"
    }

    var body: some View {
        HStack(spacing: 0) {
            ParameterSidebar(
                params: $params,
                showBoundingBox: $showBoundingBox,
                geometry: geometry,
                onShowCutList: { showCutListSheet = true },
                onExportCutList: exportCutList,
                onNewDocument: newDocument,
                onOpenDocument: openDocument,
                onSaveDocument: saveDocument,
                onSaveAsDocument: saveAsDocument,
                onFitToView: fitToView
            )
            .frame(width: 300)

            Divider()

            ZomeView(
                params: params,
                showBoundingBox: showBoundingBox,
                yaw: $cameraYaw,
                pitch: $cameraPitch,
                distance: $cameraDistance
            )
            .overlay(alignment: .bottomLeading) {
                AxisGizmo(yaw: cameraYaw, pitch: cameraPitch)
                    .padding(12)
            }
        }
        .frame(minWidth: 900, minHeight: 600)
        .navigationTitle(documentTitle)
        .sheet(isPresented: $showCutListSheet) {
            CutListSheet(
                rows: cutListRows,
                representatives: representativeTimbers,
                isPresented: $showCutListSheet,
                onExport: exportCutList
            )
        }
    }

    // MARK: - Camera

    private func fitToView() {
        cameraYaw = 0.55
        cameraPitch = 0.32
        // Frame the dome with margin: largest envelope dimension scaled to
        // scene units, times a comfort factor for a 45° FOV.
        let env = geometry.envelope
        let largest = max(Float(env.height), Float(env.diameter)) * ZomeView.sceneScale
        cameraDistance = max(0.6, largest * 1.6)
    }

    // MARK: - File actions

    private func newDocument() {
        params = .goodKarmaDefault
        documentURL = nil
    }

    private func openDocument() {
        #if canImport(AppKit)
        if let result = DocumentManager.open() {
            params = result.params
            documentURL = result.url
        }
        #endif
    }

    private func saveDocument() {
        #if canImport(AppKit)
        if let url = documentURL {
            DocumentManager.save(params, to: url)
        } else {
            saveAsDocument()
        }
        #endif
    }

    private func saveAsDocument() {
        #if canImport(AppKit)
        let suggested = documentURL?.lastPathComponent
            ?? "\(documentTitle).\(DocumentManager.defaultExtension)"
        if let url = DocumentManager.saveAs(params, suggestedName: suggested) {
            documentURL = url
        }
        #endif
    }

    // MARK: - Cut list export

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
