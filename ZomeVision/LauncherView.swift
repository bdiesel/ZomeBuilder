import SwiftUI
import UniformTypeIdentifiers
import ZomeKit
import ZomeRendering

/// 2D launcher window. Shows the active design's envelope, lets the user
/// open a `.zome` file from Files / iCloud, and toggles the immersive scene.
/// Opens the floating controls window in lockstep with the ImmersiveSpace
/// so the user always has an Exit affordance while inside.
struct LauncherView: View {
    @Environment(ZomeStore.self) private var store

    @Environment(\.openImmersiveSpace)    private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow)            private var openWindow
    @Environment(\.dismissWindow)         private var dismissWindow

    @State private var immersiveOpen: Bool = false
    @State private var showFileImporter: Bool = false
    @State private var loadError: String? = nil

    private var geometry: ZomeGeometry { Zome.build(store.params) }

    var body: some View {
        VStack(spacing: 22) {
            VStack(spacing: 6) {
                Text("ZomeVision")
                    .font(.largeTitle.weight(.bold))
                Text(store.documentName ?? "Default zome")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                row("Height",   value: CutList.formatInches(geometry.envelope.height))
                row("Diameter", value: CutList.formatInches(geometry.envelope.diameter))
                row("Crowns",   value: "\(geometry.crownCount)")
                row("Timbers",  value: "\(geometry.envelope.timbersPerSpiral * store.params.numSpirals)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(.regularMaterial)
            )

            VStack(spacing: 10) {
                Button(action: toggleImmersive) {
                    Text(immersiveOpen ? "Exit Zome" : "Enter Zome")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                HStack(spacing: 10) {
                    Button("Open Design…") { showFileImporter = true }
                        .frame(maxWidth: .infinity)
                    if store.documentName != nil {
                        Button("Reset", role: .destructive) {
                            store.params = .goodKarmaDefault
                            store.documentName = nil
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .controlSize(.regular)
            }

            if let loadError {
                Text(loadError)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(40)
        .frame(minWidth: 420, minHeight: 420)
        .fileImporter(
            isPresented: $showFileImporter,
            // .zome files don't have a registered UTI yet, so accept any
            // content type — JSON-decoding validates the actual contents.
            allowedContentTypes: [.json, .data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first { loadDesign(from: url) }
            case .failure(let error):
                loadError = "Couldn't open: \(error.localizedDescription)"
            }
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }

    private func toggleImmersive() {
        Task {
            if immersiveOpen {
                await dismissImmersiveSpace()
                dismissWindow(id: "controls")
                immersiveOpen = false
            } else {
                switch await openImmersiveSpace(id: "immersive") {
                case .opened:
                    immersiveOpen = true
                    openWindow(id: "controls")
                case .userCancelled, .error:
                    immersiveOpen = false
                @unknown default:
                    immersiveOpen = false
                }
            }
        }
    }

    private func loadDesign(from url: URL) {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode(ZomeParameters.self, from: data)
            store.params = loaded
            store.documentName = url.deletingPathExtension().lastPathComponent
            loadError = nil
        } catch {
            loadError = "Not a valid zome file: \(error.localizedDescription)"
        }
    }
}
