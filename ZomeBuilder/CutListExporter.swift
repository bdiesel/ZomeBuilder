#if canImport(AppKit)
import AppKit
import UniformTypeIdentifiers
import ZomeKit

/// Drives the NSSavePanel + writes `CutList.csv(...)` to disk.
enum CutListExporter {
    /// Show a save panel for the cut list. Returns the destination URL on
    /// success, or `nil` if the user cancelled.
    @discardableResult
    static func export(rows: [CutListEntry], suggestedName: String = "ZomeBuilder cut list") -> URL? {
        let panel = NSSavePanel()
        panel.title = "Export Cut List"
        panel.message = "Choose where to save the cut list as CSV."
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = suggestedName
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false

        guard panel.runModal() == .OK, let url = panel.url else { return nil }

        do {
            try CutList.csv(rows).write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            let alert = NSAlert(error: error)
            alert.messageText = "Couldn't save cut list"
            alert.runModal()
            return nil
        }
    }
}
#endif
