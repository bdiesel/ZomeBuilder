#if canImport(AppKit)
import AppKit
import ZomeKit

/// File I/O for `.zome` design files. Files are JSON-encoded
/// `ZomeParameters`. UTI is intentionally not registered — the user can
/// save with any extension; we suggest `.zome` by default.
enum DocumentManager {
    static let defaultExtension = "zome"

    /// Show an open panel and decode the chosen file.
    static func open() -> (params: ZomeParameters, url: URL)? {
        let panel = NSOpenPanel()
        panel.title = "Open Zome Design"
        panel.message = "Choose a zome design file."
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let params = try JSONDecoder().decode(ZomeParameters.self, from: data)
            return (params, url)
        } catch {
            present(error: error, message: "Couldn't open file")
            return nil
        }
    }

    /// Show a save panel and write the parameters as JSON.
    @discardableResult
    static func saveAs(_ params: ZomeParameters, suggestedName: String) -> URL? {
        let panel = NSSavePanel()
        panel.title = "Save Zome Design"
        panel.message = "Choose where to save your zome design."
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        panel.allowsOtherFileTypes = true

        guard panel.runModal() == .OK, let url = panel.url else { return nil }
        return write(params, to: url)
    }

    @discardableResult
    static func save(_ params: ZomeParameters, to url: URL) -> URL? {
        write(params, to: url)
    }

    // MARK: -

    private static func write(_ params: ZomeParameters, to url: URL) -> URL? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(params)
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            present(error: error, message: "Couldn't save file")
            return nil
        }
    }

    private static func present(error: Error, message: String) {
        let alert = NSAlert(error: error)
        alert.messageText = message
        alert.runModal()
    }
}
#endif
