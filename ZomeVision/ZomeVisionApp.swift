import SwiftUI
import ZomeKit
import ZomeRendering

@main
struct ZomeVisionApp: App {
    /// Single source of truth for the active design. Held in `@State` so it
    /// survives across body re-evaluations; injected into every scene via
    /// `.environment(_:)` so windows + immersive share one model.
    @State private var store = ZomeStore()

    /// Visual style for the timbers. Shared via @AppStorage with the Mac
    /// app, so a user's "I prefer wood" preference carries across.
    @AppStorage("timberAppearance") private var rawAppearance: String = TimberAppearance.rainbow.rawValue
    private var appearance: TimberAppearance {
        TimberAppearance(rawValue: rawAppearance) ?? .rainbow
    }

    var body: some Scene {
        WindowGroup(id: "launcher") {
            LauncherView()
                .environment(store)
        }
        .windowResizability(.contentSize)

        // Floating control panel shown while inside the immersive space.
        // Opened by the launcher when it presents the ImmersiveSpace.
        WindowGroup(id: "controls") {
            ImmersiveControlsView()
                .environment(store)
        }
        .windowResizability(.contentSize)

        ImmersiveSpace(id: "immersive") {
            ImmersiveDomeView(appearance: appearance)
                .environment(store)
        }
        .immersionStyle(selection: .constant(.mixed), in: .mixed)
    }
}
