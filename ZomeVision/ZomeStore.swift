import Foundation
import Observation
import ZomeKit

/// Shared design state across the launcher window, the floating controls
/// window, and the ImmersiveSpace. SwiftUI views observe via
/// `@Environment(ZomeStore.self)`; mutations from any scene propagate
/// to the others (e.g., a slider in the in-situ controls live-updates the
/// dome the user is standing inside, and the launcher's envelope readout).
@Observable
@MainActor
final class ZomeStore {
    var params: ZomeParameters = .goodKarmaDefault

    /// `nil` when no `.zome` file has been opened (i.e., we're showing the
    /// GoodKarma default).
    var documentName: String? = nil
}
