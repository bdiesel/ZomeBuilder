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

    /// Security-scoped bookmark for the most recently opened `.zome` file.
    /// Empty `Data` means no document loaded — show the GoodKarma default.
    @AppStorage("lastDocumentBookmark") private var bookmarkData: Data = Data()

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
                        Button("Reset", role: .destructive, action: resetToDefault)
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
        .onAppear { restoreLastDocument() }
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

    private func loadDesign(from url: URL, persistBookmark: Bool = true) {
        let needsAccess = url.startAccessingSecurityScopedResource()
        defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }

        do {
            let data = try Data(contentsOf: url)
            let loaded = try JSONDecoder().decode(ZomeParameters.self, from: data)
            store.params = loaded
            store.documentName = url.deletingPathExtension().lastPathComponent
            loadError = nil

            // Stash a bookmark so we can re-open this file on next launch
            // without requiring the user to re-pick it. visionOS bookmarks
            // are plain (no .withSecurityScope — that's a macOS-only flag);
            // sandbox access is mediated through the original file picker
            // grant, which the bookmark preserves.
            if persistBookmark,
               let bookmark = try? url.bookmarkData(
                   options: [],
                   includingResourceValuesForKeys: nil,
                   relativeTo: nil
               )
            {
                bookmarkData = bookmark
            }
        } catch {
            loadError = "Not a valid zome file: \(error.localizedDescription)"
        }
    }

    /// Resolve the saved bookmark on launch and reload the document. If the
    /// bookmark is stale (file moved / deleted) we silently clear it and
    /// fall back to the default zome.
    private func restoreLastDocument() {
        guard !bookmarkData.isEmpty else { return }

        var stale = false
        guard let url = try? URL(
            resolvingBookmarkData: bookmarkData,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &stale
        ) else {
            bookmarkData = Data()
            return
        }
        if stale {
            bookmarkData = Data()
            return
        }
        // Don't re-persist on restore — the bookmark we have is already
        // current; saving again would just churn UserDefaults.
        loadDesign(from: url, persistBookmark: false)
    }

    /// Called from the Reset button to revert to the default and forget
    /// the saved bookmark so the next launch starts from the default again.
    func resetToDefault() {
        store.params = .goodKarmaDefault
        store.documentName = nil
        bookmarkData = Data()
    }
}
