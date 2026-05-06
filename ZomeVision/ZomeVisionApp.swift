import SwiftUI
import ZomeKit
import ZomeRendering

@main
struct ZomeVisionApp: App {
    /// Active design — the launcher window and the immersive scene both bind
    /// to this. v1 starts with the GoodKarma default; later we'll wire
    /// `.fileImporter` so a user can open a `.zome` file built in ZomeBuilder.
    @State private var params: ZomeParameters = .goodKarmaDefault

    /// Visual style for the timbers. Shares the same AppStorage key with the
    /// Mac app, so a user's "I prefer wood" pref carries across.
    @AppStorage("timberAppearance") private var rawAppearance: String = TimberAppearance.rainbow.rawValue
    private var appearance: TimberAppearance {
        TimberAppearance(rawValue: rawAppearance) ?? .rainbow
    }

    var body: some Scene {
        WindowGroup(id: "launcher") {
            LauncherView(params: $params)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "immersive") {
            ImmersiveDomeView(params: params, appearance: appearance)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
